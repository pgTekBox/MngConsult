''' <summary>
''' Importer les produits et services — l'écran commun <see cref="ImportDonnees"/>, posé pour
''' eux. Tout le travail se fait dans le contrôle ; la page ne fait que garder
''' la porte.
''' </summary>
Public Class ImportProduits
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
        End If
    End Sub

End Class