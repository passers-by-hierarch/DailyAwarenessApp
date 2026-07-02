@echo off
chcp 65001 >nul
title DailyAwarenessApp - Prototype (Auto Open)

echo ==========================================
echo   DailyAwarenessApp 原型启动脚本
echo ==========================================
echo.

cd /d "%~dp0..\web-prototype"

REM 检查 node_modules 是否存在
if not exist "node_modules" (
    echo [1/3] 首次启动，正在安装依赖...
    call npm install
    if errorlevel 1 (
        echo.
        echo [错误] 依赖安装失败，请检查 Node.js 是否已安装
        pause
        exit /b 1
    )
    echo [1/3] 依赖安装完成
) else (
    echo [1/3] 依赖已安装，跳过安装步骤
)

echo.
echo [2/3] 启动开发服务器...
echo.
echo 启动成功后将自动打开浏览器
echo 按 Ctrl+C 可停止服务
echo.

REM 延迟2秒后打开浏览器
start "" cmd /c "timeout /t 3 /nobreak >nul && start http://localhost:5173/"

call npm run dev

pause
