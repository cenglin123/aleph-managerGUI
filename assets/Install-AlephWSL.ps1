# Install-AlephComplete.ps1
# Complete script to install WSL, Ubuntu with default credentials, and Aleph.im
# This script must be run with administrative privileges

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator!" -ForegroundColor Red
    break
}

# Function to display colored text
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

# Display introduction
Write-ColoredText "===== Aleph.im Complete Installation Script =====" "Cyan"
Write-ColoredText "This script will:" "White"
Write-ColoredText "  1. Uninstall any existing WSL distributions" "White"
Write-ColoredText "  2. Install WSL and Ubuntu" "White"
Write-ColoredText "  3. Set up Ubuntu with default credentials (alephGui/alephGui!)" "White"
Write-ColoredText "  4. Install Aleph.im and its dependencies" "White"
Write-ColoredText "==============================================" "Cyan"
## Write-ColoredText "Press Enter to continue or Ctrl+C to cancel..." "Yellow"
## Read-Host

#########################
# PART 0: Ensure WSL is available and ready
#########################

Write-ColoredText "PART 0: Ensuring WSL is available..." "Magenta"

# Step 0: ȷ�� WSL ���������ò�׼������
Write-ColoredText "Step 0: Checking and enabling WSL prerequisites..." "Cyan"

# ��� WSL �����Ƿ�������
$wslFeatureEnabled = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -eq "Enabled"
$vmPlatformEnabled = (Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State -eq "Enabled"

# ��� WSL ����δ���ã�������
if (-not $wslFeatureEnabled) {
    Write-ColoredText "WSL feature is not enabled. Enabling it now..." "Yellow"
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    $wslFeatureEnabled = $true
    $restartRequired = $true
} else {
    Write-ColoredText "WSL feature is already enabled." "Green"
}

# ��������ƽ̨����δ���ã�������
if (-not $vmPlatformEnabled) {
    Write-ColoredText "Virtual Machine Platform feature is not enabled. Enabling it now..." "Yellow"
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    $vmPlatformEnabled = $true
    $restartRequired = $true
} else {
    Write-ColoredText "Virtual Machine Platform feature is already enabled." "Green"
}

# ���ز���װWSL2�ں˸��°��������Ҫ��
$wslUpdatePath = "$env:TEMP\wsl_update_x64.msi"
if (-not (Test-Path $wslUpdatePath)) {
    try {
        Write-ColoredText "Downloading WSL2 kernel update package..." "Yellow"
        $wslUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
        Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdatePath -UseBasicParsing
        
        Write-ColoredText "Installing WSL2 kernel update package..." "Yellow"
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $wslUpdatePath, "/quiet", "/norestart" -Wait
        Write-ColoredText "WSL2 kernel update package installed successfully." "Green"
    } catch {
        Write-ColoredText "Failed to download or install WSL2 kernel update package. Error: $_" "Red"
        Write-ColoredText "Please download and install it manually from: https://aka.ms/wsl2kernel" "Yellow"
    }
}

# ���� WSL Ĭ�ϰ汾Ϊ 2
Write-ColoredText "Setting WSL default version to 2..." "Yellow"
wsl --set-default-version 2 2>$null

# ����Ƿ���Ҫ����
if ($restartRequired) {
    Write-ColoredText "WARNING: System restart is required to fully enable WSL features." "Red"
    Write-ColoredText "Do you want to restart the system now? (Y/N)" "Yellow"
    $restart = Read-Host
    if ($restart -eq "Y" -or $restart -eq "y") {
        Write-ColoredText "Restarting system in 10 seconds. Please run this script again after restart." "Red"
        Start-Sleep -Seconds 10
        Restart-Computer -Force
        exit
    } else {
        Write-ColoredText "Continuing without restart. This might cause issues with WSL installation." "Yellow"
        Write-ColoredText "If installation fails, please restart and run the script again." "Yellow"
    }
}

# ʹ�� wsl --status �������������� WSL �Ƿ����
try {
    # ����1: ʹ�� wsl --status (�����ڽ��°汾��WSL)
    wsl --status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-ColoredText "WSL is working correctly (detected via --status). Proceeding with installation." "Green"
    } else {
        # ����2: ʹ�� wsl --help ������WSL��������
        $wslHelp = wsl --help 2>&1
        if ($wslHelp -match "Windows Subsystem for Linux" -or $wslHelp -match "�÷�:") {
            Write-ColoredText "WSL is working correctly (detected via --help). Proceeding with installation." "Green"
        } else {
            throw "WSL not responding correctly"
        }
    }
} catch {
    # ����3: ���ü�� - ���WSL�����Ƿ��ִ��
    try {
        $wslVersion = wsl --version 2>&1
        if ($wslVersion -match "WSL" -or $LASTEXITCODE -eq 0) {
            Write-ColoredText "WSL is working correctly (detected via --version). Proceeding with installation." "Green"
        } else {
            throw "WSL version check failed"
        }
    } catch {
        Write-ColoredText "ERROR: WSL is not working correctly despite being enabled." "Red"
        Write-ColoredText "Please restart your computer and run this script again." "Yellow"
        exit 1
    }
}

# �ɹ����� WSL
Write-ColoredText "WSL prerequisites are now properly configured." "Green"

#########################
# PART 1: WSL and Ubuntu Installation
#########################

Write-ColoredText "PART 1: Installing WSL and Ubuntu..." "Magenta"

# Step 1: ʹ�û��ڱ��봦��ķ�������WSL���а�
Write-ColoredText "Step 1: Uninstalling all existing WSL distributions..." "Cyan"

# ������ʱ�ļ�·��
$tempDir = [System.IO.Path]::GetTempPath()
$wslOutputFile = Join-Path $tempDir "wsl_list_utf16.txt"

# ��WSL�б�������ʱ�ļ�
Write-ColoredText "Exporting WSL distribution list to temp file..." "Yellow"
cmd /c "wsl -l -v > $wslOutputFile"

# ��ʾ��ǰWSL���а��б�
$wslOutput = Get-Content -Encoding Unicode $wslOutputFile -Raw
Write-ColoredText "Current WSL distributions:" "Yellow"
Write-ColoredText $wslOutput "White"

# ʹ��PowerShell����Ubuntu���а�
Write-ColoredText "Parsing Ubuntu distributions..." "Yellow"
$foundDistros = @()

# ��ȡ�ļ���������ע�����ΪUnicode��
$lines = Get-Content -Encoding Unicode $wslOutputFile | Where-Object { $_ -match '\S' }
foreach ($line in $lines) {
    $line = $line.Trim()
    if ($line -match "Ubuntu") {
        # ȥ����ͷ��*�Ų��ָ���
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
            Write-ColoredText "Found Ubuntu distribution: $distroName" "Green"
            $foundDistros += $distroName
        }
    }
}

# ж���ҵ��ķ��а�
if ($foundDistros.Count -gt 0) {
    foreach ($distro in $foundDistros) {
        Write-ColoredText "Unregistering $distro..." "Yellow"
        wsl --unregister $distro
        Start-Sleep -Seconds 2
    }
} else {
    Write-ColoredText "No Ubuntu distributions found to unregister." "Yellow"
}

# ������ʱ�ļ�
Remove-Item -Path $wslOutputFile -Force -ErrorAction SilentlyContinue

# ���ݷ�����ֱ�ӳ���ж�س������а�
Write-ColoredText "Performing direct unregistration of common distributions..." "Yellow"
$commonDistros = @("Ubuntu", "Ubuntu-20.04", "Ubuntu-22.04", "Ubuntu-24.04")
foreach ($distro in $commonDistros) {
    try {
        Write-ColoredText "Attempting to unregister $distro (if it exists)..." "White"
        wsl --unregister $distro 2>$null
    } catch {
        # ���Դ�����Ϊ��ֻ�Ƕ���İ�ȫ��ʩ
    }
}

# Step 2: Disable and re-enable WSL feature
Write-ColoredText "Step 2: Disabling WSL feature..." "Cyan"
dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart

Write-ColoredText "Step 3: Re-enabling WSL feature..." "Cyan"
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

Write-ColoredText "Step 4: Enabling Virtual Machine Platform..." "Cyan"
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-ColoredText "Step 5: Setting WSL default version to 2..." "Cyan"
wsl --set-default-version 2

# Step 6: Install Ubuntu
Write-ColoredText "Step 6: Installing Ubuntu via WSL..." "Cyan"

# Directly use WSL command to install Ubuntu
Write-ColoredText "Using WSL command to install Ubuntu..." "Yellow"
wsl --install -d Ubuntu  --no-launch

# Step 7: �ȴ�Ubuntu��װ��ɲ���֤
Write-ColoredText "Step 7: Waiting for Ubuntu installation to complete in 15s..." "Cyan"
Start-Sleep -Seconds 15

# Ubuntu��װ��⺯��
function Test-UbuntuInstalled {
    try {
        # ����ֱ�ӷ���Ubuntu������Ƿ�װ
        wsl -d Ubuntu -- echo "test" 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

# ���Ubuntu�Ƿ�װ
$ubuntuInstalled = $false
$maxAttempts = 10
$attempt = 0

while (-not $ubuntuInstalled -and $attempt -lt $maxAttempts) {
    $attempt++
    Write-ColoredText "Checking if Ubuntu is installed (attempt $attempt of $maxAttempts)..." "Yellow"
    
    if (Test-UbuntuInstalled) {
        $ubuntuInstalled = $true
        Write-ColoredText "Ubuntu is installed successfully!" "Green"
    } else {
        Write-ColoredText "Ubuntu not detected yet. Waiting 30 seconds before checking again..." "Yellow"
        Start-Sleep -Seconds 30
    }
}

if (-not $ubuntuInstalled) {
    Write-ColoredText "Ubuntu installation could not be confirmed after $maxAttempts attempts." "Red"
    Write-ColoredText "Please try the following manual steps:" "Yellow"
    Write-ColoredText "1. Open Microsoft Store and search for Ubuntu" "Yellow"
    Write-ColoredText "2. Install Ubuntu 24.04 LTS or any available version" "Yellow"
    Write-ColoredText "3. After installation completes, run this script again" "Yellow"
    exit 1
}

# Step 8: ����Ubuntu������Ĭ���û�
Write-ColoredText "Step 8: Setting up Ubuntu with default user..." "Cyan"

# ��⵱ǰ�û����
Write-ColoredText "Detecting current Ubuntu user..." "Yellow"

$currentUser = $null
$maxUserCheckAttempts = 5
$userCheckAttempt = 0

while ($userCheckAttempt -lt $maxUserCheckAttempts -and -not $currentUser) {
    $userCheckAttempt++
    Write-ColoredText "Attempting to detect current user (attempt $userCheckAttempt)..." "Yellow"
    
    try {
        # ��������Ubuntu�������ֹͣ��
        wsl -d Ubuntu -- echo "starting" 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        
        # ���Ի�ȡ�û���
        $userResult = wsl -d Ubuntu -- whoami 2>&1
        
        # ������Ƿ���Ч
        if ($LASTEXITCODE -eq 0 -and $userResult) {
            # ��ȫ�ش����ַ���
            $userString = $userResult | Out-String
            if ($userString -and $userString.Trim() -ne "") {
                $currentUser = $userString.Trim()
                Write-ColoredText "Detected current user: $currentUser" "Green"
                break
            }
        }
        
        Write-ColoredText "User detection attempt $userCheckAttempt failed, retrying..." "Yellow"
        Start-Sleep -Seconds 3
        
    } catch {
        Write-ColoredText "Error during user detection attempt $userCheckAttempt : $_" "Yellow"
        Start-Sleep -Seconds 3
    }
}

# ������г��Զ�ʧ�ܣ����Ա��÷���
if (-not $currentUser) {
    Write-ColoredText "Standard user detection failed, trying alternative methods..." "Yellow"
    
    try {
        # ����1: ����ʹ�� id ����
        $idResult = wsl -d Ubuntu -- id -un 2>&1
        if ($LASTEXITCODE -eq 0 -and $idResult) {
            $idString = $idResult | Out-String
            if ($idString -and $idString.Trim() -ne "") {
                $currentUser = $idString.Trim()
                Write-ColoredText "User detected via id command: $currentUser" "Green"
            }
        }
    } catch {
        Write-ColoredText "Alternative method 1 failed: $_" "Yellow"
    }
    
    # ����2: ��黷������
    if (-not $currentUser) {
        try {
            $envResult = wsl -d Ubuntu -- bash -c 'echo $USER' 2>&1
            if ($LASTEXITCODE -eq 0 -and $envResult) {
                $envString = $envResult | Out-String
                if ($envString -and $envString.Trim() -ne "") {
                    $currentUser = $envString.Trim()
                    Write-ColoredText "User detected via environment variable: $currentUser" "Green"
                }
            }
        } catch {
            Write-ColoredText "Alternative method 2 failed: $_" "Yellow"
        }
    }
    
    # ����3: Ĭ�ϼ���Ϊroot�����û�������û���
    if (-not $currentUser) {
        Write-ColoredText "Could not detect user, assuming root..." "Yellow"
        $currentUser = "root"
    }
}

# ��֤�û������
if ($currentUser -and $currentUser -ne "") {
    Write-ColoredText "Final detected user: $currentUser" "Green"
    
    # ����Ƿ����alephGui�û�
    try {
        wsl -d Ubuntu -- id alephGui 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColoredText "alephGui user already exists in the system." "Green"
            $userCreated = $true
        } else {
            Write-ColoredText "alephGui user does not exist. Will install for current user: $currentUser" "Yellow"
            $userCreated = $false
        }
    } catch {
        Write-ColoredText "Could not check for alephGui user, assuming it doesn't exist." "Yellow"
        $userCreated = $false
    }
} else {
    Write-ColoredText "ERROR: Could not detect any user. Ubuntu may not be properly configured." "Red"
    Write-ColoredText "Please run the full installation script first to set up Ubuntu properly." "Yellow"
    exit 1
}

# �����û����ִ����Ӧ�İ�װ����
Write-ColoredText "Setting up Ubuntu system and creating alephGui user..." "Yellow"

try {
    if ($currentUser -eq "root") {
        Write-ColoredText "Running commands as root (without sudo)..." "Green"
        # ��root���ֱ��ִ�У���ʹ��sudo
        wsl -d Ubuntu -- apt update
        wsl -d Ubuntu -- apt -y install sudo passwd
        wsl -d Ubuntu -- useradd -m -s /bin/bash alephGui
        wsl -d Ubuntu -- bash -c "echo 'alephGui:alephGui!' | chpasswd"
        wsl -d Ubuntu -- usermod -aG sudo alephGui
        wsl -d Ubuntu -- bash -c "echo 'alephGui ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/alephGui"
        wsl -d Ubuntu -- chmod 440 /etc/sudoers.d/alephGui
        wsl -d Ubuntu -- bash -c "echo -e '[user]\ndefault=alephGui' > /etc/wsl.conf"
        wsl -d Ubuntu -- chown -R alephGui:alephGui /home/alephGui
    } else {
        Write-ColoredText "Running commands as existing user (with sudo)..." "Green"
        # �����û���ʹ��sudo
        wsl -d Ubuntu -- sudo apt update
        wsl -d Ubuntu -- sudo apt -y install sudo passwd
        wsl -d Ubuntu -- sudo useradd -m -s /bin/bash alephGui
        wsl -d Ubuntu -- sudo bash -c "echo 'alephGui:alephGui!' | chpasswd"
        wsl -d Ubuntu -- sudo usermod -aG sudo alephGui
        wsl -d Ubuntu -- sudo bash -c "echo 'alephGui ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/alephGui"
        wsl -d Ubuntu -- sudo chmod 440 /etc/sudoers.d/alephGui
        wsl -d Ubuntu -- sudo bash -c "echo -e '[user]\ndefault=alephGui' > /etc/wsl.conf"
        wsl -d Ubuntu -- sudo chown -R alephGui:alephGui /home/alephGui
    }
    
    Write-ColoredText "User setup commands completed successfully." "Green"
    
} catch {
    Write-ColoredText "ERROR during user setup: $_" "Red"
    Write-ColoredText "Attempting fallback method..." "Yellow"
    
    # ���÷��������Բ�ͬ���������
    try {
        if ($currentUser -eq "root") {
            wsl -d Ubuntu -- bash -c "apt update && apt -y install sudo && useradd -m -s /bin/bash alephGui && echo 'alephGui:alephGui!' | chpasswd && usermod -aG sudo alephGui"
        } else {
            wsl -d Ubuntu -- bash -c "sudo apt update && sudo apt -y install sudo && sudo useradd -m -s /bin/bash alephGui && echo 'alephGui:alephGui!' | sudo chpasswd && sudo usermod -aG sudo alephGui"
        }
    } catch {
        Write-ColoredText "ERROR: Fallback method also failed." "Red"
    }
}

# ����WSL��Ӧ�����ø���
Write-ColoredText "Restarting WSL to apply user configuration..." "Yellow"
wsl --shutdown
Start-Sleep -Seconds 15

# ��֤�û��Ƿ񴴽��ɹ�
Write-ColoredText "Verifying alephGui user creation..." "Yellow"
$userCreated = $false
$maxVerifyAttempts = 3
$verifyAttempt = 0

while ($verifyAttempt -lt $maxVerifyAttempts -and -not $userCreated) {
    $verifyAttempt++
    Write-ColoredText "User verification attempt $verifyAttempt..." "Yellow"
    
    try {
        $userCheck = wsl -d Ubuntu -- id -u alephGui 2>&1
        if ($LASTEXITCODE -eq 0 -and $userCheck -match "^\d+$") {
            Write-ColoredText "SUCCESS: User alephGui created successfully with UID: $userCheck" "Green"
            $userCreated = $true
        } else {
            Write-ColoredText "User verification failed: $userCheck" "Yellow"
            if ($verifyAttempt -lt $maxVerifyAttempts) {
                Write-ColoredText "Retrying user creation..." "Yellow"
                
                # �ٴγ��Դ����û�
                try {
                    $retryUser = wsl -d Ubuntu -- whoami 2>&1
                    if ($retryUser.Trim() -eq "root") {
                        wsl -d Ubuntu -- useradd -m -s /bin/bash alephGui 2>/dev/null
                        wsl -d Ubuntu -- bash -c "echo 'alephGui:alephGui!' | chpasswd"
                        wsl -d Ubuntu -- usermod -aG sudo alephGui
                        wsl -d Ubuntu -- bash -c "echo 'alephGui ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/alephGui"
                        wsl -d Ubuntu -- bash -c "echo -e '[user]\ndefault=alephGui' > /etc/wsl.conf"
                    } else {
                        wsl -d Ubuntu -- sudo useradd -m -s /bin/bash alephGui 2>/dev/null
                        wsl -d Ubuntu -- sudo bash -c "echo 'alephGui:alephGui!' | chpasswd"
                        wsl -d Ubuntu -- sudo usermod -aG sudo alephGui
                        wsl -d Ubuntu -- sudo bash -c "echo 'alephGui ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/alephGui"
                        wsl -d Ubuntu -- sudo bash -c "echo -e '[user]\ndefault=alephGui' > /etc/wsl.conf"
                    }
                    
                    # �ٴ�����WSL
                    wsl --shutdown
                    Start-Sleep -Seconds 10
                } catch {
                    Write-ColoredText "Retry attempt failed: $_" "Red"
                }
            }
        }
    } catch {
        Write-ColoredText "Error during user verification: $_" "Yellow"
        Start-Sleep -Seconds 5
    }
}

# ����״̬����
if ($userCreated) {
    Write-ColoredText "SUCCESS: Ubuntu setup completed with alephGui user." "Green"
    
    # ��֤Ĭ���û�����
    try {
        $defaultUserCheck = wsl -d Ubuntu -- bash -c "grep 'default=' /etc/wsl.conf 2>/dev/null || echo 'not set'"
        if ($defaultUserCheck -match "alephGui") {
            Write-ColoredText "Default user is correctly set to alephGui." "Green"
        } else {
            Write-ColoredText "Warning: Default user setting may not be applied correctly." "Yellow"
        }
    } catch {
        Write-ColoredText "Could not verify default user setting." "Yellow"
    }
} else {
    Write-ColoredText "ERROR: Could not create alephGui user after multiple attempts." "Red"
    Write-ColoredText "Manual intervention may be required." "Red"
}

Write-ColoredText "Part 1 completed: WSL and Ubuntu installation with user setup" "Green"










#########################
# PART 2: Aleph.im Installation - ��װ aleph.im
#########################

Write-ColoredText "PART 2: Installing Aleph.im..." "Magenta"

# ���Ubuntu�Ƿ�ɷ���
$ubuntuAccessible = $false
try {
    $ubuntuCheck = wsl -d Ubuntu -- echo "WSL Ubuntu check"
    if ($ubuntuCheck -match "check") {
        $ubuntuAccessible = $true
        Write-ColoredText "WSL Ubuntu is accessible. Proceeding with Aleph.im installation..." "Green"
    }
}
catch {
    Write-ColoredText "Error accessing Ubuntu. Trying to restart WSL..." "Yellow"
}

if (-not $ubuntuAccessible) {
    Write-ColoredText "Restarting WSL to ensure accessibility..." "Yellow"
    wsl --shutdown
    Start-Sleep -Seconds 10
    try {
        $ubuntuCheck = wsl -d Ubuntu -- echo "WSL Ubuntu check retry"
        if ($ubuntuCheck -match "check") {
            $ubuntuAccessible = $true
            Write-ColoredText "WSL Ubuntu is now accessible" "Green"
        }
    }
    catch {
        Write-ColoredText "Error: Cannot access Ubuntu. Please restart your computer and run Part 2 of this script." "Red"
        exit 1
    }
}

# ��װAleph.im 
Write-ColoredText "Installing Aleph.im..." "Cyan"

# �����û�����״̬ѡ��ִ��������û�
if ($userCreated) {
    Write-ColoredText "Installing Aleph.im as user alephGui..." "Yellow"

    # ϵͳ������
    wsl -d Ubuntu -u alephGui -- sudo apt update
    wsl -d Ubuntu -u alephGui -- sudo apt upgrade -y
    wsl -d Ubuntu -u alephGui -- sudo apt-get install -y python3-pip libsecp256k1-dev
    wsl -d Ubuntu -u alephGui -- sudo apt install -y pipx

    # ȷ�� pipx �� PATH����һ����ɣ�install + inject click==8.1.7
    wsl -d Ubuntu -u alephGui -- bash -lc `
      "pipx ensurepath && \
       pipx install aleph-client && \
       pipx inject aleph-client click==8.1.7"

    if ($LASTEXITCODE -ne 0) {
        Write-ColoredText "Aleph-client ��װ��ע�� click ʧ�ܣ����Ա��÷���..." "Yellow"
        wsl -d Ubuntu -u alephGui -- bash -lc `
          "python3 -m pip install --user pipx && \
           pipx ensurepath && \
           pipx install aleph-client && \
           pipx inject aleph-client click==8.1.7"
    }

    # ���������ļ�
    wsl -d Ubuntu -u alephGui -- mkdir -p ~/aleph-test
    wsl -d Ubuntu -u alephGui -- bash -lc "echo 'This is a test file for Aleph.im' > ~/aleph-test/test.txt"

    # ��֤ aleph �����Ƿ����
    $alephPath = wsl -d Ubuntu -u alephGui -- bash -lc "which aleph 2>/dev/null || echo 'not found'"
} else {
    Write-ColoredText "Installing Aleph.im as default user..." "Yellow"
    
    wsl -d Ubuntu -- sudo apt update
    wsl -d Ubuntu -- sudo apt upgrade -y
    wsl -d Ubuntu -- sudo apt-get install -y python3-pip libsecp256k1-dev
    wsl -d Ubuntu -- sudo apt install -y pipx
    wsl -d Ubuntu -- pipx ensurepath
    wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\""
    wsl -d Ubuntu -- bash -c "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
    
    # ���԰�װaleph-client
    wsl -d Ubuntu -- pipx install aleph-client
    if ($LASTEXITCODE -ne 0) {
        Write-ColoredText "First attempt to install aleph-client failed, trying alternative method..." "Yellow"
        wsl -d Ubuntu -- python3 -m pip install --user pipx
        wsl -d Ubuntu -- python3 -m pipx ensurepath
        wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\""
        wsl -d Ubuntu -- python3 -m pipx install aleph-client
    }
    
    # ���������ļ�
    wsl -d Ubuntu -- mkdir -p ~/aleph-test
    wsl -d Ubuntu -- bash -c "echo 'This is a test file for Aleph.im' > ~/aleph-test/test.txt"
    
    # ��֤��װ
    $alephPath = wsl -d Ubuntu -- bash -c "which aleph 2>/dev/null || echo 'not found'"
}

# ��֤Aleph.im��װ
Write-ColoredText "Verifying Aleph.im installation..." "Yellow"
if ($alephPath -and $alephPath -ne "not found") {
    Write-ColoredText "Aleph.im successfully installed at: $alephPath" "Green"
    $alephInstalled = $true
} else {
    Write-ColoredText "Aleph.im may not be installed correctly. It was not found in PATH." "Red"
    
    # ������.localĿ¼�в���
    if ($userCreated) {
        $localPath = wsl -d Ubuntu -u alephGui -- bash -c "find ~/.local -name aleph -type f 2>/dev/null || echo 'not found'"
    } else {
        $localPath = wsl -d Ubuntu -- bash -c "find ~/.local -name aleph -type f 2>/dev/null || echo 'not found'"
    }
    
    if ($localPath -and $localPath -ne "not found") {
        Write-ColoredText "Found Aleph.im at: $localPath" "Green"
        Write-ColoredText "Adding to PATH..." "Yellow"
        
        # ʹ��WSL�ڲ�������ȡĿ¼·����������PowerShell�д���
        if ($userCreated) {
            # �Ȼ�ȡĿ¼·��
            $dirPath = wsl -d Ubuntu -u alephGui -- bash -c "dirname '$localPath'"
            # Ȼ����ӵ�PATH
            wsl -d Ubuntu -u alephGui -- bash -c "echo 'export PATH=\"\${PATH}:$dirPath\"' >> ~/.bashrc"
        } else {
            # �Ȼ�ȡĿ¼·��
            $dirPath = wsl -d Ubuntu -- bash -c "dirname '$localPath'"
            # Ȼ����ӵ�PATH
            wsl -d Ubuntu -- bash -c "echo 'export PATH=\"\${PATH}:$dirPath\"' >> ~/.bashrc"
        }
        $alephInstalled = $true
    } else {
        Write-ColoredText "Could not locate Aleph.im executable." "Red"
        $alephInstalled = $false
    }
}

# ����˵��
Write-ColoredText "===== INSTALLATION COMPLETED! =====" "Green"
Write-ColoredText "To use Aleph.im in Ubuntu WSL:" "Cyan"
Write-ColoredText "1. Start Ubuntu: Type 'ubuntu' or 'wsl' in your command prompt" "Cyan"

if ($userCreated) {
    Write-ColoredText "2. You should be automatically logged in as alephGui" "Cyan"
    Write-ColoredText "   If prompted for credentials:" "Cyan"
    Write-ColoredText "   Username: alephGui" "Green"
    Write-ColoredText "   Password: alephGui!" "Green"
} else {
    Write-ColoredText "2. User alephGui could not be created. You will be logged in as default user." "Yellow"
}

if ($alephInstalled) {
    Write-ColoredText "3. Run Aleph.im commands using the 'aleph' command" "Cyan"
    Write-ColoredText "4. If 'aleph' command is not found, run: source ~/.bashrc" "Yellow"
} else {
    Write-ColoredText "3. Aleph.im installation may not have completed successfully." "Red"
    Write-ColoredText "   You may need to manually install it after logging into WSL:" "Yellow"
    Write-ColoredText "   sudo apt update && sudo apt install -y python3-pip libsecp256k1-dev pipx" "Yellow"
    Write-ColoredText "   pipx ensurepath" "Yellow"
    Write-ColoredText "   source ~/.bashrc" "Yellow"
    Write-ColoredText "   pipx install aleph-client" "Yellow"
}

Write-ColoredText "===============================" "Green"