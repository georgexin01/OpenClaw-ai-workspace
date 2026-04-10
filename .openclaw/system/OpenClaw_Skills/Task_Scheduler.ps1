# OPENCLAW SKILL: TASK SCHEDULER UI [V1.0]
# [PURPOSE]: Visual task management interface for daemon scheduled tasks

param(
    [string]$Action = "LIST",   # LIST, ADD, REMOVE, TOGGLE, PRESETS
    [string]$Name = "",
    [string]$Schedule = "",
    [string]$Command = ""
)

$DaemonSkill = Join-Path $PSScriptRoot "Daemon_Service.ps1"

switch ($Action.ToUpper()) {
    "LIST" {
        $output = & powershell -ExecutionPolicy Bypass -File $DaemonSkill -Action LIST_TASKS 2>&1 | Out-String
        Write-Output $output
    }
    "ADD" {
        if (-not $Name -or -not $Schedule -or -not $Command) {
            Write-Output "[TASKS] Required: -Name, -Schedule, -Command"
            Write-Output "Schedule formats: 'every 5m', 'every 1h', 'daily 09:00', 'hourly'"
            Write-Output "Command: skill name (e.g. 'Daemon_Health') or PowerShell command"
            break
        }
        $output = & powershell -ExecutionPolicy Bypass -File $DaemonSkill -Action ADD_TASK -TaskName $Name -TaskSchedule $Schedule -TaskCommand $Command 2>&1 | Out-String
        Write-Output $output
    }
    "REMOVE" {
        if (-not $Name) { Write-Output "[TASKS] Provide -Name to remove."; break }
        $output = & powershell -ExecutionPolicy Bypass -File $DaemonSkill -Action REMOVE_TASK -TaskName $Name 2>&1 | Out-String
        Write-Output $output
    }
    "PRESETS" {
        Write-Output @"
[TASK PRESETS] Common scheduled tasks:

1. Health Check (every 5 min):
   -Name health_check -Schedule "every 5m" -Command Daemon_Health

2. Security Scan (hourly):
   -Name security_scan -Schedule "hourly" -Command Security_Scan

3. Memory Graph (every 30 min):
   -Name memory_update -Schedule "every 30m" -Command Memory_Graph

4. Git Sync (every 2 hours):
   -Name git_sync -Schedule "every 2h" -Command Sovereign_GitSync

5. Activity Journal (daily 23:55):
   -Name daily_journal -Schedule "daily 23:55" -Command Activity_Journal

6. GPU Monitor (every 1 min):
   -Name gpu_watch -Schedule "every 1m" -Command Get_GPU_Status

Use: -Action ADD with the parameters above to install any preset.
"@
    }
    default { Write-Output "Use: LIST, ADD, REMOVE, TOGGLE, PRESETS" }
}
