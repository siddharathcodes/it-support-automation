# ============================================================
# install_apps.ps1 — Silent bulk app install via winget
# IT Support Automation Toolkit
# Usage: .\install_apps.ps1 [-Profile "Developer"|"Basic"|"Custom"] [-AppId "package.id"]
# ============================================================

param(
    [ValidateSet("Basic","Developer","Security","Custom")]
    [string]$Profile = "Basic",
    [string]$AppId = "",       # Install a single custom app by winget ID
    [switch]$ListOnly          # Just print what would be installed
)

# ── App Profiles ─────────────────────────────────────────────
$Profiles = @{
    Basic = @(
        @{ Id = "Google.Chrome";          Name = "Google Chrome" }
        @{ Id = "Mozilla.Firefox";        Name = "Mozilla Firefox" }
        @{ Id = "7zip.7zip";              Name = "7-Zip" }
        @{ Id = "Notepad++.Notepad++";    Name = "Notepad++" }
        @{ Id = "Adobe.Acrobat.Reader.64-bit"; Name = "Adobe Acrobat Reader" }
        @{ Id = "Microsoft.Teams";        Name = "Microsoft Teams" }
        @{ Id = "Zoom.Zoom";              Name = "Zoom" }
    )
    Developer = @(
        @{ Id = "Microsoft.VisualStudioCode"; Name = "VS Code" }
        @{ Id = "Git.Git";                    Name = "Git" }
        @{ Id = "OpenJS.NodeJS.LTS";          Name = "Node.js LTS" }
        @{ Id = "Python.Python.3.12";         Name = "Python 3.12" }
        @{ Id = "Docker.DockerDesktop";       Name = "Docker Desktop" }
        @{ Id = "Postman.Postman";            Name = "Postman" }
        @{ Id = "Microsoft.WindowsTerminal";  Name = "Windows Terminal" }
    )
    Security = @(
        @{ Id = "Malwarebytes.Malwarebytes";  Name = "Malwarebytes" }
        @{ Id = "Wireshark.Wireshark";        Name = "Wireshark" }
        @{ Id = "Nmap.Nmap";                  Name = "Nmap" }
        @{ Id = "Bitwarden.Bitwarden";        Name = "Bitwarden" }
    )
}

function Write-Status($msg, $color = "White") {
    Write-Host "  $msg" -ForegroundColor $color
}

function Check-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "`n[✖] winget not found. Install App Installer from the Microsoft Store." -ForegroundColor Red
        exit 1
    }
}

function Install-App($app) {
    Write-Host "`n  ──── $($app.Name) ────" -ForegroundColor Cyan
    if ($ListOnly) {
        Write-Status "Would install: $($app.Id)" "Yellow"
        return
    }

    $result = winget install --id $app.Id --silent --accept-package-agreements --accept-source-agreements 2>&1
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
        Write-Status "[✔] Installed (or already up to date)" "Green"
    } else {
        Write-Status "[✖] Failed — Exit code: $LASTEXITCODE" "Red"
        Write-Status $result "DarkGray"
    }
}

# ── Main ─────────────────────────────────────────────────────
Check-Winget

Write-Host "`n══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  App Installer — Profile: $Profile" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════`n" -ForegroundColor Cyan

if ($AppId) {
    # Single custom app
    Install-App @{ Id = $AppId; Name = $AppId }
} else {
    $apps = $Profiles[$Profile]
    Write-Status "Installing $($apps.Count) apps..." "White"
    foreach ($app in $apps) {
        Install-App $app
    }
}

Write-Host "`n[✔] Done.`n" -ForegroundColor Green
