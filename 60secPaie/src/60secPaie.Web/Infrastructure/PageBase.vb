Imports System.Web.Security

''' <summary>Page de base : compte actif, changement de mot de passe forcé, rôle administrateur, compagnie configurée, messages.</summary>
Public Class PageBase
    Inherits System.Web.UI.Page

    Protected Overridable ReadOnly Property ExigeCompagnie As Boolean
        Get
            Return True
        End Get
    End Property

    Protected Overridable ReadOnly Property ExigeAdmin As Boolean
        Get
            Return False
        End Get
    End Property

    Protected Overrides Sub OnLoad(e As EventArgs)
        ' Compte supprimé ou désactivé pendant la session : on ferme la session.
        If Contexte.Compte Is Nothing Then
            FormsAuthentication.SignOut()
            Session.Abandon()
            Response.Redirect("~/Login.aspx", True)
        End If

        ' Mot de passe réinitialisé par un administrateur : il doit être changé avant toute autre chose.
        If Contexte.Compte.Bln("DoitChangerMotDePasse") AndAlso Not TypeOf Me Is PageMonCompte Then
            Response.Redirect("~/MonCompte.aspx", True)
        End If

        If ExigeAdmin AndAlso Not Contexte.EstAdmin Then
            RedirigerAvecMessage("~/Default.aspx", "Cette page est réservée aux administrateurs.")
        End If

        If ExigeCompagnie AndAlso Contexte.CompagnieId = 0 Then
            Session("flash") = "Bienvenue ! Commencez par configurer votre compagnie."
            Response.Redirect("~/Config/Compagnie.aspx", True)
        End If
        MyBase.OnLoad(e)
    End Sub

    Protected Function IdRequete(nom As String) As Integer
        Dim v As Integer
        Return If(Integer.TryParse(Request.QueryString(nom), v) AndAlso v > 0, v, 0)
    End Function

    Protected Sub Succes(message As String)
        DirectCast(Master, SiteMaster).Afficher(message, False)
    End Sub

    Protected Sub Erreur(message As String)
        DirectCast(Master, SiteMaster).Afficher(message, True)
    End Sub

    ''' <summary>Redirige et affiche le message sur la page suivante.</summary>
    Protected Sub RedirigerAvecMessage(url As String, message As String)
        Session("flash") = message
        Response.Redirect(url, True)
    End Sub

End Class
