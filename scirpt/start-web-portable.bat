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

echo [1/6] Checking Project Structure...
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

echo [2/6] Checking Git...
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

echo [3/6] Checking Flutter...
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

echo [4/6] Checking Developer Mode...
powershell -NoProfile -Command "$v=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense; if ($v -eq 1) { exit 0 } else { exit 1 }" >nul 2>&1
if errorlevel 1 (
    echo.
    echo WARNING: Windows Developer Mode is not enabled!
    echo Flutter requires Developer Mode to build with plugins.
    echo.
    echo Please enable it:
    echo   1. Press Win + I to open Settings
    echo   2. Privacy and Security -^> For developers
    echo   3. Turn ON "Developer Mode"
    echo.
    pause
)
echo OK: Developer Mode checked
echo.

echo [5/6] Getting Dependencies...
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

echo [6/6] Starting Daily Awareness...
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
    if defined USERPROFILE (
        for %%s in ("Program Files\Git" "Program Files (x86)\Git" Git git Downloads\Git Downloads\git 下载\Git 下载\git "Downloads\Program Files\Git" Desktop\Git Desktop\git 桌面\Git 桌面\git tools\Git tools\git dev\Git dev\git soft\Git soft\git software\Git software\git app\Git app\git) do (
            if exist "%USERPROFILE%\%%~s\cmd\git.exe" (
                set "PATH=%USERPROFILE%\%%~s\cmd;%USERPROFILE%\%%~s\bin;!PATH!"
                echo Found Git at %USERPROFILE%\%%~s
                echo Found Git at %USERPROFILE%\%%~s >> "%LOG_FILE%"
                exit /b 0
            )
            if exist "%USERPROFILE%\%%~s\bin\git.exe" (
                set "PATH=%USERPROFILE%\%%~s\bin;!PATH!"
                echo Found Git at %USERPROFILE%\%%~s
                echo Found Git at %USERPROFILE%\%%~s >> "%LOG_FILE%"
                exit /b 0
            )
        )
    )
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        for %%s in ("Program Files\Git" "Program Files (x86)\Git" Git git downloads\Git downloads\git 下载\Git 下载\git tools\Git tools\git dev\Git dev\git soft\Git soft\git software\Git software\git app\Git app\git) do (
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
    echo Fuzzy searching for Git...
    echo Fuzzy searching for Git... >> "%LOG_FILE%"
    if defined USERPROFILE (
        for /d %%f in ("%USERPROFILE%\*git*") do (
            if exist "%%f\cmd\git.exe" (
                set "PATH=%%f\cmd;%%f\bin;!PATH!"
                echo Found Git at %%f
                echo Found Git at %%f >> "%LOG_FILE%"
                exit /b 0
            )
            if exist "%%f\bin\git.exe" (
                set "PATH=%%f\bin;!PATH!"
                echo Found Git at %%f
                echo Found Git at %%f >> "%LOG_FILE%"
                exit /b 0
            )
        )
        for %%u in (Downloads 下载 Desktop 桌面 Documents 文档 "My Documents" tools dev soft software app sdk) do (
            if exist "%USERPROFILE%\%%~u\" (
                for /d %%f in ("%USERPROFILE%\%%~u\*git*") do (
                    if exist "%%f\cmd\git.exe" (
                        set "PATH=%%f\cmd;%%f\bin;!PATH!"
                        echo Found Git at %%f
                        echo Found Git at %%f >> "%LOG_FILE%"
                        exit /b 0
                    )
                    if exist "%%f\bin\git.exe" (
                        set "PATH=%%f\bin;!PATH!"
                        echo Found Git at %%f
                        echo Found Git at %%f >> "%LOG_FILE%"
                        exit /b 0
                    )
                )
            )
        )
    )
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        if exist "%%d:\" (
            for /d %%f in ("%%d:\*git*") do (
                if exist "%%f\cmd\git.exe" (
                    set "PATH=%%f\cmd;%%f\bin;!PATH!"
                    echo Found Git at %%f
                    echo Found Git at %%f >> "%LOG_FILE%"
                    exit /b 0
                )
                if exist "%%f\bin\git.exe" (
                    set "PATH=%%f\bin;!PATH!"
                    echo Found Git at %%f
                    echo Found Git at %%f >> "%LOG_FILE%"
                    exit /b 0
                )
            )
        )
    )
    echo Deep searching for Git (this may take a few seconds)...
    echo Deep searching for Git... >> "%LOG_FILE%"
    for /f "delims=" %%p in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%find-tool.ps1" -ToolName git -ExeName "cmd\git.exe" 2^>nul') do (
        if exist "%%p\cmd\git.exe" (
            set "PATH=%%p\cmd;%%p\bin;!PATH!"
        ) else (
            set "PATH=%%p\bin;!PATH!"
        )
        echo Found Git at %%p
        echo Found Git at %%p >> "%LOG_FILE%"
        exit /b 0
    )
    echo.
    echo ===========================================
    echo   Automatic search could not find Git
    echo ===========================================
    set /p USER_GIT="Please enter Git installation path (e.g. D:\\Program Files\\Git), press Enter to skip: "
    if defined USER_GIT (
        if exist "!USER_GIT!\cmd\git.exe" (
            set "PATH=!USER_GIT!\cmd;!USER_GIT!\bin;!PATH!"
            echo Found Git at !USER_GIT!
            echo Found Git at !USER_GIT! >> "%LOG_FILE%"
            exit /b 0
        )
        if exist "!USER_GIT!\bin\git.exe" (
            set "PATH=!USER_GIT!\bin;!PATH!"
            echo Found Git at !USER_GIT!
            echo Found Git at !USER_GIT! >> "%LOG_FILE%"
            exit /b 0
        )
        echo Path invalid: !USER_GIT!
        echo Path invalid: !USER_GIT! >> "%LOG_FILE%"
    )
    exit /b 1

:find_flutter
    if defined USERPROFILE (
        for %%s in (flutter "flutter\flutter" Downloads\flutter "Downloads\flutter\flutter" 下载\flutter "下载\flutter\flutter" Desktop\flutter "Desktop\flutter\flutter" 桌面\flutter "桌面\flutter\flutter" Documents\flutter "Documents\flutter\flutter" 文档\flutter "文档\flutter\flutter" "My Documents\flutter" tools\flutter "tools\flutter\flutter" dev\flutter "dev\flutter\flutter" soft\flutter software\flutter app\flutter sdk\flutter "Program Files\flutter" "Program Files (x86)\flutter") do (
            if exist "%USERPROFILE%\%%~s\bin\flutter.bat" (
                set "PATH=%USERPROFILE%\%%~s\bin;!PATH!"
                echo Found Flutter at %USERPROFILE%\%%~s
                echo Found Flutter at %USERPROFILE%\%%~s >> "%LOG_FILE%"
                exit /b 0
            )
        )
    )
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        for %%s in (flutter "flutter\flutter" tools\flutter "tools\flutter\flutter" dev\flutter "dev\flutter\flutter" soft\flutter software\flutter app\flutter sdk\flutter downloads\flutter "downloads\flutter\flutter" 下载\flutter "下载\flutter\flutter" "Program Files\flutter" "Program Files (x86)\flutter") do (
            if exist "%%d:\%%~s\bin\flutter.bat" (
                set "PATH=%%d:\%%~s\bin;!PATH!"
                echo Found Flutter at %%d:\%%~s
                echo Found Flutter at %%d:\%%~s >> "%LOG_FILE%"
                exit /b 0
            )
        )
    )
    echo Fuzzy searching for Flutter...
    echo Fuzzy searching for Flutter... >> "%LOG_FILE%"
    if defined USERPROFILE (
        for /d %%f in ("%USERPROFILE%\*flutter*") do (
            if exist "%%f\bin\flutter.bat" (
                set "PATH=%%f\bin;!PATH!"
                echo Found Flutter at %%f
                echo Found Flutter at %%f >> "%LOG_FILE%"
                exit /b 0
            )
            if exist "%%f\flutter\bin\flutter.bat" (
                set "PATH=%%f\flutter\bin;!PATH!"
                echo Found Flutter at %%f\flutter
                echo Found Flutter at %%f\flutter >> "%LOG_FILE%"
                exit /b 0
            )
        )
        for %%u in (Downloads 下载 Desktop 桌面 Documents 文档 "My Documents" tools dev soft software app sdk) do (
            if exist "%USERPROFILE%\%%~u\" (
                for /d %%f in ("%USERPROFILE%\%%~u\*flutter*") do (
                    if exist "%%f\bin\flutter.bat" (
                        set "PATH=%%f\bin;!PATH!"
                        echo Found Flutter at %%f
                        echo Found Flutter at %%f >> "%LOG_FILE%"
                        exit /b 0
                    )
                    if exist "%%f\flutter\bin\flutter.bat" (
                        set "PATH=%%f\flutter\bin;!PATH!"
                        echo Found Flutter at %%f\flutter
                        echo Found Flutter at %%f\flutter >> "%LOG_FILE%"
                        exit /b 0
                    )
                )
            )
        )
    )
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        if exist "%%d:\" (
            for /d %%f in ("%%d:\*flutter*") do (
                if exist "%%f\bin\flutter.bat" (
                    set "PATH=%%f\bin;!PATH!"
                    echo Found Flutter at %%f
                    echo Found Flutter at %%f >> "%LOG_FILE%"
                    exit /b 0
                )
                if exist "%%f\flutter\bin\flutter.bat" (
                    set "PATH=%%f\flutter\bin;!PATH!"
                    echo Found Flutter at %%f\flutter
                    echo Found Flutter at %%f\flutter >> "%LOG_FILE%"
                    exit /b 0
                )
            )
        )
    )
    echo Deep searching for Flutter (this may take a few seconds)...
    echo Deep searching for Flutter... >> "%LOG_FILE%"
    for /f "delims=" %%p in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%find-tool.ps1" -ToolName flutter -ExeName "bin\flutter.bat" 2^>nul') do (
        set "PATH=%%p\bin;!PATH!"
        echo Found Flutter at %%p
        echo Found Flutter at %%p >> "%LOG_FILE%"
        exit /b 0
    )
    echo.
    echo ===========================================
    echo   Automatic search could not find Flutter
    echo ===========================================
    set /p USER_FLUTTER="Please enter Flutter installation path (e.g. D:\\flutter), press Enter to skip: "
    if defined USER_FLUTTER (
        if exist "!USER_FLUTTER!\bin\flutter.bat" (
            set "PATH=!USER_FLUTTER!\bin;!PATH!"
            echo Found Flutter at !USER_FLUTTER!
            echo Found Flutter at !USER_FLUTTER! >> "%LOG_FILE%"
            exit /b 0
        )
        echo Path invalid: !USER_FLUTTER!
        echo Path invalid: !USER_FLUTTER! >> "%LOG_FILE%"
    )
    exit /b 1