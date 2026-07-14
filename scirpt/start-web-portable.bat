@echo off
title Daily Awareness - Flutter Web (Portable)

setlocal

echo ===========================================
echo   Daily Awareness Flutter Web Launcher
echo   (Portable - Relative Path)
echo ===========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%..\frontend"

cd /d "%PROJECT_DIR%"

if not exist "pubspec.yaml" (
    echo ERROR: Project directory not found!
    echo Script location: %SCRIPT_DIR%
    echo Expected project: %PROJECT_DIR%
    pause
    exit /b 1
)

echo [1/3] Checking Flutter environment...
where flutter >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found in PATH!
    echo.
    echo Please install Flutter and add it to your PATH environment variable.
    echo Download: https://docs.flutter.dev/get-started/install
    pause
    exit /b 1
)
echo [OK] Flutter found

echo.
echo [2/3] Setting up mirrors for China...
set "PUB_HOSTED_URL=https://pub.flutter-io.cn"
set "FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn"

echo.
echo [3/3] Starting Daily Awareness...
echo.
echo This may take 30-60 seconds...
echo.
echo Visit: http://localhost:8088
echo Press Ctrl+C to stop
echo ===========================================
echo.

call flutter run -d edge --web-port 8088

endlocal