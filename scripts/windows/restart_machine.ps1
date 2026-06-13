# ============================================================
# restart_machine.ps1 — Schedule or force a machine restart
# IT Support Automation Toolkit
# Usage: .\restart_machine.ps1 [-DelayMinutes 10] [-Force] [-Remote "PC-NAME"] [-Message "reason"]
# ============================================================

param(
    [int]$DelayMinutes = 5,
    [switch]$Force,
    [string]$Remote = "",
    [string]$Message = "IT Support: Scheduled system restart. Please save your work.",
    [switch]$Cancel
)

function Write-Status($msg, $color = "White") {
    Write-Host "  $msg" -ForegroundColor $color
}

$delaySec = $DelayMinutes * 60
$target   = if ($Remote) { $Remote } else { $env:COMPUTERNAME }

Write-Host "`n══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Restart Manager — Target: $target" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════`n" -ForegroundColor Cyan

# ── Cancel pending restart ─────────────────────────────────────
if ($Cancel) {
    if ($Remote) {
        Invoke-Command -ComputerName $Remote -ScriptBlock { shutdown /a }
    } else {
        shutdown /a
    }
    Write-Status "[✔] Pending restart cancelled." "Green"
    exit 0
}

# ── Confirm before restart ─────────────────────────────────────
if (-not $Force) {
    Write-Status "Target  : $target"
    Write-Status "Delay   : $DelayMinutes minute(s)"
    Write-Status "Message : $Message" "Yellow"
    $confirm = Read-Host "`n  Proceed with restart? (y/n)"
    if ($confirm -ne "y") {
        Write-Status "Restart cancelled by user." "Red"
        exit 0
    }
}

# ── Execute restart ────────────────────────────────────────────
Write-Status "Scheduling restart in $DelayMinutes minute(s)..." "Yellow"

$shutdownArgs = "/r /t $delaySec /c `"$Message`""
if ($Force)  { $shutdownArgs += " /f" }

if ($Remote) {
    # Remote restart via WMI (requires admin rights on remote)
    try {
        Invoke-Command -ComputerName $Remote -ScriptBlock {
            param($args)
            Start-Process shutdown -ArgumentList $args -NoNewWindow
        } -ArgumentList $shutdownArgs
        Write-Status "[✔] Restart scheduled on $Remote" "Green"
    } catch {
        Write-Status "[✖] Remote restart failed: $_" "Red"
        Write-Status "    Ensure WinRM is enabled on $Remote" "DarkGray"
    }
} else {
    Start-Process shutdown -ArgumentList $shutdownArgs -NoNewWindow
    Write-Status "[✔] Restart scheduled for $target in $DelayMinutes min(s)" "Green"
    Write-Status "    Run with -Cancel to abort." "DarkGray"
}

Write-Host ""
