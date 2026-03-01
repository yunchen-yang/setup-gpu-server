@echo off
setlocal

:: Default values
set REMOTE_PORT=22
set LOCAL_PORT=8000
set REMOTE_API_PORT=8000

echo ==============================================
echo Setup GPU Server - SSH Tunneling (Windows)
echo ==============================================

if "%~1"=="" (
    echo Usage: %~nx0 user@remote_ip [local_port] [remote_api_port]
    echo Example: %~nx0 ubuntu@192.168.1.50
    echo Example: %~nx0 ubuntu@192.168.1.50 8080 8000
    exit /b 1
)

set REMOTE_TARGET=%~1

if not "%~2"=="" (
    set LOCAL_PORT=%~2
)

if not "%~3"=="" (
    set REMOTE_API_PORT=%~3
)

echo Establishing SSH tunnel to forward local port %LOCAL_PORT% to remote port %REMOTE_API_PORT% on %REMOTE_TARGET%...
echo Note: This window will stay open to keep the tunnel alive. Press Ctrl+C to close it.
echo.

ssh -N -L %LOCAL_PORT%:127.0.0.1:%REMOTE_API_PORT% %REMOTE_TARGET%

if errorlevel 1 (
    echo [ERROR] SSH tunnel disconnected or failed to connect.
    exit /b 1
)
