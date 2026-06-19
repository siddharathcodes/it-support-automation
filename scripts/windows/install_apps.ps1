# ============================================================
# install_apps.ps1 - App installer with numbered menu
# Usage: .\install_apps.ps1
# ============================================================

function Check-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "[X] winget not found. Install App Installer from Microsoft Store." -ForegroundColor Red
        exit 1
    }
}

function Install-App($id, $name) {
    Write-Host "  Installing $name..." -ForegroundColor Yellow
    winget install --id $id --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
        Write-Host "  [OK] $name installed." -ForegroundColor Green
    } else {
        Write-Host "  [X] $name failed." -ForegroundColor Red
    }
}

Check-Winget

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   APP INSTALLER - Pick what to install" -ForegroundColor Yellow
Write-Host "================================================"
Write-Host ""
Write-Host "  BASIC APPS"
Write-Host "  1.  Google Chrome"
Write-Host "  2.  Mozilla Firefox"
Write-Host "  3.  7-Zip"
Write-Host "  4.  Notepad++"
Write-Host "  5.  Adobe Acrobat Reader"
Write-Host "  6.  Microsoft Teams"
Write-Host "  7.  Zoom"
Write-Host ""
Write-Host "  DEVELOPER TOOLS"
Write-Host "  8.  VS Code"
Write-Host "  9.  Git"
Write-Host "  10. Node.js LTS"
Write-Host "  11. Python 3.12"
Write-Host "  12. Docker Desktop"
Write-Host "  13. Postman"
Write-Host "  14. Windows Terminal"
Write-Host ""
Write-Host "  SECURITY TOOLS"
Write-Host "  15. Malwarebytes"
Write-Host "  16. Wireshark"
Write-Host "  17. Nmap"
Write-Host "  18. Bitwarden"
Write-Host ""
Write-Host "  INSTALL ALL"
Write-Host "  19. Install ALL Basic Apps"
Write-Host "  20. Install ALL Developer Tools"
Write-Host "  21. Install ALL Security Tools"
Write-Host "  22. Install EVERYTHING"
Write-Host ""

$choice = Read-Host "Enter number (or multiple separated by comma e.g. 1,3,8)"
Write-Host ""

$Apps = @{
    "1"  = @("Google.Chrome",                   "Google Chrome")
    "2"  = @("Mozilla.Firefox",                 "Mozilla Firefox")
    "3"  = @("7zip.7zip",                        "7-Zip")
    "4"  = @("Notepad++.Notepad++",              "Notepad++")
    "5"  = @("Adobe.Acrobat.Reader.64-bit",      "Adobe Acrobat Reader")
    "6"  = @("Microsoft.Teams",                  "Microsoft Teams")
    "7"  = @("Zoom.Zoom",                        "Zoom")
    "8"  = @("Microsoft.VisualStudioCode",       "VS Code")
    "9"  = @("Git.Git",                          "Git")
    "10" = @("OpenJS.NodeJS.LTS",                "Node.js LTS")
    "11" = @("Python.Python.3.12",               "Python 3.12")
    "12" = @("Docker.DockerDesktop",             "Docker Desktop")
    "13" = @("Postman.Postman",                  "Postman")
    "14" = @("Microsoft.WindowsTerminal",        "Windows Terminal")
    "15" = @("Malwarebytes.Malwarebytes",        "Malwarebytes")
    "16" = @("Wireshark.Wireshark",              "Wireshark")
    "17" = @("Nmap.Nmap",                        "Nmap")
    "18" = @("Bitwarden.Bitwarden",              "Bitwarden")
}

$BasicAll     = @("1","2","3","4","5","6","7")
$DeveloperAll = @("8","9","10","11","12","13","14")
$SecurityAll  = @("15","16","17","18")

$toInstall = @()

if ($choice -eq "19") { $toInstall = $BasicAll }
elseif ($choice -eq "20") { $toInstall = $DeveloperAll }
elseif ($choice -eq "21") { $toInstall = $SecurityAll }
elseif ($choice -eq "22") { $toInstall = $BasicAll + $DeveloperAll + $SecurityAll }
else {
    $toInstall = $choice -split "," | ForEach-Object { $_.Trim() }
}

Write-Host "Installing $($toInstall.Count) app(s)..." -ForegroundColor Cyan
Write-Host ""

foreach ($num in $toInstall) {
    if ($Apps.ContainsKey($num)) {
        Install-App $Apps[$num][0] $Apps[$num][1]
    } else {
        Write-Host "  [!] Unknown option: $num" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[OK] Done." -ForegroundColor Green
Write-Host ""
