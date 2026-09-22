# system_info.ps1 - Full system snapshot
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\system_info.ps1
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\system_info.ps1 -Export
param(
    [switch]$Export,
    [string]$OutputPath = "$env:USERPROFILE\Documents"
)
function Write-Section($title) {
    Write-Host ""
    Write-Host "  ================================================" -ForegroundColor Cyan
    Write-Host "   $title" -ForegroundColor Yellow
    Write-Host "  ================================================" -ForegroundColor Cyan
}
$report = ""
Write-Section "OPERATING SYSTEM"
$os = Get-CimInstance Win32_OperatingSystem
$up = (Get-Date) - $os.LastBootUpTime
$info = [PSCustomObject]@{
    "OS Name"      = $os.Caption
    "Version"      = $os.Version
    "Build"        = $os.BuildNumber
    "Architecture" = $os.OSArchitecture
    "Last Boot"    = $os.LastBootUpTime
    "Uptime"       = "$($up.Days)d $($up.Hours)h $($up.Minutes)m"
}
$info | Format-List
$report += "=== OS ===`r`n" + ($info | Out-String)
Write-Section "HARDWARE"
$cs  = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$hw = [PSCustomObject]@{
    "Manufacturer" = $cs.Manufacturer
    "Model"        = $cs.Model
    "CPU"          = $cpu.Name
    "Cores"        = "$($cpu.NumberOfCores) cores / $($cpu.NumberOfLogicalProcessors) threads"
    "RAM (GB)"     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
}
$hw | Format-List
$report += "=== HARDWARE ===`r`n" + ($hw | Out-String)
Write-Section "DISK USAGE"
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object `
    DeviceID,
    @{N="Size(GB)"; E={[math]::Round($_.Size/1GB,2)}},
    @{N="Free(GB)"; E={[math]::Round($_.FreeSpace/1GB,2)}},
    @{N="Used%";    E={[math]::Round((($_.Size-$_.FreeSpace)/$_.Size)*100,1)}}
$disks | Format-Table -AutoSize
$report += "=== DISKS ===`r`n" + ($disks | Out-String)
Write-Section "NETWORK"
$nets = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notmatch "Loopback" } |
    Select-Object InterfaceAlias, IPAddress, PrefixLength
$nets | Format-Table -AutoSize
$report += "=== NETWORK ===`r`n" + ($nets | Out-String)
Write-Section "LOCAL USERS"
$users = Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet
$users | Format-Table -AutoSize
$report += "=== USERS ===`r`n" + ($users | Out-String)
Write-Section "RUNNING SERVICES (Top 20)"
$svcs = Get-Service | Where-Object { $_.Status -eq "Running" } |
    Select-Object DisplayName, Name | Sort-Object DisplayName | Select-Object -First 20
$svcs | Format-Table -AutoSize
$report += "=== SERVICES ===`r`n" + ($svcs | Out-String)
$swCount = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
    Where-Object { $_.DisplayName }).Count
Write-Host ""
Write-Host "  Installed packages: $swCount" -ForegroundColor Green
$report += "=== SOFTWARE ===`r`nInstalled packages: $swCount`r`n"
if ($Export) {
    if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
    $ts   = Get-Date -Format "yyyyMMdd_HHmmss"
    $file = "$OutputPath\SysInfo_$($env:COMPUTERNAME)_$ts.txt"
    $report | Out-File -FilePath $file -Encoding UTF8
    Write-Host "  [OK] Report saved: $file" -ForegroundColor Green
}
Write-Host ""
Write-Host "  [OK] Done." -ForegroundColor Green
Write-Host ""
