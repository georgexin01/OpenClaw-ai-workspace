# ZTV V30.0 SOVEREIGN SOLVER ELITE (PowerShell Native)
# --------------------------------------------------
# [IDENTITY]: SOVEREIGN_V30.0_ELITE
# [MANDATE]: Persistent GPU Performance Lock (Zero Python Dependency)

param (
    [string]$TargetAction = "CAPTCHA_SOLVE",
    [string]$SnipPath = "c:\Users\User\OneDrive\Desktop\workspace\snipaste\active_mission.png",
    [string]$ArchiveDir = "C:\Users\User\OneDrive\Desktop\workspace\archive\failed_missions"
)

# 1. HARDWARE IDENTITY LOCK (Instant Boot)
$HardwareID = (Get-CimInstance Win32_BaseBoard).SerialNumber
$VerifiedID = "07C9611_P51E971105" # PC: XIN (Updated)

if ($HardwareID -eq $VerifiedID) {
    Write-Host "[SOVEREIGN] Identity Verified: XIN. Locking GPU Performance Model..." -ForegroundColor Green
    $Model = "my-gpu-gemma"
} else {
    Write-Host "[SOVEREIGN] WARNING: Unknown Hardware Detection. Falling back to Safety Mode." -ForegroundColor Yellow
    $Model = "gemma4:e2b"
}

# 2. TRIGGER SILENT PULSE
Write-Host "[1/3] Triggering ALV Pulse..." -ForegroundColor Cyan
& powershell -ExecutionPolicy Bypass -File "c:\Users\User\OneDrive\Desktop\workspace\snipaste\auto_pulse.ps1"
Start-Sleep -Seconds 2 # Wait for snip to save

if (-not (Test-Path $SnipPath)) {
    Write-Host "[ERROR] Snip failed. active_mission.png not found." -ForegroundColor Red
    exit 1
}

# 3. LOCAL BRAIN HANDSHAKE (Ollama)
$Badge = "(Gemma4)"
Write-Host "[2/3] Delegating Logic to $Badge $Model..." -ForegroundColor Yellow

$Prompt = @"
Analyze faucet_state from image. 
1. FIND the unique icon (odd rotation or different shape).
2. FIND the 'Verify' or 'Claim' button.
3. OUTPUT ONLY valid JSON coordinates relative to the 1600x765 window.
Format: { "unique_icon": [X, Y], "verify_button": [X, Y], "reasoning": "..." }
"@

# Run Ollama and capture output
try {
    $Result = ollama run $Model $SnipPath $Prompt
} catch {
    Write-Host "[ERROR] GPU Handshake failed. Check Ollama service." -ForegroundColor Red
    exit 1
}

# 4. OUTPUT SYNC & ARCHIVE
Write-Host "[3/3] $Badge Logic Synced. Tactical Coordinates Received." -ForegroundColor Green
$Result | Out-File "c:\Users\User\OneDrive\Desktop\workspace\faucet\solver_output.txt" -Encoding utf8

# Automated Failure Archiving (Rule SM-05)
if ($Result -match "FAILED" -or $Result -match "ERROR") {
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $FailPath = Join-Path $ArchiveDir "fail_$Timestamp"
    New-Item -ItemType Directory -Path $FailPath -Force | Out-Null
    Copy-Item $SnipPath (Join-Path $FailPath "failed_capture.png")
    $Result | Out-File (Join-Path $FailPath "action_log.json")
    Write-Host "[SOVEREIGN] Mission state archived for Phoenix Post-Mortem." -ForegroundColor Cyan
}

Write-Host "MISSION READY. Awaiting Gemini-3 Bridge Execution." -ForegroundColor Cyan
