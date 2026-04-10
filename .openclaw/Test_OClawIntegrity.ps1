# OPENCLAW V2.0 INTEGRITY TEST
# ==============================

$ErrorCount = 0
$PassCount = 0
$EnginePath = Join-Path $PSScriptRoot "OpenClaw_Engine.ps1"
$GUIPath = Join-Path $PSScriptRoot "OpenClaw_GUI.ps1"
$SystemRoot = Join-Path $PSScriptRoot "system"

Write-Host "`n=== OPENCLAW V2.0 INTEGRITY TEST ===" -ForegroundColor Cyan

# Test 1: Engine syntax
Write-Host "`n[TEST 1] Engine Syntax..." -NoNewline
$err = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($EnginePath, [ref]$null, [ref]$err)
if ($err.Count -eq 0) { Write-Host " PASS" -ForegroundColor Green; $PassCount++ }
else { Write-Host " FAIL ($($err.Count) errors)" -ForegroundColor Red; $ErrorCount++ }

# Test 2: GUI syntax
Write-Host "[TEST 2] GUI Syntax..." -NoNewline
$err2 = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($GUIPath, [ref]$null, [ref]$err2)
if ($err2.Count -eq 0) { Write-Host " PASS" -ForegroundColor Green; $PassCount++ }
else { Write-Host " FAIL ($($err2.Count) errors)" -ForegroundColor Red; $ErrorCount++ }

# Test 3: Ollama connectivity
Write-Host "[TEST 3] Ollama Connection..." -NoNewline
try {
    $tags = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
    Write-Host " PASS ($($tags.models.Count) models)" -ForegroundColor Green; $PassCount++
} catch { Write-Host " FAIL (unreachable)" -ForegroundColor Red; $ErrorCount++ }

# Test 4: Model inference
Write-Host "[TEST 4] Model Inference (gemma4:e2b)..." -NoNewline
try {
    $body = @{ model = "gemma4:e2b"; prompt = "What is 1+1? Reply only the number."; stream = $false } | ConvertTo-Json -Compress
    $resp = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    if ($resp.response -match "2") { Write-Host " PASS (Response: $($resp.response.Trim()))" -ForegroundColor Green; $PassCount++ }
    else { Write-Host " WARN (Response: $($resp.response.Trim()))" -ForegroundColor Yellow; $PassCount++ }
} catch { Write-Host " FAIL ($($_.Exception.Message))" -ForegroundColor Red; $ErrorCount++ }

# Test 5: Engine query via dot-source
Write-Host "[TEST 5] Engine Query..." -NoNewline
try {
    . $EnginePath
    $result = Invoke-OClawQuery "What is 5+5? Reply only the number." 1
    if ($result -match "10") { Write-Host " PASS (Response: $($result.Trim()))" -ForegroundColor Green; $PassCount++ }
    else { Write-Host " WARN (Response: $($result.Substring(0, [Math]::Min(50, $result.Length))))" -ForegroundColor Yellow; $PassCount++ }
} catch { Write-Host " FAIL ($($_.Exception.Message))" -ForegroundColor Red; $ErrorCount++ }

# Test 6: Skills exist
Write-Host "[TEST 6] Skills Integrity..." -NoNewline
$skills = @("Architect_Review", "Bespoke_UI", "Get_GPU_Status", "MCP_Bridge", "Memory_Graph", "Security_Scan", "Sovereign_GitSync", "Start_SearXNG", "Vision_Solver", "Visual_Pulse", "Voice_Sovereign", "YT_AutoLearn")
$missing = $skills | Where-Object { -not (Test-Path (Join-Path "$SystemRoot\OpenClaw_Skills" "$_.ps1")) }
if ($missing.Count -eq 0) { Write-Host " PASS (all $($skills.Count) skills present)" -ForegroundColor Green; $PassCount++ }
else { Write-Host " FAIL (missing: $($missing -join ', '))" -ForegroundColor Red; $ErrorCount++ }

# Test 7: GPU status
Write-Host "[TEST 7] GPU Status..." -NoNewline
$gpuRaw = & powershell -ExecutionPolicy Bypass -File (Join-Path "$SystemRoot\OpenClaw_Skills" "Get_GPU_Status.ps1")
if ($gpuRaw) {
    try { $gpu = $gpuRaw | ConvertFrom-Json; Write-Host " PASS ($($gpu.Name) - $($gpu.UsedVRAM)MB)" -ForegroundColor Green; $PassCount++ }
    catch { Write-Host " FAIL (bad JSON)" -ForegroundColor Red; $ErrorCount++ }
} else { Write-Host " WARN (no GPU detected)" -ForegroundColor Yellow; $PassCount++ }

# Summary
Write-Host "`n=== RESULTS: $PassCount PASS / $ErrorCount FAIL ===" -ForegroundColor $(if ($ErrorCount -eq 0) { "Green" } else { "Red" })
Write-Host ""
