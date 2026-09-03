# =============================================================
#  run-smoke.ps1
#  Demarre le site (IIS Express), attend qu'il reponde,
#  lance le smoke test, puis arrete le site.
#
#  Usage :  pwsh run-smoke.ps1
#  (Ne pas avoir le site deja demarre dans Visual Studio en meme temps.)
# =============================================================

$ErrorActionPreference = 'Stop'

$iis    = 'C:\Program Files\IIS Express\iisexpress.exe'
$config = 'C:\MesSources\MngConsul\prjMngConsul\.vs\prjMngConsul.slnx\config\applicationhost.config'
$site   = 'prjMngConsul'
$url    = 'http://localhost:53024/wbfLogin.aspx'
$proj   = 'C:\MesSources\MngConsul\Tests\MngConsul.E2E.Tests'

Write-Host "Demarrage du site ($site) via IIS Express..." -ForegroundColor Cyan
$p = Start-Process -FilePath $iis -ArgumentList @("/config:$config", "/site:$site") -PassThru

try {
    # Attendre que le site reponde (max 60 s)
    $ok = $false
    for ($i = 0; $i -lt 60; $i++) {
        try {
            $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3
            if ($r.StatusCode -ge 200) { $ok = $true; break }
        } catch {
            Start-Sleep -Seconds 1
        }
    }

    if (-not $ok) {
        throw "Le site n'a pas repondu sur $url apres 60 s. Verifie la config IIS Express."
    }

    Write-Host "Site pret. Lancement du smoke test..." -ForegroundColor Green
    dotnet test $proj --nologo
}
finally {
    Write-Host "Arret du site..." -ForegroundColor Cyan
    if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force }
}
