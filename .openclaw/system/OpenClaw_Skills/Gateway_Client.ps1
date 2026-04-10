# OPENCLAW SKILL: GATEWAY CLIENT [V1.0]
# ========================================
# [PURPOSE]: WebSocket client for OpenClaw Gateway protocol
# [SOURCE]: Inspired by openclaw-windows-node gateway architecture
# [ACTIONS]: CONNECT, SEND, STATUS, SESSIONS, NODES, DISCONNECT

param(
    [string]$Action = "STATUS",
    [string]$GatewayUrl = "ws://localhost:18789",
    [string]$Token = "",
    [string]$Message = "",
    [string]$Role = "node"
)

$BridgeDir = Join-Path $PSScriptRoot "..\skills_bridge"
$ConfigPath = Join-Path $BridgeDir "gateway_config.json"

function Get-GatewayConfig {
    if (Test-Path $ConfigPath) { return Get-Content $ConfigPath | ConvertFrom-Json }
    $default = @{ url = $GatewayUrl; token = $Token; role = $Role; connected = $false; last_connect = "" }
    $default | ConvertTo-Json | Set-Content $ConfigPath -Force
    return $default
}

function Save-GatewayConfig($Config) {
    $Config | ConvertTo-Json | Set-Content $ConfigPath -Force
}

function Test-GatewayReachable([string]$Url) {
    # Convert ws:// to http:// for health check
    $httpUrl = $Url -replace "^ws://", "http://" -replace "^wss://", "https://"
    try {
        Invoke-RestMethod -Uri "$httpUrl/health" -TimeoutSec 3 | Out-Null
        return $true
    } catch {
        # Try direct WebSocket test
        try {
            $ws = New-Object System.Net.WebSockets.ClientWebSocket
            $ct = New-Object System.Threading.CancellationToken($false)
            $task = $ws.ConnectAsync([Uri]$Url, $ct)
            $completed = $task.Wait(3000)
            if ($completed -and $ws.State -eq "Open") {
                $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "", $ct).Wait(1000)
                $ws.Dispose()
                return $true
            }
            $ws.Dispose()
        } catch {}
        return $false
    }
}

function Send-GatewayMessage([string]$Url, [string]$AuthToken, [hashtable]$Payload) {
    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $ct = New-Object System.Threading.CancellationToken($false)

    try {
        if ($AuthToken) { $ws.Options.SetRequestHeader("Authorization", "Bearer $AuthToken") }
        $ws.ConnectAsync([Uri]$Url, $ct).GetAwaiter().GetResult()

        # Send handshake
        $handshake = @{ type = "handshake"; role = $Role; capabilities = @("system.run","system.notify","screen.capture","canvas.present") } | ConvertTo-Json -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($handshake)
        $ws.SendAsync((New-Object System.ArraySegment[byte]($bytes, 0, $bytes.Length)), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $ct).GetAwaiter().GetResult()

        # Send payload
        $msgBytes = [System.Text.Encoding]::UTF8.GetBytes(($Payload | ConvertTo-Json -Compress))
        $ws.SendAsync((New-Object System.ArraySegment[byte]($msgBytes, 0, $msgBytes.Length)), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $ct).GetAwaiter().GetResult()

        # Receive response
        $buffer = New-Object byte[] (64 * 1024)
        $recv = $ws.ReceiveAsync((New-Object System.ArraySegment[byte]($buffer)), $ct).GetAwaiter().GetResult()
        $response = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $recv.Count)

        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "", $ct).GetAwaiter().GetResult()
        return $response
    } catch {
        return @{ error = $_.Exception.Message } | ConvertTo-Json
    } finally {
        if ($ws) { $ws.Dispose() }
    }
}

switch ($Action.ToUpper()) {
    "STATUS" {
        $config = Get-GatewayConfig
        $reachable = Test-GatewayReachable $config.url

        Write-Output @"
[GATEWAY STATUS]
URL: $($config.url)
Role: $($config.role)
Reachable: $(if ($reachable) { "YES" } else { "NO" })
Token: $(if ($config.token) { "Set" } else { "Not set" })
Last connect: $(if ($config.last_connect) { $config.last_connect } else { "Never" })

Capabilities: system.run, system.notify, screen.capture, canvas.present

To connect to a gateway:
  -Action CONNECT -GatewayUrl ws://your-server:18789 -Token your_token
"@
    }

    "CONNECT" {
        $config = Get-GatewayConfig
        if ($GatewayUrl) { $config.url = $GatewayUrl }
        if ($Token) { $config.token = $Token }

        Write-Host "[GATEWAY] Testing connection to $($config.url)..." -ForegroundColor Cyan
        $reachable = Test-GatewayReachable $config.url

        if ($reachable) {
            $config.connected = $true
            $config.last_connect = (Get-Date -Format "o")
            Save-GatewayConfig $config
            Write-Output "[GATEWAY] Connected to $($config.url) as role: $($config.role)"
        } else {
            Write-Output "[GATEWAY] Cannot reach $($config.url). Ensure the gateway is running."
            Write-Output "Install OpenClaw gateway: https://github.com/openclaw/openclaw-windows-node/releases"
        }
    }

    "SEND" {
        if (-not $Message) { Write-Output "[GATEWAY] Provide -Message parameter."; break }
        $config = Get-GatewayConfig
        $payload = @{ type = "message"; content = $Message; timestamp = (Get-Date -Format "o") }
        $response = Send-GatewayMessage $config.url $config.token $payload
        Write-Output "[GATEWAY RESPONSE] $response"
    }

    "SESSIONS" {
        $config = Get-GatewayConfig
        $payload = @{ type = "query"; command = "sessions.list" }
        $response = Send-GatewayMessage $config.url $config.token $payload
        Write-Output "[SESSIONS] $response"
    }

    "NODES" {
        $config = Get-GatewayConfig
        $payload = @{ type = "query"; command = "nodes.list" }
        $response = Send-GatewayMessage $config.url $config.token $payload
        Write-Output "[NODES] $response"
    }

    "DISCONNECT" {
        $config = Get-GatewayConfig
        $config.connected = $false
        Save-GatewayConfig $config
        Write-Output "[GATEWAY] Disconnected."
    }

    default { Write-Output "Use: CONNECT, SEND, STATUS, SESSIONS, NODES, DISCONNECT" }
}
