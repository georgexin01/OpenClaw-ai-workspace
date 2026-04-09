# OPENCLAW SOVEREIGN PROTOCOL TESTER (V1.01)
# Defensive Build

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$EnginePath = Join-Path $PSScriptRoot "..\OpenClaw_Engine.ps1"
if (-not (Test-Path $EnginePath)) { exit 1 }
. $EnginePath

Write-Host "--- SOVEREIGN DEEP AUDIT V1.01 ---" -ForegroundColor Cyan
Write-OClawLog "TEST_SUITE_START" "Initiating stress test"

$TestQueries = @(
    "What is your identity name?",
    "Calculate the current VRAM status.",
    "Show me the model type.",
    "Confirm hardware lock status.",
    "Mission Test: Trigger 'WHATSAPP_MONITOR' mission."
)

$SuccessCount = 0
foreach ($q in $TestQueries) {
    Write-Host "[TEST] $q ... " -NoNewline
    $Timer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $Response = Invoke-OClawQuery $q 2
        $Timer.Stop()
        if ($Response -match "Gemma-4" -or $Response -match "SYSTEM DISPATCH") {
            Write-Host "PASS ($($Timer.Elapsed.TotalSeconds)s)" -ForegroundColor Green
            $SuccessCount++
        } else {
            Write-Host "FAIL" -ForegroundColor Red
            Write-OClawLog "TEST_FAIL" "Query: $q | Resp: $Response"
        }
    } catch {
        Write-Host "CRASH" -ForegroundColor Red
    }
}

Write-Host "Summary: $SuccessCount / $($TestQueries.Count)"
Write-OClawLog "TEST_SUITE_END" "Summary: $SuccessCount"
