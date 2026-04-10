# OPENCLAW SKILL: CLIPBOARD BRIDGE [V1.0]
# [PURPOSE]: Monitor and analyze clipboard content

param([string]$Action = "READ")  # READ, WATCH, ANALYZE

Add-Type -AssemblyName System.Windows.Forms

switch ($Action.ToUpper()) {
    "READ" {
        $text = [System.Windows.Forms.Clipboard]::GetText()
        if ($text) {
            $preview = $text.Substring(0, [Math]::Min(500, $text.Length))
            Write-Output "[CLIPBOARD] Content ($($text.Length) chars):`n---`n$preview$(if ($text.Length -gt 500) { '`n[TRUNCATED]' })"
        } else {
            $hasImage = [System.Windows.Forms.Clipboard]::ContainsImage()
            $hasFiles = [System.Windows.Forms.Clipboard]::ContainsFileDropList()
            if ($hasImage) { Write-Output "[CLIPBOARD] Contains an image (no text)." }
            elseif ($hasFiles) {
                $files = [System.Windows.Forms.Clipboard]::GetFileDropList()
                Write-Output "[CLIPBOARD] Contains $($files.Count) file(s):`n$($files | ForEach-Object { "  - $_" } | Out-String)"
            }
            else { Write-Output "[CLIPBOARD] Empty." }
        }
    }
    "ANALYZE" {
        $text = [System.Windows.Forms.Clipboard]::GetText()
        if (-not $text) { Write-Output "[CLIPBOARD] No text to analyze."; break }
        $enginePath = Join-Path $PSScriptRoot "..\..\OpenClaw_Engine.ps1"
        . $enginePath
        $prompt = "Analyze this clipboard content and provide a brief summary. What is it? What can be done with it?`n---`n$($text.Substring(0, [Math]::Min(1000, $text.Length)))"
        $result = Invoke-OClawQuery $prompt 1
        Write-Output "[CLIPBOARD ANALYSIS]`n$result"
    }
    default { Write-Output "Use: READ, ANALYZE" }
}
