@echo off
title DailyAwarenessApp - Stop

echo ==========================================
echo   Stop DailyAwarenessApp Services
echo ==========================================
echo.

set FOUND=0

for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 ^| findstr LISTENING') do (
    echo Prototype found (port 3000), PID: %%a
    taskkill /F /PID %%a >nul 2>&1
    echo Stopped
    set FOUND=1
)

for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3001 ^| findstr LISTENING') do (
    echo Prototype found (port 3001), PID: %%a
    taskkill /F /PID %%a >nul 2>&1
    echo Stopped
    set FOUND=1
)

for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3002 ^| findstr LISTENING') do (
    echo Prototype found (port 3002), PID: %%a
    taskkill /F /PID %%a >nul 2>&1
    echo Stopped
    set FOUND=1
)

for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3003 ^| findstr LISTENING') do (
    echo Prototype found (port 3003), PID: %%a
    taskkill /F /PID %%a >nul 2>&1
    echo Stopped
    set FOUND=1
)

for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3004 ^| findstr LISTENING') do (
    echo Prototype found (port 3004), PID: %%a
    taskkill /F /PID %%a >nul 2>&1
    echo Stopped
    set FOUND=1
)

for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080 ^| findstr LISTENING') do (
    echo Backend found (port 8080), PID: %%a
    taskkill /F /PID %%a >nul 2>&1
    echo Stopped
    set FOUND=1
)

if "%FOUND%"=="0" (
    echo No running services found
)

echo.
echo Done
echo.
pause
