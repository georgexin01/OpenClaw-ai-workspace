# OpenClaw Skill: Get GPU Status
# -----------------------------------------------------
# [AESTHETIC]: Terminal-Green Monospaced
# [TECH]: nvidia-smi parser (VRAM / UTIL)

function Get-OClawGPUStatus {
    try {
        $stats = nvidia-smi --query-gpu=name,memory.total,memory.used,utilization.gpu --format=csv,noheader,nounits
        $parts = $stats.Split(',')
        return [PSCustomObject]@{
            Name = $parts[0].Trim()
            TotalVRAM = [int]$parts[1].Trim()
            UsedVRAM = [int]$parts[2].Trim()
            Utilization = [int]$parts[3].Trim()
            UsedPercent = [math]::Round(([int]$parts[2].Trim() / [int]$parts[1].Trim()) * 100, 1)
        }
    } catch {
        return $null
    }
}

$status = Get-OClawGPUStatus
if ($status) {
    # Output for GUI/Engine consumption
    return $status | ConvertTo-Json -Compress
} else {
    return "{}"
}
