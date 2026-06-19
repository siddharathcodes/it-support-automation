# ============================================================
# map_network_drives.ps1 - Map or unmap network drives
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\map_network_drives.ps1
# ============================================================

param(
    [ValidateSet("Map","Unmap","List")]
    [string]$Action = "List",
    [string]$DriveLetter = "",
    [string]$UNCPath = "",
    [switch]$Persistent
)

# Edit these for your office
$DriveMap = @(
    @{ Letter = "H"; Path = "\\fileserver\home\$env:USERNAME"; Label = "Home Drive" }
    @{ Letter = "S"; Path = "\\fileserver\shared";             Label = "Shared Files" }
    @{ Letter = "T"; Path = "\\fileserver\tools";              Label = "IT Tools" }
)

function Write-Section($msg) {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  $msg" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Cyan
}

function Map-Drive($letter, $path, $persist) {
    $p = if ($persist) { "Yes" } else { "No" }
    if (Test-Path "${letter}:") {
        Write-Host "  [!] Drive $letter already in use." -ForegroundColor Yellow
        return
    }
    net use "${letter}:" "$path" /persistent:$p 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Mapped $letter`: to $path" -ForegroundColor Green
    } else {
        Write-Host "  [X] Failed to map $letter`: to $path" -ForegroundColor Red
    }
}

function Unmap-Drive($letter) {
    if (-not (Test-Path "${letter}:")) {
        Write-Host "  [!] Drive $letter not mapped." -ForegroundColor Yellow
        return
    }
    net use "${letter}:" /delete /yes 2>&1 | Out-Null
    Write-Host "  [OK] $letter`: unmapped." -ForegroundColor Green
}

function List-Drives {
    Write-Section "CURRENTLY MAPPED DRIVES"
    $mapped = Get-SmbMapping -ErrorAction SilentlyContinue
    if (-not $mapped) {
        Write-Host "  No network drives currently mapped." -ForegroundColor Yellow
        return
    }
    $mapped | Format-Table LocalPath, RemotePath, Status -AutoSize
}

switch ($Action) {
    "List" {
        List-Drives
    }
    "Map" {
        Write-Section "MAPPING DRIVES"
        if ($DriveLetter -and $UNCPath) {
            Map-Drive $DriveLetter $UNCPath $Persistent
        } else {
            foreach ($drive in $DriveMap) {
                Map-Drive $drive.Letter $drive.Path $Persistent
            }
        }
        List-Drives
    }
    "Unmap" {
        Write-Section "UNMAPPING DRIVES"
        if ($DriveLetter) {
            Unmap-Drive $DriveLetter
        } else {
            foreach ($drive in $DriveMap) {
                Unmap-Drive $drive.Letter
            }
        }
    }
}

Write-Host ""
