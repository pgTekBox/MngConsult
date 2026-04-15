Imports System.Data.SqlClient

Public Class ImportSageFactureLines
    Inherits ImportSageBase

    Protected Overrides ReadOnly Property StagingTableName As String = "staging.SageFactureLines"
    Protected Overrides ReadOnly Property PageTitle As String = "Import Lignes de Factures"
    Protected Overrides ReadOnly Property PageSubTitle As String = "Migration Sage 50 → staging.SageFactureLines"
    Protected Overrides ReadOnly Property PageIcon As String = "📝"
    Protected Overrides ReadOnly Property SageExportPath As String = "Reports > Receivables / Payables > Invoice Detail"

    Protected Overrides ReadOnly Property ColumnDefinitions As List(Of ColumnDef)
        Get
            Return New List(Of ColumnDef) From {
                New ColumnDef With {
                    .FieldName = "SageDocNumber", .DbColumnName = "SageDocNumber",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 200,
                    .IsRequired = True, .CsvHeader = "Invoice Number",
                    .DetectKeywords = New String() {"invoice", "facture", "number", "numéro", "doc"},
                    .Description = "Numéro de facture parent"
                },
                New ColumnDef With {
                    .FieldName = "SageLineDesc", .DbColumnName = "SageLineDesc",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 1000,
                    .IsRequired = False, .CsvHeader = "Description",
                    .DetectKeywords = New String() {"description", "desc", "libellé", "libelle", "item"},
                    .Description = "Description de la ligne"
                },
                New ColumnDef With {
                    .FieldName = "SageQty", .DbColumnName = "SageQty",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Quantity",
                    .DetectKeywords = New String() {"qty", "quantity", "quantité", "quantite"},
                    .Description = "Quantité"
                },
                New ColumnDef With {
                    .FieldName = "SageUnitPrice", .DbColumnName = "SageUnitPrice",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Unit Price",
                    .DetectKeywords = New String() {"unit price", "prix", "price", "unitaire"},
                    .Description = "Prix unitaire"
                },
                New ColumnDef With {
                    .FieldName = "SageAmount", .DbColumnName = "SageAmount",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Amount",
                    .DetectKeywords = New String() {"amount", "montant", "total", "line total"},
                    .Description = "Montant de la ligne"
                },
                New ColumnDef With {
                    .FieldName = "SageCompteComptable", .DbColumnName = "SageCompteComptable",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 20,
                    .IsRequired = False, .CsvHeader = "GL Account",
                    .DetectKeywords = New String() {"account", "gl", "compte", "comptable"},
                    .Description = "Compte comptable"
                },
                New ColumnDef With {
                    .FieldName = "SageTaxeCode", .DbColumnName = "SageTaxeCode",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 20,
                    .IsRequired = False, .CsvHeader = "Tax Code",
                    .DetectKeywords = New String() {"tax", "taxe", "code taxe", "tax code"},
                    .Description = "Code taxe (TPS_TVQ, EXEMPT...)"
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
