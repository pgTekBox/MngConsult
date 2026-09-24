''' <summary>
''' Création d'un employé depuis 60secPaie. L'employé est celui de MngConsul (dbo.T300Employees) :
''' il est créé dans la compagnie courante et y apparaît aussitôt. C'est la seule écriture de
''' 60secPaie dans une table de MngConsul, et elle ne fait qu'ajouter — l'identité continue de
''' se modifier là-bas. La paie, elle, se configure ensuite dans la fiche (paie.EmployePaie).
''' </summary>
Public Class PageNouvelEmploye
    Inherits PageBase

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        ' Les provinces du Canada, telles que MngConsul les connaît (T053State) ; la vue paie.Employe
        ' les traduit en code à deux lettres par leur nom. Le Québec est proposé d'office.
        Dim provinces = Db.Table("SELECT Id, Name FROM dbo.T053State WHERE CountryId = 1 ORDER BY Name")
        ddlProvince.DataSource = provinces
        ddlProvince.DataTextField = "Name"
        ddlProvince.DataValueField = "Id"
        ddlProvince.DataBind()
        For Each p As DataRow In provinces.Rows
            If p.Txt("Name").StartsWith("Qu", StringComparison.OrdinalIgnoreCase) Then
                ddlProvince.SelectedValue = p("Id").ToString()
                Exit For
            End If
        Next

        txtDateEmbauche.Text = Date.Today.ToString("yyyy-MM-dd")
    End Sub

    Private Sub btnCreer_Click(sender As Object, e As EventArgs) Handles btnCreer.Click
        Try
            Dim prenom = Requis(txtPrenom.Text, "Prénom")
            Dim nom = Requis(txtNom.Text, "Nom de famille")
            Dim code = txtCode.Text.Trim()
            Dim courriel = txtCourriel.Text.Trim()
            Dim embauche = DateN(txtDateEmbauche.Text, "Date d'embauche")
            Dim naissance = DateN(txtDateNaissance.Text, "Date de naissance")

            If naissance.HasValue AndAlso naissance.Value > Date.Today Then Throw New SaisieInvalideException(Tr("La date de naissance est dans le futur."))
            If courriel.Length > 0 AndAlso (courriel.IndexOf("@"c) <= 0 OrElse courriel.IndexOf("."c, courriel.IndexOf("@"c)) < 0) Then
                Throw New SaisieInvalideException(Tr("Le courriel est invalide."))
            End If

            Dim g = Contexte.CompanyGuid

            ' Le code employé identifie la personne dans les deux applications : un seul par compagnie.
            If code.Length > 0 AndAlso Db.ScalaireEntier(
                    "SELECT COUNT(*) FROM dbo.T300Employees WHERE CompanyGUID = @g AND EmployeeNumber = @n",
                    Db.P("@g", g), Db.P("@n", code)) > 0 Then
                Throw New SaisieInvalideException(Tr("Le code employé {0} est déjà utilisé dans cette compagnie.", code))
            End If

            ' Même prénom et même nom qu'un employé actif : on prévient avant de créer un doublon.
            ' Ce n'est pas un refus — deux personnes peuvent porter le même nom — mais il faut le dire.
            Dim homonyme = Db.ScalaireEntier(
                "SELECT TOP 1 Id FROM dbo.T300Employees WHERE CompanyGUID = @g AND ISNULL(Active, 1) = 1 " &
                "AND LTRIM(RTRIM(ISNULL(FirstName, ''))) = @p AND LTRIM(RTRIM(ISNULL(LastName, ''))) = @n",
                Db.P("@g", g), Db.P("@p", prenom), Db.P("@n", nom))
            If homonyme > 0 AndAlso Not chkMalgreDoublon.Checked Then
                pnlDoublon.Visible = True
                litDoublon.Text = Server.HtmlEncode(Tr("Un employé actif s'appelle déjà {0} {1}.", prenom, nom)) &
                                  " <a href=""" & ResolveUrl("~/Employes/Fiche.aspx?id=" & homonyme.ToString()) & """>" &
                                  Server.HtmlEncode(Tr("Voir sa fiche")) & "</a>"
                Erreur(Tr("Un employé actif porte déjà ce nom. Vérifiez, puis cochez « créer quand même » s'il s'agit bien d'une autre personne."))
                Return
            End If

            Dim id = Db.Inserer(
                "INSERT INTO dbo.T300Employees " &
                "(EmployeeGUID, CompanyGUID, EmployeeNumber, FirstName, LastName, DisplayName, DateOfBirth, Email, Phone, " &
                " Address1, Address2, City, StateId, CountryId, PostalCode, JobTitle, HireDate, Active, Created, CreatedBy) " &
                "VALUES (NEWID(), @g, @code, @prenom, @nom, @disp, @naissance, @courriel, @tel, " &
                " @a1, @a2, @ville, @etat, 1, @cp, @poste, @embauche, 1, GETDATE(), @par)",
                Db.P("@g", g), Db.P("@code", code), Db.P("@prenom", prenom), Db.P("@nom", nom),
                Db.P("@disp", prenom & " " & nom), Db.P("@naissance", naissance), Db.P("@courriel", courriel),
                Db.P("@tel", txtTelephone.Text.Trim()),
                Db.P("@a1", txtAdresse1.Text.Trim()), Db.P("@a2", txtAdresse2.Text.Trim()), Db.P("@ville", txtVille.Text.Trim()),
                Db.P("@etat", EntierN(ddlProvince.SelectedValue, "Province")), Db.P("@cp", txtCodePostal.Text.Trim().ToUpperInvariant()),
                Db.P("@poste", txtPoste.Text.Trim()), Db.P("@embauche", embauche),
                Db.P("@par", If(Contexte.Compte Is Nothing, Nothing, CObj(Contexte.Compte.Ent("Id")))))

            Contexte.Journaliser("Employé créé : " & prenom & " " & nom & ".", "~/Employes/Fiche.aspx?id=" & id.ToString())
            RedirigerAvecMessage("~/Employes/Fiche.aspx?id=" & id.ToString(),
                                 Tr("Employé créé. Configurez maintenant sa paie : vérifiez les valeurs proposées, puis enregistrez."))
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

End Class
