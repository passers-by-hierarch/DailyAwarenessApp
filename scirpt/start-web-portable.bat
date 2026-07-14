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
    echo Git not found in PATH, searching common locations...
    set "GIT_FOUND="
    
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        if exist "%%d:\Program Files\Git\bin\git.exe" (
            echo Found at %%d:\Program Files\Git
            set "PATH=%%d:\Program Files\Git\bin;%PATH%"
            set "GIT_FOUND=1"
        )
        if exist "%%d:\Program Files (x86)\Git\bin\git.exe" (
            echo Found at %%d:\Program Files (x86)\Git
            set "PATH=%%d:\Program Files (x86)\Git\bin;%PATH%"
            set "GIT_FOUND=1"
        )
        if exist "%%d:\Git\bin\git.exe" (
            echo Found at %%d:\Git
            set "PATH=%%d:\Git\bin;%PATH%"
            set "GIT_FOUND=1"
        )
        if exist "%%d:\tools\Git\bin\git.exe" (
            echo Found at %%d:\tools\Git
            set "PATH=%%d:\tools\Git\bin;%PATH%"
            set "GIT_FOUND=1"
        )
    )
    
    if not defined GIT_FOUND (
        echo ERROR: Git not found on any drive!
        echo Download: https://git-scm.com/download/win
        start "" "https://git-scm.com/download/win"
        echo.
        echo Install Git to default location, or to:
        echo   - C:\Git
        echo   - D:\Git
        echo   - etc.
        pause
        exit /b 1
    )
)
echo OK: Git ready
echo.

echo STEP 3/5 - Checking Flutter Installation
echo ----------------------------------------
where flutter >nul 2>&1
if errorlevel 1 (
    echo Flutter not found in PATH, searching common locations...
    set "FLUTTER_FOUND="
    
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        if exist "%%d:\flutter\bin\flutter.bat" (
            echo Found at %%d:\flutter
            set "PATH=%%d:\flutter\bin;%PATH%"
            set "FLUTTER_FOUND=1"
        )
        if exist "%%d:\flutter\flutter\bin\flutter.bat" (
            echo Found at %%d:\flutter\flutter
            set "PATH=%%d:\flutter\flutter\bin;%PATH%"
            set "FLUTTER_FOUND=1"
        )
        if exist "%%d:\tools\flutter\bin\flutter.bat" (
            echo Found at %%d:\tools\flutter
            set "PATH=%%d:\tools\flutter\bin;%PATH%"
            set "FLUTTER_FOUND=1"
        )
        if exist "%%d:\dev\flutter\bin\flutter.bat" (
            echo Found at %%d:\dev\flutter
            set "PATH=%%d:\dev\flutter\bin;%PATH%"
            set "FLUTTER_FOUND=1"
        )
    )
    
    if not defined FLUTTER_FOUND (
        echo ERROR: Flutter not found on any drive!
        echo Download: https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.4-stable.zip
        start "" "https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.4-stable.zip"
        echo.
        echo Installation:
        echo   Extract flutter folder to any drive root:
        echo   - C:\flutter
        echo   - D:\flutter
        echo   - E:\flutter
        echo   - etc.
        echo.
        echo Or add Flutter\bin to your PATH environment variable.
        pause
        exit /b 1
    )
)
echo OK: Flutter ready
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