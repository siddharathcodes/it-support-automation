# ============================================================
# master.ps1 - IT Support Master Control Panel
# Run this first. Pick a number. Done.
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\master.ps1
# ============================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptRoot

function Run-Script($file, $args = "") {
    $path = Join-Path $Root "scripts\windows\$file"
    if (Test-Path $path) {
        if ($args) {
            powershell -ExecutionPolicy Bypass -File $path $args
        } else {
            powershell -ExecutionPolicy Bypass -File $path
        }
    } else {
        Write-Host "[X] Script not found: $file" -ForegroundColor Red
    }
}

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "   IT SUPPORT - MASTER CONTROL PANEL" -ForegroundColor Yellow
    Write-Host "   Computer: $env:COMPUTERNAME | User: $env:USERNAME" -ForegroundColor Gray
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  INFO & AUDIT"
    Write-Host "  1.  System Info (this PC)"
    Write-Host "  2.  System Info + Export Report"
    Write-Host ""
    Write-Host "  REPAIR & FIX"
    Write-Host "  3.  Auto Repair (SFC + DISM + Network + Drivers)"
    Write-Host "  4.  Fix Internet Only"
    Write-Host "  5.  Fix Windows Update"
    Write-Host "  6.  Full System Repair (everything)"
    Write-Host ""
    Write-Host "  INSTALL & UPDATE"
    Write-Host "  7.  Install Apps (pick from menu)"
    Write-Host "  8.  Run Windows Updates"
    Write-Host "  9.  Run Windows Updates + Auto Restart"
    Write-Host ""
    Write-Host "  BACKUP"
    Write-Host "  10. Backup User Data (Documents, Downloads, Pictures)"
    Write-Host "  11. Backup User Data + Desktop + Compress to ZIP"
    Write-Host "  12. Backup Preview (dry run, no files copied)"
    Write-Host ""
    Write-Host "  NETWORK"
    Write-Host "  13. Map Network Drives"
    Write-Host "  14. List Mapped Drives"
    Write-Host "  15. Unmap All Drives"
    Write-Host "  16. Ping Check (test internet + network)"
    Write-Host ""
    Write-Host "  POWER"
    Write-Host "  17. Restart This PC (5 min delay)"
    Write-Host "  18. Restart Immediately"
    Write-Host "  19. Cancel Scheduled Restart"
    Write-Host ""
    Write-Host "  0.  Exit"
    Write-Host ""
}

while ($true) {
    Show-Menu
    $choice = Read-Host "  Pick a number"
    Write-Host ""

    switch ($choice) {

        # INFO
        "1" { Run-Script "system_info.ps1" }
        "2" {
            $out = Read-Host "Save report to (press Enter for Desktop)"
            if (-not $out) { $out = "$env:USERPROFILE\Desktop" }
            # Create path if it doesn't exist
            New-Item -ItemType Directory -Force -Path $out | Out-Null
            Run-Script "system_info.ps1" "-Export -OutputPath `"$out`""
        }

        # REPAIR
        "3" { Run-Script "auto_repair.ps1" }
        "4" {
            Write-Host "Fixing internet..." -ForegroundColor Cyan
            ipconfig /release 2>&1 | Out-Null
            ipconfig /flushdns 2>&1 | Out-Null
            ipconfig /renew 2>&1 | Out-Null
            netsh winsock reset 2>&1 | Out-Null
            netsh int ip reset 2>&1 | Out-Null
            Write-Host "[OK] Network reset done. Testing..." -ForegroundColor Green
            if (Test-Connection "8.8.8.8" -Count 2 -Quiet) {
                Write-Host "[OK] Internet working." -ForegroundColor Green
            } else {
                Write-Host "[!] Still no internet. Check router or cable." -ForegroundColor Yellow
            }
        }
        "5" {
            powershell -ExecutionPolicy Bypass -File (Join-Path $Root "scripts\windows\auto_repair.ps1") "-mode 6"
        }
        "6" {
            Write-Host "[!] Full repair takes 20-40 minutes. Continue? (y/n)" -ForegroundColor Yellow
            $confirm = Read-Host
            if ($confirm -eq "y") {
                powershell -ExecutionPolicy Bypass -File (Join-Path $Root "scripts\windows\auto_repair.ps1") -Full
            }
        }

        # INSTALL & UPDATE
        "7"  { Run-Script "install_apps.ps1" }
        "8"  { Run-Script "run_updates.ps1" }
        "9"  { Run-Script "run_updates.ps1" "-AutoRestart" }

        # BACKUP
        "10" {
            $dest = Read-Host "Backup destination? (e.g. D:\Backup, press Enter for Desktop)"
            if (-not $dest) { $dest = "$env:USERPROFILE\Desktop\Backup" }
            New-Item -ItemType Directory -Force -Path $dest | Out-Null
            Run-Script "backup_user_data.ps1" "-Destination `"$dest`""
        }
        "11" {
            $dest = Read-Host "Backup destination? (e.g. D:\Backup)"
            if (-not $dest) { $dest = "$env:USERPROFILE\Desktop\Backup" }
            New-Item -ItemType Directory -Force -Path $dest | Out-Null
            Run-Script "backup_user_data.ps1" "-Destination `"$dest`" -IncludeDesktop -Compress"
        }
        "12" { Run-Script "backup_user_data.ps1" "-DryRun" }

        # NETWORK
        "13" { Run-Script "map_network_drives.ps1" "-Action Map -Persistent" }
        "14" { Run-Script "map_network_drives.ps1" "-Action List" }
        "15" { Run-Script "map_network_drives.ps1" "-Action Unmap" }
        "16" {
            Write-Host "Pinging key hosts..." -ForegroundColor Cyan
            $hosts = @("8.8.8.8", "1.1.1.1", "google.com", "192.168.1.1")
            foreach ($h in $hosts) {
                if (Test-Connection $h -Count 2 -Quiet) {
                    Write-Host "  [OK] $h is reachable" -ForegroundColor Green
                } else {
                    Write-Host "  [X] $h is NOT reachable" -ForegroundColor Red
                }
            }
        }

        # POWER
        "17" { Run-Script "restart_machine.ps1" "-DelayMinutes 5" }
        "18" { Run-Script "restart_machine.ps1" "-Force -DelayMinutes 0" }
        "19" { Run-Script "restart_machine.ps1" "-Cancel" }

        "0"  { Write-Host "Bye." -ForegroundColor Gray; exit 0 }

        default { Write-Host "  [!] Invalid choice. Pick 0-19." -ForegroundColor Yellow }
    }

    Write-Host ""
    Write-Host "Press Enter to go back to menu..." -ForegroundColor Gray
    Read-Host | Out-Null
}
