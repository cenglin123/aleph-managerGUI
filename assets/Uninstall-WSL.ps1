# Uninstall-WSL.ps1
# �˽ű�����ж��WSL���а��WSL����
# �����Թ���ԱȨ������

# ����Ƿ��Թ���ԱȨ������
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "���Թ���Ա������д˽ű���" -ForegroundColor Red
    break
}

# ��������ʾ��ɫ�ı�
function Write-ColoredText {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Text,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
        [string]$ForegroundColor
    )
    
    Write-Host $Text -ForegroundColor $ForegroundColor
}

# ��ʾ����
Write-ColoredText "===== WSL ��ȫж�ع��� =====" "Cyan"
Write-ColoredText "�˽ű�����" "White"
Write-ColoredText "  1. �г���ж������WSL���а�" "White"
Write-ColoredText "  2. �ر�WSL����" "White"
Write-ColoredText "  3. ����Virtual Machine Platform����" "White"
Write-ColoredText "==============================================" "Cyan"
Write-ColoredText "���棺�˲�����ɾ������WSL���ݣ�" "Red"
Write-ColoredText "��Enter����������Ctrl+Cȡ��..." "Yellow"
Read-Host

#########################
# ��ʼж�ع���
#########################

Write-ColoredText "Step 1: ʶ��ж������WSL���а�..." "Cyan"

# ������ʱ�ļ�·��
$tempDir = [System.IO.Path]::GetTempPath()
$wslOutputFile = Join-Path $tempDir "wsl_list_utf16.txt"

# ��WSL�б�������ʱ�ļ�
Write-ColoredText "����WSL���а��б�..." "Yellow"
cmd /c "wsl -l -v > $wslOutputFile"

# ��ʾ��ǰWSL���а��б�
$wslOutput = Get-Content -Encoding Unicode $wslOutputFile -Raw
Write-ColoredText "��ǰWSL���а��б�:" "Yellow"
Write-ColoredText $wslOutput "White"

# ������ж�����з��а�
$foundDistros = @()

# ��ȡ�ļ���������ע�����ΪUnicode��
$lines = Get-Content -Encoding Unicode $wslOutputFile | Where-Object { $_ -match '\S' } | Select-Object -Skip 1
foreach ($line in $lines) {
    $line = $line.Trim()
    if ($line) {
        # �ָ����Ի�ȡ���а�����
        $lineParts = $line -split '\s+'
        $distroName = $null
        
        # ����Ƿ���*��ͷ
        if ($lineParts[0] -eq "*") {
            if ($lineParts.Length -ge 2) {
                $distroName = $lineParts[1]
            }
        } else {
            $distroName = $lineParts[0]
        }
        
        if ($distroName) {
            Write-ColoredText "�ҵ����а�: $distroName" "Green"
            $foundDistros += $distroName
        }
    }
}

# ������ʱ�ļ�
Remove-Item -Path $wslOutputFile -Force -ErrorAction SilentlyContinue

# ж���ҵ��ķ��а�
if ($foundDistros.Count -gt 0) {
    Write-ColoredText "��ʼж��WSL���а�..." "Yellow"
    foreach ($distro in $foundDistros) {
        Write-ColoredText "����ж�� $distro..." "Yellow"
        wsl --unregister $distro
        Start-Sleep -Seconds 2
    }
    Write-ColoredText "����WSL���а���ж�ء�" "Green"
} else {
    Write-ColoredText "δ�ҵ�WSL���а档" "Yellow"
}

# Step 2: ����WSL����
Write-ColoredText "Step 2: ����WSL����..." "Cyan"
$wslDisabled = $false

try {
    Write-ColoredText "���ڽ���Windows��ϵͳLinux����..." "Yellow"
    Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    $wslDisabled = $true
    Write-ColoredText "WSL�����ѽ��á�" "Green"
} catch {
    Write-ColoredText "����WSL����ʱ����: $_" "Red"
    Write-ColoredText "����ʹ��DISM����..." "Yellow"
    
    try {
        dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
        $wslDisabled = $true
        Write-ColoredText "WSL�����ѽ��á�" "Green"
    } catch {
        Write-ColoredText "�޷�����WSL���ܡ��볢��ͨ��Windows�����ֶ����á�" "Red"
    }
}

# Step 3: ����Virtual Machine Platform
Write-ColoredText "Step 3: ����Virtual Machine Platform����..." "Cyan"
$vmPlatformDisabled = $false

try {
    Write-ColoredText "���ڽ���Virtual Machine Platform����..." "Yellow"
    Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    $vmPlatformDisabled = $true
    Write-ColoredText "Virtual Machine Platform�����ѽ��á�" "Green"
} catch {
    Write-ColoredText "����Virtual Machine Platform����ʱ����: $_" "Red"
    Write-ColoredText "����ʹ��DISM����..." "Yellow"
    
    try {
        dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
        $vmPlatformDisabled = $true
        Write-ColoredText "Virtual Machine Platform�����ѽ��á�" "Green"
    } catch {
        Write-ColoredText "�޷�����Virtual Machine Platform���ܡ��볢��ͨ��Windows�����ֶ����á�" "Red"
    }
}

# Step 4: ����WSL����ļ�
Write-ColoredText "Step 4: ����WSL����ļ�..." "Cyan"

# ѯ���Ƿ�����WSL�ļ�
Write-ColoredText "�Ƿ�����WSL����ļ����ļ��У�(Y/N)" "Yellow"
$cleanFiles = Read-Host
if ($cleanFiles -eq "Y" -or $cleanFiles -eq "y") {
    # ������WSL���·��
    $wslPaths = @(
        "$env:LOCALAPPDATA\Packages\*Ubuntu*",
        "$env:LOCALAPPDATA\Packages\*debian*",
        "$env:LOCALAPPDATA\Packages\*kali*",
        "$env:LOCALAPPDATA\Packages\*WSL*",
        "$env:USERPROFILE\.wslconfig",
        "$env:USERPROFILE\.wsl",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Ubuntu*",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Debian*"
    )
    
    foreach ($path in $wslPaths) {
        if (Test-Path $path) {
            Write-ColoredText "����ɾ��: $path" "Yellow"
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                Write-ColoredText "  ɾ���ɹ�" "Green"
            } catch {
                Write-ColoredText "  ɾ��ʧ��: $_" "Red"
            }
        }
    }
    
    Write-ColoredText "WSL����ļ�������ɡ�" "Green"
} else {
    Write-ColoredText "����WSL�ļ�����" "Yellow"
}

# ���ж��
Write-ColoredText "===== WSLж����� =====" "Green"
Write-ColoredText "WSL�������ѱ�ж�ء�" "Cyan"
if ($wslDisabled -and $vmPlatformDisabled) {
    Write-ColoredText "���ϵͳ��Ҫ���������ж�ع��̡�" "Yellow"
    Write-ColoredText "�Ƿ���������ϵͳ��(Y/N)" "Yellow"
    $reboot = Read-Host
    if ($reboot -eq "Y" -or $reboot -eq "y") {
        Write-ColoredText "ϵͳ����10�������..." "Red"
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        Write-ColoredText "��ǵ��Ժ�����ϵͳ�����ж�ع��̡�" "Yellow"
    }
} else {
    Write-ColoredText "ж�ع��̿���δ��ȫ�ɹ��������ֶ����Windows���ܲ�����ϵͳ��" "Yellow"
}