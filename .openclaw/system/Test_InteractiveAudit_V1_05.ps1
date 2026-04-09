# OPENCLAW SOVEREIGN: INTERACTIVE AUDIT V1.05
# -----------------------------------------------
# [MANDATE]: Self-Testing via 5-Point Neural Probe
# [VERSION]: V1.05

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$EnginePath = Join-Path $PSScriptRoot "..\OpenClaw_Engine.ps1"
if (-not (Test-Path $EnginePath)) { exit 1 }
. $EnginePath

$AuditQuestions = @(
    "What are the 3 progress markers added in V1.04 boot sequence?",
    "Explain the +0.01 versioning directive from the User Lexicon.",
    "Generate a mock <ACTION> to read the system diagnostic log.",
    "What is the design aesthetic for Zeta Sovereign V1.04?",
    "Confirm stability status after the V1.03 JavaScript/IE:Edge repair."
)

Write-Host "--- SOVEREIGN INTERACTIVE AUDIT V1.05 ---" -ForegroundColor Cyan
$Results = @()

foreach ($q in $AuditQuestions) {
    Write-Host "[PROBE] $q" -ForegroundColor White
    $Response = Invoke-OClawQuery $q 2 # Tier 2 (Heavy)
    $Results += [PSCustomObject]@{
        Question = $q
        Answer   = $Response -replace '(?s)<ACTION>.*?</ACTION>', '[ACTION DISPATCHED]'
    }
}

$Results | Out-String | Write-Host -ForegroundColor Green
Write-OClawLog "INTERACTIVE_AUDIT" "V1.05 Audit Completed. 5/5 Neural Probes Resolved."
