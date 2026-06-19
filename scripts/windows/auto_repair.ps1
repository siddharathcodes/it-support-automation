# ============================================================
# auto_repair.ps1 - Auto repair Windows system corruption
# Fixes: corrupt files, drivers, disk errors, update issues
# Usage: Run as Administrator
# ============================================================

param([switch]$Full, [switch]$Quick)

# Admin check
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "[X] Run as Administrator." -ForegroundColor Red
    exit 1
}

$LogFile = "$env:USERPROFILE\Desktop\repair_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$Results = @()

function Write-Log($msg, $color = "White") {
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
    Write-Host $line -ForegroundColor $color
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
    $script:Results += $line
}

function Run-Step($title, $cmd) {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Log "Starting: $title"
    try {
        Invoke-Expression $cmd 2>&1 | Tee-Object -Append -FilePath $LogFile
        Write-Log "[OK] $title completed." "Green"
        return $true
    } catch {
        Write-Log "[X] $title failed: $_" "Red"
        return $false
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   WINDOWS AUTO REPAIR TOOL" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

if (-not $Quick -and -not $Full) {
    Write-Host "  1. Quick Repair  (SFC + DISM + DNS + Network) ~10 min"
    Write-Host "  2. Full Repair   (Everything + Disk Check + Drivers) ~30 min"
    Write-Host "  3. Network Only  (Fix internet issues)"
    Write-Host "  4. Driver Check  (Find and fix broken drivers)"
    Write-Host "  5. Disk Check    (Scan and fix disk errors)"
    Write-Host "  6. Windows Update Reset (Fix broken Windows Update)"
    Write-Host "  7. Full System Repair   (Everything, maximum fix)"
    Write-Host ""
    $mode = Read-Host "Pick number"
} elseif ($Quick) { $mode = "1" }
elseif ($Full)  { $mode = "7" }

Write-Host ""
Write-Log "Repair mode: $mode" "Cyan"
Write-Log "Computer: $env:COMPUTERNAME"
Write-Log "User: $env:USERNAME"

# ---- REPAIR STEPS ----

function Step-SFC {
    Write-Host ""
    Write-Log "Running System File Checker (SFC)..." "Cyan"
    Write-Log "This scans and repairs corrupt Windows system files..."
    sfc /scannow 2>&1 | Tee-Object -Append -FilePath $LogFile
    Write-Log "[OK] SFC complete." "Green"
}

function Step-DISM {
    Write-Host ""
    Write-Log "Running DISM - Windows Image Repair..." "Cyan"
    Write-Log "Step 1: CheckHealth"
    DISM /Online /Cleanup-Image /CheckHealth 2>&1 | Tee-Object -Append -FilePath $LogFile
    Write-Log "Step 2: ScanHealth"
    DISM /Online /Cleanup-Image /ScanHealth 2>&1 | Tee-Object -Append -FilePath $LogFile
    Write-Log "Step 3: RestoreHealth"
    DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Tee-Object -Append -FilePath $LogFile
    Write-Log "[OK] DISM complete." "Green"
}

function Step-Network {
    Write-Host ""
    Write-Log "Fixing Network Issues..." "Cyan"
    Write-Log "Releasing IP..."
    ipconfig /release 2>&1 | Out-Null
    Write-Log "Flushing DNS..."
    ipconfig /flushdns 2>&1 | Out-Null
    Write-Log "Renewing IP..."
    ipconfig /renew 2>&1 | Out-Null
    Write-Log "Resetting Winsock..."
    netsh winsock reset 2>&1 | Out-Null
    Write-Log "Resetting TCP/IP stack..."
    netsh int ip reset 2>&1 | Out-Null
    Write-Log "Resetting IPv6..."
    netsh int ipv6 reset 2>&1 | Out-Null
    Write-Log "Resetting Firewall..."
    netsh advfirewall reset 2>&1 | Out-Null
    Write-Log "Flushing ARP cache..."
    arp -d * 2>&1 | Out-Null
    Write-Log "[OK] Network reset complete. Restart recommended." "Green"

    # Test connectivity
    Write-Log "Testing connectivity..."
    if (Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet) {
        Write-Log "[OK] Internet is reachable." "Green"
    } else {
        Write-Log "[!] Still no internet. Check router/cable." "Yellow"
    }
}

function Step-Drivers {
    Write-Host ""
    Write-Log "Checking Drivers..." "Cyan"

    # Find problem devices
    $problemDevices = Get-WmiObject Win32_PNPEntity |
        Where-Object { $_.ConfigManagerErrorCode -ne 0 } |
        Select-Object Name, ConfigManagerErrorCode, DeviceID

    if ($problemDevices) {
        Write-Log "[!] Found $($problemDevices.Count) problem device(s):" "Yellow"
        foreach ($d in $problemDevices) {
            Write-Log "  - $($d.Name) (Error: $($d.ConfigManagerErrorCode))" "Yellow"
        }

        # Try to update drivers via Windows Update
        Write-Log "Attempting driver updates via Windows Update..."
        try {
            Import-Module PSWindowsUpdate -ErrorAction Stop
            Get-WindowsUpdate -UpdateType Driver -AcceptAll -Install -IgnoreReboot 2>&1 |
                Tee-Object -Append -FilePath $LogFile
            Write-Log "[OK] Driver update complete." "Green"
        } catch {
            Write-Log "[!] PSWindowsUpdate not available. Running Device Manager scan..." "Yellow"
            # Trigger hardware scan
            $scan = New-Object -ComObject DeviceManager
            pnputil /scan-devices 2>&1 | Tee-Object -Append -FilePath $LogFile
            Write-Log "[OK] Device scan complete." "Green"
        }
    } else {
        Write-Log "[OK] No problem devices found. All drivers are healthy." "Green"
    }

    # Export driver list
    $driverLog = "$env:USERPROFILE\Desktop\drivers_$(Get-Date -Format 'yyyyMMdd').txt"
    driverquery /FO TABLE 2>&1 | Out-File $driverLog -Encoding UTF8
    Write-Log "Driver list exported to: $driverLog" "Cyan"
}

function Step-Disk {
    Write-Host ""
    Write-Log "Checking Disk Health..." "Cyan"

    # Quick SMART check
    $disks = Get-PhysicalDisk | Select-Object FriendlyName, HealthStatus, OperationalStatus, Size
    foreach ($disk in $disks) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 1)
        if ($disk.HealthStatus -eq "Healthy") {
            Write-Log "  [OK] $($disk.FriendlyName) ($sizeGB GB) - $($disk.HealthStatus)" "Green"
        } else {
            Write-Log "  [!] $($disk.FriendlyName) ($sizeGB GB) - $($disk.HealthStatus)" "Red"
        }
    }

    # Schedule chkdsk on C: for next reboot
    Write-Log ""
    Write-Log "Scheduling disk check on C: for next reboot..."
    echo Y | chkdsk C: /f /r /x 2>&1 | Tee-Object -Append -FilePath $LogFile
    Write-Log "[OK] Disk check scheduled. Will run on next restart." "Green"
}

function Step-WindowsUpdateReset {
    Write-Host ""
    Write-Log "Resetting Windows Update..." "Cyan"

    Write-Log "Stopping Windows Update services..."
    Stop-Service -Name wuauserv, cryptSvc, bits, msiserver -Force -ErrorAction SilentlyContinue

    Write-Log "Clearing update cache..."
    Remove-Item "$env:SystemRoot\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Log "Reregistering DLLs..."
    $dlls = @("atl.dll","urlmon.dll","mshtml.dll","shdocvw.dll","browseui.dll",
              "jscript.dll","vbscript.dll","scrrun.dll","msxml.dll","msxml3.dll",
              "msxml6.dll","actxprxy.dll","softpub.dll","wintrust.dll","dssenh.dll",
              "rsaenh.dll","cryptdlg.dll","oleaut32.dll","ole32.dll","shell32.dll",
              "wuapi.dll","wuaueng.dll","wucltux.dll","wups.dll","wups2.dll","wusrv.dll")
    foreach ($dll in $dlls) {
        regsvr32.exe /s $dll 2>&1 | Out-Null
    }

    Write-Log "Restarting Windows Update services..."
    Start-Service -Name wuauserv, cryptSvc, bits, msiserver -ErrorAction SilentlyContinue

    Write-Log "[OK] Windows Update reset complete." "Green"
}

function Step-DiskCleanup {
    Write-Host ""
    Write-Log "Running Disk Cleanup..." "Cyan"

    # Clear temp files
    $tempPaths = @(
        $env:TEMP,
        "C:\Windows\Temp",
        "C:\Windows\Prefetch",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Temp"
    )

    $totalFreed = 0
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
            Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
            $totalFreed += $size
            Write-Log "  Cleaned: $path" "Gray"
        }
    }

    $freedMB = [math]::Round($totalFreed / 1MB, 1)
    Write-Log "[OK] Disk cleanup complete. Freed: $freedMB MB" "Green"

    # Empty Recycle Bin
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Log "[OK] Recycle Bin emptied." "Green"
}

# ---- RUN SELECTED MODE ----

switch ($mode) {
    "1" {
        # Quick Repair
        Step-SFC
        Step-DISM
        Step-Network
        Step-DiskCleanup
    }
    "2" {
        # Full Repair
        Step-SFC
        Step-DISM
        Step-Network
        Step-Drivers
        Step-DiskCleanup
    }
    "3" { Step-Network }
    "4" { Step-Drivers }
    "5" { Step-Disk }
    "6" { Step-WindowsUpdateReset }
    "7" {
        # Everything
        Step-SFC
        Step-DISM
        Step-Network
        Step-Drivers
        Step-Disk
        Step-WindowsUpdateReset
        Step-DiskCleanup
    }
    default {
        Write-Log "[X] Invalid choice." "Red"
        exit 1
    }
}

# ---- SUMMARY ----
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   REPAIR COMPLETE" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Log "Log saved to: $LogFile" "Cyan"
Write-Host ""

$restart = Read-Host "Restart now to apply all fixes? (y/n)"
if ($restart -eq "y") {
    shutdown /r /t 30 /c "IT Support: Restarting to apply repairs."
    Write-Log "Restarting in 30 seconds..." "Yellow"
}
Write-Host ""
