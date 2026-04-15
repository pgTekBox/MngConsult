Imports System.Data.SqlClient

Public Class ImportSageProduits
    Inherits ImportSageBase

    Protected Overrides ReadOnly Property StagingTableName As String = "staging.SageProduits"
    Protected Overrides ReadOnly Property PageTitle As String = "Import Produits / Services"
    Protected Overrides ReadOnly Property PageSubTitle As String = "Migration Sage 50 → staging.SageProduits"
    Protected Overrides ReadOnly Property PageIcon As String = "📦"
    Protected Overrides ReadOnly Property SageExportPath As String = "Reports > Lists > Inventory & Services"

    Protected Overrides ReadOnly Property ColumnDefinitions As List(Of ColumnDef)
        Get
            Return New List(Of ColumnDef) From {
                New ColumnDef With {
                    .FieldName = "SageName", .DbColumnName = "SageName",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 500,
                    .IsRequired = True, .CsvHeader = "Item Name",
                    .DetectKeywords = New String() {"name", "nom", "item", "produit", "service"},
                    .Description = "Nom du produit/service"
                },
                New ColumnDef With {
                    .FieldName = "SageDescription", .DbColumnName = "SageDescription",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 2000,
                    .IsRequired = False, .CsvHeader = "Description",
                    .DetectKeywords = New String() {"description", "desc"},
                    .Description = "Description"
                },
                New ColumnDef With {
                    .FieldName = "SagePrice", .DbColumnName = "SagePrice",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Price",
                    .DetectKeywords = New String() {"price", "prix", "selling", "vente"},
                    .Description = "Prix de vente"
                },
                New ColumnDef With {
                    .FieldName = "SageCompteVente", .DbColumnName = "SageCompteVente",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 20,
                    .IsRequired = False, .CsvHeader = "Revenue Account",
                    .DetectKeywords = New String() {"revenue", "vente", "income", "sale"},
                    .Description = "Compte de vente"
                },
                New ColumnDef With {
                    .FieldName = "SageCompteAchat", .DbColumnName = "SageCompteAchat",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 20,
                    .IsRequired = False, .CsvHeader = "Expense Account",
                    .DetectKeywords = New String() {"expense", "achat", "cost", "charge"},
                    .Description = "Compte d'achat"
                },
                New ColumnDef With {
                    .FieldName = "SageTaxable", .DbColumnName = "SageTaxable",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 10,
                    .IsRequired = False, .CsvHeader = "Taxable",
                    .DetectKeywords = New String() {"taxable", "tax", "taxe"},
                    .Description = "Oui / Non"
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
