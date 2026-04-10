# OPENCLAW SKILL: OCR EXTRACT [V1.0]
# [PURPOSE]: Extract text from screenshots via Gemma4 vision

param(
    [string]$ImagePath = "",
    [switch]$CaptureScreen
)

$OllamaUrl = "http://localhost:11434"
$VaultDir = Join-Path $PSScriptRoot "..\skills_bridge\visual_vault"

# Capture screen if requested
if ($CaptureScreen -or -not $ImagePath) {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $bitmap = New-Object System.Drawing.Bitmap($screen.Bounds.Width, $screen.Bounds.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($screen.Bounds.X, $screen.Bounds.Y, 0, 0, $bitmap.Size)
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $ImagePath = Join-Path $VaultDir "ocr_capture_$ts.png"
    if (-not (Test-Path $VaultDir)) { New-Item -ItemType Directory -Path $VaultDir -Force | Out-Null }
    $bitmap.Save($ImagePath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose(); $bitmap.Dispose()
    Write-Host "[OCR] Screen captured: $ImagePath" -ForegroundColor Cyan
}

if (-not (Test-Path $ImagePath)) { Write-Output "[OCR] Image not found: $ImagePath"; exit 1 }

$imageBytes = [System.IO.File]::ReadAllBytes($ImagePath)
$base64 = [Convert]::ToBase64String($imageBytes)

$body = @{
    model = "gemma4:e2b"
    prompt = "Extract ALL text visible in this image. Return only the extracted text, preserving layout and formatting as closely as possible. Do not add any commentary."
    images = @($base64)
    stream = $false
    options = @{ num_ctx = 2048 }
} | ConvertTo-Json -Compress -Depth 5

try {
    $resp = Invoke-RestMethod -Uri "$OllamaUrl/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 90
    Write-Output "[OCR RESULT]`nSource: $ImagePath`n---`n$($resp.response)"
} catch {
    Write-Output "[OCR] Failed: $($_.Exception.Message)"
}
