# ==============================================================================
# OPENCLAW SOVEREIGN ENGINE - [VERSION V3.1] - [PRECISION_CORE]
# ==============================================================================
# [IDENTITY]: OPENCLAW_ENGINE_V3.1
# [MANDATE]: Concise / Conversation-Aware / Browser + File + Daemon Capable
# ------------------------------------------------------------------------------

$script:OClawRoot = $PSScriptRoot
$script:WkDir = Resolve-Path (Join-Path $PSScriptRoot "..")
$script:LocalKnowledge = Join-Path $PSScriptRoot "system"
$script:LogFile = Join-Path $script:LocalKnowledge "diagnostic.log"
$script:ChatHistoryFile = Join-Path $PSScriptRoot "system\skills_bridge\chat_log.jsonl"
$script:OllamaUrl = "http://localhost:11434"

# --- LOGGING ---
function Write-OClawLog([string]$LogEvent, [string]$Details = "") {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $script:LogFile -Value "[$ts] [$LogEvent] $Details" -ErrorAction SilentlyContinue
}

# --- 1. MODEL DETECTION & TIERING ---
function Get-OClawModels {
    try {
        $tags = Invoke-RestMethod -Uri "$script:OllamaUrl/api/tags" -TimeoutSec 3
        return $tags.models | ForEach-Object { $_.name }
    } catch { return @() }
}

function Get-OClawIdentity([int]$Tier = 0) {
    $Available = Get-OClawModels
    $Fast = if ($Available -contains "gemma4:e2b") { "gemma4:e2b" } elseif ($Available.Count -gt 0) { $Available[0] } else { "gemma4:e2b" }
    $Heavy = if ($Available -contains "gemma4:e4b") { "gemma4:e4b" } else { $Fast }

    switch ($Tier) {
        0 {
            $RAM = [math]::Round((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1MB, 0)
            return if ($RAM -ge 16) { $Heavy } else { $Fast }
        }
        1 { return $Fast }
        2 { return $Heavy }
        default { return $Fast }
    }
}

function Test-OClawConnection {
    try { Invoke-RestMethod -Uri "$script:OllamaUrl/api/tags" -TimeoutSec 2 | Out-Null; return $true } catch { return $false }
}

# --- 2. PRIVACY & CONTEXT ---
function Protect-OClawPrivacy([string]$Payload) {
    return $Payload -replace 'c:\\Users\\[^\\]+\\Desktop', 'C:\WORKSPACE' -replace '[a-fA-F0-9]{32,}', '[REDACTED]'
}

function Get-OClawContext {
    $LexPath = Join-Path $script:LocalKnowledge "skills_bridge\user_lexicon.md"
    $Lexicon = if (Test-Path $LexPath) { Get-Content $LexPath -Raw -ErrorAction SilentlyContinue } else { "" }

    $Directive = @"
[IDENTITY]: OpenClaw V3.1 Sovereign Intelligence.
[RULES]:
- Answer directly. No filler words ("Sure", "I understand", "Of course").
- Be concise, accurate, and helpful.
- For code: provide working code only, no explanations unless asked.
- For questions: give the direct answer first, then brief context if needed.
[CAPABILITIES]: Local GPU inference, browser control (Chrome CDP), file crawling, web search, visual analysis, OCR, code sandbox, window management, git sync, architecture review, 24/7 daemon mode, prompt chains, RAG search.
"@

    if ($Lexicon.Length -gt 500) { $Lexicon = $Lexicon.Substring(0, 500) }
    return "$Directive`n`nCONTEXT:`n$Lexicon"
}

# --- 3. CONVERSATION HISTORY ---
function Get-OClawHistory([int]$MaxTurns = 5) {
    if (-not (Test-Path $script:ChatHistoryFile)) { return "" }
    $Lines = Get-Content $script:ChatHistoryFile -Tail ($MaxTurns * 2) -ErrorAction SilentlyContinue
    $History = ""
    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $obj = $line | ConvertFrom-Json -ErrorAction Stop
            if ($obj.user) { $History += "USER: $($obj.user)`n" }
            if ($obj.assistant) { $History += "ASSISTANT: $($obj.assistant)`n" }
        } catch {}
    }
    return $History
}

function Save-OClawTurn([string]$UserMsg, [string]$AssistantMsg) {
    $dir = Split-Path $script:ChatHistoryFile -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $entry = @{ user = $UserMsg; assistant = $AssistantMsg; timestamp = (Get-Date -Format "o") } | ConvertTo-Json -Compress
    Add-Content -Path $script:ChatHistoryFile -Value $entry -ErrorAction SilentlyContinue
}

# --- 4. PRECISION INFERENCE ---
function Invoke-OClawQuery([string]$UserMessage, [int]$Tier = 0) {
    $Model = Get-OClawIdentity $Tier
    $Context = Get-OClawContext
    $History = Get-OClawHistory 5

    $FullPrompt = "$Context`n`n"
    if ($History) { $FullPrompt += "RECENT CONVERSATION:`n$History`n" }
    $FullPrompt += "USER: $UserMessage`nASSISTANT (OpenClaw):"

    $Prompt = Protect-OClawPrivacy $FullPrompt

    $Body = @{
        model = $Model
        prompt = $Prompt
        stream = $false
        options = @{
            stop = @("USER:", "ASSISTANT:", "<THOUGHTS>")
            num_ctx = 4096
        }
    } | ConvertTo-Json -Compress

    Write-OClawLog "QUERY" "Model=$Model Tier=$Tier Msg=$($UserMessage.Substring(0, [Math]::Min(80, $UserMessage.Length)))"

    $Response = try {
        Invoke-RestMethod -Uri "$script:OllamaUrl/api/generate" -Method Post -Body $Body -ContentType "application/json" -TimeoutSec 180
    } catch {
        Write-OClawLog "INF_FAIL" $_.Exception.Message
        $null
    }

    if (-not $Response) { return "[ENGINE OFFLINE] Cannot reach Ollama at $script:OllamaUrl. Please ensure Ollama is running." }

    $RawRes = $Response.response

    # Clean system artifacts from response
    $CleanRes = $RawRes -replace '(?s)<ACTION>.*?</ACTION>', '' `
                        -replace '(?s)<THOUGHTS>.*?</THOUGHTS>', '' `
                        -replace '^\s*(OK\.|Sure\.|Certainly\.)\s*', ''

    # Dispatch any embedded actions
    $ActionMatches = [regex]::Matches($RawRes, "<ACTION>(.*?)<\/ACTION>")
    foreach ($Match in $ActionMatches) {
        try {
            $actionObj = $Match.Groups[1].Value.Trim() | ConvertFrom-Json
            if ($actionObj.MissionKey) { Invoke-OClawMission $actionObj.MissionKey $actionObj.Params }
        } catch { Write-OClawLog "DISPATCH_ERROR" $Match.Groups[1].Value }
    }

    $Result = $CleanRes.Trim()

    # Save conversation turn
    Save-OClawTurn $UserMessage $Result

    # Log performance
    if ($Response.eval_count -and $Response.eval_duration) {
        $tps = [math]::Round($Response.eval_count / ($Response.eval_duration / 1e9), 1)
        Write-OClawLog "PERF" "Tokens=$($Response.eval_count) Speed=${tps}t/s Model=$Model"
    }

    return $Result
}

# --- 5. TACTICAL MISSION DISPATCHER ---
function Invoke-OClawMission([string]$MissionKey, $Params) {
    Write-OClawLog "MISSION" $MissionKey
    switch ($MissionKey) {
        "READ_FILE" {
            if ($Params.Path -and (Test-Path $Params.Path)) { return Get-Content $Params.Path -Raw }
            return "FILE_NOT_FOUND"
        }
        "WRITE_FILE" {
            if ($Params.Path -and $Params.Content) {
                $dir = Split-Path $Params.Path -Parent
                if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                Set-Content -Path $Params.Path -Value $Params.Content -Force
                return "SUCCESS"
            }
            return "MISSING_PARAMS"
        }
        "VISUAL_PULSE" { return Invoke-OClawSkill "Visual_Pulse" }
        "SPEAK" { return Invoke-OClawSkill "Voice_Sovereign" "-Action Speak -Text `"$($Params.Text)`"" }
        "GIT_SYNC" { return Invoke-OClawSkill "Sovereign_GitSync" }
        "SECURITY_SCAN" { return Invoke-OClawSkill "Security_Scan" }
        "ARCHITECT_REVIEW" { return Invoke-OClawSkill "Architect_Review" }
        "GPU_STATUS" { return Invoke-OClawSkill "Get_GPU_Status" }
        "MEMORY_GRAPH" { return Invoke-OClawSkill "Memory_Graph" }
        "WEB_SEARCH" {
            if ($Params.Query) {
                try {
                    $r = Invoke-RestMethod -Uri "http://localhost:8888/search?q=$([uri]::EscapeDataString($Params.Query))&format=json" -TimeoutSec 10
                    return ($r.results | Select-Object -First 3 | ForEach-Object { "- $($_.title): $($_.url)`n  $($_.content)" }) -join "`n"
                } catch { return "SearXNG not available." }
            }
            return "NO_QUERY"
        }
        "BROWSER_START" { return Invoke-OClawSkill "Browser_Control" "-Action START -Url `"$($Params.Url)`"" }
        "BROWSER_NAVIGATE" { return Invoke-OClawSkill "Browser_Control" "-Action NAVIGATE -Url `"$($Params.Url)`"" }
        "BROWSER_SCREENSHOT" { return Invoke-OClawSkill "Browser_Control" "-Action SCREENSHOT" }
        "BROWSER_CLICK" { return Invoke-OClawSkill "Browser_Control" "-Action CLICK -X $($Params.X) -Y $($Params.Y)" }
        "BROWSER_TYPE" { return Invoke-OClawSkill "Browser_Control" "-Action TYPE -Text `"$($Params.Text)`"" }
        "BROWSER_JS" { return Invoke-OClawSkill "Browser_Control" "-Action JS -Code `"$($Params.Code)`"" }
        "BROWSER_FIND" { return Invoke-OClawSkill "Browser_Control" "-Action FIND -Text `"$($Params.Text)`"" }
        "BROWSER_VISION" { return Invoke-OClawSkill "Browser_Vision" $(if ($Params.Query) { "-Query `"$($Params.Query)`"" } else { "" }) }
        "FILE_CRAWL" { return Invoke-OClawSkill "File_Crawler" "-Action CRAWL -Path `"$($Params.Path)`"" }
        "FILE_SEARCH" { return Invoke-OClawSkill "File_Crawler" "-Action SEARCH -Query `"$($Params.Query)`"" }
        "FILE_READ" { return Invoke-OClawSkill "File_Crawler" "-Action READ -Path `"$($Params.Path)`"" }
        "DAEMON_STATUS" { return Invoke-OClawSkill "Daemon_Service" "-Action STATUS" }
        "DAEMON_INSTALL" { return Invoke-OClawSkill "Daemon_Service" "-Action INSTALL" }
        "HEALTH_CHECK" { return Invoke-OClawSkill "Daemon_Health" }
        "CODE_RUN" { return Invoke-OClawSkill "Code_Sandbox" "-Code `"$($Params.Code)`" -Language `"$($Params.Language)`"" }
        "OCR" { return Invoke-OClawSkill "OCR_Extract" "-CaptureScreen" }
        "WINDOW_LIST" { return Invoke-OClawSkill "Window_Manager" "-Action LIST" }
        "WINDOW_FOCUS" { return Invoke-OClawSkill "Window_Manager" "-Action FOCUS -Title `"$($Params.Title)`"" }
        "CLIPBOARD" { return Invoke-OClawSkill "Clipboard_Bridge" "-Action READ" }
        "RAG_QUERY" { return Invoke-OClawSkill "RAG_Index" "-Action QUERY -Query `"$($Params.Query)`"" }
        "CHAIN" { return Invoke-OClawSkill "Chain_Executor" "-Chain `"$($Params.Chain)`"" }
        "NOTIFY" { return Invoke-OClawSkill "Notify_Center" "-Title `"$($Params.Title)`" -Message `"$($Params.Message)`"" }
        "JOURNAL" { return Invoke-OClawSkill "Activity_Journal" "-Action TODAY" }
        "WEBUI_STATUS" { return Invoke-OClawSkill "OpenWebUI_Bridge" "-Action STATUS" }
        "WEBUI_INSTALL" { return Invoke-OClawSkill "OpenWebUI_Bridge" "-Action INSTALL" }
        "WEBUI_OPEN" { return Invoke-OClawSkill "OpenWebUI_Bridge" "-Action OPEN" }
        "GATEWAY_STATUS" { return Invoke-OClawSkill "Gateway_Client" "-Action STATUS" }
        "GATEWAY_CONNECT" { return Invoke-OClawSkill "Gateway_Client" "-Action CONNECT -GatewayUrl `"$($Params.Url)`" -Token `"$($Params.Token)`"" }
        "GATEWAY_SEND" { return Invoke-OClawSkill "Gateway_Client" "-Action SEND -Message `"$($Params.Message)`"" }
        "CANVAS_CARD" { return Invoke-OClawSkill "Canvas_Renderer" "-Action CARD -Title `"$($Params.Title)`" -Content `"$($Params.Content)`" -Type `"$($Params.Type)`"" }
        "CANVAS_TABLE" { return Invoke-OClawSkill "Canvas_Renderer" "-Action TABLE -Title `"$($Params.Title)`" -Data `"$($Params.Data)`"" }
        "SCREEN_FULL" { return Invoke-OClawSkill "Screen_Capture_Pro" "-Action FULL" }
        "SCREEN_WINDOW" { return Invoke-OClawSkill "Screen_Capture_Pro" "-Action WINDOW -Title `"$($Params.Title)`"" }
        "SCREEN_RECORD" { return Invoke-OClawSkill "Screen_Capture_Pro" "-Action RECORD -Duration $($Params.Duration)" }
        "PIPELINE_RUN" { return Invoke-OClawSkill "Pipeline_Router" "-Action RUN -Message `"$($Params.Message)`"" }
        "NOTE_CREATE" { return Invoke-OClawSkill "Notes_System" "-Action CREATE -Title `"$($Params.Title)`" -Content `"$($Params.Content)`"" }
        "NOTE_LIST" { return Invoke-OClawSkill "Notes_System" "-Action LIST" }
        "NOTE_ENHANCE" { return Invoke-OClawSkill "Notes_System" "-Action ENHANCE -Title `"$($Params.Title)`"" }
        "TERMINAL" { return Invoke-OClawSkill "Terminal_Exec" "-Action RUN -Command `"$($Params.Command)`"" }
        "MODEL_COMPARE" { return Invoke-OClawSkill "Multi_Model" "-Action COMPARE -Prompt `"$($Params.Prompt)`"" }
        "MODEL_BENCHMARK" { return Invoke-OClawSkill "Multi_Model" "-Action BENCHMARK" }
        "DEEPLINK_REGISTER" { return Invoke-OClawSkill "Deep_Link" "-Action REGISTER" }
        "ANALYTICS" { return Invoke-OClawSkill "Usage_Analytics" "-Action REPORT" }
        default {
            $SkillPath = Join-Path "$script:LocalKnowledge\OpenClaw_Skills" "$MissionKey.ps1"
            if (Test-Path $SkillPath) { return Invoke-OClawSkill $MissionKey }
            return "UNKNOWN_MISSION: $MissionKey"
        }
    }
}

function Invoke-OClawSkill([string]$SkillName, [string]$SkillArgs = "") {
    $SkillPath = Join-Path "$script:LocalKnowledge\OpenClaw_Skills" "$SkillName.ps1"
    if (-not (Test-Path $SkillPath)) {
        Write-OClawLog "SKILL_NOT_FOUND" $SkillName
        return "Skill '$SkillName' not found."
    }
    Write-OClawLog "SKILL_RUN" $SkillName
    try {
        if ($SkillArgs) {
            return Invoke-Expression "& powershell -ExecutionPolicy Bypass -File `"$SkillPath`" $SkillArgs"
        } else {
            return & powershell -ExecutionPolicy Bypass -File $SkillPath
        }
    } catch {
        Write-OClawLog "SKILL_ERROR" "$SkillName : $($_.Exception.Message)"
        return "Skill error: $($_.Exception.Message)"
    }
}

# --- 6. ENGINE INFO ---
function Get-OClawStatus {
    $online = Test-OClawConnection
    $models = if ($online) { (Get-OClawModels) -join ", " } else { "N/A" }
    $gpu = & powershell -ExecutionPolicy Bypass -File (Join-Path $script:LocalKnowledge "OpenClaw_Skills\Get_GPU_Status.ps1") 2>$null
    return @{
        Online = $online
        Models = $models
        ActiveModel = Get-OClawIdentity 1
        GPU = $gpu
        Version = "3.1"
    }
}

# CLI mode
if ($args.Count -gt 0) { Invoke-OClawQuery ($args -join " ") }
