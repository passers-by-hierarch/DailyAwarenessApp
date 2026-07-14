Write-Host "=========================================="
Write-Host "   Daily Awareness - Flutter Web"
Write-Host "=========================================="
Write-Host ""

$projectDir = Join-Path (Split-Path $PSScriptRoot -Parent) "frontend"

if (-not (Test-Path "$projectDir\pubspec.yaml")) {
    Write-Host "[ERROR] Project directory not found" -ForegroundColor Red
    Write-Host "Path: $projectDir"
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location $projectDir

Write-Host "[1/2] Checking Flutter environment..."
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterPath) {
    Write-Host "[ERROR] Flutter not found in PATH!" -ForegroundColor Red
    Write-Host "Please install Flutter and add to PATH"
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "[OK] Flutter found" -ForegroundColor Green

Write-Host ""
Write-Host "=========================================="
Write-Host "   [2/2] Starting Daily Awareness..."
Write-Host "=========================================="
Write-Host ""
Write-Host "This may take 30-60 seconds..."
Write-Host ""
Write-Host "If browser doesn't open, visit:"
Write-Host "  http://localhost:8088"
Write-Host ""
Write-Host "Press Ctrl+C to stop"
Write-Host "=========================================="
Write-Host ""

flutter run -d edge --web-port 8088