# ============================================================
# run_updates.ps1 — Trigger Windows Update silently
# IT Support Automation Toolkit
# Usage: .\run_updates.ps1 [-AutoRestart] [-DriverUpdates]
# Requires: PSWindowsUpdate module (auto-installs if missing)
# ============================================================

param(
    [switch]$AutoRestart,
    [switch]$DriverUpdates
)

function Write-Section($msg) {
    Write-Host "`n══ $msg ══" -ForegroundColor Cyan
}

# ── Ensure PSWindowsUpdate module ────────────────────────────
Write-Section "Checking PSWindowsUpdate Module"
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "  Installing PSWindowsUpdate..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
    Install-Module PSWindowsUpdate -Force -Scope CurrentUser -SkipPublisherCheck
    Write-Host "  [✔] Module installed." -ForegroundColor Green
} else {
    Write-Host "  [✔] PSWindowsUpdate already installed." -ForegroundColor Green
}

Import-Module PSWindowsUpdate

# ── Check available updates ──────────────────────────────────
Write-Section "Scanning for Updates"
$updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot

if ($updates.Count -eq 0) {
    Write-Host "  [✔] System is up to date. No updates found." -ForegroundColor Green
    exit 0
}

Write-Host "  Found $($updates.Count) update(s):`n" -ForegroundColor Yellow
$updates | Select-Object Title, Size, MsrcSeverity | Format-Table -AutoSize

# ── Install updates ──────────────────────────────────────────
Write-Section "Installing Updates"

$params = @{
    MicrosoftUpdate  = $true
    AcceptAll        = $true
    IgnoreReboot     = (-not $AutoRestart)
    AutoReboot       = $AutoRestart
    Verbose          = $false
}

if ($DriverUpdates) {
    $params["UpdateType"] = "Driver"
}

Install-WindowsUpdate @params

# ── Reboot prompt ─────────────────────────────────────────────
if (-not $AutoRestart) {
    $reboot = Read-Host "`n  Updates installed. Restart now? (y/n)"
    if ($reboot -eq "y") {
        Write-Host "  Restarting in 30 seconds..." -ForegroundColor Yellow
        shutdown /r /t 30 /c "IT Support: System restart after Windows Update"
    } else {
        Write-Host "  [!] Restart pending. Please restart at your earliest convenience." -ForegroundColor Yellow
    }
}

Write-Host "`n[✔] Update process complete.`n" -ForegroundColor Green
