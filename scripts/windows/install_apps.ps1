# install_apps.ps1 - App installer with numbered menu
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\windows\install_apps.ps1
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[X] winget not found. Install App Installer from Microsoft Store." -ForegroundColor Red
    exit 1
}
function Install-App($id, $name) {
    Write-Host "  Installing $name..." -ForegroundColor Yellow
    winget install --id $id --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
        Write-Host "  [OK] $name" -ForegroundColor Green
    } else {
        Write-Host "  [X] $name failed" -ForegroundColor Red
    }
}
Write-Host ""
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "   APP INSTALLER - Pick by number" -ForegroundColor Yellow
Write-Host "  ================================================"
Write-Host ""
Write-Host "  BASIC APPS"
Write-Host "  1.  Google Chrome"
Write-Host "  2.  Mozilla Firefox"
Write-Host "  3.  7-Zip"
Write-Host "  4.  Notepad++"
Write-Host "  5.  Adobe Acrobat Reader"
Write-Host "  6.  Microsoft Teams"
Write-Host "  7.  Zoom"
Write-Host "  8.  VLC Media Player"
Write-Host "  9.  WinRAR"
Write-Host ""
Write-Host "  DEVELOPER TOOLS"
Write-Host "  10. VS Code"
Write-Host "  11. Git"
Write-Host "  12. Node.js LTS"
Write-Host "  13. Python 3.12"
Write-Host "  14. Docker Desktop"
Write-Host "  15. Postman"
Write-Host "  16. Windows Terminal"
Write-Host "  17. GitHub Desktop"
Write-Host ""
Write-Host "  SECURITY TOOLS"
Write-Host "  18. Malwarebytes"
Write-Host "  19. Wireshark"
Write-Host "  20. Nmap"
Write-Host "  21. Bitwarden"
Write-Host "  22. ProtonVPN"
Write-Host ""
Write-Host "  UTILITIES"
Write-Host "  23. CPU-Z (hardware info)"
Write-Host "  24. CrystalDiskInfo (disk health)"
Write-Host "  25. HWiNFO (full hardware monitor)"
Write-Host "  26. TreeSize Free (disk space analyzer)"
Write-Host "  27. PuTTY (SSH client)"
Write-Host "  28. WinSCP (file transfer)"
Write-Host "  29. PowerToys (Microsoft utilities)"
Write-Host ""
Write-Host "  INSTALL ALL"
Write-Host "  30. Install ALL Basic Apps"
Write-Host "  31. Install ALL Developer Tools"
Write-Host "  32. Install ALL Security Tools"
Write-Host "  33. Install ALL Utilities"
Write-Host "  34. Install EVERYTHING"
Write-Host ""
$Apps = @{
    "1"  = @("Google.Chrome",                    "Google Chrome")
    "2"  = @("Mozilla.Firefox",                  "Firefox")
    "3"  = @("7zip.7zip",                         "7-Zip")
    "4"  = @("Notepad++.Notepad++",               "Notepad++")
    "5"  = @("Adobe.Acrobat.Reader.64-bit",       "Adobe Acrobat Reader")
    "6"  = @("Microsoft.Teams",                   "Microsoft Teams")
    "7"  = @("Zoom.Zoom",                         "Zoom")
    "8"  = @("VideoLAN.VLC",                      "VLC")
    "9"  = @("RARLab.WinRAR",                     "WinRAR")
    "10" = @("Microsoft.VisualStudioCode",        "VS Code")
    "11" = @("Git.Git",                           "Git")
    "12" = @("OpenJS.NodeJS.LTS",                 "Node.js LTS")
    "13" = @("Python.Python.3.12",                "Python 3.12")
    "14" = @("Docker.DockerDesktop",              "Docker Desktop")
    "15" = @("Postman.Postman",                   "Postman")
    "16" = @("Microsoft.WindowsTerminal",         "Windows Terminal")
    "17" = @("GitHub.GitHubDesktop",              "GitHub Desktop")
    "18" = @("Malwarebytes.Malwarebytes",         "Malwarebytes")
    "19" = @("Wireshark.Wireshark",               "Wireshark")
    "20" = @("Nmap.Nmap",                         "Nmap")
    "21" = @("Bitwarden.Bitwarden",               "Bitwarden")
    "22" = @("ProtonTechnologies.ProtonVPN",      "ProtonVPN")
    "23" = @("CPUID.CPU-Z",                       "CPU-Z")
    "24" = @("CrystalDewWorld.CrystalDiskInfo",  "CrystalDiskInfo")
    "25" = @("REALiX.HWiNFO",                    "HWiNFO")
    "26" = @("JAMSoftware.TreeSizeFree",          "TreeSize Free")
    "27" = @("PuTTY.PuTTY",                       "PuTTY")
    "28" = @("WinSCP.WinSCP",                     "WinSCP")
    "29" = @("Microsoft.PowerToys",               "PowerToys")
}
$BasicAll     = 1..9  | ForEach-Object { "$_" }
$DevAll       = 10..17 | ForEach-Object { "$_" }
$SecAll       = 18..22 | ForEach-Object { "$_" }
$UtilAll      = 23..29 | ForEach-Object { "$_" }
$choice = Read-Host "  Pick number(s) separated by comma (e.g. 1,3,10)"
Write-Host ""
$toInstall = @()
switch ($choice) {
    "30" { $toInstall = $BasicAll }
    "31" { $toInstall = $DevAll }
    "32" { $toInstall = $SecAll }
    "33" { $toInstall = $UtilAll }
    "34" { $toInstall = $BasicAll + $DevAll + $SecAll + $UtilAll }
    default { $toInstall = $choice -split "," | ForEach-Object { $_.Trim() } }
}
Write-Host "  Installing $($toInstall.Count) app(s)..." -ForegroundColor Cyan
Write-Host ""
foreach ($num in $toInstall) {
    if ($Apps.ContainsKey($num)) {
        Install-App $Apps[$num][0] $Apps[$num][1]
    } else {
        Write-Host "  [!] Unknown option: $num" -ForegroundColor Yellow
    }
}
Write-Host ""
Write-Host "  [OK] Done." -ForegroundColor Green
Write-Host ""
