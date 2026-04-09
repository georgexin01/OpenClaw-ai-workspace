# OpenClaw Skill: Start SearXNG
# -----------------------------------------------------
# [PURPOSE]: Initialize local docker-based search engine

$SearxDir = Join-Path $PSScriptRoot "..\searxng"
Set-Location $SearxDir

Write-Host "[OPENCLAW] Verifying Docker Status..." -ForegroundColor Cyan

$dockerCheck = docker ps 2>&1
if ($LastExitCode -ne 0) {
    Write-Host "[X] BLOCKER: Docker is not running or not installed." -ForegroundColor Red
    Write-Host "[!] Please install Docker Desktop and ensure it is active before starting SearXNG." -ForegroundColor Yellow
    exit 1
}

Write-Host "[>] Spinning up SearXNG Sovereign Search..." -ForegroundColor Green
docker-compose up -d

Write-Host "[+] SUCCESS: SearXNG instance is launching at http://localhost:8888" -ForegroundColor Cyan
Write-Host "[*] Initializing health check (may take 10 seconds)..." -ForegroundColor Gray

Start-Sleep -Seconds 5
try {
    $test = Invoke-RestMethod -Uri "http://localhost:8888/search?q=openclaw&format=json" -TimeoutSec 5
    Write-Host "[+] HEALTH CHECK PASSED: Private Search Active." -ForegroundColor Cyan
} catch {
    Write-Host "[!] Health check pending. SearXNG is still warming up." -ForegroundColor Yellow
}
