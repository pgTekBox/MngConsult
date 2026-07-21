''' <summary>
''' Hôte STANDALONE (sans master page) de l'usercontrol d'encaissement/paiement,
''' destiné à être ouvert en RadWindow (pop-up) depuis les grilles de factures.
''' Met IsPopup = True pour que l'usercontrol ferme la fenêtre après enregistrement.
''' </summary>
Public Class wbfReceiptEditPopup
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If
        ReceiptEdit1.IsPopup = True
    End Sub

End Class
