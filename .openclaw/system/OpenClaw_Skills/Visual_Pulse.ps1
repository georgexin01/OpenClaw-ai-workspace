# OPENCLAW SKILL: VISUAL PULSE [V1.0]
# [OBJECTIVE]: Multimodal visual verification (Zeta Cinematic Mandate).
# [SYNERGY]: Snipaste / Screenshot-Desktop Integration.

$CaptureDir = Join-Path $PSScriptRoot "../skills_bridge/visual_vault"
if (-not (Test-Path $CaptureDir)) { New-Item -ItemType Directory -Path $CaptureDir -Force | Out-Null }

$Timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
$FilePath = Join-Path $CaptureDir "PULSE_$Timestamp.png"

Write-Host "[VISUAL_PULSE] Initiating Screen Capture..." -ForegroundColor Cyan

# Attempt 1: Trigger Snipaste Global Hotkey (F1)
# Note: This requires Snipaste to be running.
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("{F1}")
Start-Sleep -Seconds 1 # Wait for overlay

# Attempt 2: Direct CLI Capture (as fallback for headless/server mode)
try {
    Write-Host "[VISUAL_PULSE] Running CLI Capture Fallback..." -ForegroundColor Gray
    # We use a simple powershell snippet to capture the primary screen if npx is not available
    Add-Type -AssemblyName System.Drawing
    $Screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $Bitmap = New-Object System.Drawing.Bitmap($Screen.Bounds.Width, $Screen.Bounds.Height)
    $Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    $Graphics.CopyFromScreen($Screen.Bounds.X, $Screen.Bounds.Y, 0, 0, $Bitmap.Size)
    $Bitmap.Save($FilePath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    Write-Host "[SUCCESS] Visual Pulse captured to: $FilePath" -ForegroundColor Green
} catch {
    Write-Host "[!] Visual Pulse Failed: [OS_RESTRICTION]" -ForegroundColor Red
}

# Update Memory Graph with Visual Reference
$MemoryEntry = "### [VISUAL_REFERENCE: $Timestamp]`nPath: $FilePath"
Invoke-Expression "powershell -ExecutionPolicy Bypass -File `"$PSScriptRoot/Memory_Graph.ps1`" -ExtraData '$MemoryEntry'"

return $FilePath
