# Install-AlephWSL-Preserve.ps1
# 保留现有Ubuntu并安装Aleph.im脚本（如果没有Ubuntu则安装）
# 此脚本必须以管理员权限运行

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
Write-ColoredText "===== Aleph.im 保留安装脚本 =====" "Cyan"
Write-ColoredText "此脚本将：" "White"
Write-ColoredText "  1. 检测现有Ubuntu安装" "White"
Write-ColoredText "  2. 检测当前用户身份" "White"
Write-ColoredText "  3. 安装Aleph.im及其依赖" "White"
Write-ColoredText "==============================================" "Cyan"

#########################
# PART 1: 检测Ubuntu和用户状态
#########################

Write-ColoredText "PART 1: Detecting Ubuntu and user status..." "Magenta"

# 检查Ubuntu是否可访问
$ubuntuAccessible = $false
$currentUser = $null
$userCreated = $false

try {
    $ubuntuCheck = wsl -d Ubuntu -- echo "WSL Ubuntu check"
    if ($ubuntuCheck -match "check") {
        $ubuntuAccessible = $true
        Write-ColoredText "WSL Ubuntu is accessible." "Green"
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
        Write-ColoredText "Error: Cannot access Ubuntu. Please ensure Ubuntu is installed." "Red"
        Write-ColoredText "You can install Ubuntu by running the full installation script first." "Yellow"
        exit 1
    }
}

# 检测当前用户身份
Write-ColoredText "Detecting current Ubuntu user..." "Yellow"

try {
    $currentUser = wsl -d Ubuntu -- whoami 2>&1
    if ($LASTEXITCODE -eq 0 -and $currentUser -and $currentUser.Trim() -ne "") {
        $currentUser = $currentUser.Trim()
        Write-ColoredText "Current Ubuntu user: $currentUser" "Green"
        
        # 检查是否存在alephGui用户
        wsl -d Ubuntu -- id alephGui 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColoredText "alephGui user already exists in the system." "Green"
            $userCreated = $true
        } else {
            Write-ColoredText "alephGui user does not exist. Will install for current user: $currentUser" "Yellow"
            $userCreated = $false
        }
    } else {
        Write-ColoredText "Could not detect current user. Exiting..." "Red"
        exit 1
    }
} catch {
    Write-ColoredText "Error detecting user: $_" "Red"
    exit 1
}

#########################
# PART 2: Aleph.im Installation - 安装 aleph.im
#########################

Write-ColoredText "PART 2: Installing Aleph.im..." "Magenta"

# 根据用户状态选择安装方式
if ($userCreated) {
    Write-ColoredText "Installing Aleph.im for alephGui user..." "Yellow"
    
    # 为alephGui用户安装
    try {
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
        
    } catch {
        Write-ColoredText "Error installing for alephGui user: $_" "Red"
        Write-ColoredText "Falling back to current user installation..." "Yellow"
        $userCreated = $false
    }
}

if (-not $userCreated) {
    Write-ColoredText "Installing Aleph.im for current user: $currentUser..." "Yellow"
    
    # 根据当前用户身份选择命令方式
    try {
        if ($currentUser -eq "root") {
            Write-ColoredText "Installing as root (without sudo)..." "Green"
            # 以root身份直接执行
            wsl -d Ubuntu -- apt update
            wsl -d Ubuntu -- apt upgrade -y
            wsl -d Ubuntu -- apt-get install -y python3-pip libsecp256k1-dev pipx
            wsl -d Ubuntu -- pipx ensurepath
            wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\""
            wsl -d Ubuntu -- bash -c "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
            
            # 安装aleph-client
            wsl -d Ubuntu -- pipx install aleph-client
            if ($LASTEXITCODE -ne 0) {
                Write-ColoredText "First attempt failed, trying alternative method..." "Yellow"
                wsl -d Ubuntu -- python3 -m pip install --user pipx
                wsl -d Ubuntu -- python3 -m pipx ensurepath
                wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\""
                wsl -d Ubuntu -- python3 -m pipx install aleph-client
            }
            
            # 注入click依赖
            wsl -d Ubuntu -- pipx inject aleph-client click==8.1.7
            
        } else {
            Write-ColoredText "Installing as user $currentUser (with sudo)..." "Green"
            # 使用sudo执行
            wsl -d Ubuntu -- sudo apt update
            wsl -d Ubuntu -- sudo apt upgrade -y
            wsl -d Ubuntu -- sudo apt-get install -y python3-pip libsecp256k1-dev
            wsl -d Ubuntu -- sudo apt install -y pipx
            wsl -d Ubuntu -- pipx ensurepath
            wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\""
            wsl -d Ubuntu -- bash -c "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
            
            # 安装aleph-client
            wsl -d Ubuntu -- pipx install aleph-client
            if ($LASTEXITCODE -ne 0) {
                Write-ColoredText "First attempt failed, trying alternative method..." "Yellow"
                wsl -d Ubuntu -- python3 -m pip install --user pipx
                wsl -d Ubuntu -- python3 -m pipx ensurepath
                wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\""
                wsl -d Ubuntu -- python3 -m pipx install aleph-client
            }
            
            # 注入click依赖
            wsl -d Ubuntu -- pipx inject aleph-client click==8.1.7
        }
        
        # 创建测试文件
        wsl -d Ubuntu -- mkdir -p ~/aleph-test
        wsl -d Ubuntu -- bash -c "echo 'This is a test file for Aleph.im' > ~/aleph-test/test.txt"
        
        # 验证安装
        $alephPath = wsl -d Ubuntu -- bash -c "which aleph 2>/dev/null || echo 'not found'"
        
    } catch {
        Write-ColoredText "Error during installation: $_" "Red"
        $alephPath = "not found"
    }
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
    Write-ColoredText "2. You can login as alephGui or your current user" "Cyan"
    Write-ColoredText "   alephGui credentials:" "Cyan"
    Write-ColoredText "   Username: alephGui" "Green"
    Write-ColoredText "   Password: alephGui!" "Green"
} else {
    Write-ColoredText "2. You will be logged in as: $currentUser" "Yellow"
    Write-ColoredText "   Aleph.im is installed for this user." "Yellow"
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
    Write-ColoredText "   pipx inject aleph-client click==8.1.7" "Yellow"
}

Write-ColoredText "===============================" "Green"