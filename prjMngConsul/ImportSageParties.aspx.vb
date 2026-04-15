Imports System.Data.SqlClient

Public Class ImportSageParties
    Inherits ImportSageBase

    Protected Overrides ReadOnly Property StagingTableName As String = "staging.SageParties"
    Protected Overrides ReadOnly Property PageTitle As String = "Import Clients / Fournisseurs"
    Protected Overrides ReadOnly Property PageSubTitle As String = "Migration Sage 50 → staging.SageParties"
    Protected Overrides ReadOnly Property PageIcon As String = "👥"
    Protected Overrides ReadOnly Property SageExportPath As String = "Reports > Lists > Customers / Vendors"

    Protected Overrides ReadOnly Property ColumnDefinitions As List(Of ColumnDef)
        Get
            Return New List(Of ColumnDef) From {
                New ColumnDef With {
                    .FieldName = "SageName", .DbColumnName = "SageName",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 500,
                    .IsRequired = True, .CsvHeader = "Name / Nom",
                    .DetectKeywords = New String() {"name", "nom", "raison"},
                    .Description = "Nom du tiers"
                },
                New ColumnDef With {
                    .FieldName = "SageType", .DbColumnName = "SageType",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 20,
                    .IsRequired = False, .CsvHeader = "Type",
                    .DetectKeywords = New String() {"type"},
                    .Description = "Client ou Fournisseur"
                },
                New ColumnDef With {
                    .FieldName = "SageContactName", .DbColumnName = "SageContactName",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 200,
                    .IsRequired = False, .CsvHeader = "Contact Name",
                    .DetectKeywords = New String() {"contact"},
                    .Description = "Nom du contact"
                },
                New ColumnDef With {
                    .FieldName = "SageAddress1", .DbColumnName = "SageAddress1",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 500,
                    .IsRequired = False, .CsvHeader = "Address 1",
                    .DetectKeywords = New String() {"address1", "adresse1", "address"},
                    .Description = "Adresse ligne 1"
                },
                New ColumnDef With {
                    .FieldName = "SageAddress2", .DbColumnName = "SageAddress2",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 500,
                    .IsRequired = False, .CsvHeader = "Address 2",
                    .DetectKeywords = New String() {"address2", "adresse2"},
                    .Description = "Adresse ligne 2"
                },
                New ColumnDef With {
                    .FieldName = "SageCity", .DbColumnName = "SageCity",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 50,
                    .IsRequired = False, .CsvHeader = "City / Ville",
                    .DetectKeywords = New String() {"city", "ville"},
                    .Description = "Ville"
                },
                New ColumnDef With {
                    .FieldName = "SageProvince", .DbColumnName = "SageProvince",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 50,
                    .IsRequired = False, .CsvHeader = "Province",
                    .DetectKeywords = New String() {"province", "state", "état"},
                    .Description = "Province / État"
                },
                New ColumnDef With {
                    .FieldName = "SagePostalCode", .DbColumnName = "SagePostalCode",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 20,
                    .IsRequired = False, .CsvHeader = "Postal Code",
                    .DetectKeywords = New String() {"postal", "zip", "code postal"},
                    .Description = "Code postal"
                },
                New ColumnDef With {
                    .FieldName = "SagePhone", .DbColumnName = "SagePhone",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 200,
                    .IsRequired = False, .CsvHeader = "Phone",
                    .DetectKeywords = New String() {"phone", "téléphone", "tel"},
                    .Description = "Téléphone"
                },
                New ColumnDef With {
                    .FieldName = "SageEmail", .DbColumnName = "SageEmail",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 200,
                    .IsRequired = False, .CsvHeader = "Email",
                    .DetectKeywords = New String() {"email", "courriel", "mail"},
                    .Description = "Courriel"
                },
                New ColumnDef With {
                    .FieldName = "SageTPS", .DbColumnName = "SageTPS",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 20,
                    .IsRequired = False, .CsvHeader = "GST/TPS Number",
                    .DetectKeywords = New String() {"tps", "gst"},
                    .Description = "No TPS"
                },
                New ColumnDef With {
                    .FieldName = "SageTVQ", .DbColumnName = "SageTVQ",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 20,
                    .IsRequired = False, .CsvHeader = "QST/TVQ Number",
                    .DetectKeywords = New String() {"tvq", "qst"},
                    .Description = "No TVQ"
                },
                New ColumnDef With {
                    .FieldName = "SageBalance", .DbColumnName = "SageBalance",
                    .SqlType = SqlDbType.Decimal, .MaxLength = 0,
                    .IsRequired = False, .CsvHeader = "Balance",
                    .DetectKeywords = New String() {"balance", "solde"},
                    .Description = "Solde"
                },
                New ColumnDef With {
                    .FieldName = "SageCompteAux", .DbColumnName = "SageCompteAux",
                    .SqlType = SqlDbType.VarChar, .MaxLength = 20,
                    .IsRequired = False, .CsvHeader = "Auxiliary Account",
                    .DetectKeywords = New String() {"auxiliaire", "auxiliary", "aux"},
                    .Description = "Compte auxiliaire"
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
