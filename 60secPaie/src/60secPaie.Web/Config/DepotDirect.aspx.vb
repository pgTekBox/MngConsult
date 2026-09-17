Public Class PageConfigDepotDirect
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then Charger()
    End Sub

    Private Sub Charger()
        Dim c = Db.Ligne("SELECT * FROM paie.Compagnie WHERE Id = @c", Db.P("@c", Contexte.CompagnieId))
        txtEmetteur.Text = c.Txt("DDNumeroEmetteur")
        txtCentre.Text = c.Txt("DDCentreTraitement")
        txtNomCourt.Text = c.Txt("DDNomCourt")
        txtNomLong.Text = c.Txt("DDNomLong")
        txtProchain.Text = c.Ent("DDProchainNumeroFichier").ToString()
        txtInstitution.Text = c.Txt("DDInstitution")
        txtTransit.Text = c.Txt("DDTransit")
        txtCompte.Text = ""
        Dim compte = Secret.Reveler(c.Txt("DDCompteChiffre"))
        litCompteActuel.Text = If(compte.Length = 0, "Aucun compte au dossier.", "Compte au dossier : " & Server.HtmlEncode(Secret.Masquer(compte)) & ". Laissez vide pour le conserver.")
    End Sub

    Private Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        Try
            Dim centre = Chiffres(txtCentre.Text)
            Dim institution = Chiffres(txtInstitution.Text)
            Dim transit = Chiffres(txtTransit.Text)
            If centre.Length > 0 AndAlso centre.Length <> 5 Then Throw New SaisieInvalideException("Le centre de traitement compte 5 chiffres.")
            If institution.Length > 0 AndAlso institution.Length <> 3 Then Throw New SaisieInvalideException("Le numéro d'institution compte 3 chiffres.")
            If transit.Length > 0 AndAlso transit.Length <> 5 Then Throw New SaisieInvalideException("Le numéro de transit compte 5 chiffres.")
            Dim prochain = If(EntierN(txtProchain.Text, "Prochain numéro de fichier"), 1)
            If prochain < 1 OrElse prochain > 9999 Then Throw New SaisieInvalideException("Le numéro de fichier doit se situer entre 1 et 9999.")

            Db.Exec("UPDATE paie.Compagnie SET DDNumeroEmetteur=@e, DDCentreTraitement=@ct, DDNomCourt=@nc, DDNomLong=@nl, DDInstitution=@i, DDTransit=@t, " &
                    "DDProchainNumeroFichier=@p WHERE Id=@c",
                    Db.P("@e", txtEmetteur.Text.Trim().ToUpperInvariant()), Db.P("@ct", centre), Db.P("@nc", txtNomCourt.Text.Trim()), Db.P("@nl", txtNomLong.Text.Trim()),
                    Db.P("@i", institution), Db.P("@t", transit), Db.P("@p", prochain), Db.P("@c", Contexte.CompagnieId))

            Dim compte = Chiffres(txtCompte.Text)
            If compte.Length > 0 Then
                Db.Exec("UPDATE paie.Compagnie SET DDCompteChiffre=@v WHERE Id=@c", Db.P("@v", Secret.Proteger(compte)), Db.P("@c", Contexte.CompagnieId))
            End If
            Charger()
            Succes("Paramètres de dépôt direct enregistrés.")
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

End Class
