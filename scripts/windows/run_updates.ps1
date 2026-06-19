# ============================================================
# run_updates.ps1 - Windows Update automation
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_updates.ps1
# ============================================================

param(
    [switch]$AutoRestart,
    [switch]$DriverUpdates
)

# Admin check
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "[X] Run PowerShell as Administrator for updates." -ForegroundColor Red
    exit 1
}

function Write-Section($msg) {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  $msg" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Cyan
}

Write-Section "WINDOWS UPDATE"

# Install PSWindowsUpdate if missing
Write-Host "  Checking PSWindowsUpdate module..." -ForegroundColor White
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "  Installing PSWindowsUpdate module..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
    Install-Module PSWindowsUpdate -Force -Scope CurrentUser -SkipPublisherCheck
    Write-Host "  [OK] Module installed." -ForegroundColor Green
} else {
    Write-Host "  [OK] PSWindowsUpdate already available." -ForegroundColor Green
}

Import-Module PSWindowsUpdate

# Check for updates
Write-Section "SCANNING FOR UPDATES"
$updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot

if ($updates.Count -eq 0) {
    Write-Host "  [OK] System is fully up to date." -ForegroundColor Green
    exit 0
}

Write-Host "  Found $($updates.Count) update(s):" -ForegroundColor Yellow
$updates | Select-Object Title, Size, MsrcSeverity | Format-Table -AutoSize

# Install updates
Write-Section "INSTALLING UPDATES"

$params = @{
    MicrosoftUpdate = $true
    AcceptAll       = $true
    IgnoreReboot    = (-not $AutoRestart)
    AutoReboot      = $AutoRestart
}

Install-WindowsUpdate @params

# Restart prompt
if (-not $AutoRestart) {
    Write-Host ""
    $reboot = Read-Host "  Updates done. Restart now? (y/n)"
    if ($reboot -eq "y") {
        Write-Host "  Restarting in 30 seconds..." -ForegroundColor Yellow
        shutdown /r /t 30 /c "IT Support: Restarting after Windows Update"
    } else {
        Write-Host "  [!] Please restart soon to apply updates." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[OK] Update process complete." -ForegroundColor Green
Write-Host ""
