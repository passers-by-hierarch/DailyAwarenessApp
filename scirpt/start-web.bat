@echo off
title DailyAwarenessApp - Flutter Web

cd /d "%~dp0..\frontend"

echo ==========================================
echo   DailyAwarenessApp Flutter Web
echo ==========================================
echo.
echo Starting... (this may take 30-60 seconds)
echo.
echo If browser doesn't open automatically,
echo visit: http://localhost:8088
echo.
echo Press Ctrl+C to stop
echo ==========================================
echo.

flutter run -d edge --web-port 8088

pause