@echo off

rem Copie du service compile vers le partage de deploiement.
rem /Y ecrase les fichiers existants sans demander.
robocopy "..\bin\Debug" "\\alfred\ServiceExecuteurDeploy" /E /R:2 /W:1
robocopy "..\ScriptBAT" "\\alfred\ServiceExecuteurDeploy" /E /R:2 /W:1

 

pause