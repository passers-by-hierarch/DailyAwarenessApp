$ErrorActionPreference = "Stop"

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = Join-Path $scriptPath "..\frontend"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  DailyAwarenessApp Flutter Web" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $projectPath

Write-Host "[1/3] Checking Flutter dependencies..." -ForegroundColor Yellow
try {
    flutter pub get
    Write-Host "[1/3] Dependencies ready" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to get dependencies!" -ForegroundColor Red
    Write-Host "        Please check Flutter installation" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "[2/3] Starting Flutter Web with Edge..." -ForegroundColor Yellow
Write-Host ""
Write-Host "If browser doesn't open automatically, visit:" -ForegroundColor Gray
Write-Host "        http://localhost:8088" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
Write-Host ""

try {
    flutter run -d edge --web-port 8088
} catch {
    Write-Host "[ERROR] Flutter run failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Server stopped" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
pause