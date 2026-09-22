# map_network_drives.ps1 - Map or unmap network drives
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\map_network_drives.ps1
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
function Map-Drive($letter, $path, $persist) {
    $p = if ($persist) { "Yes" } else { "No" }
    if (Test-Path "${letter}:") {
        Write-Host "  [!] Drive $letter already in use." -ForegroundColor Yellow; return
    }
    net use "${letter}:" "$path" /persistent:$p 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Mapped $letter to $path" -ForegroundColor Green
    } else {
        Write-Host "  [X] Failed: $letter -> $path" -ForegroundColor Red
    }
}
function Unmap-Drive($letter) {
    if (-not (Test-Path "${letter}:")) {
        Write-Host "  [!] $letter not mapped." -ForegroundColor Yellow; return
    }
    net use "${letter}:" /delete /yes 2>&1 | Out-Null
    Write-Host "  [OK] $letter unmapped." -ForegroundColor Green
}
function List-Drives {
    Write-Host ""
    Write-Host "  Currently Mapped Drives:" -ForegroundColor Cyan
    $mapped = Get-SmbMapping -ErrorAction SilentlyContinue
    if (-not $mapped) { Write-Host "  None mapped." -ForegroundColor Yellow; return }
    $mapped | Format-Table LocalPath, RemotePath, Status -AutoSize
}
switch ($Action) {
    "List"  { List-Drives }
    "Map"   {
        if ($DriveLetter -and $UNCPath) {
            Map-Drive $DriveLetter $UNCPath $Persistent
        } else {
            foreach ($d in $DriveMap) { Map-Drive $d.Letter $d.Path $Persistent }
        }
        List-Drives
    }
    "Unmap" {
        if ($DriveLetter) { Unmap-Drive $DriveLetter }
        else { foreach ($d in $DriveMap) { Unmap-Drive $d.Letter } }
    }
}
Write-Host ""
