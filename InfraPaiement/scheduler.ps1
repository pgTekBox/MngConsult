<#
  60secPaiement - Orchestrateur de taches planifiees (alternative a SQL Agent).
  A planifier via le Planificateur de taches Windows (schtasks).

  Modes :
    -Mode Webhooks : vide la file de webhooks (POST signe vers WebhookDispatcher.ashx).
                     A planifier toutes les 1-5 minutes.
    -Mode Daily    : reglement des echeances (s0056) + generation du lot EFT (s0057)
                     + maintenance/hygiene (s0079 : purge jetons remember-me + webhooks livres/abandonnes
                       + lignes de releve rapprochees + lots EFT regles + journaux d'echange
                       + retours EFT traites + paiements retournes [retention 7 ans par defaut]
                       + utilisateurs abonnes desactives [RGPD, retention 365 j]).
                     A planifier une fois par jour.

  Exemples d'enregistrement (a lancer en admin, adapter chemins/heures) :
    schtasks /Create /TN "60sec\Webhooks" /SC MINUTE /MO 2 ^
      /TR "powershell -NoProfile -ExecutionPolicy Bypass -File C:\...\scheduler.ps1 -Mode Webhooks"
    schtasks /Create /TN "60sec\Daily" /SC DAILY /ST 22:00 ^
      /TR "powershell -NoProfile -ExecutionPolicy Bypass -File C:\...\scheduler.ps1 -Mode Daily"

  Codes de sortie : 0 = succes, 1 = erreur (visible dans l'historique des taches).
#>
param(
  [ValidateSet("Webhooks", "Daily")]
  [string]$Mode = "Webhooks",

  # --- Configuration (a adapter au deploiement) ---
  [string]$PortailUrl    = "https://localhost/WebhookDispatcher.ashx?max=200",
  [string]$DispatchSecret = "dev-dispatch-6f2a9c14b8",   # = Web.config Webhook.DispatchSecret
  [string]$SqlServer     = "192.168.0.203",
  [string]$SqlUser       = "MngConsul",
  [string]$SqlPassword   = "wp@332p0",
  [string]$Database      = "60secPaiement"
)

$ErrorActionPreference = "Stop"

function Invoke-Proc([string]$proc) {
  Add-Type -AssemblyName System.Data
  $cs = "User Id=$SqlUser;Password=$SqlPassword;Initial Catalog=$Database;Data Source=$SqlServer;Connection Timeout=60"
  $conn = New-Object System.Data.SqlClient.SqlConnection $cs
  $conn.Open()
  try {
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $proc
    $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    $cmd.CommandTimeout = 300
    $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
    $dt = New-Object System.Data.DataTable
    [void]$da.Fill($dt)
    return ,$dt   # la virgule empeche PowerShell de derouler la DataTable en DataRow
  } finally { $conn.Close() }
}

try {
  switch ($Mode) {
    "Webhooks" {
      $r = Invoke-WebRequest -Uri $PortailUrl -Method POST `
             -Headers @{ "X-Dispatch-Secret" = $DispatchSecret } `
             -UseBasicParsing -TimeoutSec 60
      Write-Output ("[$(Get-Date -Format s)] Webhooks: HTTP $([int]$r.StatusCode) $($r.Content)")
    }
    "Daily" {
      $s = Invoke-Proc "s0056RunDailySettlement"
      if ($s.Rows.Count -gt 0) {
        Write-Output ("[$(Get-Date -Format s)] Reglement: entrants=$($s.Rows[0].NbEntrantsRegles) sortants=$($s.Rows[0].NbSortantsRegles)")
      }
      $b = Invoke-Proc "s0057AutoGenerateBatch"
      if ($b.Rows.Count -gt 0) {
        $created = $b.Rows[0].Created
        $batchId = if ($b.Rows[0].BatchId -is [DBNull]) { "-" } else { $b.Rows[0].BatchId }
        Write-Output ("[$(Get-Date -Format s)] Lot EFT: created=$created batchId=$batchId")
      }
      # Hygiene : jetons + webhooks livres/abandonnes + releve + lots EFT + journaux d'echange + retours traites.
      $m = Invoke-Proc "s0079RunDailyMaintenance"
      if ($m.Rows.Count -gt 0) {
        $r = $m.Rows[0]
        Write-Output ("[$(Get-Date -Format s)] Maintenance: jetons=$($r.PurgedTokens) webhooks=$($r.PurgedWebhooks) webhooksAband=$($r.PurgedAbandonedWebhooks) releve=$($r.PurgedBankLines) lotsEFT=$($r.PurgedEftBatches) journaux=$($r.PurgedExchangeLogs) retours=$($r.PurgedEftReturns) paiementsRet=$($r.PurgedReturnedPayments) usagersDesact=$($r.PurgedDeactivatedUsers)")
      }
    }
  }
  exit 0
} catch {
  Write-Error ("[$(Get-Date -Format s)] ERREUR ($Mode): " + $_.Exception.Message)
  exit 1
}
