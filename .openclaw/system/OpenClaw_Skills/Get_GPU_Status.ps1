function Get-OClawGPUStatus {
    try {
        # Check if nvidia-smi exists
        if (-not (Get-Command "nvidia-smi" -ErrorAction SilentlyContinue)) {
            return $null
        }

        # Query first GPU (Index 0)
        $stats = nvidia-smi --query-gpu=name,memory.total,memory.used,utilization.gpu --format=csv,noheader,nounits,index=0
        if (-not $stats) { return $null }
        
        $parts = $stats[0].Split(',')
        if ($parts.Count -lt 4) { return $null }

        $totalVal = [int]$parts[1].Trim()
        $usedVal = [int]$parts[2].Trim()
        $utilVal = [int]$parts[3].Trim()

        return [PSCustomObject]@{
            Name        = $parts[0].Trim()
            TotalVRAM   = $totalVal
            UsedVRAM    = $usedVal
            Utilization = $utilVal
            UsedPercent = [math]::Round(($usedVal / $totalVal) * 100, 1)
            Timestamp   = Get-Date -Format "HH:mm:ss"
        }
    } catch {
        return $null
    }
}

$status = Get-OClawGPUStatus
if ($null -ne $status) {
    Write-Output ($status | ConvertTo-Json -Compress)
} else {
    Write-Output '{"Utilization": 0, "UsedPercent": 0, "Error": "NVIDIA_NOT_FOUND"}'
}
