# ============================================================================
# RunAutoPayProcessor.ps1
#
# Wrapper appele par SQL Server Agent pour declencher une operation d'auto-paiement
# via le handler HTTP AutoPayProcessor.ashx.
#
# Parametres :
#   -Mode      : "process" | "preavis24h" | "preavispad3d" | "health" (requis)
#   -BaseUrl   : URL de base du site (default https://60sec.ca)
#   -Secret    : Shared secret (sinon lu depuis $env:AUTOPAY_SECRET)
#   -BatchSize : taille batch en mode process (default 50, max 200)
#   -DaysAhead : jours avant debit en mode preavispad3d (default 3)
#   -Verbose   : verbose logging
#
# Exit codes :
#   0 = OK
#   1 = HTTP error (4xx ou 5xx)
#   2 = Network error / Unable to connect
#   3 = Invalid parameters
#
# Exemples :
#   .\RunAutoPayProcessor.ps1 -Mode process
#   .\RunAutoPayProcessor.ps1 -Mode preavis24h -BaseUrl http://localhost
#   .\RunAutoPayProcessor.ps1 -Mode health
#
# Configuration SQL Agent :
#   Step Type : PowerShell (ou CmdExec si PS bloque)
#   Command   : powershell.exe -ExecutionPolicy Bypass -File "<path>\RunAutoPayProcessor.ps1" -Mode process
#
# Logging :
#   stdout = sortie JSON du handler (parse par SQL Agent dans l'historique)
#   stderr = erreurs (capture par SQL Agent)
# ============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet('process','preavis24h','preavispad3d','health')]
    [string]$Mode,

    [Parameter(Mandatory=$false)]
    [string]$BaseUrl = 'https://60sec.ca',

    [Parameter(Mandatory=$false)]
    [string]$Secret = $env:AUTOPAY_SECRET,

    [Parameter(Mandatory=$false)]
    [int]$BatchSize = 50,

    [Parameter(Mandatory=$false)]
    [int]$DaysAhead = 3,

    [Parameter(Mandatory=$false)]
    [int]$TimeoutSec = 300
)

$ErrorActionPreference = 'Stop'

# Validation parametres
if ([string]::IsNullOrWhiteSpace($Secret) -and $Mode -ne 'health') {
    Write-Error "Secret non fourni. Passez -Secret ou definissez `$env:AUTOPAY_SECRET."
    exit 3
}

# Construction de l'URL
$url = $BaseUrl.TrimEnd('/') + '/AutoPayProcessor.ashx?mode=' + $Mode
switch ($Mode) {
    'process'       { $url += '&batch=' + $BatchSize }
    'preavispad3d'  { $url += '&days=' + $DaysAhead }
}

# Construction des headers
$headers = @{}
if (-not [string]::IsNullOrWhiteSpace($Secret)) {
    $headers['X-AutoPay-Secret'] = $Secret
}

# Forcer TLS 1.2 (necessaire pour certaines plateformes)
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}

# Logging
$timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
Write-Output "[$timestamp] AutoPay $Mode -> $url"

# Appel HTTP
try {
    $response = Invoke-WebRequest -Uri $url -Headers $headers -Method 'GET' -TimeoutSec $TimeoutSec -UseBasicParsing
    $statusCode = $response.StatusCode
    $body = $response.Content

    Write-Output "[$timestamp] HTTP $statusCode"
    Write-Output $body

    if ($statusCode -ge 200 -and $statusCode -lt 300) {
        exit 0
    } else {
        Write-Error "HTTP $statusCode"
        exit 1
    }
} catch [System.Net.WebException] {
    $we = $_.Exception
    if ($we.Response) {
        try {
            $errResp = $we.Response
            $errStatus = [int]$errResp.StatusCode
            $errStream = $errResp.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errStream)
            $errBody = $reader.ReadToEnd()
            $reader.Close()
            Write-Output "[$timestamp] HTTP $errStatus"
            Write-Output $errBody
            Write-Error "HTTP error $errStatus from AutoPayProcessor"
        } catch {
            Write-Error "WebException without readable response : $($we.Message)"
        }
    } else {
        Write-Error "Network error : $($we.Message)"
    }
    exit 2
} catch {
    Write-Error "Unexpected error : $($_.Exception.Message)"
    exit 2
}
