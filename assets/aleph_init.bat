@echo off
setlocal EnableDelayedExpansion
:: aleph_switch.bat - Auto-detect and configure Aleph for Ubuntu WSL distro
:: -------------------------------------------------------------------------

echo.
echo === Auto switching WSL default distro to the one with Aleph ===
echo.

:: Step 1: Dump WSL list
wsl -l -v > tmp_wsl_utf16.txt

:: Step 2: PowerShell parses first matching Ubuntu distro name (fixing * case)
for /f "tokens=*" %%D in ('powershell -Command ^
  "$lines = Get-Content -Encoding Unicode 'tmp_wsl_utf16.txt';" ^
  "foreach ($line in $lines) {" ^
    "$trim = $line.Trim();" ^
    "if ($trim -match 'Ubuntu') {" ^
      "$parts = $trim -split '\s+';" ^
      "if ($parts.Length -ge 2) {" ^
        "if ($parts[0] -eq '*') { Write-Output $parts[1]; break } else { Write-Output $parts[0]; break }" ^
      "}" ^
    "}" ^
  }'
) do (
    set "UBUNTU_DISTRO=%%D"
)

del tmp_wsl_utf16.txt

if not defined UBUNTU_DISTRO (
    echo [ERROR] No Ubuntu-based distro found via -v listing.
    goto end
)

echo [INFO] Found Ubuntu distro: !UBUNTU_DISTRO!
echo.

:: Step 3: Set it as default
wsl --set-default !UBUNTU_DISTRO!
if errorlevel 1 (
    echo [ERROR] Failed to set !UBUNTU_DISTRO! as default.
    goto end
)
echo [OK] !UBUNTU_DISTRO! is now the default WSL distro.
echo.

:: Step 4: Get username inside Ubuntu
echo [INFO] Detecting WSL username...
for /f "tokens=*" %%u in ('wsl -d !UBUNTU_DISTRO! bash -c "whoami"') do set WSL_USER=%%u

if not defined WSL_USER (
    echo [ERROR] Failed to retrieve username from !UBUNTU_DISTRO!.
    goto end
)
echo [INFO] Detected WSL user: !WSL_USER!
echo.

:: Step 5: Verify Aleph binary
echo [INFO] Verifying Aleph installation path...
wsl -d !UBUNTU_DISTRO! test -f /home/!WSL_USER!/.local/bin/aleph
if errorlevel 1 (
    echo [WARN] Aleph not found at expected path: /home/!WSL_USER!/.local/bin/aleph
) else (
    echo [OK] Aleph found at /home/!WSL_USER!/.local/bin/aleph
)

:: Step 6: Create aleph.bat wrapper
echo [INFO] Creating Windows wrapper for Aleph...

if not exist ..\tools (
    mkdir ..\tools
)

> ..\tools\aleph.bat (
    echo @echo off
    echo :: aleph.bat - Wrapper for Aleph CLI
    echo :: Auto-generated for WSL user: !WSL_USER! on distro: !UBUNTU_DISTRO!
    echo setlocal
    echo wsl -d !UBUNTU_DISTRO! /home/!WSL_USER!/.local/bin/aleph %%*
    echo endlocal
)

echo.
echo [OK] Created ^"..\tools\aleph.bat^" wrapper script.
echo You can move this file to a directory in your PATH to use ^`aleph^` globally.
echo.

echo === Configuration completed successfully ===
echo.
echo Recommendation: Move "%TOOLS_DIR%\aleph.bat" to a directory in your PATH, such as:
echo   - C:\Users\%USERNAME%\AppData\Local\Microsoft\WindowsApps
echo   - Or create a bin folder and add it to your PATH
echo.

:end
echo Press any key to exit...
pause >nul