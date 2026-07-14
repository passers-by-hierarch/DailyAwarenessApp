@echo off
title Daily Awareness - Flutter Web Smart Launcher

setlocal

echo ===========================================
echo   Daily Awareness Flutter Web Launcher
echo   Smart Environment Check and Auto-Fix
echo ===========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%..\frontend"

cd /d "%PROJECT_DIR%"

echo STEP 1/5 - Checking Project Structure
echo ----------------------------------------
if not exist "pubspec.yaml" (
    echo ERROR: Project directory not found!
    echo Expected: %PROJECT_DIR%
    pause
    exit /b 1
)
echo OK: Project structure valid
echo.

echo STEP 2/5 - Checking Git Installation
echo ----------------------------------------
where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git not found!
    echo Download: https://git-scm.com/download/win
    start "" "https://git-scm.com/download/win"
    pause
    exit /b 1
)
echo OK: Git installed
echo.

echo STEP 3/5 - Checking Flutter Installation
echo ----------------------------------------
where flutter >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found in PATH!
    echo Download: https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.4-stable.zip
    start "" "https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.4-stable.zip"
    echo.
    echo Installation steps:
    echo 1. Extract to C:\flutter
    echo 2. Add C:\flutter\bin to PATH
    echo 3. Run flutter doctor
    pause
    exit /b 1
)
echo OK: Flutter installed
echo.

echo STEP 4/5 - Getting Dependencies
echo ----------------------------------------
echo Running flutter pub get...
set "PUB_HOSTED_URL=https://pub.flutter-io.cn"
set "FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn"
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies!
    pause
    exit /b 1
)
echo OK: Dependencies ready
echo.

echo STEP 5/5 - Starting Daily Awareness
echo ----------------------------------------
echo This may take 30-60 seconds...
echo Visit: http://localhost:8088
echo Press Ctrl+C to stop
echo ===========================================
echo.

call flutter run -d edge --web-port 8088

endlocal