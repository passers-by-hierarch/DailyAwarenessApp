@echo off
chcp 65001 >nul
title DailyAwarenessApp - Stop Prototype

echo ==========================================
echo   停止 DailyAwarenessApp 原型服务
echo ==========================================
echo.

REM 查找占用 5173 端口的进程
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :5173 ^| findstr LISTENING') do (
    set PID=%%a
)

if "%PID%"=="" (
    echo 未找到运行中的原型服务（端口 5173）
    echo.
    pause
    exit /b 0
)

echo 找到进程 PID: %PID%
echo 正在停止...

taskkill /F /PID %PID%

if errorlevel 1 (
    echo.
    echo [错误] 停止失败，请手动结束进程
) else (
    echo.
    echo [成功] 服务已停止
)

echo.
pause
