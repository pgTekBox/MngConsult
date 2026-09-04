rem Copie du service compile vers le partage de deploiement.
rem /Y ecrase sans demander, /R remplace les fichiers en lecture seule, /C ignore les erreurs.

xcopy /Y/R/C ..\bin\Debug\ServiceTraitementRecu.exe        \alfred\TraitementRecuDeploy
xcopy /Y/R/C ..\bin\Debug\ServiceTraitementRecu.exe.config \alfred\TraitementRecuDeploy
xcopy /Y/R/C ..\bin\Debug\Newtonsoft.Json.dll              \alfred\TraitementRecuDeploy
xcopy /Y/R/C ServiceController.bat                         \alfred\TraitementRecuDeploy
xcopy /Y/R/C ServiceInstaller.bat                          \alfred\TraitementRecuDeploy
xcopy /Y/R/C ServiceUninstaller.bat                        \alfred\TraitementRecuDeploy
xcopy /Y/R/C Interface.bat                                 \alfred\TraitementRecuDeploy

pause
