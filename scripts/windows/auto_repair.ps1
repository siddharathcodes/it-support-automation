# auto_repair.ps1 - Windows auto repair tool
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\auto_repair.ps1
param([switch]$Full, [switch]$Quick)
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "[X] Run as Administrator." -ForegroundColor Red; exit 1
}
$Log = "$env:USERPROFILE\Desktop\repair_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
function Write-Log($msg, $col = "White") {
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
    Write-Host $line -ForegroundColor $col
    Add-Content -Path $Log -Value $line -ErrorAction SilentlyContinue
}
Write-Host ""
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "   WINDOWS AUTO REPAIR" -ForegroundColor Yellow
Write-Host "  ================================================"
Write-Host ""
if (-not $Quick -and -not $Full) {
    Write-Host "  1. Quick Repair  (SFC + DISM + Network + Cleanup)  ~10 min"
    Write-Host "  2. Network Only  (fix internet issues)"
    Write-Host "  3. Driver Check  (find and update broken drivers)"
    Write-Host "  4. Disk Check    (schedule chkdsk)"
    Write-Host "  5. Windows Update Reset"
    Write-Host "  6. Full Repair   (everything)  ~30-40 min"
    Write-Host ""
    $mode = Read-Host "  Pick number"
} elseif ($Quick) { $mode = "1" }
elseif ($Full)    { $mode = "6" }
function Step-SFC {
    Write-Log "Running SFC /scannow..." "Cyan"
    sfc /scannow 2>&1 | Tee-Object -Append $Log
    Write-Log "[OK] SFC complete." "Green"
}
function Step-DISM {
    Write-Log "Running DISM CheckHealth..." "Cyan"
    DISM /Online /Cleanup-Image /CheckHealth 2>&1 | Tee-Object -Append $Log
    Write-Log "Running DISM RestoreHealth..." "Cyan"
    DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Tee-Object -Append $Log
    Write-Log "[OK] DISM complete." "Green"
}
function Step-Network {
    Write-Log "Resetting network..." "Cyan"
    ipconfig /release 2>&1 | Out-Null
    ipconfig /flushdns 2>&1 | Out-Null
    ipconfig /renew 2>&1 | Out-Null
    netsh winsock reset 2>&1 | Out-Null
    netsh int ip reset 2>&1 | Out-Null
    netsh int ipv6 reset 2>&1 | Out-Null
    netsh advfirewall reset 2>&1 | Out-Null
    if (Test-Connection "8.8.8.8" -Count 2 -Quiet) {
        Write-Log "[OK] Internet working." "Green"
    } else {
        Write-Log "[!] Still no internet. Check router." "Yellow"
    }
}
function Step-Drivers {
    Write-Log "Checking drivers..." "Cyan"
    $problem = Get-WmiObject Win32_PNPEntity |
        Where-Object { $_.ConfigManagerErrorCode -ne 0 } |
        Select-Object Name, ConfigManagerErrorCode
    if ($problem) {
        Write-Log "[!] Found $($problem.Count) problem device(s):" "Yellow"
        foreach ($d in $problem) { Write-Log "  - $($d.Name)" "Yellow" }
        pnputil /scan-devices 2>&1 | Tee-Object -Append $Log
    } else {
        Write-Log "[OK] All drivers healthy." "Green"
    }
}
function Step-Disk {
    Write-Log "Scheduling disk check..." "Cyan"
    echo Y | chkdsk C: /f /r /x 2>&1 | Tee-Object -Append $Log
    Write-Log "[OK] Disk check scheduled for next reboot." "Green"
}
function Step-UpdateReset {
    Write-Log "Resetting Windows Update..." "Cyan"
    Stop-Service wuauserv, cryptSvc, bits, msiserver -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue
    $dlls = @("atl.dll","urlmon.dll","mshtml.dll","wuapi.dll","wuaueng.dll","wups.dll","wups2.dll")
    foreach ($dll in $dlls) { regsvr32.exe /s $dll 2>&1 | Out-Null }
    Start-Service wuauserv, cryptSvc, bits, msiserver -ErrorAction SilentlyContinue
    Write-Log "[OK] Windows Update reset." "Green"
}
function Step-Cleanup {
    Write-Log "Running cleanup..." "Cyan"
    $paths = @($env:TEMP, "C:\Windows\Temp", "$env:LOCALAPPDATA\Temp")
    foreach ($p in $paths) {
        if (Test-Path $p) { Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Log "[OK] Cleanup done." "Green"
}
switch ($mode) {
    "1" { Step-SFC; Step-DISM; Step-Network; Step-Cleanup }
    "2" { Step-Network }
    "3" { Step-Drivers }
    "4" { Step-Disk }
    "5" { Step-UpdateReset }
    "6" { Step-SFC; Step-DISM; Step-Network; Step-Drivers; Step-Disk; Step-UpdateReset; Step-Cleanup }
    default { Write-Log "[X] Invalid choice." "Red"; exit 1 }
}
Write-Host ""
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "   REPAIR COMPLETE" -ForegroundColor Green
Write-Host "   Log saved to Desktop" -ForegroundColor Gray
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host ""
$r = Read-Host "  Restart now to apply all fixes? (y/n)"
if ($r -eq "y") {
    shutdown /r /t 30 /c "IT Support: Restarting after repairs."
    Write-Host "  Restarting in 30 seconds..." -ForegroundColor Yellow
}
Write-Host ""
