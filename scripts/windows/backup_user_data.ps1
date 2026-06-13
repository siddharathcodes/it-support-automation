# ============================================================
# backup_user_data.ps1 — Backup user profile folders
# IT Support Automation Toolkit
# Usage: .\backup_user_data.ps1 [-Destination "D:\Backups"] [-User "john"] [-Compress]
# ============================================================

param(
    [string]$Destination = "D:\IT_Backups",
    [string]$User = $env:USERNAME,
    [switch]$Compress,
    [switch]$IncludeDesktop,
    [switch]$DryRun
)

$Timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"
$UserProfile = "C:\Users\$User"
$BackupDest  = "$Destination\$User\$Timestamp"

# Folders to back up
$Folders = @("Documents", "Downloads", "Pictures", "Videos", "AppData\Roaming\Microsoft\Outlook")
if ($IncludeDesktop) { $Folders += "Desktop" }

function Write-Log($msg, $color = "White") {
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
    Write-Host $line -ForegroundColor $color
    Add-Content -Path "$BackupDest\backup.log" -Value $line -ErrorAction SilentlyContinue
}

function Format-Size($bytes) {
    if ($bytes -ge 1GB) { "{0:N2} GB" -f ($bytes / 1GB) }
    elseif ($bytes -ge 1MB) { "{0:N2} MB" -f ($bytes / 1MB) }
    else { "{0:N0} KB" -f ($bytes / 1KB) }
}

# ── Validate source ────────────────────────────────────────────
if (-not (Test-Path $UserProfile)) {
    Write-Host "[✖] User profile not found: $UserProfile" -ForegroundColor Red
    exit 1
}

# ── Create destination ─────────────────────────────────────────
if (-not $DryRun) {
    New-Item -ItemType Directory -Path $BackupDest -Force | Out-Null
}

Write-Host "`n══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Backup: $User → $BackupDest" -ForegroundColor Yellow
if ($DryRun) { Write-Host "  [DRY RUN — no files will be copied]" -ForegroundColor Magenta }
Write-Host "══════════════════════════════════════════`n" -ForegroundColor Cyan

$totalSize = 0
$results   = @()

foreach ($folder in $Folders) {
    $src  = Join-Path $UserProfile $folder
    $dest = Join-Path $BackupDest  $folder

    if (-not (Test-Path $src)) {
        Write-Log "  [SKIP] $folder — not found" "DarkGray"
        continue
    }

    $size = (Get-ChildItem $src -Recurse -ErrorAction SilentlyContinue |
             Measure-Object -Property Length -Sum).Sum
    $totalSize += $size
    $sizeStr = Format-Size $size

    Write-Log "  Copying $folder ($sizeStr)..." "White"

    if (-not $DryRun) {
        try {
            Copy-Item -Path $src -Destination $dest -Recurse -Force -ErrorAction Stop
            Write-Log "  [✔] $folder done" "Green"
            $results += [PSCustomObject]@{ Folder=$folder; Size=$sizeStr; Status="OK" }
        } catch {
            Write-Log "  [✖] $folder failed: $_" "Red"
            $results += [PSCustomObject]@{ Folder=$folder; Size=$sizeStr; Status="FAILED" }
        }
    } else {
        Write-Log "  [DRY] Would copy $folder ($sizeStr)" "Yellow"
        $results += [PSCustomObject]@{ Folder=$folder; Size=$sizeStr; Status="DRY" }
    }
}

# ── Summary ────────────────────────────────────────────────────
Write-Host "`n  ── Backup Summary ──" -ForegroundColor Cyan
$results | Format-Table -AutoSize
Write-Log "Total backup size: $(Format-Size $totalSize)" "Cyan"

# ── Optional ZIP compression ────────────────────────────────────
if ($Compress -and -not $DryRun) {
    $zipPath = "$Destination\$User`_$Timestamp.zip"
    Write-Log "  Compressing to $zipPath..." "Yellow"
    Compress-Archive -Path $BackupDest -DestinationPath $zipPath -CompressionLevel Optimal
    Remove-Item $BackupDest -Recurse -Force
    Write-Log "  [✔] Compressed archive: $zipPath" "Green"
}

Write-Host "`n[✔] Backup complete.`n" -ForegroundColor Green
