$EnginePath = 'c:\Users\User\OneDrive\Desktop\workspace\.openclaw\OpenClaw_Engine.ps1'
$msg = 'Hello'

$psJob = [powershell]::Create()
[void]$psJob.AddScript(". '$EnginePath'; Invoke-OClawQuery '$msg' 1")
$asyncRes = $psJob.BeginInvoke()
while (-not $asyncRes.IsCompleted) { Start-Sleep -Milliseconds 100 }
$res = $psJob.EndInvoke($asyncRes)
if ($psJob.HadErrors) {
    Write-Host "ERRORS:"
    $psJob.Streams.Error | ForEach-Object { 
        Write-Host $_.ToString()
        Write-Host $_.InvocationInfo.PositionMessage
    }
} else { Write-Host "NO ERRORS" }
Write-Host "RESULT:"
Write-Host ($res -join "`n")
$psJob.Dispose()
