<#
.SYNOPSIS
    Exporte les données du schéma « paie » d'une base source en un script SQL (INSERT) à exécuter sur une autre base.

.DESCRIPTION
    Sert à transférer la base de développement (LocalDB) vers le serveur. Le script produit :
      - refuse de s'exécuter si la base de destination contient déjà des données de paie (aucun doublon possible) ;
      - conserve les identifiants (IDENTITY_INSERT), donc tous les liens entre les tables ;
      - s'exécute dans une seule transaction : tout ou rien.
    Le fichier produit contient des renseignements personnels (employés, hachages de mots de passe, NAS chiffrés) :
    il est écrit dans Database\export, qui est exclu de git. Supprimez-le après le transfert.

.EXAMPLE
    .\Exporter-Donnees.ps1
    sqlcmd -S 192.168.0.203 -U MngConsul -C -f 65001 -v Base=MngConsul -i export\02_donnees.sql
#>
param(
    [string]$Source = 'Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=60secPaie;Integrated Security=True',
    [string]$Sortie = (Join-Path $PSScriptRoot 'export\02_donnees.sql')
)

$ErrorActionPreference = 'Stop'
$inv = [System.Globalization.CultureInfo]::InvariantCulture

# Ordre imposé par les clés étrangères.
$tables = 'Utilisateur', 'Compagnie', 'ElementPaie', 'Employe', 'EmployeElement', 'CumulatifDepart', 'LotPaie',
          'Remise', 'Paie', 'PaieLigne', 'RemiseLigne', 'JournalActivite', 'CompteGL'

function ConvertTo-SqlLiteral($valeur) {
    if ($null -eq $valeur -or $valeur -is [System.DBNull]) { return 'NULL' }
    if ($valeur -is [bool])     { if ($valeur) { return '1' } else { return '0' } }
    if ($valeur -is [datetime]) { return "'" + $valeur.ToString('yyyy-MM-ddTHH:mm:ss', $inv) + "'" }
    if ($valeur -is [decimal] -or $valeur -is [double] -or $valeur -is [single]) { return ([decimal]$valeur).ToString($inv) }
    if ($valeur -is [int] -or $valeur -is [long] -or $valeur -is [int16] -or $valeur -is [byte]) { return $valeur.ToString($inv) }
    return "N'" + ([string]$valeur).Replace("'", "''") + "'"
}

$cn = New-Object System.Data.SqlClient.SqlConnection $Source
$cn.Open()
try {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("/* Données 60secPaie exportées le $(Get-Date -Format 'yyyy-MM-dd HH:mm'). Contient des renseignements personnels : à supprimer après le transfert.")
    [void]$sb.AppendLine('   Exécution : sqlcmd -S <serveur> -U <compte> -C -f 65001 -v Base=<base> -i 02_donnees.sql   (le schéma doit déjà être créé par 01_schema.sql) */')
    [void]$sb.AppendLine('USE [$(Base)];')
    [void]$sb.AppendLine('GO')
    [void]$sb.AppendLine('SET NOCOUNT ON; SET XACT_ABORT ON;')
    [void]$sb.AppendLine("IF OBJECT_ID(N'paie.Compagnie') IS NULL")
    [void]$sb.AppendLine("BEGIN RAISERROR(N'Le schéma paie n''existe pas dans cette base : exécutez d''abord 01_schema.sql.', 16, 1); SET NOEXEC ON; END")
    [void]$sb.AppendLine('GO')
    [void]$sb.AppendLine('IF EXISTS (SELECT 1 FROM paie.Compagnie) OR EXISTS (SELECT 1 FROM paie.Utilisateur) OR EXISTS (SELECT 1 FROM paie.Employe)')
    [void]$sb.AppendLine("BEGIN RAISERROR(N'La base de destination contient déjà des données de paie : transfert annulé pour éviter les doublons.', 16, 1); SET NOEXEC ON; END")
    [void]$sb.AppendLine('GO')
    [void]$sb.AppendLine('BEGIN TRANSACTION;')

    $totalLignes = 0
    foreach ($table in $tables) {
        $cmd = $cn.CreateCommand()
        $cmd.CommandText = "SELECT * FROM paie.[$table] ORDER BY 1"
        $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
        $dt = New-Object System.Data.DataTable
        [void]$da.Fill($dt)

        $cmd.CommandText = "SELECT COUNT(*) FROM sys.identity_columns WHERE object_id = OBJECT_ID(N'paie.$table')"
        $aIdentite = [int]$cmd.ExecuteScalar() -gt 0

        [void]$sb.AppendLine("-- $table : $($dt.Rows.Count) ligne(s)")
        if ($dt.Rows.Count -eq 0) { continue }

        $colonnes = ($dt.Columns | ForEach-Object { "[$($_.ColumnName)]" }) -join ', '
        if ($aIdentite) { [void]$sb.AppendLine("SET IDENTITY_INSERT paie.[$table] ON;") }
        foreach ($ligne in $dt.Rows) {
            $valeurs = ($dt.Columns | ForEach-Object { ConvertTo-SqlLiteral $ligne[$_.ColumnName] }) -join ', '
            [void]$sb.AppendLine("INSERT INTO paie.[$table] ($colonnes) VALUES ($valeurs);")
            $totalLignes++
        }
        if ($aIdentite) { [void]$sb.AppendLine("SET IDENTITY_INSERT paie.[$table] OFF;") }
    }

    [void]$sb.AppendLine('COMMIT TRANSACTION;')
    [void]$sb.AppendLine("PRINT N'Transfert des données 60secPaie terminé : $totalLignes ligne(s).';")
    [void]$sb.AppendLine('GO')
    [void]$sb.AppendLine('SET NOEXEC OFF;')
    [void]$sb.AppendLine('GO')

    $dossier = Split-Path $Sortie -Parent
    if (-not (Test-Path $dossier)) { New-Item -ItemType Directory -Force $dossier | Out-Null }
    [System.IO.File]::WriteAllText($Sortie, $sb.ToString(), (New-Object System.Text.UTF8Encoding $true))
    Write-Output "$totalLignes ligne(s) exportée(s) de $($tables.Count) tables vers $Sortie"
}
finally {
    $cn.Dispose()
}
