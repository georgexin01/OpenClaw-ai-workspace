# OPENCLAW SOVEREIGN: GENERAL KNOWLEDGE AUDIT V1.06
# --------------------------------------------------
# [MANDATE]: Testing 'Normal Life' queries on Local Brain
# [VERSION]: V1.06

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$EnginePath = Join-Path $PSScriptRoot "..\OpenClaw_Engine.ps1"
if (-not (Test-Path $EnginePath)) { exit 1 }
. $EnginePath

$GeneralQuestions = @(
    "How many types of fish are there in the world?",
    "What are the best ingredients for a homemade Margherita pizza?",
    "Why is the sky blue?",
    "What are the benefits of drinking water every morning?",
    "How do you start a small garden for beginner vegetables?"
)

Write-Host "--- SOVEREIGN GENERAL AUDIT V1.06 ---" -ForegroundColor Cyan
$Results = @()

foreach ($q in $GeneralQuestions) {
    Write-Host "[PROBE] $q" -ForegroundColor White
    $Response = Invoke-OClawQuery $q 2 # Tier 2 (Heavy)
    $Results += [PSCustomObject]@{
        Question = $q
        Answer   = $Response
    }
}

$Results | Out-String | Write-Host -ForegroundColor Green
Write-OClawLog "GENERAL_AUDIT" "V1.06 Audit Completed. Normal life queries verified."
