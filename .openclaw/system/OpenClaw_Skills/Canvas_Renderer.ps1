# OPENCLAW SKILL: CANVAS RENDERER [V1.0]
# =========================================
# [PURPOSE]: Render rich UI cards and A2UI interfaces in chat/HTML
# [SOURCE]: Inspired by openclaw-windows-node canvas.present/canvas.a2ui
# [ACTIONS]: RENDER, CARD, TABLE, CHART, FORM, EXPORT

param(
    [string]$Action = "CARD",
    [string]$Title = "OpenClaw Card",
    [string]$Content = "",
    [string]$Type = "info",      # info, success, warning, error, metric
    [string]$Data = "",          # JSON data for tables/charts
    [string]$OutputPath = ""
)

$OutputDir = Join-Path $PSScriptRoot "..\..\archive\canvas"
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
if (-not $OutputPath) { $OutputPath = Join-Path $OutputDir "canvas_$ts.html" }

$ColorMap = @{
    info    = @{ bg = "#0C1020"; border = "#1A3A6A"; accent = "#3B82F6"; icon = "&#x2139;" }
    success = @{ bg = "#0C200C"; border = "#1A6A1A"; accent = "#22C55E"; icon = "&#x2713;" }
    warning = @{ bg = "#201A0C"; border = "#6A4A1A"; accent = "#F59E0B"; icon = "&#x26A0;" }
    error   = @{ bg = "#200C0C"; border = "#6A1A1A"; accent = "#EF4444"; icon = "&#x2717;" }
    metric  = @{ bg = "#0C0C20"; border = "#1A1A6A"; accent = "#8B5CF6"; icon = "&#x1F4CA;" }
}

$colors = if ($ColorMap.ContainsKey($Type)) { $ColorMap[$Type] } else { $ColorMap["info"] }

switch ($Action.ToUpper()) {
    "CARD" {
        $html = @"
<!DOCTYPE html>
<html><head><meta charset="utf-8"><style>
  body { background: #060608; margin: 0; padding: 30px; font-family: 'Segoe UI', sans-serif; }
  .card {
    background: $($colors.bg); border: 1px solid $($colors.border); border-left: 4px solid $($colors.accent);
    border-radius: 12px; padding: 24px 28px; max-width: 600px; margin: 0 auto;
    box-shadow: 0 4px 24px rgba(0,0,0,0.3);
  }
  .card-header { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; }
  .card-icon { font-size: 24px; width: 40px; height: 40px; display: flex; align-items: center; justify-content: center;
    background: $($colors.accent)15; border-radius: 8px; }
  .card-title { color: $($colors.accent); font-size: 14px; font-weight: 800; text-transform: uppercase; letter-spacing: 1.5px; }
  .card-content { color: #C8C8CC; font-size: 14px; line-height: 1.7; }
  .card-footer { margin-top: 16px; padding-top: 12px; border-top: 1px solid #1A1A1E;
    color: #555; font-size: 10px; font-family: Consolas; }
</style></head><body>
<div class="card">
  <div class="card-header">
    <div class="card-icon">$($colors.icon)</div>
    <div class="card-title">$Title</div>
  </div>
  <div class="card-content">$Content</div>
  <div class="card-footer">OpenClaw Canvas &bull; $(Get-Date -Format "yyyy-MM-dd HH:mm") &bull; $Type</div>
</div>
</body></html>
"@
        Set-Content -Path $OutputPath -Value $html -Encoding UTF8
        Write-Output "[CANVAS] Card rendered: $OutputPath"
        Write-Output "CANVAS_HTML:$html"
    }

    "TABLE" {
        if (-not $Data) { Write-Output "[CANVAS] Provide -Data (JSON array)."; break }
        try {
            $rows = $Data | ConvertFrom-Json
            $headers = $rows[0].PSObject.Properties.Name
            $headerHtml = ($headers | ForEach-Object { "<th>$_</th>" }) -join ""
            $rowsHtml = ($rows | ForEach-Object {
                $r = $_; "<tr>$(($headers | ForEach-Object { "<td>$($r.$_)</td>" }) -join '')</tr>"
            }) -join "`n"

            $html = @"
<!DOCTYPE html>
<html><head><meta charset="utf-8"><style>
  body { background: #060608; padding: 20px; font-family: 'Segoe UI', sans-serif; color: #C8C8CC; }
  table { border-collapse: collapse; width: 100%; }
  th { background: #111; color: #FF3333; text-transform: uppercase; font-size: 10px; letter-spacing: 1px;
    padding: 10px 14px; text-align: left; border-bottom: 2px solid #222; }
  td { padding: 8px 14px; border-bottom: 1px solid #151518; font-size: 13px; }
  tr:hover td { background: #0A0A0E; }
  h3 { color: #888; font-size: 12px; margin-bottom: 12px; }
</style></head><body>
<h3>$Title</h3>
<table><thead><tr>$headerHtml</tr></thead><tbody>$rowsHtml</tbody></table>
</body></html>
"@
            Set-Content -Path $OutputPath -Value $html -Encoding UTF8
            Write-Output "[CANVAS] Table rendered: $OutputPath ($($rows.Count) rows)"
        } catch { Write-Output "[CANVAS] Invalid JSON data: $($_.Exception.Message)" }
    }

    "CHART" {
        # Simple bar chart via HTML/CSS (no JS dependency)
        if (-not $Data) { Write-Output "[CANVAS] Provide -Data (JSON: [{label:'x',value:10},...])."; break }
        try {
            $items = $Data | ConvertFrom-Json
            $maxVal = ($items | Measure-Object -Property value -Maximum).Maximum
            if ($maxVal -eq 0) { $maxVal = 1 }
            $barsHtml = ($items | ForEach-Object {
                $pct = [math]::Round(($_.value / $maxVal) * 100)
                "<div class='bar-row'><span class='label'>$($_.label)</span><div class='bar-bg'><div class='bar' style='width:${pct}%'></div></div><span class='val'>$($_.value)</span></div>"
            }) -join "`n"

            $html = @"
<!DOCTYPE html>
<html><head><meta charset="utf-8"><style>
  body { background: #060608; padding: 24px; font-family: 'Segoe UI', sans-serif; color: #C8C8CC; }
  h3 { color: #888; font-size: 12px; margin-bottom: 16px; }
  .bar-row { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
  .label { width: 100px; font-size: 11px; color: #888; text-align: right; }
  .bar-bg { flex: 1; height: 20px; background: #111; border-radius: 4px; overflow: hidden; }
  .bar { height: 100%; background: linear-gradient(90deg, #CC0000, #FF3333); border-radius: 4px;
    transition: width 0.5s ease; }
  .val { width: 50px; font-size: 11px; color: #CC0000; font-family: Consolas; }
</style></head><body>
<h3>$Title</h3>
$barsHtml
</body></html>
"@
            Set-Content -Path $OutputPath -Value $html -Encoding UTF8
            Write-Output "[CANVAS] Chart rendered: $OutputPath"
        } catch { Write-Output "[CANVAS] Invalid data: $($_.Exception.Message)" }
    }

    "EXPORT" {
        $files = Get-ChildItem $OutputDir -Filter "canvas_*.html" -ErrorAction SilentlyContinue
        if ($files.Count -eq 0) { Write-Output "[CANVAS] No rendered canvases found."; break }
        $output = "[CANVAS EXPORTS] $($files.Count) files:`n"
        foreach ($f in ($files | Sort-Object LastWriteTime -Descending | Select-Object -First 10)) {
            $output += "  $($f.Name) ($([math]::Round($f.Length/1024,1))KB) - $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))`n"
        }
        Write-Output $output
    }

    default { Write-Output "Use: CARD, TABLE, CHART, EXPORT" }
}
