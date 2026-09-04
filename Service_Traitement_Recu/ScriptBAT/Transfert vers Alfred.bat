 
@echo off

rem Copie du service compile vers le partage de deploiement.
rem /Y ecrase les fichiers existants sans demander.

copy /Y "..\bin\Debug\ServiceTraitementRecu.exe" "\\alfred\ServiceTraitementRecuDeploy\ServiceTraitementRecu.exe"
copy /Y "..\bin\Debug\ServiceTraitementRecu.exe.config" "\\alfred\ServiceTraitementRecuDeploy\ServiceTraitementRecu.exe.config"
copy /Y "..\bin\Debug\Newtonsoft.Json.dll" "\\alfred\ServiceTraitementRecuDeploy\Newtonsoft.Json.dll"

copy /Y "ServiceController.bat" "\\alfred\ServiceTraitementRecuDeploy\ServiceController.bat"
copy /Y "ServiceInstaller.bat" "\\alfred\ServiceTraitementRecuDeploy\ServiceInstaller.bat"
copy /Y "ServiceUninstaller.bat" "\\alfred\ServiceTraitementRecuDeploy\ServiceUninstaller.bat"
copy /Y "Interface.bat" "\\alfred\ServiceTraitementRecuDeploy\Interface.bat"

pause
 