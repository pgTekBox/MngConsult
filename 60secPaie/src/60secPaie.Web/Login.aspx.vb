Imports System.Web.Security

Public Class PageConnexion
    Inherits System.Web.UI.Page

    Private Const EchecsMaximum As Integer = 5
    Private Const MinutesVerrouillage As Integer = 15

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim aucunUtilisateur = Db.ScalaireEntier("SELECT COUNT(*) FROM paie.Utilisateur") = 0
        pnlCreation.Visible = aucunUtilisateur
        pnlConnexion.Visible = Not aucunUtilisateur
    End Sub

    Private Sub Afficher(message As String)
        pnlErreur.Visible = True
        litErreur.Text = Server.HtmlEncode(message)
    End Sub

    Private Sub btnCreer_Click(sender As Object, e As EventArgs) Handles btnCreer.Click
        ' Possible seulement tant qu'aucun utilisateur n'existe.
        If Db.ScalaireEntier("SELECT COUNT(*) FROM paie.Utilisateur") > 0 Then
            Response.Redirect("~/Login.aspx", True)
        End If

        Dim nom = txtNom.Text.Trim()
        Dim courriel = txtCourrielAdmin.Text.Trim().ToLowerInvariant()
        If nom.Length = 0 OrElse courriel.Length = 0 OrElse Not courriel.Contains("@") Then
            Afficher("Entrez votre nom et un courriel valide.") : Return
        End If
        If txtMdp1.Text.Length < MotsDePasse.LongueurMinimale Then
            Afficher("Le mot de passe doit contenir au moins " & MotsDePasse.LongueurMinimale.ToString() & " caractères.") : Return
        End If
        If txtMdp1.Text <> txtMdp2.Text Then
            Afficher("Les deux mots de passe ne sont pas identiques.") : Return
        End If

        Db.Exec("INSERT INTO paie.Utilisateur (Courriel, NomComplet, MotDePasse, EstAdmin) VALUES (@c, @n, @m, 1)",
                Db.P("@c", courriel), Db.P("@n", nom), Db.P("@m", MotsDePasse.Hacher(txtMdp1.Text)))
        FormsAuthentication.RedirectFromLoginPage(courriel, False)
    End Sub

    Private Sub btnConnexion_Click(sender As Object, e As EventArgs) Handles btnConnexion.Click
        Const MessageGenerique As String = "Courriel ou mot de passe invalide."
        Dim courriel = txtCourriel.Text.Trim().ToLowerInvariant()
        Dim u = Db.Ligne("SELECT * FROM paie.Utilisateur WHERE Courriel = @c AND Actif = 1", Db.P("@c", courriel))

        If u Is Nothing Then
            ' Même coût de calcul que pour un compte existant, pour ne pas révéler quels courriels existent.
            MotsDePasse.Verifier(txtMotDePasse.Text, MotsDePasse.Hacher("inexistant"))
            Afficher(MessageGenerique) : Return
        End If

        Dim verrou = u.DtN("VerrouilleJusqua")
        If verrou.HasValue AndAlso verrou.Value > Date.Now Then
            Afficher("Trop de tentatives. Réessayez dans quelques minutes.") : Return
        End If

        If Not MotsDePasse.Verifier(txtMotDePasse.Text, u.Txt("MotDePasse")) Then
            Db.Exec("UPDATE paie.Utilisateur SET EchecsConnexion = EchecsConnexion + 1, " &
                    "VerrouilleJusqua = CASE WHEN EchecsConnexion + 1 >= @max THEN DATEADD(minute, @min, sysdatetime()) ELSE VerrouilleJusqua END WHERE Id = @id",
                    Db.P("@max", EchecsMaximum), Db.P("@min", MinutesVerrouillage), Db.P("@id", u.Ent("Id")))
            Afficher(MessageGenerique) : Return
        End If

        Db.Exec("UPDATE paie.Utilisateur SET EchecsConnexion = 0, VerrouilleJusqua = NULL WHERE Id = @id", Db.P("@id", u.Ent("Id")))
        Session.Clear()
        FormsAuthentication.RedirectFromLoginPage(courriel, False)
    End Sub

End Class
