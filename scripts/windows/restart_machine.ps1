# restart_machine.ps1 - Schedule or cancel a restart
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\restart_machine.ps1
param(
    [int]$DelayMinutes = 5,
    [switch]$Force,
    [string]$Remote = "",
    [string]$Message = "IT Support: Scheduled restart. Please save your work.",
    [switch]$Cancel
)
$delaySec = $DelayMinutes * 60
$target   = if ($Remote) { $Remote } else { $env:COMPUTERNAME }
Write-Host ""
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "   RESTART MANAGER - $target" -ForegroundColor Yellow
Write-Host "  ================================================"
Write-Host ""
if ($Cancel) {
    if ($Remote) { Invoke-Command -ComputerName $Remote -ScriptBlock { shutdown /a } }
    else { shutdown /a }
    Write-Host "  [OK] Pending restart cancelled." -ForegroundColor Green
    exit 0
}
if (-not $Force) {
    Write-Host "  Delay  : $DelayMinutes minute(s)"
    Write-Host "  Target : $target"
    Write-Host "  Message: $Message" -ForegroundColor Yellow
    Write-Host ""
    $c = Read-Host "  Proceed? (y/n)"
    if ($c -ne "y") { Write-Host "  Cancelled." -ForegroundColor Red; exit 0 }
}
Write-Host "  Scheduling restart in $DelayMinutes minute(s)..." -ForegroundColor Yellow
if ($Remote) {
    try {
        Invoke-Command -ComputerName $Remote -ScriptBlock {
            param($sec, $msg) shutdown /r /t $sec /c $msg
        } -ArgumentList $delaySec, $Message
        Write-Host "  [OK] Restart scheduled on $Remote" -ForegroundColor Green
    } catch {
        Write-Host "  [X] Remote restart failed: $_" -ForegroundColor Red
    }
} else {
    shutdown /r /t $delaySec /c "$Message"
    Write-Host "  [OK] Restart in $DelayMinutes min. Run with -Cancel to abort." -ForegroundColor Green
}
Write-Host ""
