# OPENCLAW SKILL: FILE CRAWLER [V1.0]
# =====================================
# [PURPOSE]: Index, search, and read local files from approved directories
# [ACTIONS]: CRAWL, SEARCH, READ, APPROVE, REVOKE, LIST_APPROVED, STATUS

param(
    [string]$Action = "STATUS",
    [string]$Path = "",
    [string]$Query = "",
    [string]$FileType = "",
    [int]$MaxResults = 25,
    [int]$MaxDepth = 5,
    [int]$MaxReadKB = 100
)

$BridgeDir = Join-Path $PSScriptRoot "..\skills_bridge"
$IndexPath = Join-Path $BridgeDir "file_index.json"
$PermPath = Join-Path $BridgeDir "crawler_permissions.json"

# Text file extensions we can read
$TextExts = @(".txt",".md",".ps1",".json",".csv",".log",".xml",".html",".htm",".py",".js",".ts",".css",".yml",".yaml",".toml",".ini",".cfg",".bat",".cmd",".sh",".sql",".env",".gitignore",".vue",".jsx",".tsx")

# Directories to always skip
$SkipDirs = @("node_modules",".git","__pycache__",".next","dist","build",".nuxt",".output","vendor","packages","cache")

# --- PERMISSION SYSTEM ---
function Get-ApprovedPaths {
    if (Test-Path $PermPath) {
        return (Get-Content $PermPath | ConvertFrom-Json).approved_paths
    }
    # Default: Desktop only
    $default = @{ approved_paths = @("$env:USERPROFILE\Desktop"); created = (Get-Date -Format "o") }
    $default | ConvertTo-Json | Set-Content $PermPath -Force
    return $default.approved_paths
}

function Test-PathApproved([string]$CheckPath) {
    $approved = Get-ApprovedPaths
    $resolved = (Resolve-Path $CheckPath -ErrorAction SilentlyContinue).Path
    if (-not $resolved) { return $false }
    foreach ($ap in $approved) {
        $apResolved = (Resolve-Path $ap -ErrorAction SilentlyContinue).Path
        if ($apResolved -and $resolved.StartsWith($apResolved, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

# --- CRAWL ---
function Invoke-Crawl([string]$CrawlPath, [int]$Depth) {
    if (-not (Test-Path $CrawlPath)) { return "Path not found: $CrawlPath" }
    if (-not (Test-PathApproved $CrawlPath)) { return "PATH NOT APPROVED. Use Action=APPROVE first to grant permission for: $CrawlPath" }

    Write-Host "[CRAWLER] Indexing: $CrawlPath (depth=$Depth)..." -ForegroundColor Cyan

    $files = Get-ChildItem -Path $CrawlPath -Recurse -File -Depth $Depth -ErrorAction SilentlyContinue |
        Where-Object { $skip = $false; foreach ($sd in $SkipDirs) { if ($_.FullName -match [regex]::Escape($sd)) { $skip = $true; break } }; -not $skip } |
        Select-Object -First 5000

    $entries = @()
    foreach ($f in $files) {
        $entries += @{
            name = $f.Name
            path = $f.FullName
            ext = $f.Extension.ToLower()
            size_kb = [math]::Round($f.Length / 1024, 1)
            modified = $f.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            parent = $f.DirectoryName
        }
    }

    # Load existing index or create new
    $index = @{
        version = "1.0"
        last_crawl = (Get-Date -Format "o")
        total_files = $entries.Count
        crawled_path = $CrawlPath
        files = $entries
    }

    # Merge with existing index if different paths
    if (Test-Path $IndexPath) {
        try {
            $existing = Get-Content $IndexPath | ConvertFrom-Json
            $existingFiles = @($existing.files | Where-Object { -not $_.path.StartsWith($CrawlPath, [StringComparison]::OrdinalIgnoreCase) })
            $index.files = $existingFiles + $entries
            $index.total_files = $index.files.Count
        } catch {}
    }

    $index | ConvertTo-Json -Depth 5 -Compress | Set-Content $IndexPath -Force

    $byType = $entries | Group-Object ext | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object { "  $($_.Name): $($_.Count) files" }
    $totalSize = [math]::Round(($entries | Measure-Object -Property size_kb -Sum).Sum / 1024, 1)

    return @"
[CRAWL COMPLETE]
Path: $CrawlPath
Files indexed: $($entries.Count)
Total size: ${totalSize}MB
Top file types:
$($byType -join "`n")
"@
}

# --- SEARCH ---
function Invoke-Search([string]$SearchQuery, [string]$TypeFilter, [int]$Max) {
    if (-not (Test-Path $IndexPath)) { return "No index found. Run CRAWL first." }

    $index = Get-Content $IndexPath | ConvertFrom-Json
    $pattern = $SearchQuery -replace '\*', '.*' -replace '\?', '.'

    $results = $index.files | Where-Object {
        $match = $_.name -match $pattern -or $_.path -match $pattern
        if ($TypeFilter) { $match = $match -and ($_.ext -eq $TypeFilter -or $_.ext -eq ".$TypeFilter") }
        $match
    } | Select-Object -First $Max

    if ($results.Count -eq 0) { return "No files found matching: $SearchQuery" }

    $output = "[SEARCH RESULTS] Found $($results.Count) files:`n"
    foreach ($r in $results) {
        $output += "  [$($r.ext)] $($r.name) ($($r.size_kb)KB) - $($r.modified)`n    $($r.path)`n"
    }
    return $output
}

# --- READ ---
function Invoke-Read([string]$FilePath, [int]$MaxKB) {
    if (-not (Test-Path $FilePath)) { return "File not found: $FilePath" }
    if (-not (Test-PathApproved $FilePath)) { return "PATH NOT APPROVED. The file's folder must be in the approved list." }

    $file = Get-Item $FilePath
    $ext = $file.Extension.ToLower()

    if ($ext -notin $TextExts) {
        return "[FILE INFO] $($file.Name) | Type: $ext | Size: $([math]::Round($file.Length/1024,1))KB | Modified: $($file.LastWriteTime) | (Binary file - content not readable)"
    }

    $sizeKB = [math]::Round($file.Length / 1024, 1)
    if ($sizeKB -gt $MaxKB) {
        $content = Get-Content $FilePath -TotalCount ([math]::Max(1, [int]($MaxKB * 15))) -ErrorAction SilentlyContinue
        $content = $content -join "`n"
        return "[FILE: $($file.Name)] (Truncated to ~${MaxKB}KB of ${sizeKB}KB)`n---`n$content`n---`n[TRUNCATED]"
    }

    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    return "[FILE: $($file.Name)] (${sizeKB}KB)`n---`n$content"
}

# --- MAIN DISPATCH ---
switch ($Action.ToUpper()) {
    "CRAWL" {
        if (-not $Path) { $Path = "$env:USERPROFILE\Desktop" }
        Write-Output (Invoke-Crawl $Path $MaxDepth)
    }
    "SEARCH" {
        if (-not $Query) { Write-Output "Provide -Query parameter."; break }
        Write-Output (Invoke-Search $Query $FileType $MaxResults)
    }
    "READ" {
        if (-not $Path) { Write-Output "Provide -Path parameter."; break }
        Write-Output (Invoke-Read $Path $MaxReadKB)
    }
    "APPROVE" {
        if (-not $Path) { Write-Output "Provide folder -Path to approve."; break }
        if (-not (Test-Path $Path)) { Write-Output "Path does not exist: $Path"; break }
        # Block system dirs
        $blocked = @("C:\Windows","C:\Program Files","C:\Program Files (x86)")
        foreach ($b in $blocked) { if ($Path.StartsWith($b, [StringComparison]::OrdinalIgnoreCase)) { Write-Output "BLOCKED: Cannot approve system directory: $Path"; exit 1 } }
        $perms = if (Test-Path $PermPath) { Get-Content $PermPath | ConvertFrom-Json } else { @{ approved_paths = @() } }
        if ($Path -notin $perms.approved_paths) { $perms.approved_paths += $Path }
        $perms | ConvertTo-Json | Set-Content $PermPath -Force
        Write-Output "[APPROVED] Folder added to crawler permissions: $Path"
    }
    "REVOKE" {
        if (-not $Path) { Write-Output "Provide folder -Path to revoke."; break }
        $perms = if (Test-Path $PermPath) { Get-Content $PermPath | ConvertFrom-Json } else { @{ approved_paths = @() } }
        $perms.approved_paths = @($perms.approved_paths | Where-Object { $_ -ne $Path })
        $perms | ConvertTo-Json | Set-Content $PermPath -Force
        Write-Output "[REVOKED] Folder removed: $Path"
    }
    "LIST_APPROVED" {
        $paths = Get-ApprovedPaths
        Write-Output "[APPROVED FOLDERS]`n$($paths | ForEach-Object { "  - $_" } | Out-String)"
    }
    "STATUS" {
        $approved = Get-ApprovedPaths
        $hasIndex = Test-Path $IndexPath
        $count = 0
        if ($hasIndex) { try { $count = (Get-Content $IndexPath | ConvertFrom-Json).total_files } catch {} }
        Write-Output "[CRAWLER STATUS]`nApproved folders: $($approved.Count)`nIndex exists: $hasIndex`nFiles indexed: $count`nIndex path: $IndexPath"
    }
    default { Write-Output "Unknown action: $Action. Use: CRAWL, SEARCH, READ, APPROVE, REVOKE, LIST_APPROVED, STATUS" }
}
