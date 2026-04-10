# OPENCLAW SKILL: SCREEN CAPTURE PRO [V1.0]
# =============================================
# [PURPOSE]: Multi-monitor screenshot + window capture + video recording
# [SOURCE]: Inspired by openclaw node screen.capture + screen.record
# [ACTIONS]: FULL, WINDOW, REGION, LIST_MONITORS, RECORD

param(
    [string]$Action = "FULL",
    [string]$Title = "",         # Window title for WINDOW action
    [int]$Monitor = 0,           # Monitor index for FULL
    [int]$X = 0, [int]$Y = 0,   # Region start
    [int]$W = 0, [int]$H = 0,   # Region size
    [int]$Duration = 5,          # Recording duration in seconds
    [int]$FPS = 2                # Frames per second for recording
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$OutputDir = Join-Path $PSScriptRoot "..\skills_bridge\visual_vault"
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
$ts = Get-Date -Format "yyyyMMdd_HHmmss"

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class ScreenAPI {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
}
"@

switch ($Action.ToUpper()) {
    "FULL" {
        $screens = [System.Windows.Forms.Screen]::AllScreens
        $target = if ($Monitor -lt $screens.Count) { $screens[$Monitor] } else { $screens[0] }
        $bounds = $target.Bounds

        $bitmap = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bitmap.Size)

        $path = Join-Path $OutputDir "screen_full_$ts.png"
        $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose(); $bitmap.Dispose()

        Write-Output "[CAPTURE] Full screen saved: $path ($($bounds.Width)x$($bounds.Height))"
        Write-Output "BASE64_IMAGE_PATH:$path"
    }

    "WINDOW" {
        if (-not $Title) {
            # Capture foreground window
            $hwnd = [ScreenAPI]::GetForegroundWindow()
        } else {
            $proc = Get-Process | Where-Object { $_.MainWindowTitle -match $Title } | Select-Object -First 1
            if (-not $proc) { Write-Output "[CAPTURE] Window '$Title' not found."; break }
            $hwnd = $proc.MainWindowHandle
            [ScreenAPI]::SetForegroundWindow($hwnd) | Out-Null
            Start-Sleep -Milliseconds 200
        }

        $rect = New-Object ScreenAPI+RECT
        [ScreenAPI]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
        $w = $rect.Right - $rect.Left; $h = $rect.Bottom - $rect.Top

        if ($w -le 0 -or $h -le 0) { Write-Output "[CAPTURE] Invalid window dimensions."; break }

        $bitmap = New-Object System.Drawing.Bitmap($w, $h)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, (New-Object System.Drawing.Size($w, $h)))

        $path = Join-Path $OutputDir "screen_window_$ts.png"
        $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose(); $bitmap.Dispose()

        Write-Output "[CAPTURE] Window captured: $path (${w}x${h})"
        Write-Output "BASE64_IMAGE_PATH:$path"
    }

    "REGION" {
        if ($W -le 0 -or $H -le 0) { Write-Output "[CAPTURE] Provide -X -Y -W -H for region."; break }

        $bitmap = New-Object System.Drawing.Bitmap($W, $H)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($X, $Y, 0, 0, (New-Object System.Drawing.Size($W, $H)))

        $path = Join-Path $OutputDir "screen_region_$ts.png"
        $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose(); $bitmap.Dispose()

        Write-Output "[CAPTURE] Region captured: $path (${W}x${H} at $X,$Y)"
        Write-Output "BASE64_IMAGE_PATH:$path"
    }

    "LIST_MONITORS" {
        $screens = [System.Windows.Forms.Screen]::AllScreens
        $output = "[MONITORS] $($screens.Count) display(s):`n"
        for ($i = 0; $i -lt $screens.Count; $i++) {
            $s = $screens[$i]
            $primary = if ($s.Primary) { " [PRIMARY]" } else { "" }
            $output += "  [$i] $($s.DeviceName)$primary — $($s.Bounds.Width)x$($s.Bounds.Height) at ($($s.Bounds.X),$($s.Bounds.Y))`n"
        }
        Write-Output $output
    }

    "RECORD" {
        Write-Host "[CAPTURE] Recording screen for ${Duration}s at ${FPS}fps..." -ForegroundColor Cyan
        $frames = @()
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen
        $bounds = $screen.Bounds
        $frameDir = Join-Path $OutputDir "recording_$ts"
        New-Item -ItemType Directory -Path $frameDir -Force | Out-Null

        $interval = [math]::Max(100, [int](1000 / $FPS))
        $totalFrames = $Duration * $FPS

        for ($i = 0; $i -lt $totalFrames; $i++) {
            $bitmap = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bitmap.Size)
            $framePath = Join-Path $frameDir "frame_$($i.ToString('D4')).png"
            $bitmap.Save($framePath, [System.Drawing.Imaging.ImageFormat]::Png)
            $graphics.Dispose(); $bitmap.Dispose()
            $frames += $framePath
            Start-Sleep -Milliseconds $interval
        }

        Write-Output "[CAPTURE] Recorded $($frames.Count) frames to: $frameDir"
        Write-Output "Use frames for video assembly or visual analysis."
    }

    default { Write-Output "Use: FULL, WINDOW, REGION, LIST_MONITORS, RECORD" }
}
