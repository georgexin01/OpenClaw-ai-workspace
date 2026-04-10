# OPENCLAW SKILL: DAEMON HEALTH [V1.0]
# =======================================
# [PURPOSE]: Comprehensive system health check

param(
    [switch]$AlertOnly,
    [switch]$AsJson
)

$SystemRoot = Join-Path $PSScriptRoot ".."
$SkillsDir = $PSScriptRoot
$OllamaUrl = "http://localhost:11434"

$alerts = @()

# 1. Ollama
$ollamaStatus = "offline"
$modelCount = 0
try {
    $tags = Invoke-RestMethod -Uri "$OllamaUrl/api/tags" -TimeoutSec 3
    $ollamaStatus = "online"
    $modelCount = $tags.models.Count
} catch { $alerts += "Ollama is offline" }

# 2. GPU
$gpuUtil = 0; $vramPct = 0; $gpuName = "N/A"
$gpuScript = Join-Path $SkillsDir "Get_GPU_Status.ps1"
if (Test-Path $gpuScript) {
    $raw = & powershell -ExecutionPolicy Bypass -File $gpuScript 2>$null
    if ($raw) {
        try {
            $gpu = $raw | ConvertFrom-Json
            $gpuUtil = $gpu.Utilization
            $vramPct = $gpu.UsedPercent
            $gpuName = $gpu.Name
            if ([double]$vramPct -gt 90) { $alerts += "VRAM usage critical: ${vramPct}%" }
        } catch {}
    }
}

# 3. Disk
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
$diskFreeGB = if ($disk) { [math]::Round($disk.FreeSpace / 1GB, 1) } else { 0 }
if ($diskFreeGB -lt 5) { $alerts += "Disk space low: ${diskFreeGB}GB free" }

# 4. RAM
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$ramUsedPct = if ($os) { [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1) } else { 0 }
$ramTotalGB = if ($os) { [math]::Round($os.TotalVisibleMemorySize / 1MB, 1) } else { 0 }
if ($ramUsedPct -gt 90) { $alerts += "RAM usage critical: ${ramUsedPct}%" }

# 5. Skills integrity
$skills = @("Architect_Review","Bespoke_UI","Browser_Control","Browser_Vision","Daemon_Health","Daemon_Service","File_Crawler","Get_GPU_Status","MCP_Bridge","Memory_Graph","Security_Scan","Sovereign_GitSync","Start_SearXNG","Vision_Solver","Visual_Pulse","Voice_Sovereign","YT_AutoLearn")
$missing = $skills | Where-Object { -not (Test-Path (Join-Path $SkillsDir "$_.ps1")) }
$skillsIntact = $missing.Count -eq 0
if (-not $skillsIntact) { $alerts += "Missing skills: $($missing -join ', ')" }

# 6. Chrome CDP
$browserActive = $false
try { Invoke-RestMethod -Uri "http://localhost:9222/json/version" -TimeoutSec 2 | Out-Null; $browserActive = $true } catch {}

# 7. Uptime
$uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptimeStr = "$([int]$uptime.TotalDays)d $($uptime.Hours)h $($uptime.Minutes)m"

$health = @{
    timestamp    = (Get-Date -Format "o")
    ollama       = $ollamaStatus
    models       = $modelCount
    gpu_name     = $gpuName
    gpu_util     = $gpuUtil
    vram_pct     = $vramPct
    disk_free_gb = $diskFreeGB
    ram_used_pct = $ramUsedPct
    ram_total_gb = $ramTotalGB
    skills_total = $skills.Count
    skills_ok    = $skillsIntact
    browser_cdp  = $browserActive
    uptime       = $uptimeStr
    alerts       = $alerts
    status       = if ($alerts.Count -eq 0) { "HEALTHY" } else { "DEGRADED" }
}

if ($AsJson) {
    Write-Output ($health | ConvertTo-Json -Compress)
} elseif ($AlertOnly -and $alerts.Count -eq 0) {
    # Quiet mode, no output if healthy
} else {
    $statusColor = if ($alerts.Count -eq 0) { "Green" } else { "Yellow" }
    Write-Host "[HEALTH] OpenClaw System Status: $($health.status)" -ForegroundColor $statusColor

    $output = @"
[OPENCLAW HEALTH REPORT]
Status: $($health.status)
Uptime: $uptimeStr

BRAIN:
  Ollama: $ollamaStatus ($modelCount models)
  GPU: $gpuName | Util: ${gpuUtil}% | VRAM: ${vramPct}%

SYSTEM:
  RAM: ${ramUsedPct}% of ${ramTotalGB}GB
  Disk C: ${diskFreeGB}GB free
  Skills: $($skills.Count - $missing.Count)/$($skills.Count) OK
  Browser CDP: $(if ($browserActive) { 'Active' } else { 'Inactive' })
"@
    if ($alerts.Count -gt 0) {
        $output += "`n`nALERTS:`n$($alerts | ForEach-Object { "  [!] $_" } | Out-String)"
    }
    Write-Output $output
}
