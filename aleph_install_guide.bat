@echo off
chcp 936 >nul
title Aleph.im WSL Installer
color 0B

:: ������ԱȨ��
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ���Թ���Ա������д˽ű���
    echo �Ҽ�������ļ���ѡ��"�Թ���Ա�������"��
    pause
    exit /b
)

:: ȷ���ű�Ŀ¼
set "SCRIPT_DIR=%~dp0"
set "ASSETS_DIR=%SCRIPT_DIR%assets"
set "FULL_INSTALL=%ASSETS_DIR%\Install-AlephWSL.ps1"
set "PRESERVE_INSTALL=%ASSETS_DIR%\Install-AlephWSL-Preserve.ps1"
set "UNINSTALL_WSL=%ASSETS_DIR%\Uninstall-WSL.ps1"
set "INIT_SCRIPT=%ASSETS_DIR%\aleph_init.bat"

:: ����Ҫ�ļ��Ƿ����
if not exist "%FULL_INSTALL%" (
    echo ���棺δ�ҵ�������װ�ű� %FULL_INSTALL%
    echo ������װѡ������á�
)

if not exist "%PRESERVE_INSTALL%" (
    echo ���棺δ�ҵ�������װ�ű� %PRESERVE_INSTALL%
    echo ������װѡ������á�
)

if not exist "%UNINSTALL_WSL%" (
    echo ���棺δ�ҵ�ж�ؽű� %UNINSTALL_WSL%
    echo ж��WSLѡ������á�
)

if not exist "%INIT_SCRIPT%" (
    echo ���棺δ�ҵ���ʼ���ű� %INIT_SCRIPT%
    echo ��װ�������Ҫ�ֶ���ʼ����
)

:menu
cls
echo ===================================================
echo             Aleph.im WSL ��װ��
echo ===================================================
echo.
echo   ��ѡ�����:
echo.
echo   [1] ������װ - ж�ؾ�WSL���а沢��װ�µ�Ubuntu��Aleph.im, �����п�����Ҫ���� (�ֶ���װ��Ӧ./assets/Install-AlephWSL.ps1)
echo   [2] ������װ - ��������Ubuntu����װAleph.im(������װ, �ֶ���װ��Ӧ./assets/Install-AlephWSL-Preserve.ps1)
echo   [3] ж�س��� - ж������WSL���а��WSL���ܣ����棺�����ʹ���е� WSL ����ʹ�ã�����ο�readme�ֶ�ж�أ�
echo   [4] �˳�����
echo.
echo ===================================================
echo.

choice /c 1234 /n /m "������ѡ�� [1-4]: "
if errorlevel 4 goto end
if errorlevel 3 goto uninstall_wsl
if errorlevel 2 goto preserve_install
if errorlevel 1 goto full_install
goto menu

:full_install
cls
if not exist "%FULL_INSTALL%" (
    echo ����δ�ҵ�������װ�ű� %FULL_INSTALL%
    echo ��ȷ���ļ��ṹ��ȷ��
    pause
    goto menu
)

echo ��������������װģʽ...
echo ��ģʽ��ж����������WSL���а棬��װ�µ�Ubuntu������Aleph.im��
echo.
choice /c YN /n /m "�Ƿ����? (Y/N) "
if errorlevel 2 goto menu

echo ִ��PowerShell��װ�ű�...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%FULL_INSTALL%\"' -Verb RunAs}"

:: �ȴ�PowerShell�ű����
echo �ȴ���װ���...
timeout /t 5 >nul
echo �����ĵȴ�PowerShell�ű�ִ�н�����Ȼ�󰴻س���ʼ��ʼ��aleph...
pause >nul

:: ���г�ʼ���ű�
if exist "%INIT_SCRIPT%" (
    echo �������г�ʼ���ű�...
    call "%INIT_SCRIPT%"
) else (
    echo ���棺�޷��ҵ���ʼ���ű� %INIT_SCRIPT%
    echo ���ֶ����г�ʼ�����̡�
)
goto end

:preserve_install
cls
if not exist "%PRESERVE_INSTALL%" (
    echo ����δ�ҵ�������װ�ű� %PRESERVE_INSTALL%
    echo ��ȷ���ļ��ṹ��ȷ��
    pause
    goto menu
)

echo ��������������װģʽ...
echo ��ģʽ���������е�Ubuntu���а棬�������а�װAleph.im��
echo ���û�а�װUbuntu������Ȱ�װUbuntu�ټ����������衣
echo.
choice /c YN /n /m "�Ƿ����? (Y/N) "
if errorlevel 2 goto menu

echo ִ��PowerShell��װ�ű�������ģʽ��...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%PRESERVE_INSTALL%\"' -Verb RunAs}"

:: �ȴ�PowerShell�ű����
echo �ȴ���װ���...
timeout /t 5 >nul
echo �������ȷ�ϰ�װ����ɣ�Ȼ�����г�ʼ���ű�...
pause >nul

:: ���г�ʼ���ű�
if exist "%INIT_SCRIPT%" (
    echo �������г�ʼ���ű�...
    call "%INIT_SCRIPT%"
) else (
    echo ���棺�޷��ҵ���ʼ���ű� %INIT_SCRIPT%
    echo ���ֶ����г�ʼ�����̡�
)
goto end

:uninstall_wsl
cls
if not exist "%UNINSTALL_WSL%" (
    echo ����δ�ҵ�ж�ؽű� %UNINSTALL_WSL%
    echo ��ȷ���ļ��ṹ��ȷ��
    pause
    goto menu
)

echo ��������WSLж��ģʽ...
echo ��ģʽ��ж������WSL���а��WSL���ܡ�
echo ���棺�˲�����ɾ������WSL���ݣ�
echo.
choice /c YN /n /m "�Ƿ����? (Y/N) "
if errorlevel 2 goto menu

echo ִ��PowerShellж�ؽű�...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%UNINSTALL_WSL%\"' -Verb RunAs}"

echo ж�ع������ڽ���...
echo ����PowerShell���������ж�ز�����
echo ��ɺ���ر�PowerShell���ڲ����ش˴���
echo.
pause
goto end

:end
echo.
echo ��лʹ��Aleph.im WSL��װ�򵼣�
echo.
pause
exit /b