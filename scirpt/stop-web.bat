@echo off
title DailyAwarenessApp - Stop Web

echo ==========================================
echo   Stop DailyAwarenessApp Flutter Web
echo ==========================================
echo.

set "WEB_PORT=8088"
set "FOUND=0"

echo [1/2] Stopping Flutter Web server...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%WEB_PORT% ^| findstr LISTENING') do (
    echo Found process on port %WEB_PORT%, PID: %%a
    taskkill /F /PID %%a >nul 2>&1
    if errorlevel 1 (
        echo Failed to stop PID %%a
    ) else (
        echo Stopped successfully
        set FOUND=1
    )
)

echo.
echo [2/2] Stopping Dart processes...
tasklist /FI "IMAGENAME eq dart.exe" | findstr /I "dart" >nul 2>&1
if not errorlevel 1 (
    echo Found dart.exe processes
    taskkill /F /IM dart.exe >nul 2>&1
    if errorlevel 1 (
        echo Failed to stop dart.exe
    ) else (
        echo dart.exe stopped
        set FOUND=1
    )
)

echo.
if "%FOUND%"=="0" (
    echo No running Flutter Web services found
) else (
    echo All services stopped
)

echo.
echo Done
pause