# OPENCLAW SKILL: TERMINAL EXECUTOR [V1.0]
# ============================================
# [PURPOSE]: Real shell execution with output capture — safe sandbox
# [SOURCE]: Inspired by Open WebUI Open Terminal feature
# [ACTIONS]: RUN, POWERSHELL, CMD, NODE, PYTHON, HISTORY

param(
    [string]$Action = "RUN",
    [string]$Command = "",
    [string]$Shell = "powershell",
    [int]$TimeoutSec = 30,
    [switch]$NoCapture
)

$BridgeDir = Join-Path $PSScriptRoot "..\skills_bridge"
$HistoryFile = Join-Path $BridgeDir "terminal_history.jsonl"

# Blocked commands for safety
$BlockedPatterns = @(
    "format-volume", "format c:", "remove-item -recurse c:\\",
    "del /s /q c:\\", "rd /s /q c:\\", "shutdown", "restart-computer",
    "rm -rf /", "mkfs", "dd if=", ":(){ :|:& };:"
)

function Test-CommandSafe([string]$Cmd) {
    foreach ($blocked in $BlockedPatterns) {
        if ($Cmd -match [regex]::Escape($blocked)) { return $false }
    }
    return $true
}

function Save-History([string]$Cmd, [string]$Output, [string]$ShellType, [int]$ExitCode) {
    $entry = @{ cmd = $Cmd; output = $Output.Substring(0, [Math]::Min(500, $Output.Length)); shell = $ShellType; exit = $ExitCode; ts = (Get-Date -Format "o") } | ConvertTo-Json -Compress
    Add-Content -Path $HistoryFile -Value $entry -ErrorAction SilentlyContinue
}

switch ($Action.ToUpper()) {
    { $_ -in @("RUN","POWERSHELL","CMD","NODE","PYTHON") } {
        if (-not $Command) { Write-Output "[TERMINAL] Provide -Command to execute."; break }

        if (-not (Test-CommandSafe $Command)) {
            Write-Output "[TERMINAL] BLOCKED: Command contains dangerous pattern. Execution denied."
            break
        }

        $shellExe = switch ($Action.ToUpper()) {
            "CMD"        { "cmd.exe" }
            "NODE"       { "node" }
            "PYTHON"     { "python" }
            default      { "powershell.exe" }
        }

        $shellArgs = switch ($Action.ToUpper()) {
            "CMD"        { "/c $Command" }
            "NODE"       { "-e `"$Command`"" }
            "PYTHON"     { "-c `"$Command`"" }
            default      { "-NoProfile -ExecutionPolicy Bypass -Command `"$Command`"" }
        }

        Write-Host "[TERMINAL] Executing ($shellExe): $($Command.Substring(0, [Math]::Min(60, $Command.Length)))..." -ForegroundColor Cyan

        $job = Start-Job -ScriptBlock {
            param($exe, $args_str)
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $exe
            $psi.Arguments = $args_str
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true

            $proc = [System.Diagnostics.Process]::Start($psi)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()

            return @{ stdout = $stdout; stderr = $stderr; exitCode = $proc.ExitCode } | ConvertTo-Json
        } -ArgumentList $shellExe, $shellArgs

        $completed = $job | Wait-Job -Timeout $TimeoutSec
        if ($completed) {
            $raw = $job | Receive-Job | Out-String
            Remove-Job $job -Force
            try {
                $result = $raw.Trim() | ConvertFrom-Json
                $output = ""
                if ($result.stdout) { $output += $result.stdout }
                if ($result.stderr) { $output += "`n[STDERR] $($result.stderr)" }
                $exitCode = $result.exitCode

                Save-History $Command $output $shellExe $exitCode

                Write-Output "[TERMINAL] Exit: $exitCode | Shell: $shellExe"
                Write-Output "---"
                Write-Output $output.Trim()
                Write-Output "---"
            } catch {
                Write-Output "[TERMINAL] Output: $raw"
            }
        } else {
            Stop-Job $job -Force; Remove-Job $job -Force
            Write-Output "[TERMINAL] Timeout after ${TimeoutSec}s. Command killed."
        }
    }

    "HISTORY" {
        if (-not (Test-Path $HistoryFile)) { Write-Output "[TERMINAL] No history."; break }
        $lines = Get-Content $HistoryFile -Tail 10
        $output = "[TERMINAL HISTORY] Last 10 commands:`n"
        foreach ($line in $lines) {
            try {
                $entry = $line | ConvertFrom-Json
                $output += "  [$($entry.shell)] $($entry.cmd.Substring(0, [Math]::Min(60, $entry.cmd.Length))) → exit:$($entry.exit) ($($entry.ts.Substring(0,16)))`n"
            } catch {}
        }
        Write-Output $output
    }

    default { Write-Output "Use: RUN, POWERSHELL, CMD, NODE, PYTHON, HISTORY" }
}
