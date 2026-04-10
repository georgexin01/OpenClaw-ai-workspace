# OPENCLAW SKILL: BROWSER CONTROL [V1.0]
# =========================================
# [PURPOSE]: Control Chrome via DevTools Protocol (CDP)
# [ACTIONS]: START, STOP, NAVIGATE, SCREENSHOT, CLICK, TYPE, JS, PAGEINFO, FIND

param(
    [string]$Action = "PAGEINFO",
    [string]$Url = "",
    [int]$X = 0,
    [int]$Y = 0,
    [string]$Text = "",
    [string]$Code = "",
    [string]$Selector = "",
    [switch]$Headless
)

$CDPPort = 9222
$CDPUrl = "http://localhost:$CDPPort"
$ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$ChromeDataDir = Join-Path $env:TEMP "openclaw_chrome_profile"
$ScreenshotDir = Join-Path $PSScriptRoot "..\skills_bridge\visual_vault"
if (-not (Test-Path $ScreenshotDir)) { New-Item -ItemType Directory -Path $ScreenshotDir -Force | Out-Null }

# --- CDP HELPERS ---
function Test-ChromeCDP {
    try { Invoke-RestMethod -Uri "$CDPUrl/json/version" -TimeoutSec 2 | Out-Null; return $true } catch { return $false }
}

function Get-CDPTabs {
    try { return Invoke-RestMethod -Uri "$CDPUrl/json" -TimeoutSec 3 } catch { return @() }
}

function Send-CDPCommand([string]$WsUrl, [string]$Method, [hashtable]$Params = @{}) {
    Add-Type -AssemblyName System.Net.Http

    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $ct = New-Object System.Threading.CancellationToken($false)

    try {
        $connectTask = $ws.ConnectAsync([Uri]$WsUrl, $ct)
        $connectTask.GetAwaiter().GetResult()

        $script:cmdId = if ($script:cmdId) { $script:cmdId + 1 } else { 1 }
        $msg = @{ id = $script:cmdId; method = $Method; params = $Params } | ConvertTo-Json -Compress -Depth 10
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $segment = New-Object System.ArraySegment[byte]($bytes, 0, $bytes.Length)

        $sendTask = $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $ct)
        $sendTask.GetAwaiter().GetResult()

        # Receive response (up to 4MB for screenshots)
        $buffer = New-Object byte[] (4 * 1024 * 1024)
        $result = ""
        do {
            $recvSeg = New-Object System.ArraySegment[byte]($buffer, 0, $buffer.Length)
            $recvTask = $ws.ReceiveAsync($recvSeg, $ct)
            $recv = $recvTask.GetAwaiter().GetResult()
            $result += [System.Text.Encoding]::UTF8.GetString($buffer, 0, $recv.Count)
        } while (-not $recv.EndOfMessage)

        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "", $ct).GetAwaiter().GetResult()
        return $result | ConvertFrom-Json
    } catch {
        return @{ error = $_.Exception.Message }
    } finally {
        if ($ws) { $ws.Dispose() }
    }
}

function Get-ActiveTabWs {
    $tabs = Get-CDPTabs
    $page = $tabs | Where-Object { $_.type -eq "page" } | Select-Object -First 1
    if ($page) { return $page.webSocketDebuggerUrl }
    return $null
}

# --- ACTIONS ---
switch ($Action.ToUpper()) {
    "START" {
        if (Test-ChromeCDP) {
            Write-Output "[BROWSER] Chrome CDP already active on port $CDPPort."
            $tabs = Get-CDPTabs
            Write-Output "Open tabs: $($tabs.Count)"
            if ($Url) {
                $wsUrl = Get-ActiveTabWs
                if ($wsUrl) { Send-CDPCommand $wsUrl "Page.navigate" @{ url = $Url } | Out-Null }
                Write-Output "Navigated to: $Url"
            }
            break
        }

        Write-Host "[BROWSER] Launching Chrome with CDP on port $CDPPort..." -ForegroundColor Cyan
        $args_list = @(
            "--remote-debugging-port=$CDPPort",
            "--user-data-dir=`"$ChromeDataDir`"",
            "--no-first-run",
            "--no-default-browser-check",
            "--disable-background-timer-throttling"
        )
        if ($Headless) { $args_list += "--headless=new" }
        if ($Url) { $args_list += $Url } else { $args_list += "about:blank" }

        Start-Process -FilePath $ChromePath -ArgumentList ($args_list -join " ") -WindowStyle Normal

        # Wait for CDP to be ready
        $ready = $false
        for ($i = 0; $i -lt 15; $i++) {
            Start-Sleep -Milliseconds 500
            if (Test-ChromeCDP) { $ready = $true; break }
        }

        if ($ready) {
            Write-Output "[BROWSER] Chrome launched and CDP active.$(if ($Url) { " URL: $Url" })"
        } else {
            Write-Output "[BROWSER] Chrome launched but CDP not responding. Port $CDPPort may be blocked."
        }
    }

    "STOP" {
        try {
            $procs = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object {
                try { $_.CommandLine -match "remote-debugging-port=$CDPPort" } catch { $false }
            }
            if ($procs) { $procs | Stop-Process -Force }
            # Fallback: close via CDP
            Invoke-RestMethod -Uri "$CDPUrl/json/close" -TimeoutSec 2 -ErrorAction SilentlyContinue | Out-Null
            Write-Output "[BROWSER] Chrome instance stopped."
        } catch {
            Write-Output "[BROWSER] Could not stop Chrome: $($_.Exception.Message)"
        }
    }

    "NAVIGATE" {
        if (-not $Url) { Write-Output "Provide -Url parameter."; break }
        if (-not (Test-ChromeCDP)) { Write-Output "[BROWSER] Chrome not running. Use -Action START first."; break }

        $wsUrl = Get-ActiveTabWs
        if (-not $wsUrl) { Write-Output "[BROWSER] No active tab found."; break }

        $r = Send-CDPCommand $wsUrl "Page.navigate" @{ url = $Url }
        if ($r.error) { Write-Output "[BROWSER] Navigation error: $($r.error)" }
        else { Write-Output "[BROWSER] Navigated to: $Url" }
    }

    "SCREENSHOT" {
        if (-not (Test-ChromeCDP)) { Write-Output "[BROWSER] Chrome not running."; break }

        $wsUrl = Get-ActiveTabWs
        if (-not $wsUrl) { Write-Output "[BROWSER] No active tab."; break }

        $r = Send-CDPCommand $wsUrl "Page.captureScreenshot" @{ format = "png"; quality = 80 }
        if ($r.result -and $r.result.data) {
            $ts = Get-Date -Format "yyyyMMdd_HHmmss"
            $imgPath = Join-Path $ScreenshotDir "browser_$ts.png"
            [System.IO.File]::WriteAllBytes($imgPath, [Convert]::FromBase64String($r.result.data))
            Write-Output "[BROWSER] Screenshot saved: $imgPath"
            Write-Output "BASE64_IMAGE_PATH:$imgPath"
        } else {
            Write-Output "[BROWSER] Screenshot failed: $($r.error)"
        }
    }

    "CLICK" {
        if (-not (Test-ChromeCDP)) { Write-Output "[BROWSER] Chrome not running."; break }
        $wsUrl = Get-ActiveTabWs

        # If selector provided, find element position first
        if ($Selector) {
            $findResult = Send-CDPCommand $wsUrl "Runtime.evaluate" @{
                expression = "var el = document.querySelector('$Selector'); if(el) { var r = el.getBoundingClientRect(); JSON.stringify({x: r.x + r.width/2, y: r.y + r.height/2, found: true}); } else { JSON.stringify({found: false}); }"
                returnByValue = $true
            }
            if ($findResult.result -and $findResult.result.result.value) {
                $pos = $findResult.result.result.value | ConvertFrom-Json
                if ($pos.found) { $X = [int]$pos.x; $Y = [int]$pos.y }
                else { Write-Output "[BROWSER] Element not found: $Selector"; break }
            }
        }

        Send-CDPCommand $wsUrl "Input.dispatchMouseEvent" @{ type = "mousePressed"; x = $X; y = $Y; button = "left"; clickCount = 1 } | Out-Null
        Send-CDPCommand $wsUrl "Input.dispatchMouseEvent" @{ type = "mouseReleased"; x = $X; y = $Y; button = "left"; clickCount = 1 } | Out-Null
        Write-Output "[BROWSER] Clicked at ($X, $Y)$(if ($Selector) { " (selector: $Selector)" })"
    }

    "TYPE" {
        if (-not $Text) { Write-Output "Provide -Text parameter."; break }
        if (-not (Test-ChromeCDP)) { Write-Output "[BROWSER] Chrome not running."; break }
        $wsUrl = Get-ActiveTabWs

        # Use insertText for reliability
        Send-CDPCommand $wsUrl "Input.insertText" @{ text = $Text } | Out-Null
        Write-Output "[BROWSER] Typed: $Text"
    }

    "JS" {
        if (-not $Code) { Write-Output "Provide -Code parameter."; break }
        if (-not (Test-ChromeCDP)) { Write-Output "[BROWSER] Chrome not running."; break }
        $wsUrl = Get-ActiveTabWs

        $r = Send-CDPCommand $wsUrl "Runtime.evaluate" @{ expression = $Code; returnByValue = $true }
        if ($r.result -and $r.result.result) {
            $val = $r.result.result.value
            if ($null -ne $val) { Write-Output "[JS RESULT] $val" }
            else { Write-Output "[JS] Executed (no return value)." }
        } else {
            Write-Output "[JS ERROR] $($r.error)"
        }
    }

    "PAGEINFO" {
        if (-not (Test-ChromeCDP)) { Write-Output "[BROWSER] Chrome not running on port $CDPPort. Use -Action START to launch."; break }
        $tabs = Get-CDPTabs
        if ($tabs.Count -eq 0) { Write-Output "[BROWSER] No tabs open."; break }

        $output = "[BROWSER STATUS] $($tabs.Count) tab(s) open:`n"
        foreach ($t in $tabs) {
            if ($t.type -eq "page") {
                $output += "  Title: $($t.title)`n  URL: $($t.url)`n"
            }
        }
        Write-Output $output
    }

    "FIND" {
        if (-not $Selector -and -not $Text) { Write-Output "Provide -Selector (CSS) or -Text to find on page."; break }
        if (-not (Test-ChromeCDP)) { Write-Output "[BROWSER] Chrome not running."; break }
        $wsUrl = Get-ActiveTabWs

        $jsCode = if ($Selector) {
            "var els = document.querySelectorAll('$Selector'); var results = []; els.forEach(function(el,i) { var r = el.getBoundingClientRect(); results.push({index:i, tag:el.tagName, text:el.innerText.substring(0,50), x:Math.round(r.x+r.width/2), y:Math.round(r.y+r.height/2), visible:r.width>0&&r.height>0}); }); JSON.stringify(results.slice(0,10));"
        } else {
            "var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT); var results = []; while(walker.nextNode()) { if(walker.currentNode.textContent.indexOf('$Text') !== -1) { var el = walker.currentNode.parentElement; var r = el.getBoundingClientRect(); results.push({tag:el.tagName, text:el.innerText.substring(0,80), x:Math.round(r.x+r.width/2), y:Math.round(r.y+r.height/2)}); } } JSON.stringify(results.slice(0,10));"
        }

        $r = Send-CDPCommand $wsUrl "Runtime.evaluate" @{ expression = $jsCode; returnByValue = $true }
        if ($r.result -and $r.result.result.value) {
            $elements = $r.result.result.value | ConvertFrom-Json
            if ($elements.Count -eq 0) { Write-Output "[FIND] No elements found." }
            else {
                $output = "[FOUND] $($elements.Count) element(s):`n"
                foreach ($el in $elements) {
                    $output += "  <$($el.tag)> `"$($el.text)`" at ($($el.x), $($el.y))$(if ($el.visible -eq $false) { ' [hidden]' })`n"
                }
                Write-Output $output
            }
        } else {
            Write-Output "[FIND] Search failed."
        }
    }

    default { Write-Output "Unknown action: $Action. Use: START, STOP, NAVIGATE, SCREENSHOT, CLICK, TYPE, JS, PAGEINFO, FIND" }
}
