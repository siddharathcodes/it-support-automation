# ============================================================
# master.ps1 - Ultimate IT Support Master Control Panel v4
# 72 options - Works from ANY location after cloning
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\master.ps1
# ============================================================

# Admin check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")

# Fix path - works no matter where you run from
if ($PSScriptRoot) {
    $WinScripts = $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    $WinScripts = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $WinScripts = (Get-Location).Path + "\scripts\windows"
}

if (-not (Test-Path "$WinScripts\system_info.ps1")) {
    Write-Host ""
    Write-Host "  [X] Scripts folder not found at: $WinScripts" -ForegroundColor Red
    Write-Host "  Run from inside the repo folder:" -ForegroundColor Yellow
    Write-Host "  cd it-support-automation" -ForegroundColor Cyan
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\windows\master.ps1" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

function Run-Script($file, $params = "") {
    $path = "$WinScripts\$file"
    if (-not (Test-Path $path)) {
        Write-Host "  [X] Not found: $path" -ForegroundColor Red
        return
    }
    if ($params) {
        powershell -ExecutionPolicy Bypass -File "$path" $params.Split(" ")
    } else {
        powershell -ExecutionPolicy Bypass -File "$path"
    }
}

function Write-Header($title) {
    Write-Host ""
    Write-Host "  ================================================" -ForegroundColor Cyan
    Write-Host "   $title" -ForegroundColor Yellow
    Write-Host "  ================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    Clear-Host
    $c = 34
    function Row($n1,$t1,$n2,$t2) {
        $l = if ("$n1" -ne "") { "  {0,2}. {1}" -f $n1,$t1 } else { "" }
        $r = if ("$n2" -ne "") { "{0,2}. {1}" -f $n2,$t2 } else { "" }
        Write-Host ("{0,-$c}{1}" -f $l,$r)
    }
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host "   IT SUPPORT - MASTER CONTROL PANEL v4" -ForegroundColor Yellow
    Write-Host ("   Computer: {0}  |  User: {1}" -f $env:COMPUTERNAME, $env:USERNAME) -ForegroundColor Gray
    if ($isAdmin) {
        Write-Host "   Mode: Administrator" -ForegroundColor Green
    } else {
        Write-Host "   Mode: Standard (some options need admin)" -ForegroundColor Yellow
    }
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  --- INFO & AUDIT ------------------- REPAIR & FIX ---" -ForegroundColor Cyan
    Row  1 "System Info"                   7 "Auto Repair Menu"
    Row  2 "System Info + Export"          8 "Fix Internet"
    Row  3 "Hardware Info"                 9 "Fix Windows Update"
    Row  4 "Top Processes (CPU)"          10 "Full System Repair (30-40 min)"
    Row  5 "Installed Software"           11 "Disk Cleanup"
    Row  6 "Event Log Errors"             12 "Fix Print Spooler"
    Row "" ""                             13 "Check Disk Health"
    Row "" ""                             14 "Reset Network Adapter"
    Write-Host ""
    Write-Host "  --- INSTALL & UPDATE --------------- BACKUP & RESTORE ---" -ForegroundColor Cyan
    Row 15 "Install Apps (34 apps)"       19 "Backup User Data"
    Row 16 "Run Windows Updates"          20 "Backup + Desktop + ZIP"
    Row 17 "Updates + Auto Restart"       21 "Backup Preview (dry run)"
    Row 18 "Update ALL Apps (winget)"     22 "Full System Image Backup"
    Write-Host ""
    Write-Host "  --- NETWORK ----------------------- USER MANAGEMENT ---" -ForegroundColor Cyan
    Row 23 "Full Network Info"            31 "List All Local Users"
    Row 24 "Ping Check"                   32 "Create New User"
    Row 25 "Port Check"                   33 "Reset User Password"
    Row 26 "Trace Route"                  34 "Enable or Disable User"
    Row 27 "Map Network Drives"           35 "Add User to Admins"
    Row 28 "List Mapped Drives"           36 "Remove User from Admins"
    Row 29 "Unmap All Drives"             37 "Delete User Account"
    Row 30 "WiFi Info + Passwords"        "" ""
    Write-Host ""
    Write-Host "  --- SERVICES ---------------------- SECURITY ---" -ForegroundColor Cyan
    Row 38 "List Running Services"        43 "Defender Status"
    Row 39 "Start a Service"              44 "Run Quick Defender Scan"
    Row 40 "Stop a Service"               45 "BitLocker Status"
    Row 41 "Restart a Service"            46 "List Startup Programs"
    Row 42 "Check if Service Exists"      47 "Check Open Ports"
    Row "" ""                             48 "Failed Login Attempts"
    Row "" ""                             49 "Firewall Status"
    Write-Host ""
    Write-Host "  --- POWER ------------------------- REMOTE (LAN) ---" -ForegroundColor Cyan
    Row 50 "Restart in 5 Minutes"         55 "Enable Remoting (this PC)"
    Row 51 "Restart Immediately"          56 "Scan Network (find PCs)"
    Row 52 "Shutdown in 5 Minutes"        57 "Connect to Remote PC"
    Row 53 "Cancel Restart/Shutdown"      58 "System Info on Remote PC"
    Row 54 "Sleep or Hibernate"           59 "Updates on Remote PC"
    Row "" ""                             60 "Fix Internet on Remote PC"
    Row "" ""                             61 "Restart Remote PC"
    Row "" ""                             62 "Copy File to Remote PC"
    Write-Host ""
    Write-Host "  --- TOOLS & SHORTCUTS ---" -ForegroundColor Cyan
    Row 63 "Device Manager"               68 "Services Console"
    Row 64 "Disk Management"              69 "Windows Firewall"
    Row 65 "Event Viewer"                 70 "Group Policy Editor"
    Row 66 "Task Manager"                 71 "Battery Report"
    Row 67 "Registry Editor"              72 "System Report (msinfo32)"
    Write-Host ""
    Write-Host "   0. Exit" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Cyan
    Write-Host ""
}
# ---- FUNCTIONS ----

function Get-HardwareInfo {
    Write-Header "HARDWARE INFO"
    $os  = Get-CimInstance Win32_OperatingSystem
    $cs  = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $ram = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    $up  = (Get-Date) - $os.LastBootUpTime
    Write-Host "  Manufacturer : $($cs.Manufacturer)"
    Write-Host "  Model        : $($cs.Model)"
    Write-Host "  CPU          : $($cpu.Name)"
    Write-Host "  Cores        : $($cpu.NumberOfCores) cores / $($cpu.NumberOfLogicalProcessors) threads"
    Write-Host "  RAM          : $ram GB"
    Write-Host "  GPU          : $($gpu.Name)"
    Write-Host "  OS           : $($os.Caption) ($($os.OSArchitecture))"
    Write-Host "  Uptime       : $($up.Days)d $($up.Hours)h $($up.Minutes)m"
    Write-Host ""
    Write-Host "  Disks:" -ForegroundColor Cyan
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        $pct = [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1)
        $col = if ($pct -gt 90) { "Red" } elseif ($pct -gt 75) { "Yellow" } else { "Green" }
        Write-Host ("  {0}  Size:{1}GB  Free:{2}GB  Used:{3}%" -f $_.DeviceID,
            [math]::Round($_.Size/1GB,1),
            [math]::Round($_.FreeSpace/1GB,1),
            $pct) -ForegroundColor $col
    }
}

function Get-TopProcesses {
    Write-Header "TOP 20 PROCESSES BY CPU"
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 |
        Select-Object Name, Id,
            @{N="CPU(s)";  E={[math]::Round($_.CPU, 1)}},
            @{N="RAM(MB)"; E={[math]::Round($_.WorkingSet64/1MB, 1)}} |
        Format-Table -AutoSize
}

function Get-InstalledSoftware {
    Write-Header "INSTALLED SOFTWARE"
    $sw = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
        Where-Object { $_.DisplayName } |
        Select-Object DisplayName, DisplayVersion, Publisher |
        Sort-Object DisplayName
    Write-Host "  Total: $($sw.Count) packages" -ForegroundColor Cyan
    Write-Host ""
    $sw | Format-Table -AutoSize
}

function Get-EventErrors {
    Write-Header "LAST 20 SYSTEM ERRORS"
    Get-EventLog -LogName System -Newest 20 -EntryType Error |
        Select-Object TimeGenerated, Source, EventID, Message |
        Format-Table -AutoSize -Wrap
}

function Fix-Internet {
    Write-Header "FIXING INTERNET"
    Write-Host "  Releasing IP..."       -ForegroundColor Gray; ipconfig /release 2>&1 | Out-Null
    Write-Host "  Flushing DNS..."       -ForegroundColor Gray; ipconfig /flushdns 2>&1 | Out-Null
    Write-Host "  Renewing IP..."        -ForegroundColor Gray; ipconfig /renew 2>&1 | Out-Null
    Write-Host "  Resetting Winsock..."  -ForegroundColor Gray; netsh winsock reset 2>&1 | Out-Null
    Write-Host "  Resetting TCP/IP..."   -ForegroundColor Gray; netsh int ip reset 2>&1 | Out-Null
    Write-Host "  Resetting IPv6..."     -ForegroundColor Gray; netsh int ipv6 reset 2>&1 | Out-Null
    Write-Host ""
    if (Test-Connection "8.8.8.8" -Count 2 -Quiet) {
        Write-Host "  [OK] Internet is working." -ForegroundColor Green
    } else {
        Write-Host "  [!] Still no internet. Check router or cable." -ForegroundColor Yellow
    }
}

function Fix-WindowsUpdate {
    Write-Header "RESETTING WINDOWS UPDATE"
    Stop-Service wuauserv, cryptSvc, bits, msiserver -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv, cryptSvc, bits, msiserver -ErrorAction SilentlyContinue
    Write-Host "  [OK] Windows Update reset. Run option 16 to update now." -ForegroundColor Green
}

function Disk-Cleanup {
    Write-Header "DISK CLEANUP"
    $paths = @(
        $env:TEMP,
        "C:\Windows\Temp",
        "C:\Windows\Prefetch",
        "$env:LOCALAPPDATA\Temp",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCookies",
        "C:\Windows\SoftwareDistribution\Download"
    )
    $total = 0
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $size = (Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum
            $total += $size
            Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  Cleaned: $p" -ForegroundColor DarkGray
        }
    }
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    $mb = [math]::Round($total / 1MB, 1)
    Write-Host ""
    Write-Host "  [OK] Freed $mb MB. Recycle Bin emptied." -ForegroundColor Green
}

function Fix-PrintSpooler {
    Write-Header "FIX PRINT SPOOLER"
    Stop-Service Spooler -Force -ErrorAction SilentlyContinue
    Start-Sleep 2
    Remove-Item "C:\Windows\System32\spool\PRINTERS\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service Spooler -ErrorAction SilentlyContinue
    Write-Host "  [OK] Print spooler restarted. Queue cleared." -ForegroundColor Green
}

function Check-DiskHealth {
    Write-Header "DISK HEALTH"
    $disks = Get-PhysicalDisk | Select-Object FriendlyName, HealthStatus, OperationalStatus,
        @{N="Size(GB)"; E={[math]::Round($_.Size/1GB,1)}}
    foreach ($d in $disks) {
        $col = if ($d.HealthStatus -eq "Healthy") { "Green" } else { "Red" }
        Write-Host ("  {0}  {1}GB  {2}" -f $d.FriendlyName, $d.'Size(GB)', $d.HealthStatus) -ForegroundColor $col
    }
    Write-Host ""
    Write-Host "  Scheduling chkdsk on C: for next reboot..." -ForegroundColor Cyan
    echo Y | chkdsk C: /f /r /x 2>&1 | Out-Null
    Write-Host "  [OK] Disk check scheduled. Restart to run." -ForegroundColor Green
}

function Fix-NetworkAdapter {
    Write-Header "RESET NETWORK ADAPTER"
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    $adapters | Select-Object Name, InterfaceDescription, LinkSpeed | Format-Table -AutoSize
    $name = Read-Host "  Adapter name to reset (Enter = all)"
    if ($name) {
        Disable-NetAdapter -Name $name -Confirm:$false; Start-Sleep 2
        Enable-NetAdapter  -Name $name -Confirm:$false
        Write-Host "  [OK] $name reset." -ForegroundColor Green
    } else {
        foreach ($a in $adapters) {
            Disable-NetAdapter -Name $a.Name -Confirm:$false; Start-Sleep 1
            Enable-NetAdapter  -Name $a.Name -Confirm:$false
            Write-Host "  [OK] Reset: $($a.Name)" -ForegroundColor Green
        }
    }
}

function Update-AllApps {
    Write-Header "UPDATE ALL APPS"
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "  [X] winget not found." -ForegroundColor Red; return
    }
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    Write-Host "  [OK] All apps updated." -ForegroundColor Green
}

function Backup-SystemImage {
    Write-Header "FULL SYSTEM IMAGE BACKUP"
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne "C" }
    $drives | Select-Object Name, @{N="Free(GB)";E={[math]::Round($_.Free/1GB,1)}} | Format-Table
    $dest = Read-Host "  Save to which drive letter? (e.g. D)"
    Write-Host "  Starting backup... this takes 20-40 minutes." -ForegroundColor Yellow
    wbadmin start backup -backupTarget:"${dest}:" -include:C: -allCritical -quiet
    Write-Host "  [OK] Backup complete." -ForegroundColor Green
}

function Get-NetworkInfo {
    Write-Header "NETWORK INFO"
    Write-Host "  Adapters:" -ForegroundColor Cyan
    Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.InterfaceAlias -notmatch "Loopback" } |
        Select-Object InterfaceAlias, IPAddress, PrefixLength | Format-Table -AutoSize
    Write-Host "  Default Gateway:" -ForegroundColor Cyan
    Get-NetRoute -DestinationPrefix "0.0.0.0/0" 2>&1 |
        Select-Object NextHop, InterfaceAlias | Format-Table -AutoSize
    Write-Host "  DNS Servers:" -ForegroundColor Cyan
    Get-DnsClientServerAddress -AddressFamily IPv4 |
        Where-Object { $_.ServerAddresses } |
        Select-Object InterfaceAlias, ServerAddresses | Format-Table -AutoSize
    Write-Host "  Public IP:" -ForegroundColor Cyan
    try {
        $pub = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 5).Content
        Write-Host "  $pub" -ForegroundColor White
    } catch {
        Write-Host "  Could not reach internet." -ForegroundColor Yellow
    }
}

function Ping-Check {
    Write-Header "PING CHECK"
    $custom = Read-Host "  Add extra hosts? (comma separated, Enter to skip)"
    $hosts = @("8.8.8.8","1.1.1.1","google.com","192.168.1.1")
    if ($custom) { $hosts += $custom.Split(",") | ForEach-Object { $_.Trim() } }
    foreach ($h in $hosts) {
        if (Test-Connection $h -Count 2 -Quiet) {
            $ms = (Test-Connection $h -Count 1).ResponseTime
            Write-Host "  [OK] $h  ${ms}ms" -ForegroundColor Green
        } else {
            Write-Host "  [X] $h  not reachable" -ForegroundColor Red
        }
    }
}

function Check-Port {
    Write-Header "PORT CHECK"
    $h    = Read-Host "  Target host or IP"
    $port = [int](Read-Host "  Port number")
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $r   = $tcp.BeginConnect($h, $port, $null, $null)
        $w   = $r.AsyncWaitHandle.WaitOne(3000)
        if ($w -and $tcp.Connected) {
            Write-Host "  [OK] Port $port on $h is OPEN" -ForegroundColor Green
        } else {
            Write-Host "  [X] Port $port on $h is CLOSED or FILTERED" -ForegroundColor Red
        }
        $tcp.Close()
    } catch {
        Write-Host "  [X] Failed: $_" -ForegroundColor Red
    }
}

function Trace-Route {
    Write-Header "TRACE ROUTE"
    $target = Read-Host "  Target (e.g. google.com)"
    tracert $target
}

function Get-WiFiInfo {
    Write-Header "WIFI INFO"
    netsh wlan show interfaces
    Write-Host ""
    Write-Host "  Saved WiFi Passwords:" -ForegroundColor Cyan
    $profiles = (netsh wlan show profiles) |
        Select-String "All User Profile" |
        ForEach-Object { $_.ToString().Split(":")[1].Trim() }
    foreach ($p in $profiles) {
        $pass = (netsh wlan show profile name="$p" key=clear 2>&1) | Select-String "Key Content"
        $pw   = if ($pass) { $pass.ToString().Split(":")[1].Trim() } else { "(no password)" }
        Write-Host "  $p  :  $pw" -ForegroundColor White
    }
}

function List-Users {
    Write-Header "LOCAL USERS"
    Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet | Format-Table -AutoSize
}

function Create-User {
    Write-Header "CREATE USER"
    $username = Read-Host "  New username"
    $password = Read-Host "  Password" -AsSecureString
    try {
        New-LocalUser -Name $username -Password $password -FullName $username `
            -Description "Created by IT Support Toolkit" -ErrorAction Stop
        Write-Host "  [OK] User $username created." -ForegroundColor Green
        if ((Read-Host "  Add to Administrators? (y/n)") -eq "y") {
            Add-LocalGroupMember -Group "Administrators" -Member $username
            Write-Host "  [OK] Added to Administrators." -ForegroundColor Green
        }
    } catch {
        Write-Host "  [X] Failed: $_" -ForegroundColor Red
    }
}

function Reset-Password {
    Write-Header "RESET PASSWORD"
    List-Users
    $username = Read-Host "  Username to reset"
    $password = Read-Host "  New password" -AsSecureString
    try {
        Set-LocalUser -Name $username -Password $password
        Write-Host "  [OK] Password reset for $username." -ForegroundColor Green
    } catch {
        Write-Host "  [X] Failed: $_" -ForegroundColor Red
    }
}

function Toggle-User {
    Write-Header "ENABLE / DISABLE USER"
    List-Users
    $username = Read-Host "  Username"
    $action   = Read-Host "  (e)nable or (d)isable?"
    try {
        if ($action -eq "e") {
            Enable-LocalUser $username
            Write-Host "  [OK] $username enabled." -ForegroundColor Green
        } else {
            Disable-LocalUser $username
            Write-Host "  [OK] $username disabled." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [X] Failed: $_" -ForegroundColor Red
    }
}

function Add-ToAdmins {
    Write-Header "ADD TO ADMINISTRATORS"
    List-Users
    $u = Read-Host "  Username to promote"
    try {
        Add-LocalGroupMember -Group "Administrators" -Member $u -ErrorAction Stop
        Write-Host "  [OK] $u added to Administrators." -ForegroundColor Green
    } catch { Write-Host "  [X] Failed: $_" -ForegroundColor Red }
}

function Remove-FromAdmins {
    Write-Header "REMOVE FROM ADMINISTRATORS"
    List-Users
    $u = Read-Host "  Username to demote"
    try {
        Remove-LocalGroupMember -Group "Administrators" -Member $u -ErrorAction Stop
        Write-Host "  [OK] $u removed from Administrators." -ForegroundColor Green
    } catch { Write-Host "  [X] Failed: $_" -ForegroundColor Red }
}

function Delete-User {
    Write-Header "DELETE USER"
    List-Users
    $u = Read-Host "  Username to DELETE"
    if ((Read-Host "  Type YES to confirm permanent deletion") -eq "YES") {
        try {
            Remove-LocalUser -Name $u -ErrorAction Stop
            Write-Host "  [OK] $u deleted." -ForegroundColor Green
        } catch { Write-Host "  [X] Failed: $_" -ForegroundColor Red }
    } else {
        Write-Host "  Cancelled." -ForegroundColor Yellow
    }
}

function Manage-Service($action) {
    Write-Header "SERVICE - $($action.ToUpper())"
    $svc = Read-Host "  Service name (e.g. Spooler, wuauserv, bits)"
    try {
        switch ($action) {
            "start"   { Start-Service   $svc -ErrorAction Stop }
            "stop"    { Stop-Service    $svc -Force -ErrorAction Stop }
            "restart" { Restart-Service $svc -Force -ErrorAction Stop }
        }
        Write-Host "  [OK] $action done on $svc." -ForegroundColor Green
    } catch { Write-Host "  [X] Failed: $_" -ForegroundColor Red }
}

function Check-Service {
    Write-Header "CHECK SERVICE"
    $svc = Read-Host "  Service name"
    $r   = Get-Service $svc -ErrorAction SilentlyContinue
    if ($r) {
        $col = if ($r.Status -eq "Running") { "Green" } else { "Yellow" }
        Write-Host "  $($r.DisplayName) - $($r.Status)" -ForegroundColor $col
    } else {
        Write-Host "  [X] Service not found: $svc" -ForegroundColor Red
    }
}

function Check-Defender {
    Write-Header "WINDOWS DEFENDER STATUS"
    $d = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($d) {
        $col = if ($d.AntivirusEnabled) { "Green" } else { "Red" }
        Write-Host "  Antivirus Enabled    : $($d.AntivirusEnabled)" -ForegroundColor $col
        Write-Host "  Real-time Protection : $($d.RealTimeProtectionEnabled)" -ForegroundColor $col
        Write-Host "  Last Quick Scan      : $($d.QuickScanEndTime)"
        Write-Host "  Definitions Updated  : $($d.AntivirusSignatureLastUpdated)"
    } else {
        Write-Host "  [!] Could not get Defender status." -ForegroundColor Yellow
    }
}

function Run-DefenderScan {
    Write-Header "DEFENDER QUICK SCAN"
    Write-Host "  Starting quick scan..." -ForegroundColor Cyan
    Start-MpScan -ScanType QuickScan
    Write-Host "  [OK] Scan started. Check Windows Security for results." -ForegroundColor Green
}

function Check-BitLocker {
    Write-Header "BITLOCKER STATUS"
    manage-bde -status 2>&1 | Select-String -Pattern "Volume|Protection Status|Lock Status|Encryption Method|Percentage"
}

function List-StartupPrograms {
    Write-Header "STARTUP PROGRAMS"
    Get-CimInstance Win32_StartupCommand |
        Select-Object Name, Command, Location, User | Format-Table -AutoSize -Wrap
}

function Check-OpenPorts {
    Write-Header "OPEN PORTS"
    netstat -ano | Select-String "LISTENING" | ForEach-Object {
        $parts = $_.ToString().Trim() -split "\s+"
        $pid_  = $parts[-1]
        $proc  = try { (Get-Process -Id $pid_ -ErrorAction SilentlyContinue).Name } catch { "unknown" }
        [PSCustomObject]@{ Port = $parts[1]; PID = $pid_; Process = $proc }
    } | Sort-Object Port | Format-Table -AutoSize
}

function Check-FailedLogins {
    Write-Header "FAILED LOGIN ATTEMPTS"
    try {
        Get-EventLog -LogName Security -InstanceId 4625 -Newest 20 -ErrorAction Stop |
            Select-Object TimeGenerated, Message | Format-List
    } catch {
        Write-Host "  [!] Need Administrator rights to read Security log." -ForegroundColor Yellow
    }
}

function Check-Firewall {
    Write-Header "FIREWALL STATUS"
    Get-NetFirewallProfile |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction |
        Format-Table -AutoSize
}

function Get-RemotePC {
    $ip   = Read-Host "  Remote PC IP (e.g. 192.168.1.102)"
    $cred = Get-Credential -Message "Admin credentials for $ip"
    return @{ IP = $ip; Cred = $cred }
}

function Scan-Network {
    Write-Header "NETWORK SCAN"
    $subnet = Read-Host "  Subnet prefix (Enter = 192.168.1)"
    if (-not $subnet) { $subnet = "192.168.1" }
    Write-Host "  Scanning $subnet.1-254... (~30 seconds)" -ForegroundColor Cyan
    Write-Host ""
    $found = 0
    1..254 | ForEach-Object {
        $ip = "$subnet.$_"
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds 1) {
            $name = try { [System.Net.Dns]::GetHostEntry($ip).HostName } catch { "unknown" }
            Write-Host "  [UP] $ip  -  $name" -ForegroundColor Green
            $found++
        }
    }
    Write-Host ""
    Write-Host "  Found $found device(s)." -ForegroundColor Cyan
}

function Copy-ToRemote {
    Write-Header "COPY FILE TO REMOTE PC"
    $r    = Get-RemotePC
    $src  = Read-Host "  Local file path"
    $dest = Read-Host "  Destination path on remote PC (e.g. C:\Temp)"
    try {
        $session = New-PSSession -ComputerName $r.IP -Credential $r.Cred
        Copy-Item -Path $src -Destination $dest -ToSession $session -Force
        Remove-PSSession $session
        Write-Host "  [OK] Copied to $($r.IP):$dest" -ForegroundColor Green
    } catch {
        Write-Host "  [X] Failed: $_" -ForegroundColor Red
    }
}

function Battery-Report {
    Write-Header "BATTERY REPORT"
    $path = "$env:USERPROFILE\Desktop\battery_report.html"
    powercfg /batteryreport /output $path 2>&1 | Out-Null
    Write-Host "  [OK] Report saved to Desktop." -ForegroundColor Green
    Start-Process $path
}

# ---- MAIN LOOP ----

while ($true) {
    Show-Menu
    $choice = Read-Host "  Pick a number"
    Write-Host ""

    switch ($choice) {
        "1"  { Run-Script "system_info.ps1" }
        "2"  {
            $out = "$env:USERPROFILE\Documents"
            New-Item -ItemType Directory -Force -Path $out | Out-Null
            Run-Script "system_info.ps1" "-Export -OutputPath `"$out`""
            Write-Host "  [OK] Saved to Documents." -ForegroundColor Green
        }
        "3"  { Get-HardwareInfo }
        "4"  { Get-TopProcesses }
        "5"  { Get-InstalledSoftware }
        "6"  { Get-EventErrors }
        "7"  { Run-Script "auto_repair.ps1" }
        "8"  { Fix-Internet }
        "9"  { Fix-WindowsUpdate }
        "10" {
            if ((Read-Host "  Full repair 30-40 min. Continue? (y/n)") -eq "y") {
                Run-Script "auto_repair.ps1" "-Full"
            }
        }
        "11" { Disk-Cleanup }
        "12" { Fix-PrintSpooler }
        "13" { Check-DiskHealth }
        "14" { Fix-NetworkAdapter }
        "15" { Run-Script "install_apps.ps1" }
        "16" { Run-Script "run_updates.ps1" }
        "17" { Run-Script "run_updates.ps1" "-AutoRestart" }
        "18" { Update-AllApps }
        "19" {
            $dest = "$env:USERPROFILE\Desktop\Backup"
            New-Item -ItemType Directory -Force -Path $dest | Out-Null
            Run-Script "backup_user_data.ps1" "-Destination `"$dest`""
        }
        "20" {
            $dest = "$env:USERPROFILE\Desktop\Backup"
            New-Item -ItemType Directory -Force -Path $dest | Out-Null
            Run-Script "backup_user_data.ps1" "-Destination `"$dest`" -IncludeDesktop -Compress"
        }
        "21" { Run-Script "backup_user_data.ps1" "-DryRun" }
        "22" { Backup-SystemImage }
        "23" { Get-NetworkInfo }
        "24" { Ping-Check }
        "25" { Check-Port }
        "26" { Trace-Route }
        "27" { Run-Script "map_network_drives.ps1" "-Action Map -Persistent" }
        "28" { Run-Script "map_network_drives.ps1" "-Action List" }
        "29" { Run-Script "map_network_drives.ps1" "-Action Unmap" }
        "30" { Get-WiFiInfo }
        "31" { List-Users }
        "32" { Create-User }
        "33" { Reset-Password }
        "34" { Toggle-User }
        "35" { Add-ToAdmins }
        "36" { Remove-FromAdmins }
        "37" { Delete-User }
        "38" {
            Write-Host ""
            Get-Service | Where-Object { $_.Status -eq "Running" } |
                Select-Object DisplayName, Name | Sort-Object DisplayName | Format-Table -AutoSize
        }
        "39" { Manage-Service "start" }
        "40" { Manage-Service "stop" }
        "41" { Manage-Service "restart" }
        "42" { Check-Service }
        "43" { Check-Defender }
        "44" { Run-DefenderScan }
        "45" { Check-BitLocker }
        "46" { List-StartupPrograms }
        "47" { Check-OpenPorts }
        "48" { Check-FailedLogins }
        "49" { Check-Firewall }
        "50" { Run-Script "restart_machine.ps1" "-DelayMinutes 5" }
        "51" { Run-Script "restart_machine.ps1" "-Force -DelayMinutes 0" }
        "52" {
            if ((Read-Host "  Shutdown in 5 min? (y/n)") -eq "y") {
                shutdown /s /t 300 /c "IT Support: Scheduled shutdown"
                Write-Host "  [OK] Shutdown in 5 min. Use option 53 to cancel." -ForegroundColor Yellow
            }
        }
        "53" { Run-Script "restart_machine.ps1" "-Cancel" }
        "54" {
            $m = Read-Host "  (s)leep or (h)ibernate?"
            if ($m -eq "h") { shutdown /h } else { rundll32.exe powrprof.dll,SetSuspendState 0,1,0 }
        }
        "55" {
            Enable-PSRemoting -Force
            Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
            Write-Host "  [OK] Remoting enabled on this PC." -ForegroundColor Green
        }
        "56" { Scan-Network }
        "57" {
            $r = Get-RemotePC
            Write-Host "  Connecting to $($r.IP)... type exit to leave" -ForegroundColor Cyan
            Enter-PSSession -ComputerName $r.IP -Credential $r.Cred
        }
        "58" {
            $r = Get-RemotePC
            Invoke-Command -ComputerName $r.IP -Credential $r.Cred `
                -FilePath "$WinScripts\system_info.ps1"
        }
        "59" {
            $r = Get-RemotePC
            Invoke-Command -ComputerName $r.IP -Credential $r.Cred `
                -FilePath "$WinScripts\run_updates.ps1"
        }
        "60" {
            $r = Get-RemotePC
            Invoke-Command -ComputerName $r.IP -Credential $r.Cred -ScriptBlock {
                ipconfig /release; ipconfig /flushdns
                ipconfig /renew; netsh winsock reset
                Write-Host "Network reset done." -ForegroundColor Green
            }
        }
        "61" {
            $r    = Get-RemotePC
            $mins = Read-Host "  Delay in minutes"
            Invoke-Command -ComputerName $r.IP -Credential $r.Cred -ScriptBlock {
                param($m)
                shutdown /r /t ($m * 60) /c "IT Support: Scheduled restart"
            } -ArgumentList $mins
            Write-Host "  [OK] Restart scheduled on $($r.IP)" -ForegroundColor Green
        }
        "62" { Copy-ToRemote }
        "63" { Start-Process devmgmt.msc }
        "64" { Start-Process diskmgmt.msc }
        "65" { Start-Process eventvwr.msc }
        "66" { Start-Process taskmgr }
        "67" { Start-Process gpedit.msc }
        "68" { Start-Process regedit }
        "69" { Start-Process services.msc }
        "70" { Start-Process wf.msc }
        "71" { Battery-Report }
        "72" { Start-Process msinfo32 }
        "0"  { Write-Host "  Bye." -ForegroundColor Gray; exit 0 }
        default { Write-Host "  [!] Invalid. Enter 0-72." -ForegroundColor Yellow }
    }

    Write-Host ""
    Write-Host "  Press Enter to return to menu..." -ForegroundColor DarkGray
    Read-Host | Out-Null
}
