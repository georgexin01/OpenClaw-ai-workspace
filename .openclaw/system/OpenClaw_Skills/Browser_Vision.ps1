# OPENCLAW SKILL: BROWSER VISION [V1.0]
# ========================================
# [PURPOSE]: Analyze browser page content using Gemma4 vision
# [SYNERGY]: Browser_Control.ps1 + Ollama multimodal API

param(
    [string]$Query = "Describe what you see on this web page. Identify all clickable buttons, links, forms, and important content.",
    [string]$ImagePath = ""
)

$OllamaUrl = "http://localhost:11434"
$ScreenshotDir = Join-Path $PSScriptRoot "..\skills_bridge\visual_vault"
$BrowserSkill = Join-Path $PSScriptRoot "Browser_Control.ps1"

# Step 1: Get screenshot if not provided
if (-not $ImagePath -or -not (Test-Path $ImagePath)) {
    Write-Host "[VISION] Taking browser screenshot..." -ForegroundColor Cyan
    $output = & powershell -ExecutionPolicy Bypass -File $BrowserSkill -Action SCREENSHOT 2>&1 | Out-String

    # Extract image path from output
    if ($output -match "BASE64_IMAGE_PATH:(.+)") {
        $ImagePath = $Matches[1].Trim()
    } else {
        Write-Output "[VISION] Failed to capture screenshot. Is the browser running?"
        Write-Output $output
        exit 1
    }
}

if (-not (Test-Path $ImagePath)) {
    Write-Output "[VISION] Image file not found: $ImagePath"
    exit 1
}

Write-Host "[VISION] Analyzing page with Gemma4..." -ForegroundColor Yellow

# Step 2: Convert image to base64
$imageBytes = [System.IO.File]::ReadAllBytes($ImagePath)
$base64 = [Convert]::ToBase64String($imageBytes)

# Step 3: Send to Ollama with vision
$body = @{
    model = "gemma4:e2b"
    prompt = @"
You are OpenClaw's Browser Vision system. Analyze this webpage screenshot.

USER QUERY: $Query

Respond with:
1. PAGE SUMMARY: What page is this? What is its purpose?
2. KEY ELEMENTS: List visible buttons, links, forms, inputs (with approximate positions)
3. ACTIONABLE: What can the user interact with? Suggest next steps.
4. ANSWER: Directly answer the user's query.

Be concise and specific.
"@
    images = @($base64)
    stream = $false
    options = @{ num_ctx = 2048 }
} | ConvertTo-Json -Compress -Depth 5

try {
    $response = Invoke-RestMethod -Uri "$OllamaUrl/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 120
    $analysis = $response.response

    if ($response.eval_count -and $response.eval_duration) {
        $tps = [math]::Round($response.eval_count / ($response.eval_duration / 1e9), 1)
        Write-Host "[VISION] Analysis complete (${tps} t/s)" -ForegroundColor Green
    }

    Write-Output "[BROWSER VISION ANALYSIS]"
    Write-Output "Screenshot: $ImagePath"
    Write-Output "---"
    Write-Output $analysis
} catch {
    Write-Output "[VISION] Ollama vision failed: $($_.Exception.Message)"
    Write-Output "Make sure Ollama is running and the model supports vision (gemma4:e2b with image input)."
}
