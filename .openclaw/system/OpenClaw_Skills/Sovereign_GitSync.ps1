# OpenClaw Skill: Sovereign Git-Sync Bridge
# -----------------------------------------------------
# [AESTHETIC]: Deep Navy / Cyber-Commit
# [PURPOSE]: Automated Intelligence Persistence

param (
    [string]$Reason = "Sovereign Intelligence Evolution",
    [bool]$Push = $false
)

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $RepoRoot

Write-Host "[SOVEREIGN] Recording Neural Evolution to Repository..." -ForegroundColor Cyan

# Stage all changes (excluding ignored files)
git add .

# Check if there are changes to commit
$status = git status --porcelain
if (-not $status) {
    Write-Host "[*] No evolution detected. Sync redundant." -ForegroundColor Gray
    exit 0
}

# Create timestamped AI-flavored commit
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$CommitMsg = "Sovereign Update [$Timestamp]: $Reason"

git commit -m $CommitMsg
Write-Host "[+] SUCCESS: Evolution recorded. Hash: $(git rev-parse --short HEAD)" -ForegroundColor Green

if ($Push) {
    Write-Host "[>] Pushing evolution to remote origin..." -ForegroundColor Yellow
    git push origin main
    if ($LastExitCode -eq 0) {
        Write-Host "[+] SUCCESS: Intelligence synchronized with Cloud Origin." -ForegroundColor Cyan
    } else {
        Write-Host "[X] BLOCKER: Remote push failed. Check network/credentials." -ForegroundColor Red
    }
}
