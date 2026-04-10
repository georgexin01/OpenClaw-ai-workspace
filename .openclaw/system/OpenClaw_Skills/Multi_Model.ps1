# OPENCLAW SKILL: MULTI-MODEL COMPARE [V1.0]
# ==============================================
# [PURPOSE]: Send same prompt to multiple models side-by-side
# [SOURCE]: Inspired by Open WebUI multi-model chat feature
# [ACTIONS]: COMPARE, LIST_MODELS, BENCHMARK

param(
    [string]$Action = "LIST_MODELS",
    [string]$Prompt = "",
    [string]$Models = "",        # Comma-separated model names
    [int]$TimeoutSec = 120
)

$OllamaUrl = "http://localhost:11434"

function Get-AvailableModels {
    try {
        $tags = Invoke-RestMethod -Uri "$OllamaUrl/api/tags" -TimeoutSec 3
        return $tags.models | ForEach-Object { $_.name }
    } catch { return @() }
}

function Invoke-ModelQuery([string]$Model, [string]$QueryPrompt) {
    $body = @{
        model = $Model
        prompt = $QueryPrompt
        stream = $false
        options = @{ num_ctx = 2048 }
    } | ConvertTo-Json -Compress

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $resp = Invoke-RestMethod -Uri "$OllamaUrl/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec $TimeoutSec
        $sw.Stop()
        $tps = if ($resp.eval_count -and $resp.eval_duration) { [math]::Round($resp.eval_count / ($resp.eval_duration / 1e9), 1) } else { 0 }
        return @{
            model = $Model
            response = $resp.response
            tokens = $resp.eval_count
            time_sec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
            tokens_per_sec = $tps
            success = $true
        }
    } catch {
        $sw.Stop()
        return @{
            model = $Model
            response = "ERROR: $($_.Exception.Message)"
            tokens = 0
            time_sec = [math]::Round($sw.Elapsed.TotalSeconds, 1)
            tokens_per_sec = 0
            success = $false
        }
    }
}

switch ($Action.ToUpper()) {
    "LIST_MODELS" {
        $models = Get-AvailableModels
        if ($models.Count -eq 0) { Write-Output "[MODELS] No models found. Is Ollama running?"; break }
        $output = "[AVAILABLE MODELS] $($models.Count):`n"
        foreach ($m in $models) {
            $output += "  - $m`n"
        }
        $output += "`nUse: -Action COMPARE -Prompt `"your question`" -Models `"model1,model2`""
        Write-Output $output
    }

    "COMPARE" {
        if (-not $Prompt) { Write-Output "[COMPARE] Provide -Prompt."; break }

        $modelList = if ($Models) { $Models -split "," | ForEach-Object { $_.Trim() } }
                     else { Get-AvailableModels }

        if ($modelList.Count -lt 2) { Write-Output "[COMPARE] Need at least 2 models. Available: $(Get-AvailableModels -join ', ')"; break }

        Write-Host "[COMPARE] Testing $($modelList.Count) models..." -ForegroundColor Cyan
        $results = @()

        foreach ($model in $modelList) {
            Write-Host "  Querying $model..." -ForegroundColor Yellow
            $result = Invoke-ModelQuery $model $Prompt
            $results += $result
        }

        # Format comparison output
        $output = "[MODEL COMPARISON]`nPrompt: $($Prompt.Substring(0, [Math]::Min(80, $Prompt.Length)))...`n"
        $output += "=" * 60 + "`n"

        foreach ($r in $results) {
            $statusIcon = if ($r.success) { "[OK]" } else { "[FAIL]" }
            $output += "`n$statusIcon $($r.model) — $($r.time_sec)s | $($r.tokens) tokens | $($r.tokens_per_sec) t/s`n"
            $output += "-" * 40 + "`n"
            $respPreview = $r.response.Substring(0, [Math]::Min(300, $r.response.Length))
            $output += "$respPreview`n"
        }

        # Winner
        $fastest = $results | Where-Object { $_.success } | Sort-Object { $_.time_sec } | Select-Object -First 1
        if ($fastest) {
            $output += "`n" + "=" * 60
            $output += "`nFASTEST: $($fastest.model) ($($fastest.time_sec)s, $($fastest.tokens_per_sec) t/s)"
        }

        Write-Output $output
    }

    "BENCHMARK" {
        $models = Get-AvailableModels
        if ($models.Count -eq 0) { Write-Output "[BENCHMARK] No models available."; break }

        $testPrompt = "What is the capital of France? One word only."
        Write-Host "[BENCHMARK] Testing $($models.Count) models with simple query..." -ForegroundColor Cyan

        $results = @()
        foreach ($m in $models) {
            $r = Invoke-ModelQuery $m $testPrompt
            $results += $r
            Write-Host "  $m: $($r.time_sec)s | $($r.tokens_per_sec) t/s | $($r.response.Trim().Substring(0, [Math]::Min(30, $r.response.Length)))" -ForegroundColor Gray
        }

        $output = "[BENCHMARK RESULTS]`n"
        foreach ($r in ($results | Sort-Object { $_.tokens_per_sec } -Descending)) {
            $bar = "#" * [math]::Min(40, [int]$r.tokens_per_sec)
            $output += "  $($r.model.PadRight(20)) $($r.tokens_per_sec.ToString().PadLeft(6)) t/s | $bar`n"
        }
        Write-Output $output
    }

    default { Write-Output "Use: COMPARE, LIST_MODELS, BENCHMARK" }
}
