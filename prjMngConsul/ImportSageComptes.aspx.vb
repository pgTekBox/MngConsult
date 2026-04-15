Imports System.Data.SqlClient

Public Class ImportSageComptes
    Inherits ImportSageBase

    Protected Overrides ReadOnly Property StagingTableName As String = "staging.SageComptes"
    Protected Overrides ReadOnly Property PageTitle As String = "Import Plan Comptable"
    Protected Overrides ReadOnly Property PageSubTitle As String = "Migration Sage 50 → staging.SageComptes"
    Protected Overrides ReadOnly Property PageIcon As String = "📊"
    Protected Overrides ReadOnly Property SageExportPath As String = "Reports > Lists > Chart of Accounts > Export CSV"

    Protected Overrides ReadOnly Property ColumnDefinitions As List(Of ColumnDef)
        Get
            Return New List(Of ColumnDef) From {
                New ColumnDef With {
                    .FieldName = "SageAccountNumber", .DbColumnName = "SageAccountNumber",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 20,
                    .IsRequired = True, .CsvHeader = "Account Number",
                    .DetectKeywords = New String() {"account", "num", "numéro", "numero", "compte", "no"},
                    .Description = "Numéro du compte"
                },
                New ColumnDef With {
                    .FieldName = "SageAccountName", .DbColumnName = "SageAccountName",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 200,
                    .CsvHeader = "Account Name",
                    .DetectKeywords = New String() {"name", "nom", "description", "libellé", "libelle"},
                    .Description = "Nom du compte"
                },
                New ColumnDef With {
                    .FieldName = "SageAccountType", .DbColumnName = "SageAccountType",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 50,
                    .CsvHeader = "Account Type",
                    .DetectKeywords = New String() {"type", "catégorie", "categorie", "classe"},
                    .Description = "Asset, Liability, Equity, Revenue, Expense",
                    .Normalizer = AddressOf NormalizeAccountType
                },
                New ColumnDef With {
                    .FieldName = "SageBalance", .DbColumnName = "SageBalance",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .CsvHeader = "Balance",
                    .DetectKeywords = New String() {"balance", "solde", "montant", "amount"},
                    .Description = "Solde du compte"
                },
                New ColumnDef With {
                    .FieldName = "SageBalanceType", .DbColumnName = "SageBalanceType",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 10,
                    .CsvHeader = "Balance Type",
                    .DetectKeywords = New String() {"debit", "crédit", "credit", "balance type", "sens"},
                    .Description = "Debit ou Credit",
                    .Normalizer = AddressOf NormalizeBalanceType
                }
            }
        End Get
    End Property

    ' ── Contrôles ──
    Protected Overrides ReadOnly Property FileUploadControl As System.Web.UI.WebControls.FileUpload
        Get
            Return fuCsvFile
        End Get
    End Property
    Protected Overrides ReadOnly Property SeparatorDropDown As System.Web.UI.WebControls.DropDownList
        Get
            Return ddlSeparator
        End Get
    End Property
    Protected Overrides ReadOnly Property EncodingDropDown As System.Web.UI.WebControls.DropDownList
        Get
            Return ddlEncoding
        End Get
    End Property
    Protected Overrides ReadOnly Property HasHeaderCheckBox As System.Web.UI.WebControls.CheckBox
        Get
            Return chkHasHeader
        End Get
    End Property
    Protected Overrides ReadOnly Property TruncateCheckBox As System.Web.UI.WebControls.CheckBox
        Get
            Return chkTruncate
        End Get
    End Property
    Protected Overrides ReadOnly Property PreviewGrid As System.Web.UI.WebControls.GridView
        Get
            Return gvPreview
        End Get
    End Property
    Protected Overrides ReadOnly Property PreviewInfoLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litPreviewInfo
        End Get
    End Property
    Protected Overrides ReadOnly Property PreviewPanel As System.Web.UI.WebControls.Panel
        Get
            Return pnlPreview
        End Get
    End Property
    Protected Overrides ReadOnly Property SuccessPanel As System.Web.UI.WebControls.Panel
        Get
            Return pnlSuccess
        End Get
    End Property
    Protected Overrides ReadOnly Property ErrorPanel As System.Web.UI.WebControls.Panel
        Get
            Return pnlError
        End Get
    End Property
    Protected Overrides ReadOnly Property WarningPanel As System.Web.UI.WebControls.Panel
        Get
            Return pnlWarning
        End Get
    End Property
    Protected Overrides ReadOnly Property SuccessLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litSuccess
        End Get
    End Property
    Protected Overrides ReadOnly Property ErrorLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litError
        End Get
    End Property
    Protected Overrides ReadOnly Property WarningLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litWarning
        End Get
    End Property
    Protected Overrides ReadOnly Property ResultsPanel As System.Web.UI.WebControls.Panel
        Get
            Return pnlResults
        End Get
    End Property
    Protected Overrides ReadOnly Property InsertedLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litInserted
        End Get
    End Property
    Protected Overrides ReadOnly Property SkippedLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litSkipped
        End Get
    End Property
    Protected Overrides ReadOnly Property ErrorsLiteral As System.Web.UI.WebControls.Literal
        Get
            Return litErrors
        End Get
    End Property
    Protected Overrides ReadOnly Property ErrorDetailsPanel As System.Web.UI.WebControls.Panel
        Get
            Return pnlErrorDetails
        End Get
    End Property
    Protected Overrides ReadOnly Property ErrorsGrid As System.Web.UI.WebControls.GridView
        Get
            Return gvErrors
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
    End Sub

    Protected Sub btnPreview_Click(sender As Object, e As EventArgs) Handles btnPreview.Click
        DoPreview()
    End Sub

    Protected Sub btnImport_Click(sender As Object, e As EventArgs) Handles btnImport.Click
        DoImport()
    End Sub

    Protected Sub btnReset_Click(sender As Object, e As EventArgs) Handles btnReset.Click
        DoReset()
    End Sub

    Protected Sub btnTruncateTable_Click(sender As Object, e As EventArgs) Handles btnTruncateTable.Click
        DoTruncate()
    End Sub

    ' ── Normalizers ──

    Private Shared Function NormalizeAccountType(value As String) As String
        If String.IsNullOrWhiteSpace(value) Then Return value
        Dim t = value.Trim().ToLower()
        If t.Contains("asset") OrElse t.Contains("actif") Then Return "Asset"
        If t.Contains("liability") OrElse t.Contains("passif") Then Return "Liability"
        If t.Contains("equity") OrElse t.Contains("capitaux") OrElse t.Contains("avoir") Then Return "Equity"
        If t.Contains("revenue") OrElse t.Contains("revenu") OrElse t.Contains("income") Then Return "Revenue"
        If t.Contains("expense") OrElse t.Contains("charge") OrElse t.Contains("dépense") Then Return "Expense"
        Select Case t
            Case "a" : Return "Asset"
            Case "l" : Return "Liability"
            Case "e" : Return "Equity"
            Case "i", "r" : Return "Revenue"
            Case "x" : Return "Expense"
            Case Else : Return value
        End Select
    End Function

    Private Shared Function NormalizeBalanceType(value As String) As String
        If String.IsNullOrWhiteSpace(value) Then Return value
        Dim t = value.Trim().ToLower()
        If t.Contains("debit") OrElse t.Contains("débit") OrElse t = "d" OrElse t = "db" Then Return "Debit"
        If t.Contains("credit") OrElse t.Contains("crédit") OrElse t = "c" OrElse t = "cr" Then Return "Credit"
        Return value
    End Function

End Class
