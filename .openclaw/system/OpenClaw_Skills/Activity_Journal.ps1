# OPENCLAW SKILL: ACTIVITY JOURNAL [V1.0]
# [PURPOSE]: Daily log of all OpenClaw activity — auto-summary

param(
    [string]$Action = "TODAY",  # TODAY, SUMMARY, FULL, CLEAR
    [string]$Date = ""          # YYYY-MM-DD format, defaults to today
)

$JournalDir = Join-Path $PSScriptRoot "..\skills_bridge\journal"
if (-not (Test-Path $JournalDir)) { New-Item -ItemType Directory -Path $JournalDir -Force | Out-Null }

$DateStr = if ($Date) { $Date } else { Get-Date -Format "yyyy-MM-dd" }
$JournalFile = Join-Path $JournalDir "journal_$DateStr.md"
$DiagLog = Join-Path $PSScriptRoot "..\diagnostic.log"
$ChatLog = Join-Path $PSScriptRoot "..\skills_bridge\chat_log.jsonl"
$DaemonLog = Join-Path $PSScriptRoot "..\skills_bridge\daemon_log.jsonl"

switch ($Action.ToUpper()) {
    "TODAY" {
        # Gather today's activity from all sources
        $entries = @()
        $todayPattern = $DateStr

        # From diagnostic log
        if (Test-Path $DiagLog) {
            $logLines = Get-Content $DiagLog | Where-Object { $_ -match "^\[$todayPattern" }
            $entries += "## Engine Activity`n$($logLines.Count) events logged"
            $queryCount = ($logLines | Where-Object { $_ -match "\[QUERY\]" }).Count
            $skillCount = ($logLines | Where-Object { $_ -match "\[SKILL_RUN\]" }).Count
            $entries += "- Queries: $queryCount"
            $entries += "- Skills executed: $skillCount"
        }

        # From chat log
        if (Test-Path $ChatLog) {
            $chatLines = Get-Content $ChatLog | Where-Object {
                if ($_) { try { ($_ | ConvertFrom-Json).timestamp -match $todayPattern } catch { $false } } else { $false }
            }
            $entries += "`n## Chat Activity`n- Conversations: $($chatLines.Count) messages"
        }

        # From daemon log
        if (Test-Path $DaemonLog) {
            $daemonLines = Get-Content $DaemonLog | Where-Object {
                if ($_) { try { ($_ | ConvertFrom-Json).ts -match $todayPattern } catch { $false } } else { $false }
            }
            $entries += "`n## Daemon Activity`n- Events: $($daemonLines.Count)"
        }

        $journal = "# OpenClaw Activity Journal — $DateStr`n`n$($entries -join "`n")`n`n---`n_Generated: $(Get-Date -Format 'o')_"
        Set-Content -Path $JournalFile -Value $journal -Force
        Write-Output $journal
    }

    "SUMMARY" {
        $enginePath = Join-Path $PSScriptRoot "..\..\OpenClaw_Engine.ps1"
        if (Test-Path $JournalFile) {
            $content = Get-Content $JournalFile -Raw
            . $enginePath
            $summary = Invoke-OClawQuery "Summarize this activity journal in 2-3 sentences:`n$content" 1
            Write-Output "[DAILY SUMMARY for $DateStr]`n$summary"
        } else {
            Write-Output "[JOURNAL] No journal found for $DateStr. Run -Action TODAY first."
        }
    }

    "FULL" {
        $journals = Get-ChildItem $JournalDir -Filter "journal_*.md" | Sort-Object Name -Descending | Select-Object -First 7
        if ($journals.Count -eq 0) { Write-Output "[JOURNAL] No journals found."; break }
        $output = "[ACTIVITY JOURNALS] Last $($journals.Count) days:`n"
        foreach ($j in $journals) {
            $date = $j.BaseName -replace "journal_", ""
            $size = [math]::Round($j.Length / 1024, 1)
            $output += "  $date (${size}KB)`n"
        }
        Write-Output $output
    }

    "CLEAR" {
        $old = Get-ChildItem $JournalDir -Filter "journal_*.md" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
        $old | Remove-Item -Force
        Write-Output "[JOURNAL] Cleared $($old.Count) journals older than 30 days."
    }

    default { Write-Output "Use: TODAY, SUMMARY, FULL, CLEAR" }
}
