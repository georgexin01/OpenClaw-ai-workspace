# OPENCLAW SKILL: NOTIFY CENTER [V1.0]
# [PURPOSE]: Windows toast/balloon notifications for alerts and completions

param(
    [string]$Title = "OpenClaw",
    [string]$Message = "Notification",
    [string]$Type = "Info",     # Info, Warning, Error, Success
    [int]$Duration = 5000
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$IconPath = Join-Path $PSScriptRoot "..\OpenClaw.ico"

$tipIcon = switch ($Type.ToLower()) {
    "warning" { [System.Windows.Forms.ToolTipIcon]::Warning }
    "error"   { [System.Windows.Forms.ToolTipIcon]::Error }
    default   { [System.Windows.Forms.ToolTipIcon]::Info }
}

$notify = New-Object System.Windows.Forms.NotifyIcon
if (Test-Path $IconPath) {
    $notify.Icon = New-Object System.Drawing.Icon($IconPath)
} else {
    $notify.Icon = [System.Drawing.SystemIcons]::Application
}
$notify.Visible = $true
$notify.ShowBalloonTip($Duration, $Title, $Message, $tipIcon)

# Keep alive briefly for the notification to show
Start-Sleep -Milliseconds ([Math]::Min($Duration + 500, 6000))
$notify.Visible = $false
$notify.Dispose()

Write-Output "[NOTIFY] Sent: [$Type] $Title — $Message"
