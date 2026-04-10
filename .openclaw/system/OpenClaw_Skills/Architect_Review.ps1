# OPENCLAW SKILL: ARCHITECT REVIEW [V1.0]
# [OBJECTIVE]: Deep architectural analysis of a workspace folder using Gemma-4.

param(
    [string]$FolderPath = "c:\Users\user\Desktop\workspace"
)

$EnginePath = Join-Path $PSScriptRoot "../OpenClaw_Engine.ps1"
. $EnginePath

Write-Host "[ARCHITECT] Initiating Deep Review of: $FolderPath" -ForegroundColor Magenta

$Files = Get-ChildItem -Path $FolderPath -Depth 1 | Select-Object Name, FullName
$FileContext = ""
foreach ($f in $Files) {
    if ($f.Length -lt 10000) { # Only small files for context
        $content = Get-Content $f.FullName -Raw
        $FileContext += "FILE: $($f.Name)`nCONTENT:`n$content`n`n"
    }
}

$Prompt = @"
You are the OpenClaw Sovereign Architect.
WORKSPACE CONTEXT:
$FileContext

MISSION: Analyze the structural integrity, naming conventions, and logic flow of this workspace.
Identify 3 CRITICAL improvements and 2 AESTHETIC enhancements (Lobster Way).
Provide the response as an ARCHITECT CARD.
"@

$Response = Invoke-OClawQuery $Prompt 2 # Tier 2 (Gemma-4)

Write-Host "`n--- ARCHITECT REVIEW COMPLETE ---" -ForegroundColor Green
Write-Host $Response
