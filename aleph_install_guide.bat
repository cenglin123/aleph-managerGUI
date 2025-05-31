@echo off
chcp 936 >nul
title Aleph.im WSL Installer
color 0B

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 请以管理员身份运行此脚本！
    echo 右键点击此文件，选择"以管理员身份运行"。
    pause
    exit /b
)

:: 确定脚本目录
set "SCRIPT_DIR=%~dp0"
set "ASSETS_DIR=%SCRIPT_DIR%assets"
set "FULL_INSTALL=%ASSETS_DIR%\Install-AlephWSL.ps1"
set "PRESERVE_INSTALL=%ASSETS_DIR%\Install-AlephWSL-Preserve.ps1"
set "UNINSTALL_WSL=%ASSETS_DIR%\Uninstall-WSL.ps1"
set "INIT_SCRIPT=%ASSETS_DIR%\aleph_init.bat"

:: 检查必要文件是否存在
if not exist "%FULL_INSTALL%" (
    echo 警告：未找到完整安装脚本 %FULL_INSTALL%
    echo 完整安装选项将不可用。
)

if not exist "%PRESERVE_INSTALL%" (
    echo 警告：未找到保留安装脚本 %PRESERVE_INSTALL%
    echo 保留安装选项将不可用。
)

if not exist "%UNINSTALL_WSL%" (
    echo 警告：未找到卸载脚本 %UNINSTALL_WSL%
    echo 卸载WSL选项将不可用。
)

if not exist "%INIT_SCRIPT%" (
    echo 警告：未找到初始化脚本 %INIT_SCRIPT%
    echo 安装后可能需要手动初始化。
)

:menu
cls
echo ===================================================
echo             Aleph.im WSL 安装向导
echo ===================================================
echo.
echo   请选择操作:
echo.
echo   [1] 完整安装 - 卸载旧WSL发行版并安装新的Ubuntu和Aleph.im, 过程中可能需要重启 (手动安装对应./assets/Install-AlephWSL.ps1)
echo   [2] 保留安装 - 保留现有Ubuntu并安装Aleph.im(如无则安装, 手动安装对应./assets/Install-AlephWSL-Preserve.ps1)
echo   [3] 卸载程序 - 卸载所有WSL发行版和WSL功能（警告：如果有使用中的 WSL 请勿使用，建议参考readme手动卸载）
echo   [4] 退出程序
echo.
echo ===================================================
echo.

choice /c 1234 /n /m "请输入选项 [1-4]: "
if errorlevel 4 goto end
if errorlevel 3 goto uninstall_wsl
if errorlevel 2 goto preserve_install
if errorlevel 1 goto full_install
goto menu

:full_install
cls
if not exist "%FULL_INSTALL%" (
    echo 错误：未找到完整安装脚本 %FULL_INSTALL%
    echo 请确保文件结构正确。
    pause
    goto menu
)

echo 正在启动完整安装模式...
echo 此模式将卸载所有现有WSL发行版，安装新的Ubuntu并设置Aleph.im。
echo.
choice /c YN /n /m "是否继续? (Y/N) "
if errorlevel 2 goto menu

echo 执行PowerShell安装脚本...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%FULL_INSTALL%\"' -Verb RunAs}"

:: 等待PowerShell脚本完成
echo 等待安装完成...
timeout /t 5 >nul
echo 请耐心等待PowerShell脚本执行结束，然后按回车开始初始化aleph...
pause >nul

:: 运行初始化脚本
if exist "%INIT_SCRIPT%" (
    echo 正在运行初始化脚本...
    call "%INIT_SCRIPT%"
) else (
    echo 警告：无法找到初始化脚本 %INIT_SCRIPT%
    echo 请手动运行初始化过程。
)
goto end

:preserve_install
cls
if not exist "%PRESERVE_INSTALL%" (
    echo 错误：未找到保留安装脚本 %PRESERVE_INSTALL%
    echo 请确保文件结构正确。
    pause
    goto menu
)

echo 正在启动保留安装模式...
echo 此模式将保留现有的Ubuntu发行版，并在其中安装Aleph.im。
echo 如果没有安装Ubuntu，则会先安装Ubuntu再继续后续步骤。
echo.
choice /c YN /n /m "是否继续? (Y/N) "
if errorlevel 2 goto menu

echo 执行PowerShell安装脚本（保留模式）...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%PRESERVE_INSTALL%\"' -Verb RunAs}"

:: 等待PowerShell脚本完成
echo 等待安装完成...
timeout /t 5 >nul
echo 按任意键确认安装已完成，然后运行初始化脚本...
pause >nul

:: 运行初始化脚本
if exist "%INIT_SCRIPT%" (
    echo 正在运行初始化脚本...
    call "%INIT_SCRIPT%"
) else (
    echo 警告：无法找到初始化脚本 %INIT_SCRIPT%
    echo 请手动运行初始化过程。
)
goto end

:uninstall_wsl
cls
if not exist "%UNINSTALL_WSL%" (
    echo 错误：未找到卸载脚本 %UNINSTALL_WSL%
    echo 请确保文件结构正确。
    pause
    goto menu
)

echo 正在启动WSL卸载模式...
echo 此模式将卸载所有WSL发行版和WSL功能。
echo 警告：此操作将删除所有WSL数据！
echo.
choice /c YN /n /m "是否继续? (Y/N) "
if errorlevel 2 goto menu

echo 执行PowerShell卸载脚本...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%UNINSTALL_WSL%\"' -Verb RunAs}"

echo 卸载过程正在进行...
echo 请在PowerShell窗口中完成卸载操作。
echo 完成后请关闭PowerShell窗口并返回此处。
echo.
pause
goto end

:end
echo.
echo 感谢使用Aleph.im WSL安装向导！
echo.
pause
exit /b