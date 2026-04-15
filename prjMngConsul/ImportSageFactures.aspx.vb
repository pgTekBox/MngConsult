Imports System.Data.SqlClient

Public Class ImportSageFactures
    Inherits ImportSageBase

    Protected Overrides ReadOnly Property StagingTableName As String = "staging.SageFactures"
    Protected Overrides ReadOnly Property PageTitle As String = "Import Factures Ouvertes"
    Protected Overrides ReadOnly Property PageSubTitle As String = "Migration Sage 50 → staging.SageFactures"
    Protected Overrides ReadOnly Property PageIcon As String = "🧾"
    Protected Overrides ReadOnly Property SageExportPath As String = "Reports > Receivables > Customer Aged / Payables > Vendor Aged"

    Protected Overrides ReadOnly Property ColumnDefinitions As List(Of ColumnDef)
        Get
            Return New List(Of ColumnDef) From {
                New ColumnDef With {
                    .FieldName = "SageDocNumber", .DbColumnName = "SageDocNumber",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 200,
                    .IsRequired = True, .CsvHeader = "Invoice Number",
                    .DetectKeywords = New String() {"invoice", "facture", "number", "numéro", "doc"},
                    .Description = "Numéro de facture"
                },
                New ColumnDef With {
                    .FieldName = "SagePartyName", .DbColumnName = "SagePartyName",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 500,
                    .IsRequired = False, .CsvHeader = "Customer/Vendor Name",
                    .DetectKeywords = New String() {"customer", "vendor", "client", "fournisseur", "name", "nom"},
                    .Description = "Nom du client/fournisseur"
                },
                New ColumnDef With {
                    .FieldName = "SageDocType", .DbColumnName = "SageDocType",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 50,
                    .IsRequired = False, .CsvHeader = "Document Type",
                    .DetectKeywords = New String() {"type", "doc type"},
                    .Description = "FactureClient, FactureFournisseur, etc."
                },
                New ColumnDef With {
                    .FieldName = "SageDocDate", .DbColumnName = "SageDocDate",
                    .SqlType = SqlDbType.Date, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Date",
                    .DetectKeywords = New String() {"date", "invoice date", "date facture"},
                    .Description = "Date de la facture"
                },
                New ColumnDef With {
                    .FieldName = "SageDueDate", .DbColumnName = "SageDueDate",
                    .SqlType = SqlDbType.Date, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Due Date",
                    .DetectKeywords = New String() {"due", "échéance", "echeance"},
                    .Description = "Date d'échéance"
                },
                New ColumnDef With {
                    .FieldName = "SageSubTotal", .DbColumnName = "SageSubTotal",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Subtotal",
                    .DetectKeywords = New String() {"subtotal", "sous-total", "ht", "hors taxe"},
                    .Description = "Sous-total HT"
                },
                New ColumnDef With {
                    .FieldName = "SageTPS", .DbColumnName = "SageTPS",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "GST/TPS",
                    .DetectKeywords = New String() {"tps", "gst"},
                    .Description = "Montant TPS"
                },
                New ColumnDef With {
                    .FieldName = "SageTVQ", .DbColumnName = "SageTVQ",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "QST/TVQ",
                    .DetectKeywords = New String() {"tvq", "qst"},
                    .Description = "Montant TVQ"
                },
                New ColumnDef With {
                    .FieldName = "SageTotal", .DbColumnName = "SageTotal",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Total",
                    .DetectKeywords = New String() {"total", "ttc", "amount", "montant"},
                    .Description = "Total TTC"
                },
                New ColumnDef With {
                    .FieldName = "SageStatus", .DbColumnName = "SageStatus",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 50,
                    .IsRequired = False, .CsvHeader = "Status",
                    .DetectKeywords = New String() {"status", "statut", "état"},
                    .Description = "Ouverte, Payee, Partielle"
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
