# OPENCLAW SKILL: SOVEREIGN INTEGRITY AUDIT [V1.1]
# [OBJECTIVE]: Detection of unauthorized code mutations (Antigravity Mandate).

$Root = Join-Path $PSScriptRoot "../../"
$LedgerPath = Join-Path $PSScriptRoot "../skills_bridge/security_ledger.json"

Write-Host "[SECURITY] Initiating Sovereign Integrity Audit..." -ForegroundColor Yellow

$Files = Get-ChildItem -Path $Root -Recurse -Filter "*.ps1" | Where-Object { $_.FullName -notmatch "archive" }

$PreviousLedger = if (Test-Path $LedgerPath) { Get-Content $LedgerPath | ConvertFrom-Json } else { @() }
$CurrentLedger = @()
$Alerts = @()

foreach ($f in $Files) {
    try {
        $Hash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash
        $RelPath = $f.FullName.Replace($Root, "")
        
        # Check against previous state
        $Match = $PreviousLedger | Where-Object { $_.Path -eq $RelPath }
        if ($null -ne $Match -and $Match.Hash -ne $Hash) {
            $Alerts += "[MUTATION] $($RelPath) has been modified since last audit."
        } elseif ($null -eq $Match) {
            $Alerts += "[NEW_FILE] $($RelPath) detected."
        }

        $CurrentLedger += [PSCustomObject]@{
            File = $f.Name
            Path = $RelPath
            Hash = $Hash
            Timestamp = (Get-Date -Format "o")
        }
    } catch {
        Write-Host "[!] Failed to hash $($f.Name)" -ForegroundColor Red
    }
}

$CurrentLedger | ConvertTo-Json | Set-Content -Path $LedgerPath -Force

if ($Alerts.Count -gt 0) {
    Write-Host "[!] SECURITY ALERT: Unrecognized mutations detected!" -ForegroundColor Red
    foreach ($a in $Alerts) { Write-Host "  > $a" -ForegroundColor Yellow }
} else {
    Write-Host "[SUCCESS] Integrity Verified. Zero unauthorized mutations detected." -ForegroundColor Green
}

return $Alerts -join "`n"
