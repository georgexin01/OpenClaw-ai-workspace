$EnginePath = 'c:\Users\User\OneDrive\Desktop\workspace\.openclaw\OpenClaw_Engine.ps1'
$msg = 'Hello'

$psJob = [powershell]::Create()
[void]$psJob.AddScript({ param($m, $p); . $p; Invoke-OClawQuery $m 1 }).AddArgument($msg).AddArgument($EnginePath)
$asyncRes = $psJob.BeginInvoke()

while (-not $asyncRes.IsCompleted) { 
    Start-Sleep -Milliseconds 100 
}

$res = $psJob.EndInvoke($asyncRes)
if ($psJob.HadErrors) {
    Write-Host "ERRORS OCCURRED:"
    $psJob.Streams.Error | ForEach-Object { Write-Host $_.ToString() }
}
$psJob.Dispose()

Write-Host "RESULT:"
Write-Host $res
