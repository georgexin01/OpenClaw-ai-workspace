# OPENCLAW SKILL: CODE SANDBOX [V1.0]
# [PURPOSE]: Execute code snippets safely in isolated environment

param(
    [string]$Code = "",
    [string]$Language = "powershell",
    [int]$TimeoutSec = 30
)

if (-not $Code) { Write-Output "[SANDBOX] Provide -Code parameter."; exit 1 }

$OutputDir = Join-Path $PSScriptRoot "..\skills_bridge\sandbox_output"
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
$ts = Get-Date -Format "yyyyMMdd_HHmmss"

switch ($Language.ToLower()) {
    "powershell" {
        $scriptFile = Join-Path $OutputDir "sandbox_$ts.ps1"
        Set-Content -Path $scriptFile -Value $Code -Force
        try {
            $job = Start-Job -ScriptBlock { param($f); & powershell -ExecutionPolicy Bypass -File $f 2>&1 } -ArgumentList $scriptFile
            $completed = $job | Wait-Job -Timeout $TimeoutSec
            if ($completed) {
                $output = $job | Receive-Job | Out-String
                Write-Output "[SANDBOX OUTPUT]`n---`n$($output.Trim())`n---`n[EXIT: $($job.State)]"
            } else {
                Stop-Job $job -Force
                Write-Output "[SANDBOX] Execution timed out after ${TimeoutSec}s."
            }
            Remove-Job $job -Force
        } finally {
            Remove-Item $scriptFile -Force -ErrorAction SilentlyContinue
        }
    }
    "python" {
        $scriptFile = Join-Path $OutputDir "sandbox_$ts.py"
        Set-Content -Path $scriptFile -Value $Code -Force
        try {
            $job = Start-Job -ScriptBlock { param($f); python $f 2>&1 } -ArgumentList $scriptFile
            $completed = $job | Wait-Job -Timeout $TimeoutSec
            if ($completed) {
                $output = $job | Receive-Job | Out-String
                Write-Output "[SANDBOX OUTPUT (Python)]`n---`n$($output.Trim())`n---"
            } else {
                Stop-Job $job -Force
                Write-Output "[SANDBOX] Python execution timed out."
            }
            Remove-Job $job -Force
        } finally {
            Remove-Item $scriptFile -Force -ErrorAction SilentlyContinue
        }
    }
    "javascript" {
        $scriptFile = Join-Path $OutputDir "sandbox_$ts.js"
        Set-Content -Path $scriptFile -Value $Code -Force
        try {
            $output = & node $scriptFile 2>&1 | Out-String
            Write-Output "[SANDBOX OUTPUT (Node.js)]`n---`n$($output.Trim())`n---"
        } finally {
            Remove-Item $scriptFile -Force -ErrorAction SilentlyContinue
        }
    }
    default { Write-Output "[SANDBOX] Supported languages: powershell, python, javascript" }
}
