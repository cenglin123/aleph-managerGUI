@echo off
:: setup_aleph_user.bat - 在 WSL Ubuntu 中设置 alephGui 用户

echo 更新软件包列表...
wsl -d Ubuntu -- bash -c "sudo apt update"

echo 安装 sudo 工具...
wsl -d Ubuntu -- bash -c "sudo apt -y install sudo"

echo 创建用户 alephGui...
wsl -d Ubuntu -- bash -c "sudo useradd -m -s /bin/bash alephGui"

echo 设置密码 alephGui!...
wsl -d Ubuntu -- bash -c "echo 'alephGui:alephGui!' | sudo chpasswd"

echo 将用户加入 sudo 组...
wsl -d Ubuntu -- bash -c "sudo usermod -aG sudo alephGui"

echo 配置 sudoers 免密...
wsl -d Ubuntu -- bash -c "echo 'alephGui ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/alephGui"

echo 设置默认登录用户为 alephGui...
wsl -d Ubuntu -- bash -c "echo -e '[user]\ndefault=alephGui' | sudo tee /etc/wsl.conf"

echo 修复用户目录权限...
wsl -d Ubuntu -- bash -c "sudo chown -R alephGui:alephGui /home/alephGui 2>/dev/null || true"

echo 用户配置完成。