# Uninstall-WSL.ps1
# 此脚本用于卸载WSL发行版和WSL功能
# 必须以管理员权限运行

# 检查是否以管理员权限运行
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "请以管理员身份运行此脚本！" -ForegroundColor Red
    break
}

# 函数：显示彩色文本
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

# 显示介绍
Write-ColoredText "===== WSL 完全卸载工具 =====" "Cyan"
Write-ColoredText "此脚本将：" "White"
Write-ColoredText "  1. 列出并卸载所有WSL发行版" "White"
Write-ColoredText "  2. 关闭WSL功能" "White"
Write-ColoredText "  3. 禁用Virtual Machine Platform功能" "White"
Write-ColoredText "==============================================" "Cyan"
Write-ColoredText "警告：此操作将删除所有WSL数据！" "Red"
Write-ColoredText "按Enter键继续，或按Ctrl+C取消..." "Yellow"
Read-Host

#########################
# 开始卸载过程
#########################

Write-ColoredText "Step 1: 识别并卸载所有WSL发行版..." "Cyan"

# 创建临时文件路径
$tempDir = [System.IO.Path]::GetTempPath()
$wslOutputFile = Join-Path $tempDir "wsl_list_utf16.txt"

# 将WSL列表导出到临时文件
Write-ColoredText "导出WSL发行版列表..." "Yellow"
cmd /c "wsl -l -v > $wslOutputFile"

# 显示当前WSL发行版列表
$wslOutput = Get-Content -Encoding Unicode $wslOutputFile -Raw
Write-ColoredText "当前WSL发行版列表:" "Yellow"
Write-ColoredText $wslOutput "White"

# 解析并卸载所有发行版
$foundDistros = @()

# 读取文件并解析（注意编码为Unicode）
$lines = Get-Content -Encoding Unicode $wslOutputFile | Where-Object { $_ -match '\S' } | Select-Object -Skip 1
foreach ($line in $lines) {
    $line = $line.Trim()
    if ($line) {
        # 分割行以获取发行版名称
        $lineParts = $line -split '\s+'
        $distroName = $null
        
        # 检查是否以*开头
        if ($lineParts[0] -eq "*") {
            if ($lineParts.Length -ge 2) {
                $distroName = $lineParts[1]
            }
        } else {
            $distroName = $lineParts[0]
        }
        
        if ($distroName) {
            Write-ColoredText "找到发行版: $distroName" "Green"
            $foundDistros += $distroName
        }
    }
}

# 清理临时文件
Remove-Item -Path $wslOutputFile -Force -ErrorAction SilentlyContinue

# 卸载找到的发行版
if ($foundDistros.Count -gt 0) {
    Write-ColoredText "开始卸载WSL发行版..." "Yellow"
    foreach ($distro in $foundDistros) {
        Write-ColoredText "正在卸载 $distro..." "Yellow"
        wsl --unregister $distro
        Start-Sleep -Seconds 2
    }
    Write-ColoredText "所有WSL发行版已卸载。" "Green"
} else {
    Write-ColoredText "未找到WSL发行版。" "Yellow"
}

# Step 2: 禁用WSL功能
Write-ColoredText "Step 2: 禁用WSL功能..." "Cyan"
$wslDisabled = $false

try {
    Write-ColoredText "正在禁用Windows子系统Linux功能..." "Yellow"
    Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    $wslDisabled = $true
    Write-ColoredText "WSL功能已禁用。" "Green"
} catch {
    Write-ColoredText "禁用WSL功能时出错: $_" "Red"
    Write-ColoredText "尝试使用DISM命令..." "Yellow"
    
    try {
        dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
        $wslDisabled = $true
        Write-ColoredText "WSL功能已禁用。" "Green"
    } catch {
        Write-ColoredText "无法禁用WSL功能。请尝试通过Windows功能手动禁用。" "Red"
    }
}

# Step 3: 禁用Virtual Machine Platform
Write-ColoredText "Step 3: 禁用Virtual Machine Platform功能..." "Cyan"
$vmPlatformDisabled = $false

try {
    Write-ColoredText "正在禁用Virtual Machine Platform功能..." "Yellow"
    Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    $vmPlatformDisabled = $true
    Write-ColoredText "Virtual Machine Platform功能已禁用。" "Green"
} catch {
    Write-ColoredText "禁用Virtual Machine Platform功能时出错: $_" "Red"
    Write-ColoredText "尝试使用DISM命令..." "Yellow"
    
    try {
        dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
        $vmPlatformDisabled = $true
        Write-ColoredText "Virtual Machine Platform功能已禁用。" "Green"
    } catch {
        Write-ColoredText "无法禁用Virtual Machine Platform功能。请尝试通过Windows功能手动禁用。" "Red"
    }
}

# Step 4: 清理WSL相关文件
Write-ColoredText "Step 4: 清理WSL相关文件..." "Cyan"

# 询问是否清理WSL文件
Write-ColoredText "是否清理WSL相关文件和文件夹？(Y/N)" "Yellow"
$cleanFiles = Read-Host
if ($cleanFiles -eq "Y" -or $cleanFiles -eq "y") {
    # 常见的WSL相关路径
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
            Write-ColoredText "正在删除: $path" "Yellow"
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                Write-ColoredText "  删除成功" "Green"
            } catch {
                Write-ColoredText "  删除失败: $_" "Red"
            }
        }
    }
    
    Write-ColoredText "WSL相关文件清理完成。" "Green"
} else {
    Write-ColoredText "跳过WSL文件清理。" "Yellow"
}

# 完成卸载
Write-ColoredText "===== WSL卸载完成 =====" "Green"
Write-ColoredText "WSL相关组件已被卸载。" "Cyan"
if ($wslDisabled -and $vmPlatformDisabled) {
    Write-ColoredText "你的系统需要重启以完成卸载过程。" "Yellow"
    Write-ColoredText "是否立即重启系统？(Y/N)" "Yellow"
    $reboot = Read-Host
    if ($reboot -eq "Y" -or $reboot -eq "y") {
        Write-ColoredText "系统将在10秒后重启..." "Red"
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        Write-ColoredText "请记得稍后重启系统以完成卸载过程。" "Yellow"
    }
} else {
    Write-ColoredText "卸载过程可能未完全成功。建议手动检查Windows功能并重启系统。" "Yellow"
}