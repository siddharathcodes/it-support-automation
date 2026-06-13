@echo off
echo.
echo  Setting up IT Support Automation Toolkit...
echo.

:: Run PowerShell setup commands
powershell -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
powershell -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '.\scripts' -Recurse -Filter *.ps1 | Unblock-File"

echo.
echo  [DONE] Setup complete. You can now run any script.
echo.
echo  Example:
echo    powershell -ExecutionPolicy Bypass -File .\scripts\windows\system_info.ps1 -Export
echo.
pause