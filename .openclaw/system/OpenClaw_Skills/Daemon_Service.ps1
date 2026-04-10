# OPENCLAW SKILL: DAEMON SERVICE [V1.0]
# ========================================
# [PURPOSE]: 24/7 background daemon with system tray, scheduled tasks, auto-restart
# [ACTIONS]: INSTALL, UNINSTALL, START, STOP, STATUS, ADD_TASK, LIST_TASKS, REMOVE_TASK

param(
    [string]$Action = "STATUS",
    [string]$TaskName = "",
    [string]$TaskSchedule = "",
    [string]$TaskCommand = "",
    [int]$HealthInterval = 300
)

$BridgeDir = Join-Path $PSScriptRoot "..\skills_bridge"
$TasksFile = Join-Path $BridgeDir "daemon_tasks.json"
$DaemonLog = Join-Path $BridgeDir "daemon_log.jsonl"
$PidFile = Join-Path $BridgeDir "daemon.pid"
$DaemonScript = $PSCommandPath
$GUIScript = Join-Path $PSScriptRoot "..\..\OpenClaw_GUI.ps1"
$HealthSkill = Join-Path $PSScriptRoot "Daemon_Health.ps1"
$IconPath = Join-Path $PSScriptRoot "..\OpenClaw.ico"
$TaskSchedName = "OpenClaw_Daemon"
$WatchdogName = "OpenClaw_Watchdog"

function Write-DaemonLog([string]$Event, [string]$Detail = "") {
    $entry = @{ ts = (Get-Date -Format "o"); event = $Event; detail = $Detail } | ConvertTo-Json -Compress
    Add-Content -Path $DaemonLog -Value $entry -ErrorAction SilentlyContinue
}

function Get-ScheduledTasks {
    if (-not (Test-Path $TasksFile)) { return @() }
    try { return @(Get-Content $TasksFile | ConvertFrom-Json) } catch { return @() }
}

function Save-ScheduledTasks($Tasks) {
    $Tasks | ConvertTo-Json -Depth 5 | Set-Content $TasksFile -Force
}

function Get-NextRun([string]$Schedule, [datetime]$LastRun) {
    $now = Get-Date
    if ($Schedule -match "^every (\d+)m$") { return $LastRun.AddMinutes([int]$Matches[1]) }
    if ($Schedule -match "^every (\d+)h$") { return $LastRun.AddHours([int]$Matches[1]) }
    if ($Schedule -match "^every (\d+)s$") { return $LastRun.AddSeconds([int]$Matches[1]) }
    if ($Schedule -match "^hourly$") { return $now.Date.AddHours($now.Hour + 1) }
    if ($Schedule -match "^daily (\d{2}):(\d{2})$") {
        $target = $now.Date.AddHours([int]$Matches[1]).AddMinutes([int]$Matches[2])
        return if ($target -le $now) { $target.AddDays(1) } else { $target }
    }
    return $now.AddMinutes(10) # fallback
}

function Test-DaemonRunning {
    if (-not (Test-Path $PidFile)) { return $false }
    $pid = Get-Content $PidFile -ErrorAction SilentlyContinue
    if (-not $pid) { return $false }
    $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
    return ($null -ne $proc)
}

# --- ACTIONS ---
switch ($Action.ToUpper()) {
    "INSTALL" {
        Write-Host "[DAEMON] Installing OpenClaw Daemon to Task Scheduler..." -ForegroundColor Cyan

        # Create startup task
        $taskAction = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$DaemonScript`" -Action START"
        schtasks /Create /TN $TaskSchedName /TR $taskAction /SC ONLOGON /F 2>&1 | Out-Null

        # Create watchdog (every 5 min check)
        $watchAction = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"if (-not (Test-Path '$PidFile') -or -not (Get-Process -Id (Get-Content '$PidFile' -EA 0) -EA 0)) { Start-Process powershell '-WindowStyle Hidden -ExecutionPolicy Bypass -File \`"$DaemonScript\`" -Action START' }`""
        schtasks /Create /TN $WatchdogName /TR $watchAction /SC MINUTE /MO 5 /F 2>&1 | Out-Null

        # Add default health check task
        $tasks = Get-ScheduledTasks
        if (-not ($tasks | Where-Object { $_.name -eq "health_check" })) {
            $tasks += @{
                name = "health_check"
                schedule = "every 5m"
                command = "Daemon_Health"
                type = "skill"
                enabled = $true
                last_run = ""
                next_run = (Get-Date).AddMinutes(5).ToString("o")
            }
            Save-ScheduledTasks $tasks
        }

        Write-DaemonLog "INSTALL" "Daemon registered in Task Scheduler"
        Write-Output "[DAEMON] Installed successfully. Will auto-start on logon + watchdog every 5 min."
        Write-Output "Scheduled tasks: $TaskSchedName, $WatchdogName"
    }

    "UNINSTALL" {
        schtasks /Delete /TN $TaskSchedName /F 2>&1 | Out-Null
        schtasks /Delete /TN $WatchdogName /F 2>&1 | Out-Null
        if (Test-Path $PidFile) { Remove-Item $PidFile -Force }
        Write-DaemonLog "UNINSTALL" "Daemon removed from Task Scheduler"
        Write-Output "[DAEMON] Uninstalled. Scheduled tasks removed."
    }

    "START" {
        if (Test-DaemonRunning) {
            Write-Output "[DAEMON] Already running (PID: $(Get-Content $PidFile))."
            break
        }

        Write-DaemonLog "START" "Daemon starting"
        Set-Content -Path $PidFile -Value $PID -Force

        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        # System Tray Icon
        $trayIcon = New-Object System.Windows.Forms.NotifyIcon
        $trayIcon.Text = "OpenClaw Daemon"
        if (Test-Path $IconPath) {
            $trayIcon.Icon = New-Object System.Drawing.Icon($IconPath)
        } else {
            $trayIcon.Icon = [System.Drawing.SystemIcons]::Application
        }
        $trayIcon.Visible = $true

        # Context Menu
        $menu = New-Object System.Windows.Forms.ContextMenuStrip
        $menuOpen = $menu.Items.Add("Open OpenClaw GUI")
        $menuHealth = $menu.Items.Add("Health Check")
        $menuPause = $menu.Items.Add("Pause Daemon")
        $menu.Items.Add("-") | Out-Null
        $menuExit = $menu.Items.Add("Exit Daemon")
        $trayIcon.ContextMenuStrip = $menu

        $script:DaemonPaused = $false
        $script:DaemonRunning = $true

        $menuOpen.Add_Click({
            if (Test-Path $GUIScript) {
                Start-Process powershell "-ExecutionPolicy Bypass -File `"$GUIScript`""
            }
        })

        $menuHealth.Add_Click({
            $result = & powershell -ExecutionPolicy Bypass -File $HealthSkill 2>&1 | Out-String
            $trayIcon.ShowBalloonTip(5000, "OpenClaw Health", $result.Substring(0, [Math]::Min(200, $result.Length)), [System.Windows.Forms.ToolTipIcon]::Info)
        })

        $menuPause.Add_Click({
            $script:DaemonPaused = -not $script:DaemonPaused
            $menuPause.Text = if ($script:DaemonPaused) { "Resume Daemon" } else { "Pause Daemon" }
            $trayIcon.ShowBalloonTip(2000, "OpenClaw", $(if ($script:DaemonPaused) { "Daemon Paused" } else { "Daemon Resumed" }), [System.Windows.Forms.ToolTipIcon]::Info)
        })

        $menuExit.Add_Click({
            $script:DaemonRunning = $false
            $trayIcon.Visible = $false
            $trayIcon.Dispose()
            if (Test-Path $PidFile) { Remove-Item $PidFile -Force }
            Write-DaemonLog "STOP" "Daemon stopped by user"
            [System.Windows.Forms.Application]::Exit()
        })

        # Health Timer
        $healthTimer = New-Object System.Windows.Forms.Timer
        $healthTimer.Interval = $HealthInterval * 1000

        $healthTimer.Add_Tick({
            if ($script:DaemonPaused) { return }

            try {
                # Run health check
                $healthRaw = & powershell -ExecutionPolicy Bypass -File $HealthSkill -AsJson 2>$null
                if ($healthRaw) {
                    $health = $healthRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($health.alerts -and $health.alerts.Count -gt 0) {
                        $trayIcon.ShowBalloonTip(5000, "OpenClaw Alert", ($health.alerts -join "; "), [System.Windows.Forms.ToolTipIcon]::Warning)
                    }
                    Write-DaemonLog "HEALTH" ($health.status)
                }

                # Run scheduled tasks
                $tasks = Get-ScheduledTasks
                $now = Get-Date
                $updated = $false
                foreach ($task in $tasks) {
                    if (-not $task.enabled) { continue }
                    $nextRun = if ($task.next_run) { [datetime]$task.next_run } else { $now }
                    if ($now -ge $nextRun) {
                        Write-DaemonLog "TASK_RUN" $task.name
                        try {
                            if ($task.type -eq "skill") {
                                $skillPath = Join-Path $PSScriptRoot "$($task.command).ps1"
                                if (Test-Path $skillPath) {
                                    & powershell -ExecutionPolicy Bypass -File $skillPath 2>&1 | Out-Null
                                }
                            } elseif ($task.type -eq "command") {
                                Invoke-Expression $task.command 2>&1 | Out-Null
                            }
                        } catch {
                            Write-DaemonLog "TASK_ERROR" "$($task.name): $($_.Exception.Message)"
                        }
                        $task.last_run = $now.ToString("o")
                        $task.next_run = (Get-NextRun $task.schedule $now).ToString("o")
                        $updated = $true
                    }
                }
                if ($updated) { Save-ScheduledTasks $tasks }
            } catch {
                Write-DaemonLog "ERROR" $_.Exception.Message
            }
        })

        $healthTimer.Start()
        $trayIcon.ShowBalloonTip(3000, "OpenClaw Daemon", "Sovereign Intelligence is running in background.", [System.Windows.Forms.ToolTipIcon]::Info)

        Write-DaemonLog "RUNNING" "PID=$PID Interval=${HealthInterval}s"
        [System.Windows.Forms.Application]::Run()
    }

    "STOP" {
        if (Test-DaemonRunning) {
            $pid = Get-Content $PidFile
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
            Write-DaemonLog "STOP" "Daemon stopped"
            Write-Output "[DAEMON] Stopped (PID: $pid)."
        } else {
            Write-Output "[DAEMON] Not running."
        }
    }

    "STATUS" {
        $running = Test-DaemonRunning
        $installed = (schtasks /Query /TN $TaskSchedName 2>&1) -notmatch "ERROR"
        $tasks = Get-ScheduledTasks
        $enabledTasks = @($tasks | Where-Object { $_.enabled })

        $output = @"
[DAEMON STATUS]
Running: $(if ($running) { "YES (PID: $(Get-Content $PidFile))" } else { "NO" })
Installed: $(if ($installed) { "YES (starts on logon)" } else { "NO" })
Scheduled tasks: $($enabledTasks.Count) active / $($tasks.Count) total
Health interval: ${HealthInterval}s
"@
        if ($tasks.Count -gt 0) {
            $output += "`nTasks:`n"
            foreach ($t in $tasks) {
                $output += "  [$( if ($t.enabled) { 'ON' } else { 'OFF' })] $($t.name) — $($t.schedule) — next: $(if ($t.next_run) { $t.next_run.Substring(0,16) } else { 'pending' })`n"
            }
        }
        Write-Output $output
    }

    "ADD_TASK" {
        if (-not $TaskName -or -not $TaskSchedule -or -not $TaskCommand) {
            Write-Output "Required: -TaskName, -TaskSchedule (e.g. 'every 5m', 'daily 09:00'), -TaskCommand (skill name or PS command)"
            break
        }
        $tasks = Get-ScheduledTasks
        $tasks = @($tasks | Where-Object { $_.name -ne $TaskName })  # Remove existing with same name
        $isSkill = Test-Path (Join-Path $PSScriptRoot "$TaskCommand.ps1")
        $tasks += @{
            name = $TaskName
            schedule = $TaskSchedule
            command = $TaskCommand
            type = if ($isSkill) { "skill" } else { "command" }
            enabled = $true
            last_run = ""
            next_run = (Get-NextRun $TaskSchedule (Get-Date)).ToString("o")
        }
        Save-ScheduledTasks $tasks
        Write-DaemonLog "ADD_TASK" "$TaskName ($TaskSchedule)"
        Write-Output "[DAEMON] Task added: $TaskName — runs $TaskSchedule — command: $TaskCommand"
    }

    "LIST_TASKS" {
        $tasks = Get-ScheduledTasks
        if ($tasks.Count -eq 0) { Write-Output "[DAEMON] No scheduled tasks."; break }
        $output = "[SCHEDULED TASKS] $($tasks.Count) total:`n"
        foreach ($t in $tasks) {
            $output += "  [$( if ($t.enabled) { 'ON' } else { 'OFF' })] $($t.name)`n    Schedule: $($t.schedule) | Command: $($t.command) ($($t.type))`n    Last: $(if ($t.last_run) { $t.last_run.Substring(0,16) } else { 'never' }) | Next: $(if ($t.next_run) { $t.next_run.Substring(0,16) } else { 'pending' })`n"
        }
        Write-Output $output
    }

    "REMOVE_TASK" {
        if (-not $TaskName) { Write-Output "Provide -TaskName to remove."; break }
        $tasks = Get-ScheduledTasks
        $tasks = @($tasks | Where-Object { $_.name -ne $TaskName })
        Save-ScheduledTasks $tasks
        Write-DaemonLog "REMOVE_TASK" $TaskName
        Write-Output "[DAEMON] Task removed: $TaskName"
    }

    default { Write-Output "Unknown action: $Action. Use: INSTALL, UNINSTALL, START, STOP, STATUS, ADD_TASK, LIST_TASKS, REMOVE_TASK" }
}
