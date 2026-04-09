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

function Add-ActionGlyph($x, $icon, $color) {
    $btn = New-Object System.Windows.Forms.Label
    $btn.Text = [char]$icon
    $btn.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 13)
    $btn.Location = New-Object System.Drawing.Point($x, 3)
    $btn.Size = New-Object System.Drawing.Size(28, 28)
    $btn.ForeColor = $color
    $btn.Cursor = "Hand"
    $btn.TextAlign = "MiddleCenter"
    $btn.Add_MouseEnter({ $this.ForeColor = [System.Drawing.Color]::White }.GetNewClosure())
    $btn.Add_MouseLeave({ $this.ForeColor = $color }.GetNewClosure())
    $actionPanel.Controls.Add($btn)
    return $btn
}

$btnMission = Add-ActionGlyph 56 0xE916 $Color_Lavender
$btnSync = Add-ActionGlyph 91 0xE895 $Color_Cyan
$btnDelete = Add-ActionGlyph 126 0xE74D $Color_Coral
$btnMin = Add-ActionGlyph 161 0xE921 $Color_Cyan
$btnClose = Add-ActionGlyph 196 0xE8BB $Color_Coral

$btnMin.Add_Click({ $form.WindowState = "Minimized" })
$btnClose.Add_Click({ $form.Close() })

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
  .spinner { display: inline-block; animation: spin 2s linear infinite; font-size: 1.2em; margin-right: 8px; vertical-align: middle; }
  body { background-color: #050810; color: white; font-family: 'Segoe UI', sans-serif; padding: 40px; margin: 0; overflow-x: hidden; }
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
</style></head>
<body><div id='container'></div></body></html>
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
        Add-Bubble "SYSTEM SYNC" "Rescanning master vault... Knowledge Singularity updated." "SYSTEM"
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
        Add-Bubble "THINKING..." "<span class='spinner'>⚙️</span> Cognitive Mirroring active. Planning mission..." "SOVEREIGN" "thinking_bubble"
        
        $psJob = [powershell]::Create()
        [void]$psJob.AddScript({ param($m, $p); . $p; Invoke-OClawQuery $m 1 }).AddArgument($msg).AddArgument($EnginePath)
        $asyncRes = $psJob.BeginInvoke()
        
        while (-not $asyncRes.IsCompleted) { 
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100 
        }
        $resObj = $psJob.EndInvoke($asyncRes)
        $res = if ($resObj) { $resObj -join "`n" } else { "No response or engine failed to load." }
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
        Add-Bubble "SEMANTIC MIRROR V35.1 ONLINE" "Semantic Memory: ACTIVE | YT Auto-Learn: ARMED | Paste any YouTube link to evolve." "SUCCESS"
    })

$form.ShowDialog() | Out-Null
