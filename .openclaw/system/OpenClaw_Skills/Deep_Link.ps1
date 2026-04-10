# OPENCLAW SKILL: DEEP LINK HANDLER [V1.0]
# ============================================
# [PURPOSE]: Register openclaw:// URL scheme for external triggering
# [SOURCE]: Inspired by openclaw-windows-node deep links
# [ACTIONS]: REGISTER, UNREGISTER, STATUS, HANDLE

param(
    [string]$Action = "STATUS",
    [string]$Uri = ""
)

$ProtocolName = "openclaw"
$GUIPath = Join-Path $PSScriptRoot "..\..\OpenClaw_GUI.ps1"
$RegBase = "HKCU:\Software\Classes\$ProtocolName"

switch ($Action.ToUpper()) {
    "REGISTER" {
        Write-Host "[DEEPLINK] Registering openclaw:// protocol handler..." -ForegroundColor Cyan

        # Create protocol key
        if (-not (Test-Path $RegBase)) { New-Item -Path $RegBase -Force | Out-Null }
        Set-ItemProperty -Path $RegBase -Name "(Default)" -Value "OpenClaw Sovereign"
        Set-ItemProperty -Path $RegBase -Name "URL Protocol" -Value ""

        # Create shell/open/command
        $cmdPath = "$RegBase\shell\open\command"
        if (-not (Test-Path $cmdPath)) { New-Item -Path $cmdPath -Force | Out-Null }

        # Handler: launch PowerShell with the URI as argument
        $handler = "powershell.exe -ExecutionPolicy Bypass -File `"$($PSCommandPath)`" -Action HANDLE -Uri `"%1`""
        Set-ItemProperty -Path $cmdPath -Name "(Default)" -Value $handler

        Write-Output @"
[DEEPLINK] Registered openclaw:// protocol handler.

Supported URLs:
  openclaw://chat          — Open GUI
  openclaw://settings      — Show settings
  openclaw://send?message=text — Send message to AI
  openclaw://skill?name=X  — Run skill X
  openclaw://health        — Run health check
  openclaw://browser?url=X — Open browser to URL

Test in browser or Run dialog (Win+R):
  openclaw://chat
"@
    }

    "UNREGISTER" {
        if (Test-Path $RegBase) {
            Remove-Item -Path $RegBase -Recurse -Force
            Write-Output "[DEEPLINK] Unregistered openclaw:// protocol."
        } else {
            Write-Output "[DEEPLINK] Protocol not registered."
        }
    }

    "STATUS" {
        $registered = Test-Path $RegBase
        Write-Output @"
[DEEPLINK STATUS]
Protocol: openclaw://
Registered: $(if ($registered) { "YES" } else { "NO" })
Handler: PowerShell → Deep_Link.ps1

$(if (-not $registered) { "Run -Action REGISTER to enable deep links." })
"@
    }

    "HANDLE" {
        if (-not $Uri) { Write-Output "[DEEPLINK] No URI provided."; break }

        # Parse openclaw://command?param=value
        $parsed = [System.Uri]$Uri
        $command = $parsed.Host
        $queryParams = @{}
        if ($parsed.Query) {
            $parsed.Query.TrimStart("?").Split("&") | ForEach-Object {
                $parts = $_.Split("=", 2)
                if ($parts.Count -eq 2) { $queryParams[$parts[0]] = [System.Uri]::UnescapeDataString($parts[1]) }
            }
        }

        Write-Host "[DEEPLINK] Handling: $command" -ForegroundColor Cyan

        switch ($command) {
            "chat" {
                Start-Process powershell "-ExecutionPolicy Bypass -File `"$GUIPath`""
                Write-Output "[DEEPLINK] Opening OpenClaw GUI..."
            }
            "send" {
                if ($queryParams.message) {
                    $enginePath = Join-Path $PSScriptRoot "..\..\OpenClaw_Engine.ps1"
                    . $enginePath
                    $result = Invoke-OClawQuery $queryParams.message 1
                    Write-Output "[DEEPLINK] AI Response: $result"
                    # Also show notification
                    & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Notify_Center.ps1") -Title "OpenClaw" -Message $result.Substring(0, [Math]::Min(150, $result.Length))
                }
            }
            "skill" {
                if ($queryParams.name) {
                    $skillPath = Join-Path $PSScriptRoot "$($queryParams.name).ps1"
                    if (Test-Path $skillPath) {
                        $output = & powershell -ExecutionPolicy Bypass -File $skillPath 2>&1 | Out-String
                        Write-Output "[DEEPLINK] Skill output: $output"
                    } else {
                        Write-Output "[DEEPLINK] Skill not found: $($queryParams.name)"
                    }
                }
            }
            "health" {
                & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Daemon_Health.ps1")
            }
            "browser" {
                if ($queryParams.url) {
                    & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Browser_Control.ps1") -Action START -Url $queryParams.url
                }
            }
            default {
                Write-Output "[DEEPLINK] Unknown command: $command"
            }
        }
    }

    default { Write-Output "Use: REGISTER, UNREGISTER, STATUS, HANDLE" }
}
