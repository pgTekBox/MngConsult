Imports System.Data.SqlClient
Imports Telerik.Web.UI

Public Class wbfSuppliersInvoices
    Inherits clsData

    Public SupplierInvoiceId As Integer

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            rgFournisseursFactures.Rebind()
        End If
    End Sub

    Private Sub rgFournisseursFactures_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rgFournisseursFactures.NeedDataSource
        Dim dt As DataTable = GetData()
        rgFournisseursFactures.DataSource = dt
    End Sub


    Private Function GetData() As DataTable
        Dim q As String = tbSearch.Text.Trim()
        Dim sSearch As String = tbSearch.Text


        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", sSearch))
        Dim ds As DataSet = ExecuteSQLds("s0023GetSuppliersInvoices", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function


    Private Sub RAP1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles RAP1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rgFournisseursFactures.Rebind()
        End If
    End Sub



    Private Sub rgFournisseursFactures_ItemDataBound(sender As Object, e As RadListViewItemEventArgs) Handles rgFournisseursFactures.ItemDataBound
        If TypeOf e.Item Is Telerik.Web.UI.RadListViewDataItem Then


            Dim item As Telerik.Web.UI.RadListViewDataItem = CType(e.Item, Telerik.Web.UI.RadListViewDataItem)
            Dim data As DataRowView = CType(item.DataItem, DataRowView)



            If data("ComptabilisationStatus") = "COMPTABILISE" Then
                Dim btnDelete As Button = CType(item.FindControl("btnDelete"), Button)
                btnDelete.CssClass &= " btn-icon-lock-red readonly-click-block"

                btnDelete.CommandName = ""


            End If


        End If

    End Sub

    ''' <summary>
    ''' Gère les boutons CommandName de la grille (DeleteInvoice, etc.)
    ''' </summary>
    Private Sub rgFournisseursFactures_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rgFournisseursFactures.ItemCommand

        If e.CommandArgument Is Nothing Then Return

        Select Case e.CommandName

            Case "DeleteInvoice"
                Dim invoiceId As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), invoiceId)
                DeleteDocument(invoiceId)
                rgFournisseursFactures.Rebind()

            Case "EditSupplierInvoice"
                SupplierInvoiceId = e.CommandArgument
                Response.Redirect("wbfSupplierInvoinceEdit.aspx?SupplierId=" & SupplierInvoiceId.ToString)

        End Select
    End Sub

    Sub DeleteDocument(invoiceId As Integer)

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@DocumentId", invoiceId))
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s317DeleteDocument ", p)
        If ds.Tables(0).Rows(0)("RetCode") = 2 Then


        End If
    End Sub


    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rgFournisseursFactures.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rgFournisseursFactures.Rebind()
    End Sub

    ''' <summary>
    ''' Détermine si le bouton "Payer" doit être visible sur une ligne.
    ''' Visible UNIQUEMENT si :
    '''   - StatutPaiement <> 'PAYEE' (il reste à payer)
    '''   - ComptabilisationStatus = 'COMPTABILISE' (facture finalisée, pas en brouillon)
    ''' </summary>
    Public Function CanPay(statutPaiement As Object, comptabilisationStatus As Object) As Boolean
        If statutPaiement Is Nothing OrElse IsDBNull(statutPaiement) Then Return False
        If comptabilisationStatus Is Nothing OrElse IsDBNull(comptabilisationStatus) Then Return False

        Dim statut As String = statutPaiement.ToString().Trim().ToUpper()
        Dim compta As String = comptabilisationStatus.ToString().Trim().ToUpper()

        Return statut <> "PAYEE" AndAlso compta = "COMPTABILISE"
    End Function

    ''' <summary>
    ''' Formate un montant decimal pour usage dans une URL (point comme separateur).
    ''' Evite que la virgule FR soit interpretee comme separateur de milliers cote
    ''' destination, transformant 493,24 en 49324.
    ''' </summary>
    Public Function FormatAmountForUrl(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return "0"
        Try
            Return Convert.ToDecimal(value).ToString("F2", System.Globalization.CultureInfo.InvariantCulture)
        Catch
            Return "0"
        End Try
    End Function

    ''' <summary>
    ''' Determine si le bouton "Programmer auto-paiement" doit etre affiche.
    ''' Affiche si :
    '''   - Facture non payee (StatutPaiement <> 'PAYEE')
    '''   - Facture comptabilisee
    '''   - Une autorisation T144 active existe pour ce fournisseur
    ''' </summary>
    Public Function CanShowAutoPayButton(statutPaiement As Object, comptabilisation As Object, hasAuth As Object) As Boolean
        If statutPaiement Is Nothing OrElse IsDBNull(statutPaiement) Then Return False
        If comptabilisation Is Nothing OrElse IsDBNull(comptabilisation) Then Return False

        Dim statut As String = statutPaiement.ToString().Trim().ToUpper()
        Dim compta As String = comptabilisation.ToString().Trim().ToUpper()

        If statut = "PAYEE" Then Return False
        If compta <> "COMPTABILISE" Then Return False

        ' Necessite une autorisation T144 active
        If hasAuth Is Nothing OrElse IsDBNull(hasAuth) Then Return False
        Try
            Return CBool(hasAuth)
        Catch
            Return False
        End Try
    End Function

    ''' <summary>
    ''' Determine si la facture est deja programmee pour auto-paiement
    ''' (affiche l'icone verte avec checkmark au lieu de l'icone neutre violette).
    ''' </summary>
    Public Function IsAutoPayActive(autoPay As Object, autoPayStatus As Object) As Boolean
        If autoPay Is Nothing OrElse IsDBNull(autoPay) Then Return False
        Try
            If Not CBool(autoPay) Then Return False
        Catch
            Return False
        End Try

        If autoPayStatus Is Nothing OrElse IsDBNull(autoPayStatus) Then Return True
        Dim s As String = autoPayStatus.ToString().Trim().ToUpper()
        Return s = "PLANIFIE" OrElse s = "EN_COURS" OrElse s = "REQUIRES_3DS"
    End Function

End Class
