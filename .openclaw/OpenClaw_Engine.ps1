# OPENCLAW ENGINE V33.0 [SOVEREIGN_CORE]
# -----------------------------------
# [IDENTITY]: OPENCLAW_ENGINE_33.0
# [MANDATE]: Persistent GPU Execution / Zero Cloud Token Usage

$WkDir = Resolve-Path (Join-Path $PSScriptRoot "..")
$SharedKnowledge = Join-Path $env:USERPROFILE ".gemini\antigravity\knowledge"
$LocalKnowledge = Join-Path $PSScriptRoot "system"

# 1. HARDWARE IDENTITY LOCK & TIERING
function Get-OClawIdentity([int]$Tier = 1) {
    # COG-TUNING: Hardware Awareness (SM-DNA)
    $script = Join-Path $PSScriptRoot "system/OpenClaw_Skills/Get_GPU_Status.ps1"
    $raw = & powershell -ExecutionPolicy Bypass -File $script
    $GpuStatus = if ($raw) { $raw | ConvertFrom-Json } else { $null }

    $HardwareID = (Get-CimInstance Win32_BaseBoard).SerialNumber
    $IsXIN = ($HardwareID -eq "07C9611_P51E971105")
    
    # Adaptive Threshold: If VRAM > 90% or GPU > 95%, force Tier 1 (Fast)
    if ($GpuStatus -and ($GpuStatus.UsedPercent -gt 90 -or $GpuStatus.Utilization -gt 95)) {
        Write-Host "[SOVEREIGN] CRITICAL LOAD: GPU at $($GpuStatus.UsedPercent)%. Force-Tiering To Gemma:2B." -ForegroundColor Coral
        return "gemma:2b"
    }

    if ($Tier -eq 1) { return "gemma:2b" } 
    if ($IsXIN) { return "my-gpu-gemma" } 
    return "gemma4:e2b"
}

$ActiveSkills = @() 

# 2. CONTEXT AGGREGATOR (Sovereign Intelligence Logic)
function Sync-OClawSkill([string]$TargetName) {
    $SearchDir = Join-Path $env:USERPROFILE ".gemini\antigravity"
    $Found = Get-ChildItem -Path $SearchDir -Recurse -Filter "*$TargetName*" | Where-Object { $_.Extension -eq ".md" } | Select-Object -First 1
    
    if ($Found) {
        $Content = Get-Content $Found.FullName -Raw
        $global:ActiveSkills += "--- SYNCED SKILL: $($Found.Name) ---`n$Content"
        return "### SUCCESS: [SKILL_SYNC] $TargetName absorbed into active memory."
    }
    return "### BLOCKER: [SKILL_SYNC] Target '$TargetName' not found in master vault."
}

function Get-OClawContext {
    $LocalCore = Get-ChildItem (Join-Path $LocalKnowledge "core_rules") -Filter *.md | ForEach-Object { Get-Content $_.FullName -Raw } | Out-String
    $MissionVault = Get-Content (Join-Path $LocalKnowledge "skills_bridge\mission_vault.md") -Raw
    $PromptDNA = Get-Content (Join-Path $LocalKnowledge "skills_bridge\prompt_dna_v2.md") -Raw
    $UserLexicon = Get-Content (Join-Path $LocalKnowledge "skills_bridge\user_lexicon.md") -Raw
    
    # Load last 5 history lines
    $LogPath = Join-Path $LocalKnowledge "skills_bridge\chat_log.jsonl"
    $History = if (Test-Path $LogPath) { (Get-Content $LogPath -Tail 5) -join "`n" } else { "" }
    
    $DeepSkills = $global:ActiveSkills -join "`n`n"
    
    $SovereignDirective = @"
    [SOVEREIGN MAP ACTIVE]:
    You are the 'VOID INTELLIGENCE'. Absolute compliance with 'sovereign_wisdom_v30.md' is mandatory.
    
    [SEMANTIC ANCESTRY]:
    You must adapt your vocabulary and mission strategy based on the USER_LEXICON and CHAT_HISTORY provided. 
    Learn jargon, shortcuts, and preferred logical flows.
    
    [COGNITIVE SOLVING FLOW]:
    1. <THOUGHTS>: Audit request + Check User Lexicon + Local Rules.
    2. <PLAN>: Outline tactical missions.
    3. <RESPONSE>: Final high-fidelity response [CARD].
    
    [AUTONOMOUS CAPABILITIES]:
    Tactical Actions: [READ_FILE, WRITE_FILE, WEB_SEARCH, UPDATE_LEXICON, RESOLVE_FAUCET].
    To execute a WEB_SEARCH, use: <ACTION>{"MissionKey":"WEB_SEARCH", "Params":{"Query":"search terms"}}</ACTION>
    To execute other actions, use JSON block inside <ACTION> tag.
"@

    $RawContext = "IDENTITY: OpenClaw (Sovereign).`n`nUSER_LEXICON:`n$UserLexicon`n`nCHAT_HISTORY:`n$History`n`nTACTICAL_CORE:`n$LocalCore`n`nDYNAMIC_SKILLS:`n$DeepSkills`n`nMISSION_PROTOCOLS:`n$MissionVault`n`nPROMPT_DNA:`n$PromptDNA`n`n$SovereignDirective"
    $Sanitized = $RawContext -replace '[^\x20-\x7E\n\r]', '' 
    return $Sanitized
}

# 3. THE CARD SHIELD (Formatting Guarantee)
function Format-OClawCard([string]$RawText) {
    $CleanText = $RawText -replace "\(Gemma-2B:Fast\) ", ""
    
    # Emoji Intelligence Injection
    $Result = $CleanText -replace "### SUCCESS", "### [+] SUCCESS" `
                         -replace "### BLOCKER", "### [X] BLOCKER" `
                         -replace "### INSIGHT", "### [*] INSIGHT" `
                         -replace "### MISSION", "### [>] MISSION"
                         
    return $Result
}

# 4. BRAIN HANDSHAKE (Ollama API - Tiered Protocol)
function Invoke-OClawQuery([string]$UserMessage, [int]$Tier = 1) {

    # YT AUTO-LEARNING INTERCEPT (Rule YT-LEARN-01 | P0 Mandate)
    if ($UserMessage -match "(https?://(www\.)?(youtube\.com|youtu\.be)/\S+)") {
        $YtUrl = $Matches[1]
        $SkillPath = Join-Path $LocalKnowledge "OpenClaw_Skills\YT_AutoLearn.ps1"
        Write-Host "[OPENCLAW] [YT] YouTube URL detected. Initiating Auto-Learning..." -ForegroundColor Cyan
        $YtResult = & powershell -ExecutionPolicy Bypass -File $SkillPath -Url $YtUrl -UserNote $UserMessage
        # Continue conversation with the result appended as context
        $UserMessage = "$UserMessage`n`n[YT_AUTOLEARN_RESULT]:`n$YtResult"
    }

    $Model = Get-OClawIdentity $Tier
    $Context = Get-OClawContext
    $Prompt = "$Context`n`nUSER: $UserMessage`n`nASSISTANT (OpenClaw):"
    
    $Uri = "http://localhost:11434/api/generate"
    $Body = @{
        model = $Model
        prompt = $Prompt
        stream = $false
        options = @{ num_ctx = 2048; num_gpu = 1 }
    } | ConvertTo-Json -Compress
    
    $Timeout = if ($Tier -eq 1) { 30 } else { 120 }
    $Response = Invoke-RestMethod -Uri $Uri -Method Post -Body $Body -ContentType "application/json" -TimeoutSec $Timeout -ErrorAction SilentlyContinue -ErrorVariable err
    if ($err) {
        return "[ERROR] Handshake failed. Details: $($err[0].Exception.Message)"
    }
    
    # TELEMETRY SYNC: Capture GPU state post-inference
    $script = Join-Path $PSScriptRoot "system/OpenClaw_Skills/Get_GPU_Status.ps1"
    $raw = & powershell -ExecutionPolicy Bypass -File $script
    $GpuRes = if ($raw) { $raw | ConvertFrom-Json } else { $null }
    $Telemetry = if ($GpuRes) { "[GPU: $($GpuRes.Utilization)% | VRAM: $($GpuRes.UsedPercent)%] " } else { "" }

    $Badge = if ($Model -eq "gemma:2b") { "($($Telemetry)Gemma-2B:Fast)" } else { "($($Telemetry)Gemma-4:Heavy)" }
    
    # Cognitive Filter: Strip internal monologue
    $RawRes = $Response.response
    $CleanRes = $RawRes -replace '(?s)<THOUGHTS>.*?</THOUGHTS>', '' -replace '(?s)<PLAN>.*?</PLAN>', ''
    
    # Autonomous Action Dispatcher
    if ($CleanRes -match '(?s)<ACTION>(.*?)</ACTION>') {
        $jsonStr = $matches[1]
        try {
            $actionObj = $jsonStr | ConvertFrom-Json
            $actionRes = Invoke-OClawMission $actionObj.MissionKey $actionObj.Params
            $CleanRes += "`n`n### [*] SYSTEM DISPATCH:`n$actionRes"
        } catch {
            $CleanRes += "`n`n### [X] SYSTEM DISPATCH ERROR:`nFailed to parse action JSON."
        }
        $CleanRes = $CleanRes -replace '(?s)<ACTION>.*?</ACTION>', ''
    }
    
    # Persistent Logging (V35.0)
    $LogEntry = @{ timestamp = (Get-Date -Format "o"); user = $UserMessage; assistant = $CleanRes.Trim() } | ConvertTo-Json -Compress
    Add-Content -Path (Join-Path $LocalKnowledge "skills_bridge\chat_log.jsonl") -Value $LogEntry
    
    $FormattedResponse = Format-OClawCard $CleanRes.Trim()
    
    # SOVEREIGN SYNC: Auto-Commit changes if mission resulted in file/logic updates
    if ($CleanRes -match "SUCCESS" -or $CleanRes -match "MISSION") {
        $Reason = if ($CleanRes -match "\[(.*?)\]") { $matches[1] } else { "Mission Logic Evolution" }
        Invoke-OClawSkill "Sovereign_GitSync" "-Reason '$Reason'"
    }
    
    return "$Badge $FormattedResponse"
}

# 5. INTELLIGENCE DISPATCHER (Action Tiers)
function Invoke-OClawUpdateLexicon([string]$NewKnowledge) {
    $LexPath = Join-Path $LocalKnowledge "skills_bridge\user_lexicon.md"
    $Current = Get-Content $LexPath -Raw
    $Updated = "$Current`n`n### [MEMORY_UPDATE: $(Get-Date)]`n$NewKnowledge"
    Set-Content -Path $LexPath -Value $Updated -Force -ErrorAction SilentlyContinue -ErrorVariable err
    if ($err) {
        return "### BLOCKER: [SEMANTIC_LINK] Failed to evolve lexicon."
    }
    
    # Auto-Sync Lexicon Evolution
    Invoke-OClawSkill "Sovereign_GitSync" "-Reason 'Lexicon Expansion'"
    
    return "### SUCCESS: [SEMANTIC_LINK] Lexicon upgraded with new strategy context."
}

function Invoke-OClawFileRead([string]$Path) {
    if (Test-Path $Path) {
        return Get-Content $Path -Raw
    }
    return "### BLOCKER: [FILE_READ] File '$Path' not found."
}

function Invoke-OClawFileWrite([string]$Path, [string]$Content) {
    Set-Content -Path $Path -Value $Content -Force -ErrorAction SilentlyContinue -ErrorVariable err
    if ($err) {
        return "### BLOCKER: [FILE_WRITE] Failed to update '$Path'. Error: $($err[0].Exception.Message)"
    }
    return "### SUCCESS: [FILE_WRITE] '$Path' updated with new logic."
}

function Invoke-OClawWebSearch([string]$Query) {
    Write-Host "[OPENCLAW] [WEB] Initiating SearXNG search for: $Query" -ForegroundColor Cyan
    $Uri = "http://localhost:8888/search?q=$($Query -replace ' ', '+')&format=json"
    
    try {
        $Response = Invoke-RestMethod -Uri $Uri -Method Get -TimeoutSec 10
        if ($Response.results.Count -eq 0) {
            return "### BLOCKER: [WEB_RESEARCH] No results found for '$Query'."
        }
        
        $Results = $Response.results | Select-Object -First 3
        $Summary = ""
        foreach ($res in $Results) {
            $Summary += "Source: $($res.url)`nTitle: $($res.title)`nSnippet: $($res.content)`n`n"
        }
        
        return "### SUCCESS: [WEB_RESEARCH] Data retrieved from SearXNG:`n$Summary"
    } catch {
        return "### BLOCKER: [WEB_RESEARCH] SearXNG instance not responding at http://localhost:8888. Please run Start_SearXNG skill."
    }
}

# 6. SKILL DISPATCHER (Local Execution)
function Invoke-OClawSkill([string]$SkillName) {
    $SkillPath = Join-Path "$LocalKnowledge\OpenClaw_Skills" "$SkillName.ps1"
    if (Test-Path $SkillPath) {
        Write-Host "[OPENCLAW] Executing Skill: $SkillName" -ForegroundColor Cyan
        & powershell -ExecutionPolicy Bypass -File $SkillPath
    } else {
        Write-Host "[ERROR] Skill '$SkillName' not found." -ForegroundColor Red
    }
}

# 7. TACTICAL MISSION DISPATCHER
function Invoke-OClawMission([string]$MissionKey, $Params) {
    switch ($MissionKey) {
        "CHECK_WHATSAPP" {
            $PulsePath = Join-Path $WkDir "snipaste\auto_pulse.ps1"
            & powershell -ExecutionPolicy Bypass -File $PulsePath
        }
        "READ_FILE" {
            return Invoke-OClawFileRead $Params.Path
        }
        "WRITE_FILE" {
            return Invoke-OClawFileWrite $Params.Path $Params.Content
        }
        "WEB_SEARCH" {
            return Invoke-OClawWebSearch $Params.Query
        }
        "UPDATE_LEXICON" {
            return Invoke-OClawUpdateLexicon $Params.Knowledge
        }
        "RESOLVE_FAUCET" {
            $FaucetPath = Join-Path $WkDir "faucet\scripts\ztv_v3_solver.ps1"
            $Result = & powershell -ExecutionPolicy Bypass -File $FaucetPath
            return "### MISSION: [FAUCET_PULSE] Analysis Complete.`n$Result"
        }
        default {
            Invoke-OClawSkill $MissionKey
        }
    }
}

if ($args.Count -gt 0) { Invoke-OClawQuery $args[0] }
