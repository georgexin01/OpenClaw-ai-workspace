# OPENCLAW SKILL: USAGE ANALYTICS [V1.0]
# =========================================
# [PURPOSE]: Track tokens, inference time, costs per model
# [SOURCE]: Inspired by Open WebUI usage analytics
# [ACTIONS]: REPORT, LOG, RESET, DAILY, TOP_MODELS

param(
    [string]$Action = "REPORT",
    [string]$Model = "",
    [int]$Tokens = 0,
    [double]$TimeSec = 0,
    [string]$Date = ""
)

$BridgeDir = Join-Path $PSScriptRoot "..\skills_bridge"
$AnalyticsFile = Join-Path $BridgeDir "usage_analytics.jsonl"
$DiagLog = Join-Path $PSScriptRoot "..\diagnostic.log"

switch ($Action.ToUpper()) {
    "LOG" {
        if (-not $Model -or $Tokens -eq 0) { Write-Output "[ANALYTICS] Provide -Model and -Tokens."; break }
        $entry = @{
            model = $Model; tokens = $Tokens; time_sec = $TimeSec
            tps = if ($TimeSec -gt 0) { [math]::Round($Tokens / $TimeSec, 1) } else { 0 }
            ts = (Get-Date -Format "o"); date = (Get-Date -Format "yyyy-MM-dd")
        } | ConvertTo-Json -Compress
        Add-Content -Path $AnalyticsFile -Value $entry -ErrorAction SilentlyContinue
        Write-Output "[ANALYTICS] Logged: $Model $Tokens tokens ${TimeSec}s"
    }

    "REPORT" {
        # Gather from diagnostic log
        $entries = @()

        # Parse from diagnostic.log PERF entries
        if (Test-Path $DiagLog) {
            Get-Content $DiagLog | Where-Object { $_ -match "\[PERF\]" } | ForEach-Object {
                if ($_ -match "Tokens=(\d+) Speed=([\d.]+)t/s Model=(\S+)") {
                    $entries += @{ tokens = [int]$Matches[1]; tps = [double]$Matches[2]; model = $Matches[3] }
                }
            }
        }

        # Also from analytics file
        if (Test-Path $AnalyticsFile) {
            Get-Content $AnalyticsFile | ForEach-Object {
                try { $entries += ($_ | ConvertFrom-Json) } catch {}
            }
        }

        if ($entries.Count -eq 0) { Write-Output "[ANALYTICS] No usage data yet. Start chatting to generate data."; break }

        $totalTokens = ($entries | Measure-Object -Property tokens -Sum).Sum
        $totalQueries = $entries.Count
        $avgTps = [math]::Round(($entries | Where-Object { $_.tps -gt 0 } | Measure-Object -Property tps -Average).Average, 1)

        # By model
        $byModel = $entries | Group-Object model | ForEach-Object {
            @{
                model = $_.Name
                queries = $_.Count
                tokens = ($_.Group | Measure-Object -Property tokens -Sum).Sum
                avg_tps = [math]::Round(($_.Group | Where-Object { $_.tps -gt 0 } | Measure-Object -Property tps -Average).Average, 1)
            }
        } | Sort-Object { $_.tokens } -Descending

        $output = @"
[USAGE ANALYTICS REPORT]
Total queries: $totalQueries
Total tokens: $totalTokens
Average speed: ${avgTps} t/s

PER MODEL:
"@
        foreach ($m in $byModel) {
            $bar = "#" * [math]::Min(30, [int]($m.tokens / [math]::Max(1, $totalTokens) * 30))
            $output += "  $($m.model.PadRight(18)) $($m.queries.ToString().PadLeft(5)) queries | $($m.tokens.ToString().PadLeft(8)) tokens | $($m.avg_tps) t/s $bar`n"
        }

        # Estimated cost (at ~$0.10/1M tokens for local inference = electricity only)
        $estCost = [math]::Round($totalTokens / 1000000 * 0.10, 4)
        $output += "`nEstimated electricity cost: ~`$$estCost (vs ~`$$([math]::Round($totalTokens / 1000000 * 3, 2)) if using cloud API)"
        $output += "`nSavings from local inference: ~$([math]::Round((1 - 0.10/3) * 100))%"

        Write-Output $output
    }

    "DAILY" {
        $targetDate = if ($Date) { $Date } else { Get-Date -Format "yyyy-MM-dd" }
        $entries = @()

        if (Test-Path $DiagLog) {
            Get-Content $DiagLog | Where-Object { $_ -match "^\[$targetDate" -and $_ -match "\[PERF\]" } | ForEach-Object {
                if ($_ -match "Tokens=(\d+) Speed=([\d.]+)t/s Model=(\S+)") {
                    $entries += @{ tokens = [int]$Matches[1]; tps = [double]$Matches[2]; model = $Matches[3] }
                }
            }
        }

        if ($entries.Count -eq 0) { Write-Output "[ANALYTICS] No data for $targetDate."; break }

        $totalTokens = ($entries | Measure-Object -Property tokens -Sum).Sum
        Write-Output "[DAILY USAGE: $targetDate] Queries: $($entries.Count) | Tokens: $totalTokens | Avg: $([math]::Round(($entries | Measure-Object -Property tps -Average).Average, 1)) t/s"
    }

    "TOP_MODELS" {
        $entries = @()
        if (Test-Path $DiagLog) {
            Get-Content $DiagLog | Where-Object { $_ -match "\[PERF\]" } | ForEach-Object {
                if ($_ -match "Speed=([\d.]+)t/s Model=(\S+)") {
                    $entries += @{ tps = [double]$Matches[1]; model = $Matches[2] }
                }
            }
        }

        if ($entries.Count -eq 0) { Write-Output "[ANALYTICS] No performance data."; break }

        $ranked = $entries | Group-Object model | ForEach-Object {
            @{ model = $_.Name; avg_tps = [math]::Round(($_.Group | Measure-Object -Property tps -Average).Average, 1); samples = $_.Count }
        } | Sort-Object { $_.avg_tps } -Descending

        $output = "[TOP MODELS BY SPEED]`n"
        $rank = 1
        foreach ($m in $ranked) {
            $output += "  #$rank $($m.model) — $($m.avg_tps) t/s ($($m.samples) samples)`n"
            $rank++
        }
        Write-Output $output
    }

    "RESET" {
        if (Test-Path $AnalyticsFile) { Remove-Item $AnalyticsFile -Force }
        Write-Output "[ANALYTICS] Reset complete."
    }

    default { Write-Output "Use: REPORT, LOG, DAILY, TOP_MODELS, RESET" }
}
