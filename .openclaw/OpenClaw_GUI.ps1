# ==============================================================================
# OPENCLAW SOVEREIGN V3.1 — PROFESSIONAL GUI
# ==============================================================================
# [TECH]: WPF (XAML) + WebBrowser Chat + Chrome CDP + Async Jobs
# [AESTHETIC]: Zeta Red / Deep Zinc / Glassmorphism / Cinematic
# ==============================================================================

# --- 0. SYSTEM COMPATIBILITY ---
$RegPath = "HKCU:\Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION"
if (-not (Test-Path $RegPath)) { New-Item $RegPath -Force | Out-Null }
$ProcName = [System.IO.Path]::GetFileName(([System.Diagnostics.Process]::GetCurrentProcess()).MainModule.FileName)
Set-ItemProperty -Path $RegPath -Name $ProcName -Value 11001 -PropertyType DWord -ErrorAction SilentlyContinue

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$EnginePath = Join-Path $PSScriptRoot "OpenClaw_Engine.ps1"
$SystemRoot = Join-Path $PSScriptRoot "system"
$SkillsDir = Join-Path $SystemRoot "OpenClaw_Skills"
$AssetPath = Join-Path $SystemRoot "assets\crab_icon.png"
if (-not (Test-Path $AssetPath)) { $AssetPath = $null }

# --- 1. STATE ---
$script:ActiveModel = "gemma4:e2b"
$script:OllamaOnline = $false
$script:MessageCount = 0
$script:IsBusy = $false

# --- 2. XAML LAYOUT ---
$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OpenClaw V3.1" Height="860" Width="1200"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen" MinWidth="900" MinHeight="650">

    <Window.Resources>
        <Style x:Key="SideBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#888"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Height" Value="34"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Padding" Value="16,0,0,0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#12FF0000"/>
                    <Setter Property="Foreground" Value="#FF3333"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style x:Key="HeaderBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#555"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Width" Value="38"/>
            <Setter Property="Height" Value="38"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Foreground" Value="#FF0000"/>
                    <Setter Property="Background" Value="#0CFF0000"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style x:Key="SectionLabel" TargetType="TextBlock">
            <Setter Property="Foreground" Value="#444"/>
            <Setter Property="FontSize" Value="9"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Margin" Value="16,12,0,4"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
        </Style>
    </Window.Resources>

    <Border Name="MainBorder" Background="#F2060608" BorderBrush="#22FF0000" BorderThickness="1" CornerRadius="14" Margin="6">
        <Border.Effect>
            <DropShadowEffect Color="#FF0000" BlurRadius="30" ShadowDepth="0" Opacity="0.12"/>
        </Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="46"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="24"/>
            </Grid.RowDefinitions>

            <!-- HEADER -->
            <Border Grid.Row="0" Background="#090909" CornerRadius="14,14,0,0" BorderBrush="#15FF0000" BorderThickness="0,0,0,1">
                <Grid Margin="16,0">
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <TextBlock Text="&#x1F980;" FontSize="16" VerticalAlignment="Center" Margin="0,0,8,0"/>
                        <TextBlock Text="OPENCLAW" Foreground="White" FontSize="14" FontWeight="Black" FontFamily="Segoe UI" VerticalAlignment="Center"/>
                        <Border Background="#18FF0000" CornerRadius="3" Margin="8,0,0,0" Padding="6,2">
                            <TextBlock Text="V3.1" Foreground="#FF4444" FontSize="9" FontWeight="Bold"/>
                        </Border>
                        <Border Background="#111" CornerRadius="3" Margin="12,0,0,0" Padding="8,2">
                            <TextBlock Name="StatusIndicator" Text="&#x25CF; Checking..." Foreground="#555" FontSize="9"/>
                        </Border>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                        <TextBlock Name="GpuStatus" Text="GPU: --%" Foreground="#444" FontSize="9" VerticalAlignment="Center" Margin="0,0,10,0" FontFamily="Consolas"/>
                        <ComboBox Name="ModelSelect" Width="115" Height="24" FontSize="9" Background="#111" Foreground="White" BorderBrush="#222" VerticalContentAlignment="Center" Margin="0,0,12,0"/>
                        <Button Name="MinBtn" Content="&#x2014;" Style="{StaticResource HeaderBtn}"/>
                        <Button Name="MaxBtn" Content="&#x25A1;" Style="{StaticResource HeaderBtn}"/>
                        <Button Name="CloseBtn" Content="&#x2715;" Style="{StaticResource HeaderBtn}"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- BODY -->
            <Grid Grid.Row="1">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="210"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- SIDEBAR -->
                <Border Grid.Column="0" Background="#070708" BorderBrush="#111" BorderThickness="0,0,1,0">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto" Margin="0,6,0,0">
                            <StackPanel>
                                <TextBlock Text="CHAT" Style="{StaticResource SectionLabel}"/>
                                <Button Name="BtnChat" Content="&#x1F4AC;  New Chat" Style="{StaticResource SideBtn}"/>

                                <TextBlock Text="BROWSER" Style="{StaticResource SectionLabel}"/>
                                <Button Name="BtnBrowser" Content="&#x1F310;  Open Browser" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnBrowserVision" Content="&#x1F441;  Page Vision" Style="{StaticResource SideBtn}"/>

                                <TextBlock Text="FILES" Style="{StaticResource SectionLabel}"/>
                                <Button Name="BtnCrawler" Content="&#x1F4C2;  File Crawler" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnRAG" Content="&#x1F9E9;  RAG Search" Style="{StaticResource SideBtn}"/>

                                <TextBlock Text="INTELLIGENCE" Style="{StaticResource SectionLabel}"/>
                                <Button Name="BtnArchitect" Content="&#x1F3D7;  Architect Review" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnChain" Content="&#x26D3;  Prompt Chain" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnSandbox" Content="&#x1F4BB;  Code Sandbox" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnOCR" Content="&#x1F4F7;  OCR Extract" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnClipboard" Content="&#x1F4CB;  Clipboard" Style="{StaticResource SideBtn}"/>

                                <TextBlock Text="SYSTEM" Style="{StaticResource SectionLabel}"/>
                                <Button Name="BtnHealth" Content="&#x1F3E5;  Health Check" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnDaemon" Content="&#x26A1;  Daemon Mode" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnSecurity" Content="&#x1F6E1;  Security Scan" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnGitSync" Content="&#x1F504;  Git Sync" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnGPU" Content="&#x1F4CA;  GPU Status" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnWindows" Content="&#x1FA9F;  Window Manager" Style="{StaticResource SideBtn}"/>

                                <TextBlock Text="TOOLS" Style="{StaticResource SectionLabel}"/>
                                <Button Name="BtnMemory" Content="&#x1F9E0;  Memory Graph" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnVoice" Content="&#x1F50A;  Voice" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnYTLearn" Content="&#x1F4FA;  YT AutoLearn" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnJournal" Content="&#x1F4D3;  Activity Journal" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnTasks" Content="&#x1F4C5;  Task Scheduler" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnSearch" Content="&#x1F50D;  Web Search" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnKnowledge" Content="&#x1F4DA;  Knowledge Vault" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnExport" Content="&#x1F4BE;  Export Chat" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnHotkeys" Content="&#x2328;  Hotkeys" Style="{StaticResource SideBtn}"/>

                                <TextBlock Text="INTEGRATIONS" Style="{StaticResource SectionLabel}"/>
                                <Button Name="BtnWebUI" Content="&#x1F5A5;  Open WebUI" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnGateway" Content="&#x1F50C;  Gateway" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnCanvas" Content="&#x1F3A8;  Canvas" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnScreenPro" Content="&#x1F4F8;  Screen Capture" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnPipeline" Content="&#x1F6E0;  Pipeline" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnNotes" Content="&#x1F4DD;  Notes" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnTerminal" Content="&#x1F4DF;  Terminal" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnMultiModel" Content="&#x2696;  Model Compare" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnDeepLink" Content="&#x1F517;  Deep Links" Style="{StaticResource SideBtn}"/>
                                <Button Name="BtnAnalytics" Content="&#x1F4C8;  Analytics" Style="{StaticResource SideBtn}"/>
                            </StackPanel>
                        </ScrollViewer>

                        <!-- BOTTOM STATUS -->
                        <Border Grid.Row="1" Background="#050506" Padding="14,8" BorderBrush="#111" BorderThickness="0,1,0,0" CornerRadius="0,0,0,14">
                            <StackPanel>
                                <TextBlock Name="ModelLabel" Text="Model: gemma4:e2b" Foreground="#444" FontSize="8.5" FontFamily="Consolas"/>
                                <TextBlock Name="SpeedLabel" Text="Speed: -- t/s" Foreground="#333" FontSize="8.5" FontFamily="Consolas" Margin="0,1,0,0"/>
                            </StackPanel>
                        </Border>
                    </Grid>
                </Border>

                <!-- CHAT + INPUT -->
                <Grid Grid.Column="1">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="64"/>
                    </Grid.RowDefinitions>

                    <Border Grid.Row="0" Background="#060607">
                        <WebBrowser Name="ChatView"/>
                    </Border>

                    <Border Grid.Row="1" Background="#090909" BorderBrush="#111" BorderThickness="0,1,0,0" CornerRadius="0,0,14,0">
                        <Grid Margin="14,10,14,10">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="85"/>
                            </Grid.ColumnDefinitions>
                            <Border Grid.Column="0" Background="#0E0E10" CornerRadius="8" BorderBrush="#1A1A1E" BorderThickness="1" Margin="0,0,8,0">
                                <TextBox Name="InputBox" Background="Transparent" Foreground="#D4D4D8" BorderThickness="0"
                                         VerticalContentAlignment="Center" Padding="14,0" FontSize="13" FontFamily="Segoe UI"
                                         CaretBrush="#FF3333" AcceptsReturn="False"
                                         ToolTip="Type a message... (Enter to send)"/>
                            </Border>
                            <Button Name="SendBtn" Grid.Column="1" Content="SEND" Background="#BB0000" Foreground="White"
                                    FontSize="11" FontWeight="Bold" Cursor="Hand" BorderThickness="0" FontFamily="Segoe UI">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                            </Button>
                        </Grid>
                    </Border>
                </Grid>
            </Grid>

            <!-- FOOTER STATUS BAR -->
            <Border Grid.Row="2" Background="#050506" CornerRadius="0,0,14,14" BorderBrush="#0C0C0C" BorderThickness="0,1,0,0">
                <Grid Margin="16,0">
                    <TextBlock Name="FooterLeft" Text="OpenClaw V3.1 Sovereign" Foreground="#2A2A2A" FontSize="8.5" VerticalAlignment="Center" FontFamily="Segoe UI"/>
                    <TextBlock Name="FooterRight" Text="" Foreground="#2A2A2A" FontSize="8.5" VerticalAlignment="Center" HorizontalAlignment="Right" FontFamily="Consolas"/>
                </Grid>
            </Border>

            <!-- BOOT OVERLAY -->
            <Border Name="BootOverlay" Grid.RowSpan="3" Background="#060608" CornerRadius="14" Panel.ZIndex="100">
                <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                    <TextBlock Text="&#x1F980;" FontSize="52" HorizontalAlignment="Center" Margin="0,0,0,12"/>
                    <TextBlock Text="OPENCLAW" Foreground="White" FontSize="28" FontWeight="Black" HorizontalAlignment="Center" FontFamily="Segoe UI">
                        <TextBlock.Effect><DropShadowEffect Color="#FF0000" BlurRadius="25" ShadowDepth="0" Opacity="0.4"/></TextBlock.Effect>
                    </TextBlock>
                    <TextBlock Text="V3.1 SOVEREIGN INTELLIGENCE" Foreground="#FF3333" FontSize="10" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,4,0,30" FontFamily="Segoe UI" Opacity="0.7"/>
                    <ProgressBar Name="BootProgress" Width="260" Height="2" Background="#111" Foreground="#CC0000" BorderThickness="0" Maximum="100"/>
                    <TextBlock Name="BootLog" Text="Initializing..." Foreground="#333" FontSize="9" Margin="0,14,0,0" HorizontalAlignment="Center" FontFamily="Consolas"/>
                </StackPanel>
            </Border>
        </Grid>
    </Border>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader([xml]$XAML)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# --- 3. ELEMENT BINDING ---
$ChatView = $Window.FindName("ChatView")
$InputBox = $Window.FindName("InputBox")
$SendBtn = $Window.FindName("SendBtn")
$MinBtn = $Window.FindName("MinBtn")
$MaxBtn = $Window.FindName("MaxBtn")
$CloseBtn = $Window.FindName("CloseBtn")
$BootOverlay = $Window.FindName("BootOverlay")
$BootProgress = $Window.FindName("BootProgress")
$BootLog = $Window.FindName("BootLog")
$GpuStatus = $Window.FindName("GpuStatus")
$StatusIndicator = $Window.FindName("StatusIndicator")
$ModelSelect = $Window.FindName("ModelSelect")
$ModelLabel = $Window.FindName("ModelLabel")
$SpeedLabel = $Window.FindName("SpeedLabel")
$FooterRight = $Window.FindName("FooterRight")

# Bind all sidebar buttons
$sideButtons = @{}
foreach ($name in @("BtnChat","BtnBrowser","BtnBrowserVision","BtnCrawler","BtnRAG","BtnArchitect","BtnChain","BtnSandbox","BtnOCR","BtnClipboard","BtnHealth","BtnDaemon","BtnSecurity","BtnGitSync","BtnGPU","BtnWindows","BtnMemory","BtnVoice","BtnYTLearn","BtnJournal","BtnTasks","BtnSearch","BtnKnowledge","BtnExport","BtnHotkeys","BtnWebUI","BtnGateway","BtnCanvas","BtnScreenPro","BtnPipeline","BtnNotes","BtnTerminal","BtnMultiModel","BtnDeepLink","BtnAnalytics")) {
    $sideButtons[$name] = $Window.FindName($name)
}

# --- 4. CHAT HTML ---
$ChatHTML = @"
<!DOCTYPE html>
<html><head>
<meta http-equiv="X-UA-Compatible" content="IE=edge"/>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    background: #060607; color: #C8C8CC; font-family: 'Segoe UI', sans-serif;
    padding: 20px 24px; overflow-x: hidden; font-size: 13.5px; line-height: 1.65;
  }
  #container { display: flex; flex-direction: column; gap: 14px; }

  .bubble { max-width: 88%; padding: 14px 18px; border-radius: 10px; animation: fadeIn 0.25s ease; word-wrap: break-word; }
  .bubble-ai { background: #0C0C0E; border: 1px solid #1A1A1E; border-left: 3px solid #AA0000; align-self: flex-start; }
  .bubble-user { background: #0E0E12; border: 1px solid #1A1A22; border-right: 3px solid #333; align-self: flex-end; text-align: right; }
  .bubble-system { background: #0A0A0C; border: 1px solid #151518; border-left: 3px solid #553300; align-self: flex-start; opacity: 0.85; font-size: 0.92em; }

  .bubble-title { font-size: 0.65em; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; margin-bottom: 6px; opacity: 0.5; }
  .bubble-ai .bubble-title { color: #CC0000; }
  .bubble-user .bubble-title { color: #666; }
  .bubble-system .bubble-title { color: #885500; }

  .bubble-content { line-height: 1.65; }
  .bubble-content pre { background: #08080A; border: 1px solid #161618; border-radius: 5px; padding: 10px; margin: 6px 0; overflow-x: auto; font-family: 'Cascadia Code', Consolas, monospace; font-size: 0.88em; line-height: 1.45; }
  .bubble-content code { font-family: 'Cascadia Code', Consolas, monospace; font-size: 0.88em; background: #0C0C0E; padding: 1px 4px; border-radius: 3px; }
  .bubble-time { font-size: 0.6em; color: #2A2A2A; margin-top: 6px; text-align: right; }

  .typing-indicator { display: inline-flex; gap: 5px; padding: 6px 0; }
  .typing-dot { width: 5px; height: 5px; border-radius: 50%; background: #CC0000; animation: pulse 1.4s infinite; }
  .typing-dot:nth-child(2) { animation-delay: 0.2s; }
  .typing-dot:nth-child(3) { animation-delay: 0.4s; }

  .welcome { text-align: center; padding: 60px 20px; }
  .welcome h2 { color: #CC0000; font-size: 1em; font-weight: 900; letter-spacing: 4px; margin-bottom: 6px; }
  .welcome p { color: #333; font-size: 0.8em; }
  .welcome .hint { color: #222; font-size: 0.72em; margin-top: 16px; line-height: 2; }

  @keyframes fadeIn { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }
  @keyframes pulse { 0%,60%,100% { opacity: 0.2; } 30% { opacity: 1; } }
  ::-webkit-scrollbar { width: 4px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: #1A1A1A; border-radius: 2px; }
</style>
<script>
  function addBubble(id, title, content, type, time) {
    var cls = 'bubble bubble-' + (type || 'ai');
    var h = '<div id="'+id+'" class="'+cls+'"><div class="bubble-title">'+title+'</div><div class="bubble-content">'+content+'</div>';
    if (time) h += '<div class="bubble-time">'+time+'</div>';
    h += '</div>';
    document.getElementById('container').insertAdjacentHTML('beforeend', h);
    window.scrollTo(0, document.body.scrollHeight);
  }
  function removeBubble(id) { var e=document.getElementById(id); if(e) e.remove(); }
  function showTyping() { addBubble('typing_ind','THINKING','<div class="typing-indicator"><div class="typing-dot"></div><div class="typing-dot"></div><div class="typing-dot"></div></div>','system',''); }
  function hideTyping() { removeBubble('typing_ind'); }
  function clearChat() { document.getElementById('container').innerHTML=''; }
  function showWelcome() {
    document.getElementById('container').innerHTML = '<div class="welcome"><h2>OPENCLAW V3.1</h2><p>Sovereign Intelligence Ready</p><div class="hint">[BROWSER] open URL &bull; [CRAWL] Desktop &bull; [SEARCH] query &bull; [CODE] snippet &bull; [OCR]<br/>Or just type a message to talk to Gemma4</div></div>';
  }
</script>
</head><body><div id="container"></div></body></html>
"@

$ChatView.NavigateToString($ChatHTML)

# --- 5. CHAT FUNCTIONS ---
function Invoke-JS([string]$Code) { try { $ChatView.InvokeScript("eval", @($Code)) } catch {} }

function Add-ChatBubble([string]$Title, [string]$Content, [string]$Type = "ai", [string]$Id = "") {
    if (-not $Id) { $Id = "b" + [guid]::NewGuid().ToString().Substring(0,8) }
    $ts = Get-Date -Format "HH:mm"
    $safe = $Content -replace '\\', '\\\\' -replace "'", "\'" -replace '"', '\"' -replace "`r`n", '<br/>' -replace "`n", '<br/>' -replace "`r", ''
    $safeTitle = $Title -replace "'", "\'" -replace '"', '\"'
    Invoke-JS "addBubble('$Id','$safeTitle',`"$safe`",'$Type','$ts');"
    return $Id
}

# --- 6. ASYNC SKILL RUNNER ---
function Invoke-SkillAsync([string]$SkillName, [string]$Label, [string]$SkillArgs = "") {
    if ($script:IsBusy) { return }
    $script:IsBusy = $true
    Add-ChatBubble "SKILL" "Running $Label..." "system"
    Invoke-JS "showTyping();"

    $skillPath = Join-Path $SkillsDir "$SkillName.ps1"
    $runArgs = if ($SkillArgs) { "$SkillArgs" } else { "" }
    $job = Start-Job -ScriptBlock {
        param($path, $a)
        if ($a) { & powershell -ExecutionPolicy Bypass -File $path $a.Split(" ") 2>&1 | Out-String }
        else { & powershell -ExecutionPolicy Bypass -File $path 2>&1 | Out-String }
    } -ArgumentList $skillPath, $runArgs

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(400)
    $timer.Add_Tick({
        if ($job.State -ne "Running") {
            $timer.Stop(); Invoke-JS "hideTyping();"
            $result = try { ($job | Receive-Job | Out-String).Trim() } catch { "Error." }
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            if (-not $result) { $result = "Done (no output)." }
            Add-ChatBubble $Label.ToUpper() $result "ai"
            $script:IsBusy = $false
            $InputBox.IsEnabled = $true; $InputBox.Focus()
        }
    }.GetNewClosure())
    $timer.Start()
}

# --- 7. SEND MESSAGE ---
$SendAction = {
    $msg = $InputBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($msg) -or $script:IsBusy) { return }
    $script:IsBusy = $true
    $InputBox.Clear(); $InputBox.IsEnabled = $false
    $SendBtn.IsEnabled = $false; $SendBtn.Content = "..."

    Add-ChatBubble "YOU" $msg "user"
    Invoke-JS "showTyping();"

    $tier = if ($script:ActiveModel -match "e4b") { 2 } else { 1 }
    $job = Start-Job -ScriptBlock {
        param($m, $e, $t)
        try { . $e; return Invoke-OClawQuery $m $t }
        catch { return "[ERROR] $($_.Exception.Message)" }
    } -ArgumentList $msg, $EnginePath, $tier

    $poll = New-Object System.Windows.Threading.DispatcherTimer
    $poll.Interval = [TimeSpan]::FromMilliseconds(300)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $poll.Add_Tick({
        if ($job.State -ne "Running") {
            $poll.Stop(); Invoke-JS "hideTyping();"
            $r = try { $job | Receive-Job -ErrorAction Stop } catch { "[ERROR] $($_.Exception.Message)" }
            if (-not $r) { $r = "[No response]" }
            $r = ($r | Out-String).Trim() -replace '```(\w*)\n', '<pre><code>' -replace '```', '</code></pre>'
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            Add-ChatBubble "OPENCLAW" $r "ai"
            $SpeedLabel.Text = "Speed: $([math]::Round($sw.Elapsed.TotalSeconds, 1))s"
            $script:IsBusy = $false; $InputBox.IsEnabled = $true
            $SendBtn.IsEnabled = $true; $SendBtn.Content = "SEND"
            $InputBox.Focus()
        } elseif ($sw.Elapsed.TotalSeconds -gt 200) {
            $poll.Stop(); Invoke-JS "hideTyping();"
            Stop-Job $job -ErrorAction SilentlyContinue; Remove-Job $job -Force -ErrorAction SilentlyContinue
            Add-ChatBubble "SYSTEM" "Timeout after 200s." "system"
            $script:IsBusy = $false; $InputBox.IsEnabled = $true
            $SendBtn.IsEnabled = $true; $SendBtn.Content = "SEND"
        }
    }.GetNewClosure())
    $poll.Start()
}

$SendBtn.Add_Click($SendAction)

# --- 8. SPECIAL PREFIX COMMANDS ---
$InputBox.Add_KeyDown({
    if ($_.Key -ne "Return" -or $script:IsBusy) { return }
    $text = $InputBox.Text.Trim()
    $_.Handled = $true

    # [BROWSER] commands
    if ($text -match '^\[BROWSER\]\s*(.*)') {
        $cmd = $Matches[1].Trim()
        $InputBox.Clear()
        if ($cmd -match '^open\s+(.+)') { Invoke-SkillAsync "Browser_Control" "Browser" "-Action START -Url $($Matches[1])" }
        elseif ($cmd -match '^go\s+(.+)') { Invoke-SkillAsync "Browser_Control" "Browser" "-Action NAVIGATE -Url $($Matches[1])" }
        elseif ($cmd -match '^screenshot') { Invoke-SkillAsync "Browser_Control" "Browser Screenshot" "-Action SCREENSHOT" }
        elseif ($cmd -match '^click\s+(\d+)\s+(\d+)') { Invoke-SkillAsync "Browser_Control" "Browser Click" "-Action CLICK -X $($Matches[1]) -Y $($Matches[2])" }
        elseif ($cmd -match '^find\s+(.+)') { Invoke-SkillAsync "Browser_Control" "Browser Find" "-Action FIND -Text $($Matches[1])" }
        elseif ($cmd -match '^type\s+(.+)') { Invoke-SkillAsync "Browser_Control" "Browser Type" "-Action TYPE -Text `"$($Matches[1])`"" }
        elseif ($cmd -match '^js\s+(.+)') { Invoke-SkillAsync "Browser_Control" "Browser JS" "-Action JS -Code `"$($Matches[1])`"" }
        elseif ($cmd -match '^vision\s*(.*)') { Invoke-SkillAsync "Browser_Vision" "Browser Vision" $(if ($Matches[1]) { "-Query `"$($Matches[1])`"" } else { "" }) }
        elseif ($cmd -match '^stop') { Invoke-SkillAsync "Browser_Control" "Browser" "-Action STOP" }
        elseif ($cmd -match '^info') { Invoke-SkillAsync "Browser_Control" "Browser" "-Action PAGEINFO" }
        else { Add-ChatBubble "SYSTEM" "Browser commands: open URL, go URL, screenshot, click X Y, find text, type text, js code, vision [query], stop, info" "system"; $script:IsBusy = $false }
        return
    }

    # [CRAWL] commands
    if ($text -match '^\[CRAWL\]\s*(.*)') {
        $cmd = $Matches[1].Trim()
        $InputBox.Clear()
        if ($cmd -match '^search\s+(.+)') { Invoke-SkillAsync "File_Crawler" "File Search" "-Action SEARCH -Query `"$($Matches[1])`"" }
        elseif ($cmd -match '^read\s+(.+)') { Invoke-SkillAsync "File_Crawler" "File Read" "-Action READ -Path `"$($Matches[1])`"" }
        elseif ($cmd -match '^approve\s+(.+)') { Invoke-SkillAsync "File_Crawler" "Crawler" "-Action APPROVE -Path `"$($Matches[1])`"" }
        elseif ($cmd -match '^status') { Invoke-SkillAsync "File_Crawler" "Crawler Status" "-Action STATUS" }
        elseif ($cmd) { Invoke-SkillAsync "File_Crawler" "File Crawl" "-Action CRAWL -Path `"$cmd`"" }
        else { Invoke-SkillAsync "File_Crawler" "File Crawl" "-Action CRAWL" }
        return
    }

    # [SEARCH] prefix
    if ($text -match '^\[SEARCH\]\s*(.+)') {
        $q = $Matches[1]; $InputBox.Clear()
        Add-ChatBubble "YOU" "Search: $q" "user"
        $script:IsBusy = $true; Invoke-JS "showTyping();"
        $sj = Start-Job -ScriptBlock { param($query,$ep); . $ep
            try { $r = Invoke-RestMethod -Uri "http://localhost:8888/search?q=$([uri]::EscapeDataString($query))&format=json" -TimeoutSec 10
                ($r.results | Select-Object -First 5 | ForEach-Object { "[$($_.title)]($($_.url))`n$($_.content)" }) -join "`n---`n"
            } catch { Invoke-OClawQuery "Search: $query" 1 }
        } -ArgumentList $q, $EnginePath
        $st = New-Object System.Windows.Threading.DispatcherTimer
        $st.Interval = [TimeSpan]::FromMilliseconds(300)
        $st.Add_Tick({ if ($sj.State -ne "Running") { $st.Stop(); Invoke-JS "hideTyping();"
            $sr = try { ($sj|Receive-Job|Out-String).Trim() } catch { "Search failed." }
            Remove-Job $sj -Force -EA 0; Add-ChatBubble "SEARCH" $sr "ai"; $script:IsBusy = $false } }.GetNewClosure())
        $st.Start(); return
    }

    # [CODE] prefix
    if ($text -match '^\[CODE\]\s*(.+)') {
        $code = $Matches[1]; $InputBox.Clear()
        Invoke-SkillAsync "Code_Sandbox" "Code Sandbox" "-Code `"$code`""
        return
    }

    # [OCR] prefix
    if ($text -match '^\[OCR\]') {
        $InputBox.Clear()
        Invoke-SkillAsync "OCR_Extract" "OCR" "-CaptureScreen"
        return
    }

    # [YTLEARN] prefix
    if ($text -match '^\[YTLEARN\]\s*(.+)') {
        $url = $Matches[1]; $InputBox.Clear()
        Invoke-SkillAsync "YT_AutoLearn" "YT AutoLearn" "-Url $url"
        return
    }

    # [TERMINAL] prefix
    if ($text -match '^\[TERMINAL\]\s*(.+)') {
        $cmd = $Matches[1]; $InputBox.Clear()
        Add-ChatBubble "YOU" "Terminal: $cmd" "user"
        Invoke-SkillAsync "Terminal_Exec" "Terminal" "-Action RUN -Command `"$cmd`""
        return
    }

    # [NOTE] prefix
    if ($text -match '^\[NOTE\]\s*(.+)') {
        $noteText = $Matches[1]; $InputBox.Clear()
        if ($noteText -match '^list') { Invoke-SkillAsync "Notes_System" "Notes" "-Action LIST" }
        elseif ($noteText -match '^create\s+(.+)') { Invoke-SkillAsync "Notes_System" "Notes" "-Action CREATE -Title `"$($Matches[1])`"" }
        elseif ($noteText -match '^read\s+(.+)') { Invoke-SkillAsync "Notes_System" "Notes" "-Action READ -NoteId `"$($Matches[1])`"" }
        else { Invoke-SkillAsync "Notes_System" "Notes" "-Action CREATE -Title `"Quick Note`" -Content `"$noteText`"" }
        return
    }

    # [WEBUI] prefix
    if ($text -match '^\[WEBUI\]\s*(.*)') {
        $cmd = if ($Matches[1]) { $Matches[1].Trim().ToUpper() } else { "STATUS" }
        $InputBox.Clear()
        Invoke-SkillAsync "OpenWebUI_Bridge" "Open WebUI" "-Action $cmd"
        return
    }

    # [DAEMON] prefix
    if ($text -match '^\[DAEMON\]\s*(.*)') {
        $cmd = if ($Matches[1]) { $Matches[1].Trim() } else { "STATUS" }
        $InputBox.Clear()
        Invoke-SkillAsync "Daemon_Service" "Daemon" "-Action $($cmd.ToUpper())"
        return
    }

    # Normal message
    & $SendAction
})

# --- 9. SIDEBAR BUTTON HANDLERS ---
$sideButtons["BtnChat"].Add_Click({ Invoke-JS "clearChat(); showWelcome();"; $script:MessageCount = 0 })
$sideButtons["BtnBrowser"].Add_Click({ $InputBox.Text = "[BROWSER] open "; $InputBox.Focus(); $InputBox.CaretIndex = $InputBox.Text.Length; Add-ChatBubble "SYSTEM" "Type a URL after [BROWSER] open. Commands: open, go, screenshot, click X Y, find, type, js, vision, stop" "system" })
$sideButtons["BtnBrowserVision"].Add_Click({ Invoke-SkillAsync "Browser_Vision" "Browser Vision" })
$sideButtons["BtnCrawler"].Add_Click({ $InputBox.Text = "[CRAWL] "; $InputBox.Focus(); $InputBox.CaretIndex = $InputBox.Text.Length; Add-ChatBubble "SYSTEM" "Type a folder path or: search query, read filepath, approve path, status" "system" })
$sideButtons["BtnRAG"].Add_Click({ $InputBox.Text = "[SEARCH] "; $InputBox.Focus(); $InputBox.CaretIndex = $InputBox.Text.Length })
$sideButtons["BtnArchitect"].Add_Click({ Invoke-SkillAsync "Architect_Review" "Architect Review" })
$sideButtons["BtnChain"].Add_Click({ $InputBox.Text = ""; $InputBox.Focus(); Add-ChatBubble "SYSTEM" "Enter prompts separated by semicolons for a multi-step chain. Example: Research Vue 3; Analyze best practices; Summarize in 3 points" "system" })
$sideButtons["BtnSandbox"].Add_Click({ $InputBox.Text = "[CODE] "; $InputBox.Focus(); $InputBox.CaretIndex = $InputBox.Text.Length; Add-ChatBubble "SYSTEM" "Type PowerShell code after [CODE] to execute in sandbox." "system" })
$sideButtons["BtnOCR"].Add_Click({ Invoke-SkillAsync "OCR_Extract" "OCR Extract" "-CaptureScreen" })
$sideButtons["BtnClipboard"].Add_Click({ Invoke-SkillAsync "Clipboard_Bridge" "Clipboard" "-Action ANALYZE" })
$sideButtons["BtnHealth"].Add_Click({ Invoke-SkillAsync "Daemon_Health" "Health Check" })
$sideButtons["BtnDaemon"].Add_Click({ Invoke-SkillAsync "Daemon_Service" "Daemon" "-Action STATUS" })
$sideButtons["BtnSecurity"].Add_Click({ Invoke-SkillAsync "Security_Scan" "Security Scan" })
$sideButtons["BtnGitSync"].Add_Click({ Invoke-SkillAsync "Sovereign_GitSync" "Git Sync" })
$sideButtons["BtnGPU"].Add_Click({ Invoke-SkillAsync "Get_GPU_Status" "GPU Status" })
$sideButtons["BtnWindows"].Add_Click({ Invoke-SkillAsync "Window_Manager" "Window Manager" "-Action LIST" })
$sideButtons["BtnMemory"].Add_Click({ Invoke-SkillAsync "Memory_Graph" "Memory Graph" })
$sideButtons["BtnVoice"].Add_Click({ Start-Job -ScriptBlock { param($p); & powershell -ExecutionPolicy Bypass -File $p -Action Speak -Text "OpenClaw V3 Sovereign Intelligence active." 2>&1 } -ArgumentList (Join-Path $SkillsDir "Voice_Sovereign.ps1"); Add-ChatBubble "VOICE" "Speaking..." "system" })
$sideButtons["BtnYTLearn"].Add_Click({ $InputBox.Text = "[YTLEARN] "; $InputBox.Focus(); $InputBox.CaretIndex = $InputBox.Text.Length })
$sideButtons["BtnJournal"].Add_Click({ Invoke-SkillAsync "Activity_Journal" "Activity Journal" "-Action TODAY" })
$sideButtons["BtnTasks"].Add_Click({ Invoke-SkillAsync "Task_Scheduler" "Task Scheduler" "-Action LIST" })
$sideButtons["BtnSearch"].Add_Click({ $InputBox.Text = "[SEARCH] "; $InputBox.Focus(); $InputBox.CaretIndex = $InputBox.Text.Length })
$sideButtons["BtnKnowledge"].Add_Click({
    $kDir = Join-Path $PSScriptRoot "knowledge"; $sDir = Join-Path $SystemRoot "knowledge"
    $files = @(); if (Test-Path $kDir) { $files += Get-ChildItem $kDir -Filter "*.md" }; if (Test-Path $sDir) { $files += Get-ChildItem $sDir -Filter "*.md" }
    $list = if ($files.Count) { ($files | ForEach-Object { "- $($_.Name) ($([math]::Round($_.Length/1024,1))KB)" }) -join "`n" } else { "No knowledge files." }
    Add-ChatBubble "KNOWLEDGE VAULT" "Found $($files.Count) files:`n$list" "ai"
})
$sideButtons["BtnExport"].Add_Click({
    $dir = Join-Path $PSScriptRoot "exports"; if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $f = Join-Path $dir "chat_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    try { $h = $ChatView.Document.Body.OuterHtml; Set-Content $f "<html><head><meta charset='utf-8'><style>body{background:#060607;color:#C8C8CC;font-family:Segoe UI;padding:20px}</style></head><body>$h</body></html>" -Encoding UTF8
        Add-ChatBubble "EXPORT" "Saved: $f" "system" } catch { Add-ChatBubble "EXPORT" "Failed." "system" }
})
$sideButtons["BtnHotkeys"].Add_Click({ Invoke-SkillAsync "Hotkey_Commander" "Hotkeys" "-Action LIST" })

# --- V3.1 INTEGRATION BUTTONS ---
$sideButtons["BtnWebUI"].Add_Click({ Invoke-SkillAsync "OpenWebUI_Bridge" "Open WebUI" "-Action STATUS" })
$sideButtons["BtnGateway"].Add_Click({ Invoke-SkillAsync "Gateway_Client" "Gateway" "-Action STATUS" })
$sideButtons["BtnCanvas"].Add_Click({ Invoke-SkillAsync "Canvas_Renderer" "Canvas" "-Action CARD -Title `"OpenClaw Status`" -Content `"System operational. All skills loaded.`" -Type success" })
$sideButtons["BtnScreenPro"].Add_Click({ Invoke-SkillAsync "Screen_Capture_Pro" "Screen Capture" "-Action FULL" })
$sideButtons["BtnPipeline"].Add_Click({ Invoke-SkillAsync "Pipeline_Router" "Pipeline" "-Action LIST" })
$sideButtons["BtnNotes"].Add_Click({ Invoke-SkillAsync "Notes_System" "Notes" "-Action LIST" })
$sideButtons["BtnTerminal"].Add_Click({ $InputBox.Text = "[TERMINAL] "; $InputBox.Focus(); $InputBox.CaretIndex = $InputBox.Text.Length; Add-ChatBubble "SYSTEM" "Type a command after [TERMINAL]. Supports PowerShell, cmd, node, python." "system" })
$sideButtons["BtnMultiModel"].Add_Click({ Invoke-SkillAsync "Multi_Model" "Model Compare" "-Action BENCHMARK" })
$sideButtons["BtnDeepLink"].Add_Click({ Invoke-SkillAsync "Deep_Link" "Deep Links" "-Action STATUS" })
$sideButtons["BtnAnalytics"].Add_Click({ Invoke-SkillAsync "Usage_Analytics" "Analytics" "-Action REPORT" })

# --- 10. WINDOW CONTROLS ---
$Window.Add_MouseLeftButtonDown({ $Window.DragMove() })
$MinBtn.Add_Click({ $Window.WindowState = "Minimized" })
$MaxBtn.Add_Click({ $Window.WindowState = if ($Window.WindowState -eq "Maximized") { "Normal" } else { "Maximized" } })
$CloseBtn.Add_Click({ $Window.Close() })

# --- 11. GPU TIMER ---
$gpuTimer = New-Object System.Windows.Threading.DispatcherTimer
$gpuTimer.Interval = [TimeSpan]::FromSeconds(5)
$gpuTimer.Add_Tick({
    $gs = Join-Path $SystemRoot "OpenClaw_Skills\Get_GPU_Status.ps1"
    if (Test-Path $gs) { $raw = & powershell -ExecutionPolicy Bypass -File $gs 2>$null
        if ($raw) { try { $s = $raw | ConvertFrom-Json; $GpuStatus.Text = "GPU:$($s.Utilization)% VRAM:$($s.UsedPercent)%"
            $GpuStatus.Foreground = if ([int]$s.UsedPercent -gt 85) { [System.Windows.Media.Brushes]::Red } else { [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(68,68,68)) }
        } catch {} } }
})

# --- 12. MODEL SELECT ---
$ModelSelect.Items.Add("gemma4:e2b") | Out-Null; $ModelSelect.Items.Add("gemma4:e4b") | Out-Null; $ModelSelect.SelectedIndex = 0
$ModelSelect.Add_SelectionChanged({ $script:ActiveModel = $ModelSelect.SelectedItem; $ModelLabel.Text = "Model: $($script:ActiveModel)" })

# --- 13. BOOT ---
$Window.Add_Loaded({
    $BootLog.Text = "Connecting to Ollama..."; $BootProgress.Value = 15
    $ok = $false; try { $t = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3; $ok = $true; $script:OllamaOnline = $true } catch {}
    $BootProgress.Value = 35; $BootLog.Text = if ($ok) { "Models loaded." } else { "Ollama offline." }

    if ($ok -and $t.models) { $ModelSelect.Items.Clear(); foreach ($m in $t.models) { $ModelSelect.Items.Add($m.name) | Out-Null }
        if ($ModelSelect.Items.Count -gt 0) { $ModelSelect.SelectedIndex = 0; $script:ActiveModel = $ModelSelect.Items[0] } }

    $BootProgress.Value = 55; $BootLog.Text = "Checking GPU..."
    $gs = Join-Path $SystemRoot "OpenClaw_Skills\Get_GPU_Status.ps1"
    $gr = & powershell -ExecutionPolicy Bypass -File $gs 2>$null
    if ($gr) { try { $g = $gr | ConvertFrom-Json; $GpuStatus.Text = "GPU:$($g.Utilization)% VRAM:$($g.UsedPercent)%" } catch {} }

    $BootProgress.Value = 75; $BootLog.Text = "Loading 25 skills..."
    $skillCount = (Get-ChildItem $SkillsDir -Filter "*.ps1" -ErrorAction SilentlyContinue).Count
    $FooterRight.Text = "$skillCount skills loaded"

    $BootProgress.Value = 100; $BootLog.Text = "SOVEREIGN ONLINE"
    $StatusIndicator.Text = if ($ok) { [char]0x25CF + " Online" } else { [char]0x25CF + " Offline" }
    $StatusIndicator.Foreground = if ($ok) { [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0,180,70)) } else { [System.Windows.Media.Brushes]::Red }

    $BootOverlay.Visibility = "Collapsed"
    $gpuTimer.Start()
    Invoke-JS "showWelcome();"
    $InputBox.Focus()
})

$Window.ShowDialog() | Out-Null
