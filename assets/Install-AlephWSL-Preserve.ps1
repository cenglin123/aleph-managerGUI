# Install-AlephWSL-Preserve.ps1
# ��������Ubuntu����װAleph.im�ű������û��Ubuntu��װ��
# �˽ű������Թ���ԱȨ������

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
Write-ColoredText "===== Aleph.im ������װ�ű� =====" "Cyan"
Write-ColoredText "�˽ű�����" "White"
Write-ColoredText "  1. �������Ubuntu��װ" "White"
Write-ColoredText "  2. ��⵱ǰ�û����" "White"
Write-ColoredText "  3. ��װAleph.im��������" "White"
Write-ColoredText "==============================================" "Cyan"

#########################
# PART 1: ���Ubuntu���û�״̬
#########################

Write-ColoredText "PART 1: Detecting Ubuntu and user status..." "Magenta"

# ���Ubuntu�Ƿ�ɷ���
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

# ��⵱ǰ�û����
Write-ColoredText "Detecting current Ubuntu user..." "Yellow"

try {
    $currentUser = wsl -d Ubuntu -- whoami 2>&1
    if ($LASTEXITCODE -eq 0 -and $currentUser -and $currentUser.Trim() -ne "") {
        $currentUser = $currentUser.Trim()
        Write-ColoredText "Current Ubuntu user: $currentUser" "Green"
        
        # ����Ƿ����alephGui�û�
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
# PART 2: Aleph.im Installation - ��װ aleph.im
#########################

Write-ColoredText "PART 2: Installing Aleph.im..." "Magenta"

# �����û�״̬ѡ��װ��ʽ
if ($userCreated) {
    Write-ColoredText "Installing Aleph.im for alephGui user..." "Yellow"
    
    # ΪalephGui�û���װ
    try {
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
        
    } catch {
        Write-ColoredText "Error installing for alephGui user: $_" "Red"
        Write-ColoredText "Falling back to current user installation..." "Yellow"
        $userCreated = $false
    }
}

if (-not $userCreated) {
    Write-ColoredText "Installing Aleph.im for current user: $currentUser..." "Yellow"
    
    # ���ݵ�ǰ�û����ѡ�����ʽ
    try {
        if ($currentUser -eq "root") {
            Write-ColoredText "Installing as root (without sudo)..." "Green"
            # ��root���ֱ��ִ��
            wsl -d Ubuntu -- apt update
            wsl -d Ubuntu -- apt upgrade -y
            wsl -d Ubuntu -- apt-get install -y python3-pip libsecp256k1-dev pipx
            wsl -d Ubuntu -- pipx ensurepath
            wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\""
            wsl -d Ubuntu -- bash -c "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
            
            # ��װaleph-client
            wsl -d Ubuntu -- pipx install aleph-client
            if ($LASTEXITCODE -ne 0) {
                Write-ColoredText "First attempt failed, trying alternative method..." "Yellow"
                wsl -d Ubuntu -- python3 -m pip install --user pipx
                wsl -d Ubuntu -- python3 -m pipx ensurepath
                wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\""
                wsl -d Ubuntu -- python3 -m pipx install aleph-client
            }
            
            # ע��click����
            wsl -d Ubuntu -- pipx inject aleph-client click==8.1.7
            
        } else {
            Write-ColoredText "Installing as user $currentUser (with sudo)..." "Green"
            # ʹ��sudoִ��
            wsl -d Ubuntu -- sudo apt update
            wsl -d Ubuntu -- sudo apt upgrade -y
            wsl -d Ubuntu -- sudo apt-get install -y python3-pip libsecp256k1-dev
            wsl -d Ubuntu -- sudo apt install -y pipx
            wsl -d Ubuntu -- pipx ensurepath
            wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\""
            wsl -d Ubuntu -- bash -c "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
            
            # ��װaleph-client
            wsl -d Ubuntu -- pipx install aleph-client
            if ($LASTEXITCODE -ne 0) {
                Write-ColoredText "First attempt failed, trying alternative method..." "Yellow"
                wsl -d Ubuntu -- python3 -m pip install --user pipx
                wsl -d Ubuntu -- python3 -m pipx ensurepath
                wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\""
                wsl -d Ubuntu -- python3 -m pipx install aleph-client
            }
            
            # ע��click����
            wsl -d Ubuntu -- pipx inject aleph-client click==8.1.7
        }
        
        # ���������ļ�
        wsl -d Ubuntu -- mkdir -p ~/aleph-test
        wsl -d Ubuntu -- bash -c "echo 'This is a test file for Aleph.im' > ~/aleph-test/test.txt"
        
        # ��֤��װ
        $alephPath = wsl -d Ubuntu -- bash -c "which aleph 2>/dev/null || echo 'not found'"
        
    } catch {
        Write-ColoredText "Error during installation: $_" "Red"
        $alephPath = "not found"
    }
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