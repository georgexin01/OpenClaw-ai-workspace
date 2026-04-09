# OPENCLAW SOVEREIGN PROTOCOL TESTER (V1.03)
# Defensive Build - Sovereign Deep Audit

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$EnginePath = Join-Path $PSScriptRoot "..\OpenClaw_Engine.ps1"
if (-not (Test-Path $EnginePath)) { exit 1 }
. $EnginePath

Write-Host "--- SOVEREIGN DEEP AUDIT V1.03 ---" -ForegroundColor Cyan
Write-OClawLog "TEST_SUITE_START" "Initiating V1.03 stress test"

$TestQueries = @(
    "hi",
    "What is your identity name?",
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
        
        # V1.03 Check: 'hi' should NOT contain the word 'Recording' or 'Evolution' (Technical logs)
        if ($q -eq "hi" -and ($Response -match "Recording" -or $Response -match "Evolution recorded")) {
             Write-Host "FAIL (Technical logs leaked)" -ForegroundColor Red
             Write-OClawLog "TEST_FAIL" "Query: $q | Leak detected."
        }
        elseif ($Response -match "Gemma-4" -or $Response -match "Sovereign" -or $Response -match "hello") {
            Write-Host "PASS ($($Timer.Elapsed.TotalSeconds)s)" -ForegroundColor Green
            $SuccessCount++
        } else {
            Write-Host "FAIL (Unexpected response content)" -ForegroundColor Red
            Write-OClawLog "TEST_FAIL" "Query: $q | Resp: $Response"
        }
    } catch {
        Write-Host "CRASH" -ForegroundColor Red
    }
}

Write-Host "Summary: $SuccessCount / $($TestQueries.Count)"
Write-OClawLog "TEST_SUITE_END" "V1.03 Summary: $SuccessCount"
