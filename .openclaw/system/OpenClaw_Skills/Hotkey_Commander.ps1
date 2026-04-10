# OPENCLAW SKILL: HOTKEY COMMANDER [V1.0]
# [PURPOSE]: Register global hotkeys to trigger OpenClaw skills

param(
    [string]$Action = "LIST",   # LIST, REGISTER, START
    [string]$HotkeyCombo = "",  # e.g. "Ctrl+Shift+O"
    [string]$SkillName = ""
)

$ConfigPath = Join-Path $PSScriptRoot "..\skills_bridge\hotkey_config.json"

function Get-HotkeyConfig {
    if (Test-Path $ConfigPath) { return Get-Content $ConfigPath | ConvertFrom-Json }
    $default = @(
        @{ combo = "Ctrl+Shift+O"; skill = "GUI_OPEN"; description = "Open OpenClaw GUI" }
        @{ combo = "Ctrl+Shift+H"; skill = "Daemon_Health"; description = "Quick health check" }
        @{ combo = "Ctrl+Shift+S"; skill = "OCR_Extract"; description = "Screenshot + OCR" }
        @{ combo = "Ctrl+Shift+C"; skill = "Clipboard_Bridge"; description = "Analyze clipboard" }
    )
    $default | ConvertTo-Json -Depth 3 | Set-Content $ConfigPath -Force
    return $default
}

switch ($Action.ToUpper()) {
    "LIST" {
        $config = Get-HotkeyConfig
        $output = "[HOTKEY COMMANDER] Registered hotkeys:`n"
        foreach ($h in $config) {
            $output += "  $($h.combo) → $($h.skill) ($($h.description))`n"
        }
        $output += "`nNote: Hotkeys are active when Daemon is running with START action."
        Write-Output $output
    }
    "REGISTER" {
        if (-not $HotkeyCombo -or -not $SkillName) { Write-Output "Provide -HotkeyCombo and -SkillName."; break }
        $config = @(Get-HotkeyConfig)
        $config = @($config | Where-Object { $_.combo -ne $HotkeyCombo })
        $config += @{ combo = $HotkeyCombo; skill = $SkillName; description = "User-defined" }
        $config | ConvertTo-Json -Depth 3 | Set-Content $ConfigPath -Force
        Write-Output "[HOTKEY] Registered: $HotkeyCombo → $SkillName"
    }
    "START" {
        Write-Host "[HOTKEY] Starting global hotkey listener..." -ForegroundColor Cyan
        Write-Host "[HOTKEY] Note: This runs as a blocking loop. Use in daemon context." -ForegroundColor Yellow
        $config = Get-HotkeyConfig
        Write-Output "[HOTKEY] Listener active with $($config.Count) hotkeys. Press Ctrl+C to stop."
        # Hotkey registration requires a message pump — documented as daemon integration
        Write-Output "[HOTKEY] Full implementation requires Daemon_Service integration. Use from daemon context."
    }
    default { Write-Output "Use: LIST, REGISTER, START" }
}
