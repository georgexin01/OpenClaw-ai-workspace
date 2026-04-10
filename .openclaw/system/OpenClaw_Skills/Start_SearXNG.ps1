$PossiblePaths = @(
    (Join-Path $PSScriptRoot "..\searxng"),
    (Join-Path $PSScriptRoot "..\..\searxng"),
    (Join-Path $PSScriptRoot "system/searxng")
)

$SearxDir = $null
foreach ($path in $PossiblePaths) {
    if (Test-Path $path) { $SearxDir = $path; break }
}

if (-not $SearxDir) {
    Write-Host "[X] BLOCKER: SearXNG directory not found in relative proximity." -ForegroundColor Red
    exit 1
}

Set-Location $SearxDir
Write-Host "[OPENCLAW] Verifying Docker Status..." -ForegroundColor Cyan

if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "[X] BLOCKER: Docker not found in PATH." -ForegroundColor Red
    exit 1
}

# Support both 'docker-compose' and 'docker compose'
$ComposeCmd = if (Get-Command "docker-compose" -ErrorAction SilentlyContinue) { "docker-compose" } else { "docker compose" }

Write-Host "[>] Spinning up SearXNG Sovereign Search via $ComposeCmd..." -ForegroundColor Green
& $ComposeCmd up -d

Write-Host "[+] SUCCESS: SearXNG instance is launching at http://localhost:8888" -ForegroundColor Cyan
Write-Host "[*] Initializing health check sequence..." -ForegroundColor Gray

for ($i=1; $i -le 3; $i++) {
    Start-Sleep -Seconds 5
    try {
        $test = Invoke-RestMethod -Uri "http://localhost:8888/search?q=openclaw&format=json" -TimeoutSec 5
        Write-Host "[+] HEALTH CHECK PASSED: Private Search Active." -ForegroundColor Cyan
        break
    } catch {
        Write-Host "[!] Health check pending ($i/3)..." -ForegroundColor Yellow
    }
}
