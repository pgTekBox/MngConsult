@echo off
cd /d "%~dp0"
echo Demarrage %date% %time% > Rejouer-Scripts.log
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Deployer-Serveur.ps1" -Action Schema >> Rejouer-Scripts.log 2>&1
echo Fin, code %errorlevel% >> Rejouer-Scripts.log
type Rejouer-Scripts.log
echo.
pause
