@echo off
chcp 65001 >nul
title DailyAwarenessApp - Prototype

echo ==========================================
echo   DailyAwarenessApp 原型启动脚本
echo ==========================================
echo.

cd /d "%~dp0..\web-prototype"

REM 检查 node_modules 是否存在
if not exist "node_modules" (
    echo [1/2] 首次启动，正在安装依赖...
    call npm install
    if errorlevel 1 (
        echo.
        echo [错误] 依赖安装失败，请检查 Node.js 是否已安装
        pause
        exit /b 1
    )
    echo [1/2] 依赖安装完成
) else (
    echo [1/2] 依赖已安装，跳过安装步骤
)

echo.
echo [2/2] 启动开发服务器...
echo.
echo 启动成功后，浏览器访问: http://localhost:5173/
echo 按 Ctrl+C 可停止服务
echo.

call npm run dev

pause
