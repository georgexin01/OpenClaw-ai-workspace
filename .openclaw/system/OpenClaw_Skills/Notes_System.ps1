# OPENCLAW SKILL: NOTES SYSTEM [V1.0]
# ======================================
# [PURPOSE]: Persistent notes with AI text enhancement
# [SOURCE]: Inspired by Open WebUI notes feature
# [ACTIONS]: CREATE, LIST, READ, UPDATE, DELETE, ENHANCE, SEARCH

param(
    [string]$Action = "LIST",
    [string]$Title = "",
    [string]$Content = "",
    [string]$NoteId = "",
    [string]$Query = "",
    [string]$Tag = ""
)

$NotesDir = Join-Path $PSScriptRoot "..\skills_bridge\notes"
if (-not (Test-Path $NotesDir)) { New-Item -ItemType Directory -Path $NotesDir -Force | Out-Null }

function Get-NoteId([string]$NoteTitle) {
    return ($NoteTitle -replace '[^\w\s-]', '' -replace '\s+', '_').ToLower().Substring(0, [Math]::Min(40, $NoteTitle.Length))
}

switch ($Action.ToUpper()) {
    "CREATE" {
        if (-not $Title) { Write-Output "[NOTES] Provide -Title."; break }
        $id = if ($NoteId) { $NoteId } else { Get-NoteId $Title }
        $path = Join-Path $NotesDir "$id.md"

        $note = @"
---
title: $Title
created: $(Get-Date -Format "o")
modified: $(Get-Date -Format "o")
tags: [$Tag]
---

$Content
"@
        Set-Content -Path $path -Value $note -Encoding UTF8
        Write-Output "[NOTES] Created: $Title ($id.md)"
    }

    "LIST" {
        $files = Get-ChildItem $NotesDir -Filter "*.md" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
        if ($files.Count -eq 0) { Write-Output "[NOTES] No notes found. Use -Action CREATE to start."; break }

        $output = "[NOTES] $($files.Count) notes:`n"
        foreach ($f in $files) {
            $firstLine = (Get-Content $f.FullName | Where-Object { $_ -match "^title:" } | Select-Object -First 1) -replace "title:\s*", ""
            $tags = (Get-Content $f.FullName | Where-Object { $_ -match "^tags:" } | Select-Object -First 1) -replace "tags:\s*", ""
            $output += "  [$($f.BaseName)] $firstLine $tags ($($f.LastWriteTime.ToString('MM-dd HH:mm')))`n"
        }
        Write-Output $output
    }

    "READ" {
        $id = if ($NoteId) { $NoteId } else { Get-NoteId $Title }
        $path = Join-Path $NotesDir "$id.md"
        if (-not (Test-Path $path)) { Write-Output "[NOTES] Note '$id' not found."; break }
        $content = Get-Content $path -Raw
        Write-Output "[NOTE: $id]`n$content"
    }

    "UPDATE" {
        $id = if ($NoteId) { $NoteId } else { Get-NoteId $Title }
        $path = Join-Path $NotesDir "$id.md"
        if (-not (Test-Path $path)) { Write-Output "[NOTES] Note '$id' not found."; break }
        if (-not $Content) { Write-Output "[NOTES] Provide -Content to append."; break }

        # Update modified date
        $existing = Get-Content $path -Raw
        $existing = $existing -replace "modified: .+", "modified: $(Get-Date -Format 'o')"
        $updated = "$existing`n`n$Content"
        Set-Content -Path $path -Value $updated -Encoding UTF8
        Write-Output "[NOTES] Updated: $id"
    }

    "DELETE" {
        $id = if ($NoteId) { $NoteId } else { Get-NoteId $Title }
        $path = Join-Path $NotesDir "$id.md"
        if (Test-Path $path) { Remove-Item $path -Force; Write-Output "[NOTES] Deleted: $id" }
        else { Write-Output "[NOTES] Not found: $id" }
    }

    "ENHANCE" {
        $id = if ($NoteId) { $NoteId } else { Get-NoteId $Title }
        $path = Join-Path $NotesDir "$id.md"
        if (-not (Test-Path $path)) { Write-Output "[NOTES] Note '$id' not found."; break }

        $content = Get-Content $path -Raw
        $enginePath = Join-Path $PSScriptRoot "..\..\OpenClaw_Engine.ps1"
        . $enginePath

        $prompt = "Improve and enhance this note. Fix grammar, improve clarity, add structure with headers. Keep the same information but make it more professional:`n`n$($content.Substring(0, [Math]::Min(2000, $content.Length)))"
        $enhanced = Invoke-OClawQuery $prompt 1

        $enhancedPath = Join-Path $NotesDir "${id}_enhanced.md"
        Set-Content -Path $enhancedPath -Value "---`ntitle: $Title (Enhanced)`nenhanced: $(Get-Date -Format 'o')`n---`n`n$enhanced" -Encoding UTF8
        Write-Output "[NOTES] Enhanced version saved: ${id}_enhanced.md`n$enhanced"
    }

    "SEARCH" {
        if (-not $Query) { Write-Output "[NOTES] Provide -Query."; break }
        $files = Get-ChildItem $NotesDir -Filter "*.md" -ErrorAction SilentlyContinue
        $results = @()
        foreach ($f in $files) {
            $content = Get-Content $f.FullName -Raw
            if ($content -match $Query) { $results += $f }
        }
        if ($results.Count -eq 0) { Write-Output "[NOTES] No notes matching: $Query"; break }
        $output = "[NOTES SEARCH] $($results.Count) matches for '$Query':`n"
        foreach ($r in $results) { $output += "  [$($r.BaseName)] $($r.LastWriteTime.ToString('MM-dd HH:mm'))`n" }
        Write-Output $output
    }

    default { Write-Output "Use: CREATE, LIST, READ, UPDATE, DELETE, ENHANCE, SEARCH" }
}
