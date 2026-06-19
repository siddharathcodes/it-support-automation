# ============================================================
# system_info.ps1 - Full system information gatherer
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\system_info.ps1
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\system_info.ps1 -Export
# ============================================================

param(
    [switch]$Export,
    [string]$OutputPath = "$env:USERPROFILE\Documents"
)

# Admin check
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "[WARNING] Not running as Administrator. Some info may be limited." -ForegroundColor Yellow
}

function Write-Section($title) {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Cyan
}

$report = ""

# OS Info
Write-Section "OPERATING SYSTEM"
$os = Get-CimInstance Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
$osInfo = [PSCustomObject]@{
    "OS Name"        = $os.Caption
    "Version"        = $os.Version
    "Build"          = $os.BuildNumber
    "Architecture"   = $os.OSArchitecture
    "Last Boot"      = $os.LastBootUpTime
    "Uptime"         = "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
}
$osInfo | Format-List
$report += "=== OS ===`r`n" + ($osInfo | Out-String)

# Hardware
Write-Section "HARDWARE"
$cs  = Get-CimInstance Win32_ComputerSystem
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
$report += "=== HARDWARE ===`r`n" + ($hwInfo | Out-String)

# Disk
Write-Section "DISK USAGE"
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object `
    DeviceID,
    @{N="Size(GB)"; E={[math]::Round($_.Size / 1GB, 2)}},
    @{N="Free(GB)"; E={[math]::Round($_.FreeSpace / 1GB, 2)}},
    @{N="Used%";    E={[math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1)}}
$disks | Format-Table -AutoSize
$report += "=== DISKS ===`r`n" + ($disks | Out-String)

# Network
Write-Section "NETWORK ADAPTERS"
$nets = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notmatch "Loopback" } |
    Select-Object InterfaceAlias, IPAddress, PrefixLength
$nets | Format-Table -AutoSize
$report += "=== NETWORK ===`r`n" + ($nets | Out-String)

# Users
Write-Section "LOCAL USERS"
$users = Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet
$users | Format-Table -AutoSize
$report += "=== USERS ===`r`n" + ($users | Out-String)

# Services
Write-Section "RUNNING SERVICES (Top 20)"
$services = Get-Service |
    Where-Object { $_.Status -eq "Running" } |
    Select-Object DisplayName, Name, Status |
    Sort-Object DisplayName |
    Select-Object -First 20
$services | Format-Table -AutoSize
$report += "=== SERVICES ===`r`n" + ($services | Out-String)

# Software count
$swCount = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
    Where-Object { $_.DisplayName }).Count
Write-Host ""
Write-Host "  Installed software packages: $swCount" -ForegroundColor Green
$report += "=== SOFTWARE ===`r`nInstalled packages: $swCount`r`n"

# Export
if ($Export) {
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $filename  = "$OutputPath\SysInfo_$($env:COMPUTERNAME)_$timestamp.txt"
    $report | Out-File -FilePath $filename -Encoding UTF8
    Write-Host ""
    Write-Host "[OK] Report saved to: $filename" -ForegroundColor Green
}

Write-Host ""
Write-Host "[OK] System info complete." -ForegroundColor Green
Write-Host ""
