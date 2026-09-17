Imports System.Web.Security

''' <summary>
''' La page publique : ce que 60secPaie fait, pour qui, et avec quelles tables de taux.
'''
''' C'est la seule page du service ouverte aux visiteurs — Web.config l'autorise
''' nommément, tout le reste exige une session. Elle ne touche ni la base ni la
''' paie : elle présente, elle ne calcule pas.
'''
''' Un visiteur déjà connecté n'a que faire d'un bouton « Me connecter » : les
''' trois appels à l'action le mènent alors droit à son tableau de bord.
''' </summary>
Public Class PagePresentation
    Inherits System.Web.UI.Page

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        litLangues.Text = I18n.SelecteurLangues(Request)

        Dim connecte = (User IsNot Nothing AndAlso User.Identity IsNot Nothing AndAlso User.Identity.IsAuthenticated)
        Dim cible = ResolveUrl(If(connecte, "~/Default.aspx", "~/Login.aspx"))
        Dim entree = If(connecte, "Mon tableau de bord", "Me connecter")
        Dim action = If(connecte, "Ouvrir mon tableau de bord", "Commencer une paie")

        lnkEntree.NavigateUrl = cible
        lnkEntree.Text = entree

        lnkAction.NavigateUrl = cible
        lnkAction.Text = action

        lnkAppel.NavigateUrl = cible
        lnkAppel.Text = action
    End Sub

    ''' <summary>Même sortie traduite que le reste du service : la page est écrite en français.</summary>
    Protected Overrides Sub Render(writer As HtmlTextWriter)
        I18n.RendreTraduit(writer, Sub(w) MyBase.Render(w))
    End Sub

End Class