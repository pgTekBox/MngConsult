Imports System.Data.SqlClient

Public Class ImportSageBalanceVerification
    Inherits ImportSageBase

    Protected Overrides ReadOnly Property StagingTableName As String = "staging.SageBalanceVerification"
    Protected Overrides ReadOnly Property PageTitle As String = "Import Balance de Vérification"
    Protected Overrides ReadOnly Property PageSubTitle As String = "Migration Sage 50 → staging.SageBalanceVerification"
    Protected Overrides ReadOnly Property PageIcon As String = "📋"
    Protected Overrides ReadOnly Property SageExportPath As String = "Reports > Financials > Trial Balance (à la date de coupure)"

    Protected Overrides ReadOnly Property ColumnDefinitions As List(Of ColumnDef)
        Get
            Return New List(Of ColumnDef) From {
                New ColumnDef With {
                    .FieldName = "SageCompte", .DbColumnName = "SageCompte",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 20,
                    .IsRequired = True, .CsvHeader = "Account Number / Numéro",
                    .DetectKeywords = New String() {"account", "num", "numéro", "numero", "compte", "no"},
                    .Description = "Numéro du compte"
                },
                New ColumnDef With {
                    .FieldName = "SageDescription", .DbColumnName = "SageDescription",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 200,
                    .IsRequired = False, .CsvHeader = "Account Name / Description",
                    .DetectKeywords = New String() {"name", "nom", "description", "libellé", "libelle"},
                    .Description = "Nom du compte"
                },
                New ColumnDef With {
                    .FieldName = "SageDebit", .DbColumnName = "SageDebit",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Debit Balance",
                    .DetectKeywords = New String() {"debit", "débit"},
                    .Description = "Solde débiteur"
                },
                New ColumnDef With {
                    .FieldName = "SageCredit", .DbColumnName = "SageCredit",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Credit Balance",
                    .DetectKeywords = New String() {"credit", "crédit"},
                    .Description = "Solde créditeur"
                }
            }
        End Get
    End Property

    ' ── Contrôles (liés au markup) ──
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

    ' ── Events ──
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

End Class
