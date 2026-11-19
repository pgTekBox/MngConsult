# =============================================================================
# FAKE APIDECK — TEMPORAIRE, à retirer au renouvellement de l'essai Apideck.
#
# Exporte la dernière extraction réelle d'une compagnie (staging.ConnecteurDonnee)
# vers App_Data\ApideckFake\{ressource}.json. Avec Apideck.Fake=true dans
# Web.config, clsApideckFake rejoue ces fichiers à la place d'Apideck.
#
# Les fichiers survivent aux vidages de la préparation (s-vider), qui effacent
# staging.ConnecteurDonnee.
#
#   .\Database\Outils\ExporterApideckFake.ps1
#   .\Database\Outils\ExporterApideckFake.ps1 -CompanyGUID D89EB638-6B05-443D-B1C9-01A6316443BF
# =============================================================================
param(
    [string]$CompanyGUID = 'D2D2D2D2-0000-4000-8000-000000000002',
    [string]$Dossier
)

$ErrorActionPreference = 'Stop'
$racine = Resolve-Path (Join-Path $PSScriptRoot '..\..')
if (-not $Dossier) { $Dossier = Join-Path $racine 'App_Data\ApideckFake' }

# La chaîne de connexion de l'application : une seule source de vérité.
[xml]$config = Get-Content (Join-Path $racine 'Web.config') -Raw
$cs = ($config.configuration.appSettings.add | Where-Object { $_.key -eq 'ConnectionString' }).value
if (-not $cs) { throw 'ConnectionString introuvable dans Web.config.' }

New-Item -ItemType Directory -Force $Dossier | Out-Null

# Pour chaque ressource, la dernière extraction qui l'a lue.
$sql = @'
WITH dernier AS (
    SELECT [Ressource], MAX([RunId]) AS [RunId]
      FROM staging.ConnecteurDonnee
     WHERE [CompanyGUID] = @CompanyGUID
     GROUP BY [Ressource]
)
SELECT d.[Ressource], d.[Json]
  FROM staging.ConnecteurDonnee d
  JOIN dernier x ON x.[Ressource] = d.[Ressource] AND x.[RunId] = d.[RunId]
 WHERE d.[CompanyGUID] = @CompanyGUID
 ORDER BY d.[Ressource], d.[Rang];
'@

$cn = New-Object System.Data.SqlClient.SqlConnection $cs
$cn.Open()
try {
    $cmd = $cn.CreateCommand()
    $cmd.CommandText = $sql
    $cmd.CommandTimeout = 300
    [void]$cmd.Parameters.AddWithValue('@CompanyGUID', [Guid]$CompanyGUID)
    $lecteur = $cmd.ExecuteReader()

    $parRessource = [ordered]@{}
    while ($lecteur.Read()) {
        $r = $lecteur.GetString(0)
        if (-not $parRessource.Contains($r)) { $parRessource[$r] = New-Object System.Collections.Generic.List[string] }
        $parRessource[$r].Add($lecteur.GetString(1))
    }
    $lecteur.Close()
}
finally { $cn.Close() }

if ($parRessource.Count -eq 0) { throw "Aucune extraction enregistrée pour $CompanyGUID." }

$utf8 = New-Object System.Text.UTF8Encoding $false
foreach ($r in $parRessource.Keys) {
    $fichier = Join-Path $Dossier ($r + '.json')
    [IO.File]::WriteAllText($fichier, '[' + ($parRessource[$r] -join ",`n") + ']', $utf8)
    '{0,-24} {1,6} enregistrement(s)' -f $r, $parRessource[$r].Count
}
"Exporté vers $Dossier"
