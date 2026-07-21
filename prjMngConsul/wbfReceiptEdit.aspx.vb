''' <summary>
''' Page complète (master page) qui héberge l'usercontrol d'encaissement/paiement.
''' Accès via le menu. Le même usercontrol est réutilisé en pop-up par
''' wbfReceiptEditPopup.aspx (ouvert en RadWindow depuis les grilles de factures).
''' </summary>
Public Class wbfReceiptEdit
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If
    End Sub

End Class
