@echo off
title 生活助手 - Flutter Web

echo ==========================================
echo   生活助手 Flutter Web
echo ==========================================
echo.

cd /d "%~dp0..\frontend"

set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

echo [1/3] Checking Flutter environment...
where flutter >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] Flutter not found in PATH!
    echo Please install Flutter and add it to your PATH environment variable.
    pause
    exit /b 1
)
echo [OK] Flutter found

echo.
echo [2/3] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo.
    echo [ERROR] Failed to get dependencies!
    pause
    exit /b 1
)
echo [OK] Dependencies ready

echo.
echo ==========================================
echo   [3/3] Starting Daily Awareness...
echo ==========================================
echo.
echo This may take 30-60 seconds...
echo.
echo If browser doesn't open automatically, visit:
echo   http://localhost:8088
echo.
echo Press Ctrl+C to stop
echo ==========================================
echo.

call flutter run -d edge --web-port 8088

pause