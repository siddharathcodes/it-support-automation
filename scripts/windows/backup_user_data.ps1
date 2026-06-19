# ============================================================
# backup_user_data.ps1 - Backup user profile folders
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\backup_user_data.ps1
# ============================================================

param(
    [string]$Destination = "$env:USERPROFILE\Desktop\Backup",
    [string]$User        = $env:USERNAME,
    [switch]$IncludeDesktop,
    [switch]$Compress,
    [switch]$DryRun
)

$Timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"
$UserProfile = "C:\Users\$User"
$BackupDest  = "$Destination\$User\$Timestamp"
$Folders     = @("Documents", "Downloads", "Pictures", "Videos", "AppData\Roaming\Microsoft\Outlook")

if ($IncludeDesktop) { $Folders += "Desktop" }

function Write-Section($msg) {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  $msg" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Cyan
}

function Format-Size($bytes) {
    if ($bytes -ge 1GB) { return "{0:N2} GB" -f ($bytes / 1GB) }
    if ($bytes -ge 1MB) { return "{0:N2} MB" -f ($bytes / 1MB) }
    return "{0:N0} KB" -f ($bytes / 1KB)
}

Write-Section "USER DATA BACKUP"
Write-Host "  User        : $User" -ForegroundColor White
Write-Host "  Source      : $UserProfile" -ForegroundColor White
Write-Host "  Destination : $BackupDest" -ForegroundColor White
if ($DryRun) { Write-Host "  Mode        : DRY RUN (no files copied)" -ForegroundColor Magenta }
Write-Host ""

if (-not (Test-Path $UserProfile)) {
    Write-Host "[X] User profile not found: $UserProfile" -ForegroundColor Red
    exit 1
}

if (-not $DryRun) {
    New-Item -ItemType Directory -Path $BackupDest -Force | Out-Null
}

$results = @()

foreach ($folder in $Folders) {
    $src  = Join-Path $UserProfile $folder
    $dest = Join-Path $BackupDest $folder

    if (-not (Test-Path $src)) {
        Write-Host "  [SKIP] $folder - not found" -ForegroundColor DarkGray
        $results += [PSCustomObject]@{ Folder=$folder; Size="--"; Status="SKIPPED" }
        continue
    }

    $bytes   = (Get-ChildItem $src -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $sizeStr = Format-Size $bytes

    if ($DryRun) {
        Write-Host "  [DRY] Would copy $folder ($sizeStr)" -ForegroundColor Yellow
        $results += [PSCustomObject]@{ Folder=$folder; Size=$sizeStr; Status="DRY RUN" }
        continue
    }

    Write-Host "  Copying $folder ($sizeStr)..." -ForegroundColor White
    try {
        Copy-Item -Path $src -Destination $dest -Recurse -Force -ErrorAction Stop
        Write-Host "  [OK] $folder done" -ForegroundColor Green
        $results += [PSCustomObject]@{ Folder=$folder; Size=$sizeStr; Status="OK" }
    } catch {
        Write-Host "  [X] $folder failed: $_" -ForegroundColor Red
        $results += [PSCustomObject]@{ Folder=$folder; Size=$sizeStr; Status="FAILED" }
    }
}

Write-Section "SUMMARY"
$results | Format-Table -AutoSize

if ($Compress -and -not $DryRun) {
    $zipPath = "$Destination\$User`_$Timestamp.zip"
    Write-Host "  Compressing to ZIP..." -ForegroundColor Yellow
    Compress-Archive -Path $BackupDest -DestinationPath $zipPath -CompressionLevel Optimal
    Remove-Item $BackupDest -Recurse -Force
    Write-Host "  [OK] ZIP saved: $zipPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "[OK] Backup complete." -ForegroundColor Green
Write-Host ""
