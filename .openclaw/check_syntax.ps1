$errs = $null
$tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile('c:\Users\User\OneDrive\Desktop\workspace\.openclaw\OpenClaw_Engine.ps1', [ref]$tokens, [ref]$errs)
if ($errs) {
    foreach ($e in $errs) {
        Write-Output "$($e.Extent.StartLineNumber): $($e.Message)"
    }
} else {
    Write-Output "No syntax errors"
}
