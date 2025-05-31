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

# Step 0: 确保 WSL 功能已启用并准备就绪
Write-ColoredText "Step 0: Checking and enabling WSL prerequisites..." "Cyan"

# 检查 WSL 功能是否已启用
$wslFeatureEnabled = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -eq "Enabled"
$vmPlatformEnabled = (Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State -eq "Enabled"

# 如果 WSL 功能未启用，启用它
if (-not $wslFeatureEnabled) {
    Write-ColoredText "WSL feature is not enabled. Enabling it now..." "Yellow"
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    $wslFeatureEnabled = $true
    $restartRequired = $true
} else {
    Write-ColoredText "WSL feature is already enabled." "Green"
}

# 如果虚拟机平台功能未启用，启用它
if (-not $vmPlatformEnabled) {
    Write-ColoredText "Virtual Machine Platform feature is not enabled. Enabling it now..." "Yellow"
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    $vmPlatformEnabled = $true
    $restartRequired = $true
} else {
    Write-ColoredText "Virtual Machine Platform feature is already enabled." "Green"
}

# 下载并安装WSL2内核更新包（如果需要）
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

# 设置 WSL 默认版本为 2
Write-ColoredText "Setting WSL default version to 2..." "Yellow"
wsl --set-default-version 2 2>$null

# 检查是否需要重启
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

# 使用 wsl --status 或其他方法测试 WSL 是否可用
try {
    # 方法1: 使用 wsl --status (适用于较新版本的WSL)
    wsl --status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-ColoredText "WSL is working correctly (detected via --status). Proceeding with installation." "Green"
    } else {
        # 方法2: 使用 wsl --help 来测试WSL基本功能
        $wslHelp = wsl --help 2>&1
        if ($wslHelp -match "Windows Subsystem for Linux" -or $wslHelp -match "用法:") {
            Write-ColoredText "WSL is working correctly (detected via --help). Proceeding with installation." "Green"
        } else {
            throw "WSL not responding correctly"
        }
    }
} catch {
    # 方法3: 备用检测 - 检查WSL命令是否可执行
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

# 成功配置 WSL
Write-ColoredText "WSL prerequisites are now properly configured." "Green"

#########################
# PART 1: WSL and Ubuntu Installation
#########################

Write-ColoredText "PART 1: Installing WSL and Ubuntu..." "Magenta"

# Step 1: 使用基于编码处理的方法解析WSL发行版
Write-ColoredText "Step 1: Uninstalling all existing WSL distributions..." "Cyan"

# 创建临时文件路径
$tempDir = [System.IO.Path]::GetTempPath()
$wslOutputFile = Join-Path $tempDir "wsl_list_utf16.txt"

# 将WSL列表导出到临时文件
Write-ColoredText "Exporting WSL distribution list to temp file..." "Yellow"
cmd /c "wsl -l -v > $wslOutputFile"

# 显示当前WSL发行版列表
$wslOutput = Get-Content -Encoding Unicode $wslOutputFile -Raw
Write-ColoredText "Current WSL distributions:" "Yellow"
Write-ColoredText $wslOutput "White"

# 使用PowerShell解析Ubuntu发行版
Write-ColoredText "Parsing Ubuntu distributions..." "Yellow"
$foundDistros = @()

# 读取文件并解析（注意编码为Unicode）
$lines = Get-Content -Encoding Unicode $wslOutputFile | Where-Object { $_ -match '\S' }
foreach ($line in $lines) {
    $line = $line.Trim()
    if ($line -match "Ubuntu") {
        # 去除开头的*号并分割行
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
            Write-ColoredText "Found Ubuntu distribution: $distroName" "Green"
            $foundDistros += $distroName
        }
    }
}

# 卸载找到的发行版
if ($foundDistros.Count -gt 0) {
    foreach ($distro in $foundDistros) {
        Write-ColoredText "Unregistering $distro..." "Yellow"
        wsl --unregister $distro
        Start-Sleep -Seconds 2
    }
} else {
    Write-ColoredText "No Ubuntu distributions found to unregister." "Yellow"
}

# 清理临时文件
Remove-Item -Path $wslOutputFile -Force -ErrorAction SilentlyContinue

# 备份方法：直接尝试卸载常见发行版
Write-ColoredText "Performing direct unregistration of common distributions..." "Yellow"
$commonDistros = @("Ubuntu", "Ubuntu-20.04", "Ubuntu-22.04", "Ubuntu-24.04")
foreach ($distro in $commonDistros) {
    try {
        Write-ColoredText "Attempting to unregister $distro (if it exists)..." "White"
        wsl --unregister $distro 2>$null
    } catch {
        # 忽略错误，因为这只是额外的安全措施
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

# Step 7: 等待Ubuntu安装完成并验证
Write-ColoredText "Step 7: Waiting for Ubuntu installation to complete in 15s..." "Cyan"
Start-Sleep -Seconds 15

# Ubuntu安装检测函数
function Test-UbuntuInstalled {
    try {
        # 尝试直接访问Ubuntu来检测是否安装
        wsl -d Ubuntu -- echo "test" 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

# 检查Ubuntu是否安装
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

# Step 8: 设置Ubuntu并创建默认用户
Write-ColoredText "Step 8: Setting up Ubuntu with default user..." "Cyan"

# 检测当前用户身份
Write-ColoredText "Detecting current Ubuntu user..." "Yellow"

$currentUser = $null
$maxUserCheckAttempts = 5
$userCheckAttempt = 0

while ($userCheckAttempt -lt $maxUserCheckAttempts -and -not $currentUser) {
    $userCheckAttempt++
    Write-ColoredText "Attempting to detect current user (attempt $userCheckAttempt)..." "Yellow"
    
    try {
        # 首先启动Ubuntu（如果已停止）
        wsl -d Ubuntu -- echo "starting" 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        
        # 尝试获取用户名
        $userResult = wsl -d Ubuntu -- whoami 2>&1
        
        # 检查结果是否有效
        if ($LASTEXITCODE -eq 0 -and $userResult) {
            # 安全地处理字符串
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

# 如果所有尝试都失败，尝试备用方法
if (-not $currentUser) {
    Write-ColoredText "Standard user detection failed, trying alternative methods..." "Yellow"
    
    try {
        # 方法1: 尝试使用 id 命令
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
    
    # 方法2: 检查环境变量
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
    
    # 方法3: 默认假设为root（如果没有其他用户）
    if (-not $currentUser) {
        Write-ColoredText "Could not detect user, assuming root..." "Yellow"
        $currentUser = "root"
    }
}

# 验证用户检测结果
if ($currentUser -and $currentUser -ne "") {
    Write-ColoredText "Final detected user: $currentUser" "Green"
    
    # 检查是否存在alephGui用户
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

# 根据用户身份执行相应的安装命令
Write-ColoredText "Setting up Ubuntu system and creating alephGui user..." "Yellow"

try {
    if ($currentUser -eq "root") {
        Write-ColoredText "Running commands as root (without sudo)..." "Green"
        # 以root身份直接执行，不使用sudo
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
        # 已有用户，使用sudo
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
    
    # 备用方法：尝试不同的命令组合
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

# 重启WSL以应用配置更改
Write-ColoredText "Restarting WSL to apply user configuration..." "Yellow"
wsl --shutdown
Start-Sleep -Seconds 15

# 验证用户是否创建成功
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
                
                # 再次尝试创建用户
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
                    
                    # 再次重启WSL
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

# 最终状态报告
if ($userCreated) {
    Write-ColoredText "SUCCESS: Ubuntu setup completed with alephGui user." "Green"
    
    # 验证默认用户设置
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
# PART 2: Aleph.im Installation - 安装 aleph.im
#########################

Write-ColoredText "PART 2: Installing Aleph.im..." "Magenta"

# 检查Ubuntu是否可访问
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

# 安装Aleph.im 
Write-ColoredText "Installing Aleph.im..." "Cyan"

# 根据用户创建状态选择执行命令的用户
if ($userCreated) {
    Write-ColoredText "Installing Aleph.im as user alephGui..." "Yellow"

    # 系统包更新
    wsl -d Ubuntu -u alephGui -- sudo apt update
    wsl -d Ubuntu -u alephGui -- sudo apt upgrade -y
    wsl -d Ubuntu -u alephGui -- sudo apt-get install -y python3-pip libsecp256k1-dev
    wsl -d Ubuntu -u alephGui -- sudo apt install -y pipx

    # 确保 pipx 在 PATH，并一步完成：install + inject click==8.1.7
    wsl -d Ubuntu -u alephGui -- bash -lc `
      "pipx ensurepath && \
       pipx install aleph-client && \
       pipx inject aleph-client click==8.1.7"

    if ($LASTEXITCODE -ne 0) {
        Write-ColoredText "Aleph-client 安装或注入 click 失败，尝试备用方案..." "Yellow"
        wsl -d Ubuntu -u alephGui -- bash -lc `
          "python3 -m pip install --user pipx && \
           pipx ensurepath && \
           pipx install aleph-client && \
           pipx inject aleph-client click==8.1.7"
    }

    # 创建测试文件
    wsl -d Ubuntu -u alephGui -- mkdir -p ~/aleph-test
    wsl -d Ubuntu -u alephGui -- bash -lc "echo 'This is a test file for Aleph.im' > ~/aleph-test/test.txt"

    # 验证 aleph 命令是否可用
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
    
    # 尝试安装aleph-client
    wsl -d Ubuntu -- pipx install aleph-client
    if ($LASTEXITCODE -ne 0) {
        Write-ColoredText "First attempt to install aleph-client failed, trying alternative method..." "Yellow"
        wsl -d Ubuntu -- python3 -m pip install --user pipx
        wsl -d Ubuntu -- python3 -m pipx ensurepath
        wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\""
        wsl -d Ubuntu -- python3 -m pipx install aleph-client
    }
    
    # 创建测试文件
    wsl -d Ubuntu -- mkdir -p ~/aleph-test
    wsl -d Ubuntu -- bash -c "echo 'This is a test file for Aleph.im' > ~/aleph-test/test.txt"
    
    # 验证安装
    $alephPath = wsl -d Ubuntu -- bash -c "which aleph 2>/dev/null || echo 'not found'"
}

# 验证Aleph.im安装
Write-ColoredText "Verifying Aleph.im installation..." "Yellow"
if ($alephPath -and $alephPath -ne "not found") {
    Write-ColoredText "Aleph.im successfully installed at: $alephPath" "Green"
    $alephInstalled = $true
} else {
    Write-ColoredText "Aleph.im may not be installed correctly. It was not found in PATH." "Red"
    
    # 尝试在.local目录中查找
    if ($userCreated) {
        $localPath = wsl -d Ubuntu -u alephGui -- bash -c "find ~/.local -name aleph -type f 2>/dev/null || echo 'not found'"
    } else {
        $localPath = wsl -d Ubuntu -- bash -c "find ~/.local -name aleph -type f 2>/dev/null || echo 'not found'"
    }
    
    if ($localPath -and $localPath -ne "not found") {
        Write-ColoredText "Found Aleph.im at: $localPath" "Green"
        Write-ColoredText "Adding to PATH..." "Yellow"
        
        # 使用WSL内部命令提取目录路径，避免在PowerShell中处理
        if ($userCreated) {
            # 先获取目录路径
            $dirPath = wsl -d Ubuntu -u alephGui -- bash -c "dirname '$localPath'"
            # 然后添加到PATH
            wsl -d Ubuntu -u alephGui -- bash -c "echo 'export PATH=\"\${PATH}:$dirPath\"' >> ~/.bashrc"
        } else {
            # 先获取目录路径
            $dirPath = wsl -d Ubuntu -- bash -c "dirname '$localPath'"
            # 然后添加到PATH
            wsl -d Ubuntu -- bash -c "echo 'export PATH=\"\${PATH}:$dirPath\"' >> ~/.bashrc"
        }
        $alephInstalled = $true
    } else {
        Write-ColoredText "Could not locate Aleph.im executable." "Red"
        $alephInstalled = $false
    }
}

# 最终说明
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