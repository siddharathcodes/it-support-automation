@echo off
setlocal
echo.
echo ================================================
echo   IT Support Automation Toolkit - Setup
echo ================================================
echo.

:: Password protection
set /p pwd="Enter IT password: "
if not "%pwd%"=="UCA@IT2026" (
    echo.
    echo [X] Wrong password. Access denied.
    echo.
    pause
    exit /b
)

echo.
echo [1/3] Setting execution policy...
powershell -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" 2>nul
echo Done.

echo.
echo [2/3] Unblocking all scripts...
powershell -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '.\scripts' -Recurse -Include *.ps1 | Unblock-File"
echo Done.

echo.
echo [3/3] Stripping any corrupted characters from scripts...
powershell -ExecutionPolicy Bypass -Command "Get-ChildItem -Recurse -Include *.ps1 | ForEach-Object { $c = Get-Content $_.FullName -Raw -Encoding UTF8; $c = $c -replace '[^\x00-\x7F]', ''; Set-Content $_.FullName -Value $c -Encoding UTF8 }"
echo Done.

echo.
echo ================================================
echo   SETUP COMPLETE - How to use:
echo ================================================
echo.
echo   OPTION 1 - Master menu (easiest):
echo   powershell -ExecutionPolicy Bypass -File .\scripts\windows\master.ps1
echo.
echo   OPTION 2 - Run individual scripts:
echo   powershell -ExecutionPolicy Bypass -File .\scripts\windows\system_info.ps1 -Export
echo   powershell -ExecutionPolicy Bypass -File .\scripts\windows\install_apps.ps1
echo   powershell -ExecutionPolicy Bypass -File .\scripts\windows\run_updates.ps1
echo   powershell -ExecutionPolicy Bypass -File .\scripts\windows\backup_user_data.ps1 -Destination D:\Backup
echo   powershell -ExecutionPolicy Bypass -File .\scripts\windows\auto_repair.ps1
echo.
echo ================================================
echo.
pause
