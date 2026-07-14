@echo off
setlocal enabledelayedexpansion
title Daily Awareness - Flutter Web

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%..\frontend"
set "LOG_FILE=%SCRIPT_DIR%startup.log"

echo =========================================== > "%LOG_FILE%"
echo   Daily Awareness Flutter Web Launcher      >> "%LOG_FILE%"
echo =========================================== >> "%LOG_FILE%"
echo Start: %date% %time%                       >> "%LOG_FILE%"
echo.                                           >> "%LOG_FILE%"

echo ===========================================
echo   Daily Awareness Flutter Web Launcher
echo ===========================================
echo.

cd /d "%PROJECT_DIR%" 2>> "%LOG_FILE%"
if errorlevel 1 (
    echo ERROR: Cannot access project directory!
    echo %PROJECT_DIR%
    echo See: %LOG_FILE%
    pause
    exit /b 1
)

echo [1/5] Checking Project Structure...
if not exist "pubspec.yaml" (
    echo ERROR: pubspec.yaml not found!
    echo Expected: %PROJECT_DIR%
    echo ERROR: pubspec.yaml not found >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo OK: Project valid
echo OK: Project valid >> "%LOG_FILE%"
echo.

echo [2/5] Checking Git...
where git >nul 2>&1
if errorlevel 1 (
    echo Git not in PATH, searching...
    call :find_git
    if errorlevel 1 (
        echo ERROR: Git not found!
        echo Download: https://git-scm.com/download/win
        start "" "https://git-scm.com/download/win"
        echo ERROR: Git not found >> "%LOG_FILE%"
        pause
        exit /b 1
    )
)
echo OK: Git ready
echo OK: Git ready >> "%LOG_FILE%"
echo.

echo [3/5] Checking Flutter...
where flutter >nul 2>&1
if errorlevel 1 (
    echo Flutter not in PATH, searching...
    call :find_flutter
    if errorlevel 1 (
        echo ERROR: Flutter not found!
        echo Download: https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.4-stable.zip
        start "" "https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.4-stable.zip"
        echo ERROR: Flutter not found >> "%LOG_FILE%"
        pause
        exit /b 1
    )
)
echo OK: Flutter ready
echo OK: Flutter ready >> "%LOG_FILE%"
echo.

echo [4/5] Getting Dependencies...
set "PUB_HOSTED_URL=https://pub.flutter-io.cn"
set "FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn"
call flutter pub get >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo ERROR: Failed to get dependencies!
    echo Check log: %LOG_FILE%
    pause
    exit /b 1
)
echo OK: Dependencies ready
echo OK: Dependencies ready >> "%LOG_FILE%"
echo.

echo [5/5] Starting Daily Awareness...
echo Visit: http://localhost:8088
echo Press Ctrl+C to stop
echo ===========================================
echo.

call flutter run -d edge --web-port 8088

echo.
echo Log: %LOG_FILE%
pause
endlocal
exit /b 0

:find_git
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        for %%s in ("Program Files\Git" "Program Files (x86)\Git" Git git tools\Git tools\git dev\Git dev\git soft\Git soft\git software\Git software\git app\Git app\git) do (
            if exist "%%d:\%%~s\cmd\git.exe" (
                set "PATH=%%d:\%%~s\cmd;%%d:\%%~s\bin;!PATH!"
                echo Found Git at %%d:\%%~s
                echo Found Git at %%d:\%%~s >> "%LOG_FILE%"
                exit /b 0
            )
            if exist "%%d:\%%~s\bin\git.exe" (
                set "PATH=%%d:\%%~s\bin;!PATH!"
                echo Found Git at %%d:\%%~s
                echo Found Git at %%d:\%%~s >> "%LOG_FILE%"
                exit /b 0
            )
        )
    )
    exit /b 1

:find_flutter
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        for %%s in (flutter "flutter\flutter" tools\flutter "tools\flutter\flutter" dev\flutter "dev\flutter\flutter" soft\flutter software\flutter app\flutter sdk\flutter) do (
            if exist "%%d:\%%~s\bin\flutter.bat" (
                set "PATH=%%d:\%%~s\bin;!PATH!"
                echo Found Flutter at %%d:\%%~s
                echo Found Flutter at %%d:\%%~s >> "%LOG_FILE%"
                exit /b 0
            )
        )
    )
    exit /b 1