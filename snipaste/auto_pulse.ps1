# Autonomous Pulse Protocol (ALV - Snipaste CLI)
# This script performs a silent background screen capture.
# It bridges Gemini 3 Pro -> Local Vision without interrupting the user.

param (
    [string]$OutputPath = "c:\Users\User\OneDrive\Desktop\workspace\snipaste\active_mission.png"
)

# Snipaste Executable Path (Windows Store App)
$SnipastePath = "C:\Program Files\WindowsApps\45479liulios.17062D84F7C46_2.11.300.0_x64__p7pnf6hceqser\Snipaste.exe"

Write-Host "Initiating Autonomous Pulse (ALV)..."

# Trigger Full Screen Snip and Save to OutputPath
# -o specifies the output file
& $SnipastePath snip --full -o $OutputPath

# Wait for file lock to release
Start-Sleep -Milliseconds 500

if (Test-Path $OutputPath) {
    Write-Host "PULSE SUCCESS: $OutputPath updated." -ForegroundColor Green
} else {
    Write-Error "PULSE FAILED: Image not found."
}
