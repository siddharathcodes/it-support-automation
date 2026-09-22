# run_updates.ps1 - Windows Update automation
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_updates.ps1
param([switch]$AutoRestart)
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "[X] Run as Administrator." -ForegroundColor Red; exit 1
}
Write-Host ""
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "   WINDOWS UPDATE" -ForegroundColor Yellow
Write-Host "  ================================================"
Write-Host ""
Write-Host "  Checking PSWindowsUpdate module..." -ForegroundColor Gray
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "  Installing PSWindowsUpdate..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
    Install-Module PSWindowsUpdate -Force -Scope CurrentUser -SkipPublisherCheck
    Write-Host "  [OK] Module installed." -ForegroundColor Green
} else {
    Write-Host "  [OK] Module ready." -ForegroundColor Green
}
Import-Module PSWindowsUpdate
Write-Host ""
Write-Host "  Scanning for updates..." -ForegroundColor Cyan
$updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
if ($updates.Count -eq 0) {
    Write-Host "  [OK] System is fully up to date." -ForegroundColor Green
    exit 0
}
Write-Host "  Found $($updates.Count) update(s):" -ForegroundColor Yellow
$updates | Select-Object Title, Size, MsrcSeverity | Format-Table -AutoSize
Write-Host "  Installing updates..." -ForegroundColor Cyan
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot:(-not $AutoRestart) -AutoReboot:$AutoRestart
if (-not $AutoRestart) {
    $r = Read-Host "  Updates done. Restart now? (y/n)"
    if ($r -eq "y") {
        shutdown /r /t 30 /c "IT Support: Restarting after Windows Update"
        Write-Host "  Restarting in 30 seconds..." -ForegroundColor Yellow
    }
}
Write-Host ""
Write-Host "  [OK] Update process complete." -ForegroundColor Green
Write-Host ""
