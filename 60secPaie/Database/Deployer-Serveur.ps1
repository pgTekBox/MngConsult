<#
.SYNOPSIS
    Déploie le schéma « paie » sur un serveur SQL, en lisant la chaîne de connexion
    dans le fichier de configuration d'une application existante. Le mot de passe n'est jamais affiché.

.PARAMETER Config
    Fichier web.config qui contient la chaîne de connexion (appSettings, clé donnée par -Cle).
.PARAMETER Action
    Verifier   : lecture seule (connexion, droits, état du schéma paie).
    Schema     : exécute 01_schema.sql.
    Donnees    : exécute export\02_donnees.sql (produit par Exporter-Donnees.ps1).
    Configurer : écrit ConnectionStrings.config de l'application 60secPaie à partir de cette chaîne de connexion.
#>
param(
    [string]$Config = 'C:\MesSources\MngConsult\prjMngConsul\Web.config',
    [string]$Cle = 'ConnectionString',
    [ValidateSet('Verifier', 'Schema', 'Configurer')][string]$Action = 'Verifier'
)

$ErrorActionPreference = 'Stop'

[xml]$xml = Get-Content -LiteralPath $Config -Encoding UTF8
$noeud = $xml.configuration.appSettings.add | Where-Object { $_.key -eq $Cle } | Select-Object -First 1
if (-not $noeud) { throw "Clé '$Cle' introuvable dans $Config." }

# On reconstruit une chaîne propre : seuls le serveur, la base et le compte sont repris.
$origine = New-Object System.Data.SqlClient.SqlConnectionStringBuilder $noeud.value
$b = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$b['Data Source'] = $origine['Data Source']
$b['Initial Catalog'] = $origine['Initial Catalog']
$b['User ID'] = $origine['User ID']
$b['Password'] = $origine['Password']
$b['MultipleActiveResultSets'] = $true
$b['Connect Timeout'] = 30
$base = [string]$b['Initial Catalog']
Write-Output "Serveur : $($b['Data Source'])   Base : $base   Compte : $($b['User ID'])   (mot de passe lu dans le fichier, non affiché)"

function Invoke-Script([System.Data.SqlClient.SqlConnection]$cn, [string]$fichier) {
    $sql = [System.IO.File]::ReadAllText($fichier, [System.Text.Encoding]::UTF8).Replace('$(Base)', $base)
    $lots = [regex]::Split($sql, '^\s*GO\s*$', 'Multiline, IgnoreCase')
    foreach ($lot in $lots) {
        if ($lot.Trim().Length -eq 0) { continue }
        $cmd = $cn.CreateCommand()
        $cmd.CommandTimeout = 120
        $cmd.CommandText = $lot
        [void]$cmd.ExecuteNonQuery()   # une erreur arrête tout : aucun lot suivant n'est exécuté
    }
}

if ($Action -eq 'Configurer') {
    $dossier = (Resolve-Path (Join-Path $PSScriptRoot '..\src\60secPaie.Web')).Path
    $doc = New-Object System.Xml.XmlDocument
    [void]$doc.AppendChild($doc.CreateXmlDeclaration('1.0', 'utf-8', $null))
    [void]$doc.AppendChild($doc.CreateComment(' Genere par Deployer-Serveur.ps1. Exclu de git : contient le mot de passe du serveur SQL. '))
    $racine = $doc.CreateElement('connectionStrings')
    [void]$doc.AppendChild($racine)
    $add = $doc.CreateElement('add')
    $add.SetAttribute('name', 'Paie')
    $add.SetAttribute('connectionString', $b.ConnectionString)
    $add.SetAttribute('providerName', 'System.Data.SqlClient')
    [void]$racine.AppendChild($add)
    $doc.Save((Join-Path $dossier 'ConnectionStrings.config'))
    Write-Output "ConnectionStrings.config pointe maintenant vers $($b['Data Source']) / $base."
    return
}

$cn = New-Object System.Data.SqlClient.SqlConnection $b.ConnectionString
$cn.add_InfoMessage({ param($s, $e) Write-Host ("  SQL : " + $e.Message) })
$cn.Open()
try {
    if ($Action -eq 'Verifier') {
        $cmd = $cn.CreateCommand()
        $cmd.CommandText = @"
SELECT @@SERVERNAME AS Serveur, DB_NAME() AS Base, SUSER_SNAME() AS Compte,
       CAST(SERVERPROPERTY('ProductVersion') AS varchar(30)) AS Version,
       IS_MEMBER('db_owner') AS EstDbOwner,
       HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'CREATE SCHEMA') AS PeutCreerSchema,
       HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'CREATE TABLE') AS PeutCreerTable,
       CASE WHEN SCHEMA_ID('paie') IS NULL THEN 0 ELSE 1 END AS SchemaPaieExiste,
       (SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID('paie')) AS TablesDansPaie,
       (SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID('dbo')) AS TablesDansDbo
"@
        $r = $cmd.ExecuteReader()
        [void]$r.Read()
        for ($i = 0; $i -lt $r.FieldCount; $i++) { Write-Output ("  {0,-18} {1}" -f $r.GetName($i), $r.GetValue($i)) }
        $r.Close()
    }
    elseif ($Action -eq 'Schema') {
        Invoke-Script $cn (Join-Path $PSScriptRoot '01_schema.sql')
        Write-Output 'Schéma paie déployé.'
    }
}
finally {
    $cn.Dispose()
}
