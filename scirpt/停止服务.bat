@echo off
chcp 65001 >nul
title DailyAwarenessApp - Stop

echo ==========================================
echo   停止 DailyAwarenessApp 服务
echo ==========================================
echo.

set FOUND=0

REM 查找占用 5173 端口的进程（原型）
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :5173 ^| findstr LISTENING') do (
    echo 找到原型服务 (端口 5173)，PID: %%a
    taskkill /F /PID %%a >nul 2>&1
    echo 已停止
    set FOUND=1
)

REM 查找占用 8080 端口的进程（后端API）
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080 ^| findstr LISTENING') do (
    echo 找到后端服务 (端口 8080)，PID: %%a
    taskkill /F /PID %%a >nul 2>&1
    echo 已停止
    set FOUND=1
)

if "%FOUND%"=="0" (
    echo 未找到运行中的服务
)

echo.
echo 完成
echo.
pause
