@echo off
echo.
echo ================================================
echo   IT Support Automation Toolkit - Setup
echo ================================================
echo.
echo [1/2] Unblocking all scripts...
powershell -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '.\scripts' -Recurse -Include *.ps1 | Unblock-File"
echo Done.
echo.
echo [2/2] Cleaning scripts...
powershell -ExecutionPolicy Bypass -Command "Get-ChildItem -Recurse -Include *.ps1 | ForEach-Object { $c = Get-Content $_.FullName -Raw -Encoding UTF8; $c = $c -replace '[^\x00-\x7F]', ''; Set-Content $_.FullName -Value $c -Encoding UTF8 }"
echo Done.
echo.
echo ================================================
echo   SETUP COMPLETE
echo.
echo   Run this to start:
echo   powershell -ExecutionPolicy Bypass -File .\scripts\windows\master.ps1
echo ================================================
echo.
pause