# OPENCLAW SKILL: CHAIN EXECUTOR [V1.0]
# [PURPOSE]: Multi-step AI prompt chains (research → analyze → act)

param(
    [string]$Chain = "",       # JSON array of prompts or semicolon-separated
    [int]$MaxSteps = 5,
    [int]$Tier = 1
)

if (-not $Chain) { Write-Output "[CHAIN] Provide -Chain parameter (semicolon-separated prompts or JSON array)."; exit 1 }

$EnginePath = Join-Path $PSScriptRoot "..\..\OpenClaw_Engine.ps1"
. $EnginePath

# Parse chain
$steps = @()
if ($Chain.StartsWith("[")) {
    try { $steps = $Chain | ConvertFrom-Json } catch { $steps = @($Chain) }
} else {
    $steps = $Chain -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

if ($steps.Count -gt $MaxSteps) { $steps = $steps[0..($MaxSteps - 1)] }

Write-Host "[CHAIN] Executing $($steps.Count)-step prompt chain..." -ForegroundColor Cyan
$context = ""
$results = @()

for ($i = 0; $i -lt $steps.Count; $i++) {
    $stepPrompt = $steps[$i]
    if ($context) { $stepPrompt = "Previous context:`n$context`n`nNext task: $stepPrompt" }

    Write-Host "[CHAIN $($i+1)/$($steps.Count)] $($stepPrompt.Substring(0, [Math]::Min(60, $stepPrompt.Length)))..." -ForegroundColor Yellow
    $result = Invoke-OClawQuery $stepPrompt $Tier
    $context = $result
    $results += @{ step = $i + 1; prompt = $steps[$i]; result = $result }
}

$output = "[CHAIN COMPLETE] $($steps.Count) steps executed:`n"
foreach ($r in $results) {
    $output += "`n--- Step $($r.step) ---`nPrompt: $($r.prompt)`nResult: $($r.result)`n"
}
Write-Output $output
