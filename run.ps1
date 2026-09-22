# run.ps1 - One command to download and launch IT Support Master Menu
# Usage: irm https://raw.githubusercontent.com/siddharathcodes/it-support-automation/main/run.ps1 | iex

Write-Host ""
Write-Host "  Downloading IT Support Toolkit..." -ForegroundColor Cyan

$dest = "$env:TEMP\it-support-automation"

# Clean old copy if exists
if (Test-Path $dest) {
    Remove-Item $dest -Recurse -Force
}

# Download repo ZIP
$zip = "$env:TEMP\it-tools.zip"
$url = "https://github.com/siddharathcodes/it-support-automation/archive/refs/heads/main.zip"

try {
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    Write-Host "  Downloaded." -ForegroundColor Green
} catch {
    Write-Host "  [X] Download failed. Check internet connection." -ForegroundColor Red
    exit 1
}

# Extract
Expand-Archive -Path $zip -DestinationPath $dest -Force
Remove-Item $zip -Force

# Find extracted folder
$folder = Get-ChildItem $dest | Select-Object -First 1

# Unblock all scripts
Get-ChildItem "$($folder.FullName)\scripts" -Recurse -Include *.ps1 | Unblock-File

Write-Host "  [OK] Ready. Launching master menu..." -ForegroundColor Green
Write-Host ""

# Launch master menu
powershell -ExecutionPolicy Bypass -File "$($folder.FullName)\scripts\windows\master.ps1"
