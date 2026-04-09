$EnginePath = 'c:\Users\User\OneDrive\Desktop\workspace\.openclaw\OpenClaw_Engine.ps1'
$psJob = [powershell]::Create()
[void]$psJob.AddScript(". '$EnginePath'")
$asyncRes = $psJob.BeginInvoke()
while (-not $asyncRes.IsCompleted) { Start-Sleep -Milliseconds 100 }
$res = $psJob.EndInvoke($asyncRes)
if ($psJob.HadErrors) {
    Write-Host "ERRORS:"
    $psJob.Streams.Error | ForEach-Object { Write-Host $_.ToString() }
} else { Write-Host "NO ERRORS" }
$psJob.Dispose()
