# OPENCLAW SKILL: OPEN WEBUI BRIDGE [V1.0]
# ===========================================
# [PURPOSE]: Connect OpenClaw to Open WebUI Docker for premium chat interface
# [SOURCE]: Inspired by open-webui/open-webui (ghcr.io)
# [ACTIONS]: INSTALL, START, STOP, STATUS, OPEN, CONFIGURE

param(
    [string]$Action = "STATUS",
    [string]$OllamaUrl = "http://host.docker.internal:11434",
    [int]$Port = 3000,
    [string]$ApiKey = "openclaw_sovereign_key"
)

$ContainerName = "openclaw-webui"
$ImageName = "ghcr.io/open-webui/open-webui:main"

function Test-DockerRunning {
    try { docker info 2>&1 | Out-Null; return $true } catch { return $false }
}

function Test-ContainerRunning {
    $state = docker inspect -f '{{.State.Running}}' $ContainerName 2>$null
    return $state -eq "true"
}

switch ($Action.ToUpper()) {
    "INSTALL" {
        if (-not (Test-DockerRunning)) {
            Write-Output "[WEBUI] Docker is not running. Please start Docker Desktop first."
            break
        }

        Write-Host "[WEBUI] Pulling Open WebUI image..." -ForegroundColor Cyan
        docker pull $ImageName

        # Stop existing if any
        docker stop $ContainerName 2>$null | Out-Null
        docker rm $ContainerName 2>$null | Out-Null

        Write-Host "[WEBUI] Starting Open WebUI container..." -ForegroundColor Cyan
        $result = docker run -d `
            -p "${Port}:8080" `
            -e "OLLAMA_BASE_URL=$OllamaUrl" `
            -e "OPENAI_API_BASE_URL=http://host.docker.internal:11434/v1" `
            -e "OPENAI_API_KEY=$ApiKey" `
            -e "WEBUI_AUTH=False" `
            -e "WEBUI_NAME=OpenClaw Sovereign" `
            -v "openclaw-webui:/app/backend/data" `
            --name $ContainerName `
            --restart always `
            $ImageName 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Output "[WEBUI] Open WebUI installed and running!"
            Write-Output "Access at: http://localhost:$Port"
            Write-Output "Container: $ContainerName"
            Write-Output "Ollama URL: $OllamaUrl"
            Write-Output ""
            Write-Output "Your Gemma4 models will appear automatically in the Open WebUI interface."
        } else {
            Write-Output "[WEBUI] Failed to start: $result"
        }
    }

    "START" {
        if (-not (Test-DockerRunning)) { Write-Output "[WEBUI] Docker not running."; break }
        if (Test-ContainerRunning) { Write-Output "[WEBUI] Already running at http://localhost:$Port"; break }
        docker start $ContainerName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "[WEBUI] Started at http://localhost:$Port"
        } else {
            Write-Output "[WEBUI] Container not found. Run -Action INSTALL first."
        }
    }

    "STOP" {
        docker stop $ContainerName 2>$null
        Write-Output "[WEBUI] Stopped."
    }

    "STATUS" {
        $dockerOk = Test-DockerRunning
        $containerOk = if ($dockerOk) { Test-ContainerRunning } else { $false }

        $output = @"
[OPEN WEBUI STATUS]
Docker: $(if ($dockerOk) { "Running" } else { "NOT RUNNING" })
Container ($ContainerName): $(if ($containerOk) { "Running" } else { "Stopped/Not installed" })
URL: http://localhost:$Port
Ollama: $OllamaUrl
"@
        if ($containerOk) {
            # Health check
            try {
                $resp = Invoke-RestMethod -Uri "http://localhost:$Port/api/config" -TimeoutSec 3
                $output += "`nWeb UI: HEALTHY (version: $($resp.version))"
            } catch {
                $output += "`nWeb UI: Starting up (may need a minute)..."
            }
        }
        Write-Output $output
    }

    "OPEN" {
        Start-Process "http://localhost:$Port"
        Write-Output "[WEBUI] Opening browser to http://localhost:$Port"
    }

    "CONFIGURE" {
        $configOutput = @"
[OPEN WEBUI CONFIGURATION]

Docker Command (copy/paste to run manually):
docker run -d -p ${Port}:8080 \
  -e OLLAMA_BASE_URL=$OllamaUrl \
  -e OPENAI_API_BASE_URL=http://host.docker.internal:11434/v1 \
  -e OPENAI_API_KEY=$ApiKey \
  -e WEBUI_AUTH=False \
  -e WEBUI_NAME=OpenClaw Sovereign \
  -v openclaw-webui:/app/backend/data \
  --name $ContainerName \
  --restart always \
  $ImageName

Features available after install:
- Full ChatGPT-like UI for Gemma4 models
- RAG (upload documents for AI analysis)
- Multi-model comparison (gemma4:e2b vs e4b)
- Image analysis via Gemma4 vision
- Web search integration (connect to SearXNG)
- Python code execution in browser
- Persistent chat history
- Notes with AI enhancement
"@
        Write-Output $configOutput
    }

    default { Write-Output "Use: INSTALL, START, STOP, STATUS, OPEN, CONFIGURE" }
}
