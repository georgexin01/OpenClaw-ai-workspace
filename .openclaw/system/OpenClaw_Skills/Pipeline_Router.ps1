# OPENCLAW SKILL: PIPELINE ROUTER [V1.0]
# =========================================
# [PURPOSE]: Message filter/transform chains before AI processing
# [SOURCE]: Inspired by Open WebUI pipelines architecture
# [ACTIONS]: RUN, LIST, ADD, REMOVE, TEST

param(
    [string]$Action = "LIST",
    [string]$Message = "",
    [string]$PipelineName = "",
    [string]$PipelineType = "filter",  # filter, transform, router
    [string]$PipelineCode = ""
)

$BridgeDir = Join-Path $PSScriptRoot "..\skills_bridge"
$PipelinesFile = Join-Path $BridgeDir "pipelines.json"

function Get-Pipelines {
    if (-not (Test-Path $PipelinesFile)) {
        # Default pipelines
        $defaults = @(
            @{ name = "privacy_filter"; type = "filter"; enabled = $true; order = 1
               description = "Remove sensitive data (API keys, passwords, paths)"
               code = '$msg -replace "[a-fA-F0-9]{32,}", "[REDACTED_KEY]" -replace "password\s*[:=]\s*\S+", "password: [HIDDEN]" -replace "c:\\Users\\[^\\]+", "C:\USER"' }
            @{ name = "url_detector"; type = "transform"; enabled = $true; order = 2
               description = "Detect URLs and add web search context"
               code = 'if ($msg -match "https?://\S+") { $msg + " [URL_DETECTED: Auto-context enabled]" } else { $msg }' }
            @{ name = "code_formatter"; type = "transform"; enabled = $true; order = 3
               description = "Detect code patterns and add language hints"
               code = 'if ($msg -match "function |def |class |import |const ") { "[CODE_CONTEXT] " + $msg } else { $msg }' }
            @{ name = "length_guard"; type = "filter"; enabled = $true; order = 99
               description = "Truncate messages over 4000 chars"
               code = 'if ($msg.Length -gt 4000) { $msg.Substring(0, 4000) + " [TRUNCATED]" } else { $msg }' }
        )
        $defaults | ConvertTo-Json -Depth 5 | Set-Content $PipelinesFile -Force
        return $defaults
    }
    return @(Get-Content $PipelinesFile | ConvertFrom-Json)
}

function Save-Pipelines($Pipes) { $Pipes | ConvertTo-Json -Depth 5 | Set-Content $PipelinesFile -Force }

switch ($Action.ToUpper()) {
    "LIST" {
        $pipes = Get-Pipelines
        $output = "[PIPELINES] $($pipes.Count) registered:`n"
        foreach ($p in ($pipes | Sort-Object { $_.order })) {
            $status = if ($p.enabled) { "ON" } else { "OFF" }
            $output += "  [$status] #$($p.order) $($p.name) ($($p.type)) — $($p.description)`n"
        }
        Write-Output $output
    }

    "RUN" {
        if (-not $Message) { Write-Output "[PIPELINE] Provide -Message to process."; break }
        $pipes = Get-Pipelines | Where-Object { $_.enabled } | Sort-Object { $_.order }
        $msg = $Message
        $log = @()

        foreach ($p in $pipes) {
            $before = $msg
            try {
                $msg = Invoke-Expression $p.code
                if ($msg -ne $before) { $log += "[$($p.name)] Modified" }
            } catch {
                $log += "[$($p.name)] Error: $($_.Exception.Message)"
            }
        }

        $output = "[PIPELINE RESULT]`n"
        if ($log.Count -gt 0) { $output += "Transforms: $($log -join ' | ')`n" }
        $output += "---`n$msg"
        Write-Output $output
    }

    "ADD" {
        if (-not $PipelineName -or -not $PipelineCode) {
            Write-Output "[PIPELINE] Provide -PipelineName and -PipelineCode."
            Write-Output "Code must use `$msg variable. Example: '`$msg -replace `"bad`",`"good`"'"
            break
        }
        $pipes = @(Get-Pipelines)
        $maxOrder = ($pipes | Measure-Object -Property order -Maximum).Maximum
        $pipes += @{
            name = $PipelineName; type = $PipelineType; enabled = $true
            order = $maxOrder + 1; description = "Custom pipeline"
            code = $PipelineCode
        }
        Save-Pipelines $pipes
        Write-Output "[PIPELINE] Added: $PipelineName (order: $($maxOrder + 1))"
    }

    "REMOVE" {
        if (-not $PipelineName) { Write-Output "[PIPELINE] Provide -PipelineName."; break }
        $pipes = @(Get-Pipelines | Where-Object { $_.name -ne $PipelineName })
        Save-Pipelines $pipes
        Write-Output "[PIPELINE] Removed: $PipelineName"
    }

    "TEST" {
        if (-not $Message) { $Message = "Check my API key abc123def456abc123def456abc123de and visit https://example.com for function myFunc() { return true; }" }
        Write-Output "[PIPELINE TEST] Input: $($Message.Substring(0, [Math]::Min(100, $Message.Length)))..."
        $pipes = Get-Pipelines | Where-Object { $_.enabled } | Sort-Object { $_.order }
        $msg = $Message
        foreach ($p in $pipes) {
            $before = $msg
            try { $msg = Invoke-Expression $p.code } catch {}
            if ($msg -ne $before) { Write-Output "  [$($p.name)] MATCHED — transformed" }
            else { Write-Output "  [$($p.name)] no change" }
        }
        Write-Output "`nOutput: $($msg.Substring(0, [Math]::Min(200, $msg.Length)))"
    }

    default { Write-Output "Use: LIST, RUN, ADD, REMOVE, TEST" }
}
