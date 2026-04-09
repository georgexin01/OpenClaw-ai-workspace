# OPENCLAW SOVEREIGN V1.01
# -----------------------------------------------------
# [AESTHETIC]: Liquid Glass (Zeta Red / Deep Zinc)
# [TECH]: Win32 Native Portal / Sovereign Core
# [STATUS]: Version Reset Active (04-10-2026)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. WIN32 NATIVE DRAG DISPATCHER
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
}
"@

$EnginePath = Join-Path $PSScriptRoot "OpenClaw_Engine.ps1"
$SystemRoot = Join-Path $PSScriptRoot "system"
$AssetPath = Join-Path $SystemRoot "assets\crab_icon.png"

# -----------------------------------------------------
# 2. DESIGN TOKENS (ZETA SOVEREIGN V45.0)
# -----------------------------------------------------
$Color_ZetaRed = [System.Drawing.ColorTranslator]::FromHtml("#FF0000")
$Color_Zinc = [System.Drawing.ColorTranslator]::FromHtml("#27272A")
$Color_Surface = [System.Drawing.ColorTranslator]::FromHtml("#0A0A0B")
$Color_DeepBlack = [System.Drawing.ColorTranslator]::FromHtml("#050505")
$Color_Glass = [System.Drawing.Color]::FromArgb(180, 5, 5, 5) # Layered Depth

# -----------------------------------------------------
# 3. GHOST SHELL ASSEMBLY
# -----------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Zeta Sovereign V1.01"
$form.Size = New-Object System.Drawing.Size(875, 665)
$form.BackColor = $Color_DeepBlack
$form.FormBorderStyle = "None"
$form.StartPosition = "CenterScreen"
# $form.TransparencyKey = $Color_DeepBlack

$form.Add_MouseDown({ [Win32]::ReleaseCapture(); [Win32]::SendMessage($form.Handle, 0xA1, 0x2, 0) })

function Update-FormRegion {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rect = New-Object System.Drawing.Rectangle(0, 0, $form.Width, $form.Height)
    $radius = 35
    $path.AddArc($rect.X, $rect.Y, $radius, $radius, 180, 90)
    $path.AddArc($rect.Right - $radius, $rect.Y, $radius, $radius, 270, 90)
    $path.AddArc($rect.Right - $radius, $rect.Bottom - $radius, $radius, $radius, 0, 90)
    $path.AddArc($rect.X, $rect.Bottom - $radius, $radius, $radius, 90, 90)
    $path.CloseFigure()
    $form.Region = New-Object System.Drawing.Region($path)
    return $path
}

$currentPath = Update-FormRegion

$form.Add_Resize({
        $script:currentPath = Update-FormRegion
        $form.Invalidate()
    })

$form.Add_Paint({
        $g = $_.Graphics
        $g.SmoothingMode = "AntiAlias"
        $g.FillPath((New-Object System.Drawing.SolidBrush($Color_Glass)), $script:currentPath)
        $g.DrawPath((New-Object System.Drawing.Pen($Color_ZetaRed, 2)), $script:currentPath)
    })

$sizeGrip = New-Object System.Windows.Forms.Label
$sizeGrip.Location = New-Object System.Drawing.Point(($form.Width - 28), ($form.Height - 28))
$sizeGrip.Size = New-Object System.Drawing.Size(28, 28)
$sizeGrip.Cursor = "SizeNWSE"
$sizeGrip.BackColor = [System.Drawing.Color]::Transparent
$sizeGrip.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
$sizeGrip.Add_MouseDown({ [Win32]::ReleaseCapture(); [Win32]::SendMessage($form.Handle, 0x112, 0xF008, 0) })
$form.Controls.Add($sizeGrip)
$sizeGrip.BringToFront()

# -----------------------------------------------------
# 4. GLYPH TRAY
# -----------------------------------------------------
$actionPanel = New-Object System.Windows.Forms.Panel
$actionPanel.Size = New-Object System.Drawing.Size(245, 35)
$actionPanel.Location = New-Object System.Drawing.Point(595, 21)
$actionPanel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($actionPanel)

function Add-ActionGlyph($x, $icon, $color, $tooltipText) {
    $btn = New-Object System.Windows.Forms.Label
    $btn.Text = [char]$icon
    $btn.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 15) # Increased size
    $btn.Location = New-Object System.Drawing.Point($x, 3)
    $btn.Size = New-Object System.Drawing.Size(32, 28)
    $btn.ForeColor = $color
    $btn.Cursor = "Hand"
    $btn.TextAlign = "MiddleCenter"
    
    $tip = New-Object System.Windows.Forms.ToolTip
    $tip.SetToolTip($btn, $tooltipText)
    
    $btn.Add_MouseEnter({ $this.ForeColor = [System.Drawing.Color]::White }.GetNewClosure())
    $btn.Add_MouseLeave({ $this.ForeColor = $color }.GetNewClosure())
    $actionPanel.Controls.Add($btn)
    return $btn
}

$btnMission = Add-ActionGlyph 10 0xE7E7 $Color_ZetaRed "EXECUTE MISSION STRATEGY"
$btnBrain =   Add-ActionGlyph 45 0xE8A9 $Color_ZetaRed "AUDIT SOVEREIGN BRAIN"
$btnSync =    Add-ActionGlyph 80 0xE895 $Color_ZetaRed "SYNC KNOWLEDGE VAULT"
$btnDelete =  Add-ActionGlyph 115 0xE74D $Color_ZetaRed "CLEAR CHAT HISTORY"
$btnMin =     Add-ActionGlyph 150 0xE921 $Color_ZetaRed "MINIMIZE"
$btnClose =   Add-ActionGlyph 185 0xE8BB $Color_ZetaRed "CLOSE SOVEREIGN PORTAL"

$btnMin.Add_Click({ $form.WindowState = "Minimized" })
$btnClose.Add_Click({ $form.Close() })

# 4.1 GPU HEARTBEAT MONITOR
$gpuLabel = New-Object System.Windows.Forms.Label
$gpuLabel.Text = "GPU: --% | VRAM: --MB"
$gpuLabel.Location = New-Object System.Drawing.Point(340, 24)
$gpuLabel.Size = New-Object System.Drawing.Size(250, 30)
$gpuLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$gpuLabel.ForeColor = [System.Drawing.Color]::Gray
$gpuLabel.TextAlign = "MiddleRight"
$gpuLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($gpuLabel)

$gpuTimer = New-Object System.Windows.Forms.Timer
$gpuTimer.Interval = 5000 # 5 seconds
$gpuTimer.Add_Tick({
    $script = Join-Path $SystemRoot "OpenClaw_Skills/Get_GPU_Status.ps1"
    $raw = & powershell -ExecutionPolicy Bypass -File $script
    if ($raw) {
        try {
            $status = $raw | ConvertFrom-Json
            $gpuLabel.Text = "GPU: $($status.Utilization)% | VRAM: $($status.UsedVRAM)MB ($($status.UsedPercent)%)"
            $gpuLabel.ForeColor = if ($status.UsedPercent -gt 90) { $Color_ZetaRed } else { [System.Drawing.Color]::Gray }
        } catch {}
    }
})
$gpuTimer.Start()

# -----------------------------------------------------
# 5. BRANDING
# -----------------------------------------------------
$logoBox = New-Object System.Windows.Forms.PictureBox
$logoBox.Location = New-Object System.Drawing.Point(28, 21)
$logoBox.Size = New-Object System.Drawing.Size(35, 35)
$logoBox.SizeMode = "Zoom"
if (Test-Path $AssetPath) { $logoBox.Image = [System.Drawing.Image]::FromFile($AssetPath) }
$form.Controls.Add($logoBox)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "OPENCLAW"
$titleLabel.Location = New-Object System.Drawing.Point(70, 31)
$titleLabel.AutoSize = $true
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI Black", 8)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($titleLabel)

# -----------------------------------------------------
# 6. LIQUID CHAT (WebBrowser)
# -----------------------------------------------------
$chatView = New-Object System.Windows.Forms.WebBrowser
$chatView.Location = New-Object System.Drawing.Point(35, 77)
$chatView.Size = New-Object System.Drawing.Size(805, 476)
$chatView.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$chatView.DocumentText = @"
<html><head><style>
  @keyframes fadeUp { from { transform: translateY(20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
  @keyframes spin { 100% { transform: rotate(360deg); } }
  @keyframes pulse { 0% { opacity: 0.5; } 50% { opacity: 1; } 100% { opacity: 0.5; } }
  
  .spinner { display: inline-block; animation: spin 2s linear infinite; font-size: 1.2em; margin-right: 8px; vertical-align: middle; }
  
  body { 
    background-color: #050505; color: #E4E4E7; 
    font-family: 'Inter', 'Segoe UI', sans-serif; padding: 40px; margin: 0; 
    overflow-x: hidden;
  }
  
  /* Layer 0: Atmosphere Noise */
  body::before {
    content: ''; position: fixed; top: 0; left: 0; width: 100%; height: 100%;
    background-image: url('https://grainy-gradients.vercel.app/noise.svg');
    opacity: 0.08; pointer-events: none; z-index: 999;
  }

  #boot-screen {
    position: fixed; top: 0; left: 0; width: 100%; height: 100%; 
    background: #050505; z-index: 9999; display: flex; flex-direction: column;
    justify-content: center; align-items: center; text-align: center;
    transition: opacity 0.5s ease;
  }
  .boot-text { font-family: 'Segoe UI Black', sans-serif; letter-spacing: 8px; color: #FF0000; font-size: 1.5em; margin-bottom: 20px; animation: pulse 1.5s infinite; }
  .progress-container { width: 300px; height: 2px; background: rgba(255, 0, 0, 0.1); border-radius: 2px; overflow: hidden; }
  #progress-bar { width: 0%; height: 100%; background: #FF0000; transition: width 0.3s ease; box-shadow: 0 0 20px rgba(255, 0, 0, 0.6); }
  .boot-log { font-family: 'Consolas', monospace; font-size: 0.7em; color: rgba(255,255,255,0.3); margin-top: 20px; text-transform: uppercase; letter-spacing: 2px; }

  /* Layer 2: Zeta Bubbles */
  .bubble { 
    max-width: 85%; padding: 25px; margin-bottom: 35px; 
    border-radius: 12px; border: 1px solid rgba(255, 0, 0, 0.15);
    background: rgba(15, 15, 17, 0.7); backdrop-filter: blur(25px);
    animation: fadeUp 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards;
    position: relative;
  }
  .bubble-ai { border-left: 3px solid #FF0000; box-shadow: -10px 0 30px rgba(255, 0, 0, 0.03); }
  .bubble-user { 
    border-right: 3px solid #3F3F46; 
    margin-left: auto; text-align: right;
    background: rgba(63, 63, 70, 0.05);
  }
  
  .bubble-title { font-weight: 900; text-transform: uppercase; color: #FF0000; font-size: 0.75em; margin-bottom:12px; letter-spacing: 2px; cursor: pointer; }
  .bubble-user .bubble-title { color: #A1A1AA; }
  .bubble-content { line-height: 1.8; opacity: 0.9; font-size: 1.05em; font-weight: 400; transition: opacity 0.3s; }
  
  /* Collapsible State (V50.0) */
  .bubble.collapsed { padding-bottom: 12px; margin-bottom: 15px; border-style: dashed; }
  .bubble.collapsed .bubble-content { display: none; opacity: 0; }
  .bubble.collapsed::after { content: ' +'; color: rgba(255,0,0,0.5); font-weight: bold; position: absolute; right: 20px; top: 22px; }

  /* Tailwind-style Utility Hooks */
  .text-zeta { color: #FF0000; }
  .bg-zeta { background: #FF0000; }
  .border-zinc { border-color: #27272A; }
</style>
<script>
  var progress = 0;
  function updateProgress(val, log) {
    progress = val;
    document.getElementById('progress-bar').style.width = progress + '%';
    if(log) document.getElementById('boot-log').innerText = log;
    if(progress >= 100) {
      setTimeout(function() {
        document.getElementById('boot-screen').style.opacity = '0';
        setTimeout(function() { document.getElementById('boot-screen').style.display = 'none'; }, 500);
      }, 500);
    }
  }

  function toggleBubble(id) {
    var el = document.getElementById(id);
    if (el) { el.classList.toggle('collapsed'); }
  }
</script>
</head>
<body>
<div id='boot-screen'>
  <div class='boot-text'>OPENCLAW SOVEREIGN</div>
  <div class='progress-container'><div id='progress-bar'></div></div>
  <div id='boot-log' class='boot-log'>Initializing Neuro-Cache...</div>
</div>
<div id='container'></div>
</body></html>
"@
$form.Controls.Add($chatView)

# -----------------------------------------------------
# 7. SOVEREIGN INPUT
# -----------------------------------------------------
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object System.Drawing.Point(35, 574)
$inputBox.Size = New-Object System.Drawing.Size(700, 26)
$inputBox.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$inputBox.BackColor = $Color_Surface
$inputBox.ForeColor = [System.Drawing.Color]::White
$inputBox.BorderStyle = "FixedSingle"
$inputBox.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$form.Controls.Add($inputBox)

$sendBtn = New-Object System.Windows.Forms.Button
$sendBtn.Location = New-Object System.Drawing.Point(749, 574)
$sendBtn.Size = New-Object System.Drawing.Size(91, 26)
$sendBtn.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
$sendBtn.Text = "SEND"
$sendBtn.Font = New-Object System.Drawing.Font("Segoe UI Black", 8)
$sendBtn.BackColor = $Color_ZetaRed
$sendBtn.ForeColor = [System.Drawing.Color]::White
$sendBtn.FlatStyle = "Flat"
$sendBtn.FlatAppearance.BorderSize = 0
$sendBtn.Cursor = "Hand"
$form.Controls.Add($sendBtn)

# -----------------------------------------------------
# 8. SOVEREIGN LOGIC
# -----------------------------------------------------
function Add-Bubble($title, $content, $type = "AI", $id = $null) {
    if (!$id) { $id = "b-" + [guid]::NewGuid().ToString().Substring(0,8) } # Unique ID generation
    $class = if ($type -eq "USER") { "bubble bubble-user" } else { "bubble bubble-ai" }
    
    $html = "<div id='$id' class='$class' onclick='toggleBubble(\`$id\`)'><div class='bubble-title'>$title</div><div class='bubble-content'>$content</div></div>"
    $safe = $html.Replace("'", "\'").Replace("`r`n", "<br/>").Replace("`n", "<br/>")
    $script = "var div = document.createElement('div'); div.innerHTML = '$safe'; document.getElementById('container').appendChild(div); window.scrollTo(0,document.body.scrollHeight);"
    
    # Auto-Collapse logic for AI cards after 2s
    if ($type -ne "USER" -and $type -ne "SUCCESS") {
        $script += "setTimeout(function() { toggleBubble('$id'); }, 2000);"
    }
    
    $chatView.Document.InvokeScript("eval", @($script))
}

function Remove-Bubble($id) {
    if (!$id) { return }
    $script = "var el = document.getElementById('$id'); if(el) { el.parentNode.removeChild(el); }"
    $chatView.Document.InvokeScript("eval", @($script))
}

$btnDelete.Add_Click({ 
        $chatView.Document.GetElementById("container").InnerHtml = "" 
        [System.Media.SystemSounds]::Beep.Play()
        & powershell -ExecutionPolicy Bypass -Command { . '$EnginePath'; Write-OClawLog "GUI_ACTION" "CLEAR_CHAT" }
    })

$btnSync.Add_Click({
        Add-Bubble "SYSTEM SYNC" "Synchronizing Sovereignty to Repository..." "SYSTEM"
        & powershell -ExecutionPolicy Bypass -Command { . '$EnginePath'; Write-OClawLog "GUI_ACTION" "GIT_SYNC_START" }
        Start-Process "powershell" "-ExecutionPolicy Bypass -Command { . '$EnginePath'; Invoke-OClawSkill 'Sovereign_GitSync' }"
    })

$btnBrain.Add_Click({
        Add-Bubble "NEURAL AUDIT" "Interrogating local brain for architectural metadata..." "SYSTEM"
        & powershell -ExecutionPolicy Bypass -Command { . '$EnginePath'; Write-OClawLog "GUI_ACTION" "BRAIN_AUDIT_START" }
        $psJob = [powershell]::Create()
        [void]$psJob.AddScript({ param($p); . $p; Invoke-OClawModelInfo }).AddArgument($EnginePath)
        $asyncRes = $psJob.BeginInvoke()
        while (-not $asyncRes.IsCompleted) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 100 }
        $res = $psJob.EndInvoke($asyncRes) -join "`n"
        $psJob.Dispose()
        Add-Bubble "BRAIN_INFO" $res "INSIGHT"
    })

$btnMission.Add_Click({
        Add-Bubble "MISSION TRIGGER" "Tactical Wave initiated." "MISSION"
        & powershell -ExecutionPolicy Bypass -Command { . '$EnginePath'; Write-OClawLog "GUI_ACTION" "MISSION_START" "RESOLVE_FAUCET" }
        Start-Process "powershell" "-ExecutionPolicy Bypass -Command { . '$EnginePath'; Invoke-OClawMission 'RESOLVE_FAUCET' }"
    })

$SendAction = {
    $msg = $inputBox.Text
    if (-not [string]::IsNullOrWhiteSpace($msg)) {
        $inputBox.Clear()
        Add-Bubble "USER" $msg "USER"
        Add-Bubble "COGNITIVE SYNC" "<span class='spinner'>⚙️</span> Delegating to local brain... Analyzing context." "SOVEREIGN" "thinking_bubble"
        
        # Async Background Execution (Non-Blocking)
        & powershell -ExecutionPolicy Bypass -Command { . '$EnginePath'; Write-OClawLog "MESSAGE_DISPATCH" "User: $msg" }
        $psJob = [powershell]::Create()
        [void]$psJob.AddScript({ 
            param($m, $p) 
            try {
                . $p
                return Invoke-OClawQuery $m 1
            } catch {
                return "### [X] ENGINE_CRASH: $($_.Exception.Message)"
            }
        }).AddArgument($msg).AddArgument($EnginePath)
        
        $asyncRes = $psJob.BeginInvoke()
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $stallDetected = $false
        
        # Event Loop with 150s Watchdog
        while (-not $asyncRes.IsCompleted) { 
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 200 
            if ($timer.Elapsed.TotalSeconds -gt 150) {
                $stallDetected = $true
                break
            }
        }
        
        if ($stallDetected) {
            $psJob.Stop()
            $res = "### [X] MISSION_STALL: Engine failed to respond within 150 seconds. Hardware pressure may be too high."
            & powershell -ExecutionPolicy Bypass -Command { . '$EnginePath'; Write-OClawLog "CRITICAL_FAILURE" "WATCHDOG_TIMEOUT" }
        } else {
            $resObj = $psJob.EndInvoke($asyncRes)
            $res = if ($resObj) { $resObj -join "`n" } else { "### [!] TIMEOUT: Engine returned null." }
        }
        $psJob.Dispose()
        
        Remove-Bubble "thinking_bubble"
        Add-Bubble "RESPONSE" $res "INSIGHT"
    }
}

$inputBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            & $SendAction
            $_.SuppressKeyPress = $true
        }
    })

$sendBtn.Add_Click($SendAction)

$form.Add_Shown({
        # SOVEREIGN BOOT SEQUENCE (V45.0)
        $chatView.Document.InvokeScript("updateProgress", @(10, "Mounting Memory Layer..."))
        Start-Sleep -Milliseconds 100
        $chatView.Document.InvokeScript("updateProgress", @(30, "Syncing GPU Identity..."))
        
        $script:currentGpu = & powershell -ExecutionPolicy Bypass -File (Join-Path $SystemRoot "OpenClaw_Skills\Get_GPU_Status.ps1")
        
        $chatView.Document.InvokeScript("updateProgress", @(60, "Establishing Brain Handshake..."))
        $chatView.Document.InvokeScript("updateProgress", @(90, "Neuro-Logic Online."))
        
        Start-Sleep -Milliseconds 200
        $chatView.Document.InvokeScript("updateProgress", @(100, "READY."))
        
        Add-Bubble "ZETA SOVEREIGN V1.01 ONLINE" "Brain: Gemma4:e2b (7.2GB) Ready | Atmosphere: ACTIVE | Design DNA: Zeta Core (Red/Black)" "SUCCESS"
    })

$form.ShowDialog() | Out-Null
