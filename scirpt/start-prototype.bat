@echo off
title 生活助手 - Prototype

echo ==========================================
echo   生活助手 Prototype
echo ==========================================
echo.

cd /d "%~dp0..\web-prototype"

if not exist "node_modules" (
    echo [1/3] First run, installing dependencies...
    call npm install
    if errorlevel 1 (
        echo.
        echo [ERROR] Failed to install dependencies. Please check if Node.js is installed.
        pause
        exit /b 1
    )
    echo [1/3] Dependencies installed
) else (
    echo [1/3] Dependencies found, skipping install
)

echo.
echo [2/3] Starting dev server...
echo.
echo After startup, check terminal for the URL (usually http://localhost:3000/)
echo Press Ctrl+C to stop
echo.

echo [3/3] Launching...
echo.

call npm run dev

pause
