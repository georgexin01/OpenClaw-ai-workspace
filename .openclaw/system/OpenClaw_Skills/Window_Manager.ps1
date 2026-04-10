# OPENCLAW SKILL: WINDOW MANAGER [V1.0]
# [PURPOSE]: List, focus, resize, minimize, screenshot Windows apps

param(
    [string]$Action = "LIST",   # LIST, FOCUS, MINIMIZE, MAXIMIZE, CLOSE, SCREENSHOT
    [string]$Title = "",        # Window title pattern
    [int]$ProcessId = 0
)

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class WinAPI {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    public struct RECT { public int Left, Top, Right, Bottom; }
}
"@

function Get-VisibleWindows {
    Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowHandle -ne [IntPtr]::Zero } |
        Select-Object Id, ProcessName, MainWindowTitle, MainWindowHandle
}

switch ($Action.ToUpper()) {
    "LIST" {
        $windows = Get-VisibleWindows
        if ($Title) { $windows = $windows | Where-Object { $_.MainWindowTitle -match $Title } }
        if ($windows.Count -eq 0) { Write-Output "[WINDOWS] No visible windows found."; break }
        $output = "[VISIBLE WINDOWS] $($windows.Count) found:`n"
        foreach ($w in $windows) {
            $output += "  [PID $($w.Id)] $($w.ProcessName) — `"$($w.MainWindowTitle)`"`n"
        }
        Write-Output $output
    }
    "FOCUS" {
        $target = Get-VisibleWindows | Where-Object { $_.MainWindowTitle -match $Title -or $_.Id -eq $ProcessId } | Select-Object -First 1
        if ($target) {
            [WinAPI]::ShowWindow($target.MainWindowHandle, 9) | Out-Null  # SW_RESTORE
            [WinAPI]::SetForegroundWindow($target.MainWindowHandle) | Out-Null
            Write-Output "[WINDOW] Focused: $($target.MainWindowTitle)"
        } else { Write-Output "[WINDOW] Not found." }
    }
    "MINIMIZE" {
        $target = Get-VisibleWindows | Where-Object { $_.MainWindowTitle -match $Title -or $_.Id -eq $ProcessId } | Select-Object -First 1
        if ($target) {
            [WinAPI]::ShowWindow($target.MainWindowHandle, 6) | Out-Null  # SW_MINIMIZE
            Write-Output "[WINDOW] Minimized: $($target.MainWindowTitle)"
        } else { Write-Output "[WINDOW] Not found." }
    }
    "MAXIMIZE" {
        $target = Get-VisibleWindows | Where-Object { $_.MainWindowTitle -match $Title -or $_.Id -eq $ProcessId } | Select-Object -First 1
        if ($target) {
            [WinAPI]::ShowWindow($target.MainWindowHandle, 3) | Out-Null  # SW_MAXIMIZE
            Write-Output "[WINDOW] Maximized: $($target.MainWindowTitle)"
        } else { Write-Output "[WINDOW] Not found." }
    }
    "CLOSE" {
        $target = Get-Process | Where-Object { $_.MainWindowTitle -match $Title -or $_.Id -eq $ProcessId } | Select-Object -First 1
        if ($target) {
            $target.CloseMainWindow() | Out-Null
            Write-Output "[WINDOW] Close signal sent: $($target.MainWindowTitle)"
        } else { Write-Output "[WINDOW] Not found." }
    }
    "SCREENSHOT" {
        $target = Get-VisibleWindows | Where-Object { $_.MainWindowTitle -match $Title -or $_.Id -eq $ProcessId } | Select-Object -First 1
        if (-not $target) { Write-Output "[WINDOW] Not found."; break }

        # Focus window first
        [WinAPI]::ShowWindow($target.MainWindowHandle, 9) | Out-Null
        [WinAPI]::SetForegroundWindow($target.MainWindowHandle) | Out-Null
        Start-Sleep -Milliseconds 300

        $rect = New-Object WinAPI+RECT
        [WinAPI]::GetWindowRect($target.MainWindowHandle, [ref]$rect) | Out-Null
        $w = $rect.Right - $rect.Left; $h = $rect.Bottom - $rect.Top

        Add-Type -AssemblyName System.Drawing
        $bitmap = New-Object System.Drawing.Bitmap($w, $h)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, (New-Object System.Drawing.Size($w, $h)))

        $outDir = Join-Path $PSScriptRoot "..\skills_bridge\visual_vault"
        if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
        $outPath = Join-Path $outDir "window_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
        $bitmap.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose(); $bitmap.Dispose()
        Write-Output "[WINDOW] Screenshot saved: $outPath"
    }
    default { Write-Output "Use: LIST, FOCUS, MINIMIZE, MAXIMIZE, CLOSE, SCREENSHOT" }
}
