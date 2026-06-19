# ============================================================
# restart_machine.ps1 - Schedule or cancel a restart
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\restart_machine.ps1
# ============================================================

param(
    [int]$DelayMinutes = 5,
    [switch]$Force,
    [string]$Remote = "",
    [string]$Message = "IT Support: Scheduled system restart. Please save your work.",
    [switch]$Cancel
)

$delaySec = $DelayMinutes * 60
$target   = if ($Remote) { $Remote } else { $env:COMPUTERNAME }

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  RESTART MANAGER - Target: $target" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

if ($Cancel) {
    if ($Remote) {
        Invoke-Command -ComputerName $Remote -ScriptBlock { shutdown /a }
    } else {
        shutdown /a
    }
    Write-Host "  [OK] Pending restart cancelled." -ForegroundColor Green
    exit 0
}

if (-not $Force) {
    Write-Host "  Target  : $target"
    Write-Host "  Delay   : $DelayMinutes minute(s)"
    Write-Host "  Message : $Message" -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "  Proceed? (y/n)"
    if ($confirm -ne "y") {
        Write-Host "  Cancelled." -ForegroundColor Red
        exit 0
    }
}

Write-Host ""
Write-Host "  Scheduling restart in $DelayMinutes minute(s)..." -ForegroundColor Yellow

if ($Remote) {
    try {
        Invoke-Command -ComputerName $Remote -ScriptBlock {
            param($sec, $msg)
            shutdown /r /t $sec /c $msg
        } -ArgumentList $delaySec, $Message
        Write-Host "  [OK] Restart scheduled on $Remote" -ForegroundColor Green
    } catch {
        Write-Host "  [X] Remote restart failed: $_" -ForegroundColor Red
        Write-Host "      Make sure WinRM is enabled on $Remote" -ForegroundColor DarkGray
    }
} else {
    shutdown /r /t $delaySec /c "$Message"
    Write-Host "  [OK] Restart scheduled in $DelayMinutes min(s)" -ForegroundColor Green
    Write-Host "  Run with -Cancel to abort." -ForegroundColor DarkGray
}

Write-Host ""
