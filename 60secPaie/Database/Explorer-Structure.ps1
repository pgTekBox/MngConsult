<#
.SYNOPSIS
    LECTURE SEULE. Décrit la STRUCTURE (jamais les données) des tables de la base partagée dont le nom correspond à un motif :
    colonnes, types, clés. Sert à préparer l'intégration de 60secPaie avec les utilisateurs et compagnies de MngConsul.
    La chaîne de connexion est lue dans le Web.config d'une application existante et n'est jamais affichée.
#>
param(
    [string]$Config = 'C:\MesSources\MngConsult\prjMngConsul\Web.config',
    [string]$Cle = 'ConnectionString',
    [string[]]$Motifs = @('%'),
    [switch]$ListeSeulement
)

$ErrorActionPreference = 'Stop'
[xml]$xml = Get-Content -LiteralPath $Config -Encoding UTF8
$noeud = $xml.configuration.appSettings.add | Where-Object { $_.key -eq $Cle } | Select-Object -First 1
$o = New-Object System.Data.SqlClient.SqlConnectionStringBuilder $noeud.value
$b = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$b['Data Source'] = $o['Data Source']; $b['Initial Catalog'] = $o['Initial Catalog']
$b['User ID'] = $o['User ID']; $b['Password'] = $o['Password']; $b['Connect Timeout'] = 30

$cn = New-Object System.Data.SqlClient.SqlConnection $b.ConnectionString
$cn.Open()
try {
    foreach ($motif in $Motifs) {
        $cmd = $cn.CreateCommand()
        if ($ListeSeulement) {
            # Noms de tables et nombre de lignes approximatif (métadonnées seulement).
            $cmd.CommandText = "SELECT s.name + '.' + t.name AS TableName, SUM(p.rows) AS Lignes FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id " +
                               "JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1) WHERE t.name LIKE @m GROUP BY s.name, t.name ORDER BY 1"
        } else {
            $cmd.CommandText = "SELECT c.TABLE_SCHEMA + '.' + c.TABLE_NAME AS TableName, c.COLUMN_NAME, c.DATA_TYPE + " +
                               "CASE WHEN c.CHARACTER_MAXIMUM_LENGTH IS NOT NULL THEN '(' + CASE WHEN c.CHARACTER_MAXIMUM_LENGTH = -1 THEN 'max' ELSE CAST(c.CHARACTER_MAXIMUM_LENGTH AS varchar) END + ')' ELSE '' END AS Type, " +
                               "c.IS_NULLABLE AS Nullable, CASE WHEN k.COLUMN_NAME IS NOT NULL THEN 'PK' ELSE '' END AS Cle, " +
                               "CASE WHEN COLUMNPROPERTY(OBJECT_ID(c.TABLE_SCHEMA + '.' + c.TABLE_NAME), c.COLUMN_NAME, 'IsIdentity') = 1 THEN 'identity' ELSE '' END AS Ident " +
                               "FROM INFORMATION_SCHEMA.COLUMNS c LEFT JOIN (SELECT ku.TABLE_SCHEMA, ku.TABLE_NAME, ku.COLUMN_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc " +
                               "JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE ku ON ku.CONSTRAINT_NAME = tc.CONSTRAINT_NAME AND ku.TABLE_SCHEMA = tc.TABLE_SCHEMA WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY') k " +
                               "ON k.TABLE_SCHEMA = c.TABLE_SCHEMA AND k.TABLE_NAME = c.TABLE_NAME AND k.COLUMN_NAME = c.COLUMN_NAME " +
                               "WHERE c.TABLE_NAME LIKE @m AND c.TABLE_SCHEMA <> 'paie' ORDER BY c.TABLE_SCHEMA, c.TABLE_NAME, c.ORDINAL_POSITION"
        }
        [void]$cmd.Parameters.AddWithValue('@m', $motif)
        $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
        $dt = New-Object System.Data.DataTable
        [void]$da.Fill($dt)
        $dt | Format-Table -AutoSize | Out-String -Width 220 | Write-Output
    }
}
finally { $cn.Dispose() }
