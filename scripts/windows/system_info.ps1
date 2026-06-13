# ============================================================
# system_info.ps1 — Gather comprehensive system information
# IT Support Automation Toolkit
# Usage: .\system_info.ps1 [-Export] [-OutputPath "C:\Reports"]
# ============================================================

param(
    [switch]$Export,
    [string]$OutputPath = "$env:USERPROFILE\Desktop"
)

function Write-Section($title) {
    Write-Host "`n══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
}

$report = @()

# ── OS Info ────────────────────────────────────────────────
Write-Section "OPERATING SYSTEM"
$os = Get-CimInstance Win32_OperatingSystem
$osInfo = [PSCustomObject]@{
    "OS Name"        = $os.Caption
    "Version"        = $os.Version
    "Build"          = $os.BuildNumber
    "Architecture"   = $os.OSArchitecture
    "Last Boot"      = $os.LastBootUpTime
    "Uptime"         = ((Get-Date) - $os.LastBootUpTime).ToString("dd\d\ hh\h\ mm\m")
}
$osInfo | Format-List
$report += "=== OS ===" + ($osInfo | Out-String)

# ── Hardware ────────────────────────────────────────────────
Write-Section "HARDWARE"
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$hwInfo = [PSCustomObject]@{
    "Manufacturer"   = $cs.Manufacturer
    "Model"          = $cs.Model
    "CPU"            = $cpu.Name
    "CPU Cores"      = $cpu.NumberOfCores
    "Logical CPUs"   = $cpu.NumberOfLogicalProcessors
    "Total RAM (GB)" = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
}
$hwInfo | Format-List
$report += "=== HARDWARE ===" + ($hwInfo | Out-String)

# ── Disk Info ───────────────────────────────────────────────
Write-Section "DISK USAGE"
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID,
    @{N="Size(GB)";E={[math]::Round($_.Size/1GB,2)}},
    @{N="Free(GB)";E={[math]::Round($_.FreeSpace/1GB,2)}},
    @{N="Used%";E={[math]::Round((($_.Size - $_.FreeSpace)/$_.Size)*100,1)}}
$disks | Format-Table -AutoSize
$report += "=== DISKS ===" + ($disks | Out-String)

# ── Network ─────────────────────────────────────────────────
Write-Section "NETWORK ADAPTERS"
$nets = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notmatch "Loopback" } |
    Select-Object InterfaceAlias, IPAddress, PrefixLength
$nets | Format-Table -AutoSize
$report += "=== NETWORK ===" + ($nets | Out-String)

# ── Users ───────────────────────────────────────────────────
Write-Section "LOCAL USERS"
$users = Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet
$users | Format-Table -AutoSize
$report += "=== USERS ===" + ($users | Out-String)

# ── Running Services (top 20) ────────────────────────────────
Write-Section "RUNNING SERVICES (Top 20)"
$services = Get-Service | Where-Object {$_.Status -eq "Running"} |
    Select-Object DisplayName, Name, Status | Sort-Object DisplayName | Select-Object -First 20
$services | Format-Table -AutoSize
$report += "=== SERVICES ===" + ($services | Out-String)

# ── Installed Software (count only) ─────────────────────────
$softwareCount = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object { $_.DisplayName }).Count
Write-Host "`n  Installed software packages: $softwareCount" -ForegroundColor Green

# ── Export ──────────────────────────────────────────────────
if ($Export) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $filename = "$OutputPath\SysInfo_$($env:COMPUTERNAME)_$timestamp.txt"
    $report | Out-File -FilePath $filename -Encoding UTF8
    Write-Host "`n[✔] Report saved to: $filename" -ForegroundColor Green
}

Write-Host "`n[✔] System info complete.`n" -ForegroundColor Green
