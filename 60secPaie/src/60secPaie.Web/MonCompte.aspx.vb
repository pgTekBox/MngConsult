Imports System.Web.Security

Public Class PageMonCompte
    Inherits PageBase

    Private Const EchecsMaximum As Integer = 5

    Protected Overrides ReadOnly Property ExigeCompagnie As Boolean
        Get
            Return False
        End Get
    End Property

    Private Function Moi() As DataRow
        Dim u = Db.Ligne("SELECT * FROM dbo.Utilisateur WHERE Courriel = @c AND Actif = 1", Db.P("@c", Contexte.Utilisateur))
        If u Is Nothing Then
            FormsAuthentication.SignOut()
            Response.Redirect("~/Login.aspx", True)
        End If
        Return u
    End Function

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim u = Moi()
        litCourriel.Text = Server.HtmlEncode(u.Txt("Courriel"))
        If Not IsPostBack Then
            txtNom.Text = u.Txt("NomComplet")
            If u.Bln("DoitChangerMotDePasse") Then
                Erreur("Votre mot de passe a été réinitialisé par un administrateur. Choisissez-en un nouveau pour continuer ; " &
                       "le « mot de passe actuel » est le mot de passe temporaire qu'on vous a remis.")
            End If
        End If
    End Sub

    Private Sub btnEnregistrerNom_Click(sender As Object, e As EventArgs) Handles btnEnregistrerNom.Click
        Try
            Db.Exec("UPDATE dbo.Utilisateur SET NomComplet = @n WHERE Id = @id", Db.P("@n", Requis(txtNom.Text, "Nom complet")), Db.P("@id", Moi().Ent("Id")))
            Succes("Vos informations sont enregistrées.")
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub btnChangerMotDePasse_Click(sender As Object, e As EventArgs) Handles btnChangerMotDePasse.Click
        Dim u = Moi()

        ' Le mot de passe actuel est exigé : une session laissée ouverte ne suffit pas pour prendre le compte.
        If Not MotsDePasse.Verifier(txtActuel.Text, u.Txt("MotDePasse")) Then
            Db.Exec("UPDATE dbo.Utilisateur SET EchecsConnexion = EchecsConnexion + 1 WHERE Id = @id", Db.P("@id", u.Ent("Id")))
            If u.Ent("EchecsConnexion") + 1 >= EchecsMaximum Then
                Db.Exec("UPDATE dbo.Utilisateur SET VerrouilleJusqua = DATEADD(minute, 15, sysdatetime()) WHERE Id = @id", Db.P("@id", u.Ent("Id")))
                FormsAuthentication.SignOut()
                Session.Abandon()
                Response.Redirect("~/Login.aspx", True)
            End If
            Erreur("Le mot de passe actuel est incorrect.")
            Return
        End If

        If txtNouveau.Text.Length < MotsDePasse.LongueurMinimale Then
            Erreur("Le nouveau mot de passe doit contenir au moins " & MotsDePasse.LongueurMinimale.ToString() & " caractères.") : Return
        End If
        If txtNouveau.Text <> txtConfirmation.Text Then
            Erreur("Les deux nouveaux mots de passe ne sont pas identiques.") : Return
        End If
        If txtNouveau.Text = txtActuel.Text Then
            Erreur("Le nouveau mot de passe doit être différent de l'actuel.") : Return
        End If

        Db.Exec("UPDATE dbo.Utilisateur SET MotDePasse = @m, EchecsConnexion = 0, VerrouilleJusqua = NULL, DoitChangerMotDePasse = 0 WHERE Id = @id",
                Db.P("@m", MotsDePasse.Hacher(txtNouveau.Text)), Db.P("@id", u.Ent("Id")))
        Contexte.Journaliser("Mot de passe modifié.")
        Succes("Votre mot de passe a été changé.")
    End Sub

End Class
