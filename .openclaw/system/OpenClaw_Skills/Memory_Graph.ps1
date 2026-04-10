# OPENCLAW SKILL: MEMORY GRAPH [V1.1]
# [OBJECTIVE]: Extract semantic DNA from chat history and lexicon with fail-safe parsing.

$LogPath = Join-Path $PSScriptRoot "../skills_bridge/chat_log.jsonl"
$LexPath = Join-Path $PSScriptRoot "../skills_bridge/user_lexicon.md"
$GraphPath = Join-Path $PSScriptRoot "../skills_bridge/memory_graph.json"

Write-Host "[MEMORY] Synthesizing Project DNA Graph..." -ForegroundColor Magenta

$History = if (Test-Path $LogPath) { Get-Content $LogPath } else { @() }
$Lexicon = if (Test-Path $LexPath) { Get-Content $LexPath -Raw } else { "" }

$Entities = @{
    "DESIGN_DNA" = @()
    "CORE_LOGIC" = @()
    "USER_PREF"  = @()
}

# Scan Lexicon for P0 Mandates
if ($Lexicon -match "\[MANDATE\]: (.*)") {
    $Entities.CORE_LOGIC += $Matches[1].Split(",").Trim()
}

# Scan History with Resilience
$History | ForEach-Object {
    if (-not [string]::IsNullOrWhiteSpace($_)) {
        try {
            $obj = $_ | ConvertFrom-Json -ErrorAction Stop
            if ($obj.assistant -match "Zeta|Cinematic|Liquid Glass") { $Entities.DESIGN_DNA += "Zeta Cinematic Aesthetics" }
            if ($obj.user -match "Gemma4|Gemma-4") { $Entities.CORE_LOGIC += "Gemma-4 Deep Integration" }
        } catch {
            # Skip malformed lines
        }
    }
}

$Entities.DESIGN_DNA = $Entities.DESIGN_DNA | Select-Object -Unique
$Entities.CORE_LOGIC = $Entities.CORE_LOGIC | Select-Object -Unique

$Graph = @{
    Version    = "1.1"
    LastUpdate = (Get-Date -Format "o")
    Graph      = $Entities
}

$Graph | ConvertTo-Json | Set-Content -Path $GraphPath -Force

Write-Host "[SUCCESS] Memory Graph evolved. Project DNA identified." -ForegroundColor Green
