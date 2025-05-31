@echo off
:: aleph.bat - Wrapper for Aleph CLI
:: Auto-generated for WSL user: alephGui on distro: Ubuntu
setlocal
wsl -d Ubuntu /home/alephGui/.local/bin/aleph %*
endlocal
