rem /c	Ignores errors.
rem /e	Copies all subdirectories, even if they are empty. Use /e with the /s and /t command-line options.
rem /y	Suppresses prompting to confirm that you want to overwrite an existing destination file.
rem /c	Ignores errors.


 
xcopy	/Y/R/C	..\bin\debug\BouncyCastle.Crypto.dll	\\MTL-GI-05\PreDeploySMTPService
xcopy	/Y/R/C	..\bin\debug\DnsClient.dll	\\MTL-GI-05\PreDeploySMTPService 
xcopy	/Y/R/C	..\bin\debug\MailKit.dll	\\MTL-GI-05\PreDeploySMTPService 
xcopy	/Y/R/C	..\bin\debug\MimeKit.dll	\\MTL-GI-05\PreDeploySMTPService 
xcopy	/Y/R/C	..\bin\debug\System.Buffers.dll	\\MTL-GI-05\PreDeploySMTPService 
xcopy	/Y/R/C	..\bin\debug\TkbServiceMailTask.exe	\\MTL-GI-05\PreDeploySMTPService 
xcopy	/Y/R/C	 ServiceController.bat	\\MTL-GI-05\PreDeploySMTPService  
xcopy	/Y/R/C	 ServiceUninstaller.bat	\\MTL-GI-05\PreDeploySMTPService  
xcopy	/Y/R/C	 ServiceInstaller.bat	\\MTL-GI-05\PreDeploySMTPService  
 
  

pause
