@echo off
setlocal enabledelayedexpansion
title Daily Awareness - Flutter Web Smart Launcher

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%..\frontend"
set "LOG_FILE=%SCRIPT_DIR%startup.log"

echo =========================================== > "%LOG_FILE%"
echo   Daily Awareness Flutter Web Launcher      >> "%LOG_FILE%"
echo   Smart Environment Check and Auto-Fix      >> "%LOG_FILE%"
echo =========================================== >> "%LOG_FILE%"
echo Start time: %date% %time%                  >> "%LOG_FILE%"
echo.                                           >> "%LOG_FILE%"

echo ===========================================
echo   Daily Awareness Flutter Web Launcher
echo   Smart Environment Check and Auto-Fix
echo ===========================================
echo.

cd /d "%PROJECT_DIR%" 2>> "%LOG_FILE%"
if errorlevel 1 (
    echo ERROR: Failed to change directory!
    echo Check: %PROJECT_DIR%
    echo.
    echo Log: %LOG_FILE%
    pause
    exit /b 1
)

echo STEP 1/5 - Checking Project Structure
echo ----------------------------------------
echo [STEP 1/5] Checking Project Structure... >> "%LOG_FILE%"
if not exist "pubspec.yaml" (
    echo ERROR: Project directory not found!
    echo Expected: %PROJECT_DIR%
    echo ERROR: pubspec.yaml not found >> "%LOG_FILE%"
    echo Expected: %PROJECT_DIR% >> "%LOG_FILE%"
    echo.
    echo Log: %LOG_FILE%
    pause
    exit /b 1
)
echo OK: Project structure valid
echo OK: Project structure valid >> "%LOG_FILE%"
echo.

echo STEP 2/5 - Checking Git Installation
echo ----------------------------------------
echo [STEP 2/5] Checking Git Installation... >> "%LOG_FILE%"
where git >nul 2>&1
if errorlevel 1 (
    echo Git not found in PATH, searching common locations...
    echo Git not found in PATH, searching... >> "%LOG_FILE%"
    
    set "GIT_FOUND="
    
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        if exist "%%d:\Program Files\Git\bin\git.exe" (
            echo Found at %%d:\Program Files\Git
            set "PATH=%%d:\Program Files\Git\bin;!PATH!"
            set "GIT_FOUND=1"
            echo Found Git at %%d:\Program Files\Git >> "%LOG_FILE%"
        )
        if exist "%%d:\Program Files (x86)\Git\bin\git.exe" (
            echo Found at %%d:\Program Files (x86)\Git
            set "PATH=%%d:\Program Files (x86)\Git\bin;!PATH!"
            set "GIT_FOUND=1"
            echo Found Git at %%d:\Program Files (x86)\Git >> "%LOG_FILE%"
        )
        if exist "%%d:\Git\bin\git.exe" (
            echo Found at %%d:\Git
            set "PATH=%%d:\Git\bin;!PATH!"
            set "GIT_FOUND=1"
            echo Found Git at %%d:\Git >> "%LOG_FILE%"
        )
        if exist "%%d:\tools\Git\bin\git.exe" (
            echo Found at %%d:\tools\Git
            set "PATH=%%d:\tools\Git\bin;!PATH!"
            set "GIT_FOUND=1"
            echo Found Git at %%d:\tools\Git >> "%LOG_FILE%"
        )
    )
    
    if not defined GIT_FOUND (
        echo ERROR: Git not found on any drive!
        echo Download: https://git-scm.com/download/win
        echo ERROR: Git not found >> "%LOG_FILE%"
        echo Download: https://git-scm.com/download/win >> "%LOG_FILE%"
        start "" "https://git-scm.com/download/win"
        echo.
        echo Please install Git first, then restart this script.
        echo.
        echo Log: %LOG_FILE%
        pause
        exit /b 1
    )
)
echo OK: Git ready
echo OK: Git ready >> "%LOG_FILE%"
echo.

echo STEP 3/5 - Checking Flutter Installation
echo ----------------------------------------
echo [STEP 3/5] Checking Flutter Installation... >> "%LOG_FILE%"
where flutter >nul 2>&1
if errorlevel 1 (
    echo Flutter not found in PATH, searching common locations...
    echo Flutter not found in PATH, searching... >> "%LOG_FILE%"
    
    set "FLUTTER_FOUND="
    
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        if exist "%%d:\flutter\bin\flutter.bat" (
            echo Found at %%d:\flutter
            set "PATH=%%d:\flutter\bin;!PATH!"
            set "FLUTTER_FOUND=1"
            echo Found Flutter at %%d:\flutter >> "%LOG_FILE%"
        )
        if exist "%%d:\flutter\flutter\bin\flutter.bat" (
            echo Found at %%d:\flutter\flutter
            set "PATH=%%d:\flutter\flutter\bin;!PATH!"
            set "FLUTTER_FOUND=1"
            echo Found Flutter at %%d:\flutter\flutter >> "%LOG_FILE%"
        )
        if exist "%%d:\tools\flutter\bin\flutter.bat" (
            echo Found at %%d:\tools\flutter
            set "PATH=%%d:\tools\flutter\bin;!PATH!"
            set "FLUTTER_FOUND=1"
            echo Found Flutter at %%d:\tools\flutter >> "%LOG_FILE%"
        )
        if exist "%%d:\dev\flutter\bin\flutter.bat" (
            echo Found at %%d:\dev\flutter
            set "PATH=%%d:\dev\flutter\bin;!PATH!"
            set "FLUTTER_FOUND=1"
            echo Found Flutter at %%d:\dev\flutter >> "%LOG_FILE%"
        )
    )
    
    if not defined FLUTTER_FOUND (
        echo ERROR: Flutter not found on any drive!
        echo Download: https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.4-stable.zip
        echo ERROR: Flutter not found >> "%LOG_FILE%"
        echo Download URL logged >> "%LOG_FILE%"
        start "" "https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.4-stable.zip"
        echo.
        echo Installation:
        echo   Extract flutter folder to any drive root:
        echo   - C:\flutter
        echo   - D:\flutter
        echo   - etc.
        echo.
        echo Log: %LOG_FILE%
        pause
        exit /b 1
    )
)
echo OK: Flutter ready
echo OK: Flutter ready >> "%LOG_FILE%"
echo.

echo STEP 4/5 - Getting Dependencies
echo ----------------------------------------
echo [STEP 4/5] Getting Dependencies... >> "%LOG_FILE%"
echo Running flutter pub get...

set "PUB_HOSTED_URL=https://pub.flutter-io.cn"
set "FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn"

call flutter pub get >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo ERROR: Failed to get dependencies!
    echo ERROR: flutter pub get failed >> "%LOG_FILE%"
    echo.
    echo Check log file for details: %LOG_FILE%
    echo.
    echo Possible solutions:
    echo 1. Check your internet connection
    echo 2. Ensure you have Git installed
    echo 3. Run flutter pub cache repair
    echo 4. Try deleting pubspec.lock and running again
    pause
    exit /b 1
)
echo OK: Dependencies ready
echo OK: Dependencies ready >> "%LOG_FILE%"
echo.

echo STEP 5/5 - Starting Daily Awareness
echo ----------------------------------------
echo [STEP 5/5] Starting Daily Awareness... >> "%LOG_FILE%"
echo This may take 30-60 seconds...
echo Visit: http://localhost:8088
echo Press Ctrl+C to stop
echo ===========================================
echo.
echo Started at: %date% %time% >> "%LOG_FILE%"

call flutter run -d edge --web-port 8088

echo.
echo Log: %LOG_FILE%
pause

endlocal