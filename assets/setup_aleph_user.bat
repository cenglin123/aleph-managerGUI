@echo off
:: setup_aleph_user.bat - �� WSL Ubuntu ������ alephGui �û�

echo ����������б�...
wsl -d Ubuntu -- bash -c "sudo apt update"

echo ��װ sudo ����...
wsl -d Ubuntu -- bash -c "sudo apt -y install sudo"

echo �����û� alephGui...
wsl -d Ubuntu -- bash -c "sudo useradd -m -s /bin/bash alephGui"

echo �������� alephGui!...
wsl -d Ubuntu -- bash -c "echo 'alephGui:alephGui!' | sudo chpasswd"

echo ���û����� sudo ��...
wsl -d Ubuntu -- bash -c "sudo usermod -aG sudo alephGui"

echo ���� sudoers ����...
wsl -d Ubuntu -- bash -c "echo 'alephGui ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/alephGui"

echo ����Ĭ�ϵ�¼�û�Ϊ alephGui...
wsl -d Ubuntu -- bash -c "echo -e '[user]\ndefault=alephGui' | sudo tee /etc/wsl.conf"

echo �޸��û�Ŀ¼Ȩ��...
wsl -d Ubuntu -- bash -c "sudo chown -R alephGui:alephGui /home/alephGui 2>/dev/null || true"

echo �û�������ɡ�