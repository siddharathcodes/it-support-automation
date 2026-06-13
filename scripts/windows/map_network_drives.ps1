# ============================================================
# map_network_drives.ps1 — Map or unmap network drives
# IT Support Automation Toolkit
# Usage: .\map_network_drives.ps1 [-Action Map|Unmap|List] [-DriveLetter Z] [-UNCPath "\\server\share"]
# ============================================================

param(
    [ValidateSet("Map","Unmap","List")]
    [string]$Action = "List",
    [string]$DriveLetter = "",
    [string]$UNCPath = "",
    [string]$Label = "",
    [switch]$Persistent,
    [switch]$UseCredentials
)

# ── Predefined drive map (edit this section for your org) ────
$DriveMap = @(
    @{ Letter = "H"; Path = "\\fileserver\home\$env:USERNAME"; Label = "Home Drive" }
    @{ Letter = "S"; Path = "\\fileserver\shared";             Label = "Shared Files" }
    @{ Letter = "T"; Path = "\\fileserver\tools";              Label = "IT Tools" }
)

function Write-Header($msg) {
    Write-Host "`n  [$msg]" -ForegroundColor Cyan
}

function Map-Drive($letter, $path, $label, $persist) {
    $persist = if ($persist) { "Yes" } else { "No" }
    Write-Header "Mapping $letter`: → $path"

    if (Test-Path "${letter}:") {
        Write-Host "  [!] Drive $letter already in use." -ForegroundColor Yellow
        return
    }

    try {
        net use "${letter}:" "$path" /persistent:$persist 2>&1 | Out-Null
        if ($label) {
            # Set volume label via shell (best-effort)
            $shell = New-Object -ComObject Shell.Application
        }
        Write-Host "  [✔] Mapped $letter`: to $path" -ForegroundColor Green
    } catch {
        Write-Host "  [✖] Failed: $_" -ForegroundColor Red
    }
}

function Unmap-Drive($letter) {
    Write-Header "Unmapping $letter`:"
    if (-not (Test-Path "${letter}:")) {
        Write-Host "  [!] Drive $letter not mapped." -ForegroundColor Yellow
        return
    }
    net use "${letter}:" /delete /yes 2>&1 | Out-Null
    Write-Host "  [✔] $letter`: unmapped." -ForegroundColor Green
}

function List-Drives {
    Write-Header "Currently Mapped Network Drives"
    $mapped = Get-SmbMapping -ErrorAction SilentlyContinue
    if (-not $mapped) {
        Write-Host "  No network drives currently mapped." -ForegroundColor Yellow
        return
    }
    $mapped | Format-Table LocalPath, RemotePath, Status -AutoSize
}

# ── Main ─────────────────────────────────────────────────────
switch ($Action) {
    "List" {
        List-Drives
    }
    "Map" {
        if ($DriveLetter -and $UNCPath) {
            # Manual single drive
            Map-Drive $DriveLetter $UNCPath $Label $Persistent
        } else {
            # Map all predefined drives
            Write-Host "`n  Mapping all predefined drives..." -ForegroundColor Cyan
            foreach ($drive in $DriveMap) {
                Map-Drive $drive.Letter $drive.Path $drive.Label $Persistent
            }
        }
        List-Drives
    }
    "Unmap" {
        if ($DriveLetter) {
            Unmap-Drive $DriveLetter
        } else {
            Write-Host "`n  Unmapping all predefined drives..." -ForegroundColor Cyan
            foreach ($drive in $DriveMap) {
                Unmap-Drive $drive.Letter
            }
        }
    }
}

Write-Host ""
