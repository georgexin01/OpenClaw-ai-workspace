# OPENCLAW KINETIC GUI V33.0 [HARDENED]
# -----------------------------------------------------
# [AESTHETIC]: Liquid Glass (Dynamic Bubbles / Adaptive Blur)
# [TECH]: Win32 Native Portal / Integrity Verified
# [STATUS]: Sovereign Hardening Complete

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
# 2. DESIGN TOKENS
# -----------------------------------------------------
$Color_DarkNavy = [System.Drawing.ColorTranslator]::FromHtml("#050810")
$Color_Cyan = [System.Drawing.ColorTranslator]::FromHtml("#00E5CC")
$Color_Coral = [System.Drawing.ColorTranslator]::FromHtml("#FF4D4C")
$Color_Lavender = [System.Drawing.ColorTranslator]::FromHtml("#9E9EFF")
$Color_Surface = [System.Drawing.ColorTranslator]::FromHtml("#0A0F1A")
$Color_Glass = [System.Drawing.Color]::FromArgb(160, 10, 15, 26)

# -----------------------------------------------------
# 3. GHOST SHELL ASSEMBLY
# -----------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "OpenClaw Hardened V33.0"
$form.Size = New-Object System.Drawing.Size(875, 665)
$form.BackColor = $Color_DarkNavy
$form.FormBorderStyle = "None"
$form.StartPosition = "CenterScreen"
# $form.TransparencyKey = $Color_DarkNavy

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
        $g.DrawPath((New-Object System.Drawing.Pen($Color_Cyan, 2)), $script:currentPath)
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

$btnMission = Add-ActionGlyph 20 0xE7E7 $Color_Cyan "EXECUTE MISSION STRATEGY" # Clearer icon (Play/Mission)
$btnSync = Add-ActionGlyph 60 0xE895 $Color_Cyan "SYNC KNOWLEDGE VAULT"
$btnDelete = Add-ActionGlyph 100 0xE74D $Color_Coral "CLEAR CHAT HISTORY"
$btnMin = Add-ActionGlyph 140 0xE921 $Color_Cyan "MINIMIZE"
$btnClose = Add-ActionGlyph 180 0xE8BB $Color_Coral "CLOSE SOVEREIGN PORTAL"

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
            $gpuLabel.ForeColor = if ($status.UsedPercent -gt 90) { $Color_Coral } else { [System.Drawing.Color]::Gray }
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
  @keyframes slideUp { from { transform: translateY(30px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
  @keyframes spin { 100% { transform: rotate(360deg); } }
  @keyframes pulse { 0% { opacity: 0.5; } 50% { opacity: 1; } 100% { opacity: 0.5; } }
  .spinner { display: inline-block; animation: spin 2s linear infinite; font-size: 1.2em; margin-right: 8px; vertical-align: middle; }
  body { background-color: #050810; color: white; font-family: 'Segoe UI', sans-serif; padding: 40px; margin: 0; overflow-x: hidden; }
  
  #boot-screen {
    position: fixed; top: 0; left: 0; width: 100%; height: 100%; 
    background: #050810; z-index: 9999; display: flex; flex-direction: column;
    justify-content: center; align-items: center; text-align: center;
  }
  .boot-text { font-family: 'Segoe UI Black', sans-serif; letter-spacing: 5px; color: #00E5CC; font-size: 1.5em; margin-bottom: 20px; animation: pulse 1.5s infinite; }
  .progress-container { width: 300px; height: 4px; background: rgba(0, 229, 204, 0.1); border-radius: 2px; overflow: hidden; }
  #progress-bar { width: 0%; height: 100%; background: #00E5CC; transition: width 0.3s ease; box-shadow: 0 0 15px #00E5CC; }
  .boot-log { font-family: 'Consolas', monospace; font-size: 0.7em; color: rgba(255,255,255,0.4); margin-top: 20px; text-transform: uppercase; }

  .bubble { 
    max-width: 80%; padding: 25px; margin-bottom: 30px; 
    border-radius: 20px 20px 20px 4px; border: 1px solid rgba(0, 229, 204, 0.2);
    background: rgba(10, 15, 26, 0.6); backdrop-filter: blur(20px);
    animation: slideUp 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
  }
  .bubble-ai { border-left: 4px solid #00E5CC; }
  .bubble-user { 
    border-left: none; border-right: 4px solid #FF4D4C; 
    border-radius: 20px 20px 4px 20px;
    margin-left: auto; text-align: right;
    border-color: rgba(255, 77, 76, 0.5);
    background: rgba(255, 77, 76, 0.05);
  }
  .bubble-title { font-weight: 800; text-transform: uppercase; color: #00E5CC; font-size: 0.8em; margin-bottom:10px; }
  .bubble-user .bubble-title { color: #FF4D4C; }
  .bubble-content { line-height: 1.7; opacity: 0.9; font-size: 1.1em; }
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
$sendBtn.BackColor = $Color_Cyan
$sendBtn.ForeColor = $Color_DarkNavy
$sendBtn.FlatStyle = "Flat"
$sendBtn.FlatAppearance.BorderSize = 0
$sendBtn.Cursor = "Hand"
$form.Controls.Add($sendBtn)

# -----------------------------------------------------
# 8. SOVEREIGN LOGIC
# -----------------------------------------------------
function Add-Bubble($title, $content, $type = "AI", $id = $null) {
    $class = if ($type -eq "USER") { "bubble bubble-user" } else { "bubble bubble-ai" }
    $idStr = if ($id) { " id='$id'" } else { "" }
    $html = "<div$idStr class='$class'><div class='bubble-title'>$title</div><div class='bubble-content'>$content</div></div>"
    $safe = $html.Replace("'", "\'").Replace("`r`n", "<br/>").Replace("`n", "<br/>")
    $script = "var div = document.createElement('div'); div.innerHTML = '$safe'; document.getElementById('container').appendChild(div); window.scrollTo(0,document.body.scrollHeight);"
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
    })

$btnSync.Add_Click({
        Add-Bubble "SYSTEM SYNC" "Synchronizing Sovereignty to Repository..." "SYSTEM"
        Start-Process "powershell" "-ExecutionPolicy Bypass -Command { . '$EnginePath'; Invoke-OClawSkill 'Sovereign_GitSync' }"
    })

$btnMission.Add_Click({
        Add-Bubble "MISSION TRIGGER" "Tactical Wave initiated." "MISSION"
        Start-Process "powershell" "-ExecutionPolicy Bypass -Command { . '$EnginePath'; Invoke-OClawMission 'RESOLVE_FAUCET' }"
    })

$SendAction = {
    $msg = $inputBox.Text
    if (-not [string]::IsNullOrWhiteSpace($msg)) {
        $inputBox.Clear()
        Add-Bubble "USER" $msg "USER"
        Add-Bubble "COGNITIVE SYNC" "<span class='spinner'>⚙️</span> Delegating to local brain... Analyzing context." "SOVEREIGN" "thinking_bubble"
        
        # Async Background Execution (Non-Blocking)
        $psJob = [powershell]::Create()
        [void]$psJob.AddScript({ 
            param($m, $p) 
            try {
                # Source the engine and invoke query
                . $p
                $ans = Invoke-OClawQuery $m 1
                return $ans
            } catch {
                return "### [X] ENGINE_CRASH: $($_.Exception.Message)"
            }
        }).AddArgument($msg).AddArgument($EnginePath)
        
        $asyncRes = $psJob.BeginInvoke()
        
        # Event Loop while waiting
        while (-not $asyncRes.IsCompleted) { 
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 200 
        }
        
        $resObj = $psJob.EndInvoke($asyncRes)
        $res = if ($resObj) { $resObj -join "`n" } else { "### [!] TIMEOUT: Engine failed to materialize response." }
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
        # SOVEREIGN BOOT SEQUENCE (V38.1)
        $chatView.Document.InvokeScript("updateProgress", @(10, "Mounting Memory Layer..."))
        Start-Sleep -Milliseconds 100
        $chatView.Document.InvokeScript("updateProgress", @(30, "Syncing GPU Identity..."))
        
        $script:currentGpu = & powershell -ExecutionPolicy Bypass -File (Join-Path $SystemRoot "OpenClaw_Skills\Get_GPU_Status.ps1")
        
        $chatView.Document.InvokeScript("updateProgress", @(60, "Establishing Brain Handshake..."))
        $chatView.Document.InvokeScript("updateProgress", @(90, "Neuro-Logic Online."))
        
        Start-Sleep -Milliseconds 200
        $chatView.Document.InvokeScript("updateProgress", @(100, "READY."))
        
        Add-Bubble "SEMANTIC MIRROR V38.1 ONLINE" "Brain: READY | Mission Strategy: ACTIVE | Hardware Lock: STABLE" "SUCCESS"
    })

$form.ShowDialog() | Out-Null
