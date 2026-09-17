<#
.SYNOPSIS
    LECTURE SEULE. Valeurs distinctes de colonnes de CATÉGORIE (jamais de renseignements personnels) de T300Employees,
    et présence des objets MngConsul dont 60secPaie dépend. Connexion lue dans le Web.config de prjMngConsul, jamais affichée.
#>
$ErrorActionPreference = 'Stop'
[xml]$xml = Get-Content -LiteralPath 'C:\MesSources\MngConsult\prjMngConsul\Web.config' -Encoding UTF8
$v = ($xml.configuration.appSettings.add | Where-Object { $_.key -eq 'ConnectionString' } | Select-Object -First 1).value
$o = New-Object System.Data.SqlClient.SqlConnectionStringBuilder $v
$b = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$b['Data Source'] = $o['Data Source']; $b['Initial Catalog'] = $o['Initial Catalog']; $b['User ID'] = $o['User ID']; $b['Password'] = $o['Password']
$cn = New-Object System.Data.SqlClient.SqlConnection $b.ConnectionString
$cn.Open()
try {
    $requetes = [ordered]@{
        'PayFrequency'     = "SELECT ISNULL(PayFrequency,'(null)') AS Valeur, COUNT(*) AS Nb FROM dbo.T300Employees GROUP BY PayFrequency"
        'SalaryType'       = "SELECT ISNULL(SalaryType,'(null)') AS Valeur, COUNT(*) AS Nb FROM dbo.T300Employees GROUP BY SalaryType"
        'EmploymentStatus' = "SELECT ISNULL(EmploymentStatus,'(null)') AS Valeur, COUNT(*) AS Nb FROM dbo.T300Employees GROUP BY EmploymentStatus"
        'Remplissage'      = "SELECT COUNT(*) AS Employes, COUNT(DISTINCT CompanyGUID) AS Compagnies, SUM(CASE WHEN SIN IS NOT NULL AND SIN <> '' THEN 1 ELSE 0 END) AS AvecNAS, SUM(CASE WHEN HourlyRate > 0 THEN 1 ELSE 0 END) AS AvecTaux, SUM(CASE WHEN AnnualSalary > 0 THEN 1 ELSE 0 END) AS AvecSalaire, SUM(CASE WHEN BankAccount IS NOT NULL AND BankAccount <> '' THEN 1 ELSE 0 END) AS AvecCompte, SUM(CASE WHEN DateOfBirth IS NOT NULL THEN 1 ELSE 0 END) AS AvecNaissance FROM dbo.T300Employees"
        'Precision'        = "SELECT COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_SCALE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'T300Employees' AND DATA_TYPE = 'decimal'"
        'Objets'           = "SELECT name, type_desc FROM sys.objects WHERE name IN ('s0210GetUserCompanies','fCompanyName','fParamS','s0200GetUserByEmail','s0201UpdateLastLogin') ORDER BY name"
        'Provinces'        = "SELECT TOP 5 s.Id, s.Name FROM dbo.T053State s ORDER BY s.Id"
        'ProvinceQuebec'   = "SELECT Id, Name FROM dbo.T053State WHERE Name LIKE 'Qu%' OR NameFr LIKE 'Qu%'"
        'VuePaieEmploye'   = "SELECT (SELECT COUNT(*) FROM paie.Compagnie WHERE CompanyGUID IS NOT NULL) AS CompagniesAvecPaie, (SELECT COUNT(*) FROM paie.Employe) AS EmployesVisibles, (SELECT COUNT(*) FROM paie.EmployePaie) AS PaiesConfigurees"
        'ProcCompagnies'   = "SELECT COUNT(*) AS Utilisateurs, SUM(CASE WHEN isAccountant = 1 THEN 1 ELSE 0 END) AS Comptables, SUM(CASE WHEN IsAdmin = 1 THEN 1 ELSE 0 END) AS Admins FROM dbo.T015User WHERE IsDeleted = 0 AND IsActive = 1"
    }
    foreach ($nom in $requetes.Keys) {
        $cmd = $cn.CreateCommand(); $cmd.CommandText = $requetes[$nom]
        $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
        $dt = New-Object System.Data.DataTable; [void]$da.Fill($dt)
        "== $nom"
        $dt | Format-Table -AutoSize | Out-String -Width 200 | ForEach-Object { $_.Trim() }
    }
}
finally { $cn.Dispose() }
