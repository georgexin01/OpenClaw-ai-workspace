# OPENCLAW SKILL: RAG INDEX [V1.0]
# [PURPOSE]: Local retrieval-augmented generation — TF-IDF over crawled files

param(
    [string]$Action = "QUERY",  # BUILD, QUERY, STATUS
    [string]$Query = "",
    [int]$TopK = 3
)

$BridgeDir = Join-Path $PSScriptRoot "..\skills_bridge"
$IndexPath = Join-Path $BridgeDir "file_index.json"
$RAGPath = Join-Path $BridgeDir "rag_chunks.json"
$TextExts = @(".txt",".md",".ps1",".json",".csv",".log",".xml",".html",".py",".js",".ts",".css",".yml",".yaml")

function Build-RAGIndex {
    if (-not (Test-Path $IndexPath)) { Write-Output "[RAG] No file index found. Run File_Crawler first."; return }
    $index = Get-Content $IndexPath | ConvertFrom-Json
    $chunks = @()

    foreach ($f in $index.files) {
        if ($f.ext -notin $TextExts) { continue }
        if ($f.size_kb -gt 200) { continue }  # Skip large files
        if (-not (Test-Path $f.path)) { continue }

        try {
            $content = Get-Content $f.path -Raw -ErrorAction Stop
            if (-not $content -or $content.Length -lt 20) { continue }

            # Split into chunks of ~500 chars
            $words = $content -split '\s+' | Where-Object { $_.Length -gt 2 }
            $chunkSize = 80  # words per chunk
            for ($i = 0; $i -lt $words.Count; $i += $chunkSize) {
                $chunk = ($words[$i..[Math]::Min($i + $chunkSize - 1, $words.Count - 1)]) -join " "
                $chunks += @{
                    file = $f.name
                    path = $f.path
                    text = $chunk
                    words = ($chunk.ToLower() -split '\s+' | Sort-Object -Unique)
                }
            }
        } catch {}
    }

    @{ version = "1.0"; built = (Get-Date -Format "o"); chunk_count = $chunks.Count; chunks = $chunks } |
        ConvertTo-Json -Depth 5 -Compress | Set-Content $RAGPath -Force

    Write-Output "[RAG] Index built: $($chunks.Count) chunks from $($index.total_files) files."
}

function Search-RAG([string]$SearchQuery, [int]$K) {
    if (-not (Test-Path $RAGPath)) { Write-Output "[RAG] No index. Run -Action BUILD first."; return }

    $rag = Get-Content $RAGPath | ConvertFrom-Json
    $queryWords = $SearchQuery.ToLower() -split '\s+' | Where-Object { $_.Length -gt 2 } | Sort-Object -Unique

    # Simple TF-IDF scoring
    $scored = foreach ($chunk in $rag.chunks) {
        $overlap = ($queryWords | Where-Object { $chunk.words -contains $_ }).Count
        if ($overlap -gt 0) {
            @{ score = $overlap; file = $chunk.file; path = $chunk.path; text = $chunk.text }
        }
    }

    $top = $scored | Sort-Object { $_.score } -Descending | Select-Object -First $K
    if ($top.Count -eq 0) { return "[RAG] No relevant chunks found for: $SearchQuery" }

    $context = ($top | ForEach-Object { "[From: $($_.file)]`n$($_.text)" }) -join "`n---`n"

    # Query AI with context
    $enginePath = Join-Path $PSScriptRoot "..\..\OpenClaw_Engine.ps1"
    . $enginePath
    $prompt = "Using ONLY the following context from local files, answer the question. If the context doesn't contain the answer, say so.`n`nCONTEXT:`n$context`n`nQUESTION: $SearchQuery"
    $answer = Invoke-OClawQuery $prompt 1

    return "[RAG ANSWER]`nSources: $($top | ForEach-Object { $_.file } | Select-Object -Unique | Out-String)`n$answer"
}

switch ($Action.ToUpper()) {
    "BUILD" { Build-RAGIndex }
    "QUERY" {
        if (-not $Query) { Write-Output "[RAG] Provide -Query parameter."; break }
        Write-Output (Search-RAG $Query $TopK)
    }
    "STATUS" {
        if (Test-Path $RAGPath) {
            $rag = Get-Content $RAGPath | ConvertFrom-Json
            Write-Output "[RAG STATUS] Chunks: $($rag.chunk_count) | Built: $($rag.built)"
        } else {
            Write-Output "[RAG] No index built yet. Use -Action BUILD."
        }
    }
    default { Write-Output "Use: BUILD, QUERY, STATUS" }
}
