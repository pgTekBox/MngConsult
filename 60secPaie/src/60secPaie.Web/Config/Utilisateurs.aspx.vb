''' <summary>Gestion des utilisateurs, réservée aux administrateurs : création, rôle, activation, réinitialisation du mot de passe.</summary>
Public Class PageUtilisateurs
    Inherits PageBase

    Protected Overrides ReadOnly Property ExigeAdmin As Boolean
        Get
            Return True
        End Get
    End Property

    Protected Overrides ReadOnly Property ExigeCompagnie As Boolean
        Get
            Return False
        End Get
    End Property

    Private ReadOnly Property UtilisateurId As Integer
        Get
            Return IdRequete("id")
        End Get
    End Property

    Private ReadOnly Property EstMoi As Boolean
        Get
            Return UtilisateurId = Contexte.Compte.Ent("Id")
        End Get
    End Property

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        If UtilisateurId = 0 Then
            litTitreFormulaire.Text = "Nouvel utilisateur"
            lblMotDePasse.CssClass = "requis"
            litAideMotDePasse.Text = "Au moins " & MotsDePasse.LongueurMinimale.ToString() & " caractères. La personne devra le changer à sa première connexion."
            Return
        End If

        Dim u = Db.Ligne("SELECT * FROM paie.Utilisateur WHERE Id = @id", Db.P("@id", UtilisateurId))
        If u Is Nothing Then Response.Redirect("~/Config/Utilisateurs.aspx", True)

        litTitreFormulaire.Text = "Modifier l'utilisateur"
        txtNom.Text = u.Txt("NomComplet")
        txtCourriel.Text = u.Txt("Courriel")
        txtCourriel.ReadOnly = True
        chkAdmin.Checked = u.Bln("EstAdmin")
        chkActif.Checked = u.Bln("Actif")
        ' On ne peut pas se retirer soi-même ses droits ni se désactiver.
        chkAdmin.Enabled = Not EstMoi
        chkActif.Enabled = Not EstMoi
        litAideMotDePasse.Text = If(EstMoi,
            "Pour changer votre propre mot de passe, utilisez la page Mon compte.",
            "Laissez vide pour ne pas le changer. Sinon la personne devra le remplacer à sa prochaine connexion.")
        txtMotDePasse.Enabled = Not EstMoi
        txtConfirmation.Enabled = Not EstMoi

        Dim verrou = u.DtN("VerrouilleJusqua")
        btnDeverrouiller.Visible = verrou.HasValue AndAlso verrou.Value > Date.Now
    End Sub

    Private Sub Page_PreRender(sender As Object, e As EventArgs) Handles Me.PreRender
        rptUtilisateurs.DataSource = Db.Table(
            "SELECT Id, NomComplet, Courriel, Actif, EstAdmin, VerrouilleJusqua, DoitChangerMotDePasse FROM paie.Utilisateur ORDER BY Actif DESC, NomComplet")
        rptUtilisateurs.DataBind()
    End Sub

    Protected Function Etat(actif As Object, verrouilleJusqua As Object, doitChanger As Object) As String
        If Not CBool(actif) Then Return "Inactif"
        If Not IsDBNull(verrouilleJusqua) AndAlso Convert.ToDateTime(verrouilleJusqua) > Date.Now Then Return "Verrouillé (trop de tentatives)"
        If CBool(doitChanger) Then Return "Actif - mot de passe temporaire"
        Return "Actif"
    End Function

    Private Shared Function AutresAdminsActifs(saufId As Integer) As Integer
        Return Db.ScalaireEntier("SELECT COUNT(*) FROM paie.Utilisateur WHERE EstAdmin = 1 AND Actif = 1 AND Id <> @id", Db.P("@id", saufId))
    End Function

    Private Function NouveauMotDePasse(requis As Boolean) As String
        If txtMotDePasse.Text.Length = 0 AndAlso Not requis Then Return Nothing
        If txtMotDePasse.Text.Length < MotsDePasse.LongueurMinimale Then
            Throw New SaisieInvalideException("Le mot de passe temporaire doit contenir au moins " & MotsDePasse.LongueurMinimale.ToString() & " caractères.")
        End If
        If txtMotDePasse.Text <> txtConfirmation.Text Then Throw New SaisieInvalideException("Les deux mots de passe ne sont pas identiques.")
        Return MotsDePasse.Hacher(txtMotDePasse.Text)
    End Function

    Private Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Try
            Dim nom = Requis(txtNom.Text, "Nom complet")

            If UtilisateurId = 0 Then
                Dim courriel = Requis(txtCourriel.Text, "Courriel").ToLowerInvariant()
                If Not courriel.Contains("@") OrElse courriel.Contains(" ") Then Throw New SaisieInvalideException("Le courriel est invalide.")
                If Db.ScalaireEntier("SELECT COUNT(*) FROM paie.Utilisateur WHERE Courriel = @c", Db.P("@c", courriel)) > 0 Then
                    Throw New SaisieInvalideException("Un utilisateur existe déjà avec ce courriel.")
                End If

                Db.Exec("INSERT INTO paie.Utilisateur (Courriel, NomComplet, MotDePasse, Actif, EstAdmin, DoitChangerMotDePasse) VALUES (@c, @n, @m, @a, @adm, 1)",
                        Db.P("@c", courriel), Db.P("@n", nom), Db.P("@m", NouveauMotDePasse(True)),
                        Db.P("@a", chkActif.Checked), Db.P("@adm", chkAdmin.Checked))
                Contexte.Journaliser("Utilisateur créé : " & courriel & If(chkAdmin.Checked, " (administrateur).", "."))
                RedirigerAvecMessage("~/Config/Utilisateurs.aspx", "Utilisateur créé. Remettez-lui son mot de passe temporaire de façon sécuritaire.")
            End If

            Dim u = Db.Ligne("SELECT * FROM paie.Utilisateur WHERE Id = @id", Db.P("@id", UtilisateurId))
            If u Is Nothing Then Throw New SaisieInvalideException("Utilisateur introuvable.")

            ' Ses propres droits ne changent pas ici ; et il doit toujours rester un administrateur actif.
            Dim estAdmin = If(EstMoi, u.Bln("EstAdmin"), chkAdmin.Checked)
            Dim actif = If(EstMoi, u.Bln("Actif"), chkActif.Checked)
            If u.Bln("EstAdmin") AndAlso u.Bln("Actif") AndAlso Not (estAdmin AndAlso actif) AndAlso AutresAdminsActifs(UtilisateurId) = 0 Then
                Throw New SaisieInvalideException("Il doit rester au moins un administrateur actif.")
            End If

            Db.Exec("UPDATE paie.Utilisateur SET NomComplet = @n, EstAdmin = @adm, Actif = @a WHERE Id = @id",
                    Db.P("@n", nom), Db.P("@adm", estAdmin), Db.P("@a", actif), Db.P("@id", UtilisateurId))

            Dim message = "Utilisateur enregistré."
            Dim hache = If(EstMoi, Nothing, NouveauMotDePasse(False))
            If hache IsNot Nothing Then
                Db.Exec("UPDATE paie.Utilisateur SET MotDePasse = @m, DoitChangerMotDePasse = 1, EchecsConnexion = 0, VerrouilleJusqua = NULL WHERE Id = @id",
                        Db.P("@m", hache), Db.P("@id", UtilisateurId))
                Contexte.Journaliser("Mot de passe réinitialisé pour " & u.Txt("Courriel") & ".")
                message = "Mot de passe réinitialisé. La personne devra le changer à sa prochaine connexion."
            End If
            If u.Bln("Actif") <> actif Then Contexte.Journaliser("Utilisateur " & If(actif, "réactivé", "désactivé") & " : " & u.Txt("Courriel") & ".")
            If u.Bln("EstAdmin") <> estAdmin Then Contexte.Journaliser("Rôle modifié pour " & u.Txt("Courriel") & " : " & If(estAdmin, "administrateur", "utilisateur") & ".")

            RedirigerAvecMessage("~/Config/Utilisateurs.aspx", message)
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub btnDeverrouiller_Click(sender As Object, e As EventArgs) Handles btnDeverrouiller.Click
        Db.Exec("UPDATE paie.Utilisateur SET EchecsConnexion = 0, VerrouilleJusqua = NULL WHERE Id = @id", Db.P("@id", UtilisateurId))
        RedirigerAvecMessage("~/Config/Utilisateurs.aspx", "Compte déverrouillé.")
    End Sub

End Class
