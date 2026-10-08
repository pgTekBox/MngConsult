''' <summary>
''' Les formulaires officiels de fin d'année (T4 de l'ARC, Relevé 1 de Revenu Québec), téléversés par la
''' compagnie pour une année. Le fichier est vérifié et préparé par FormulaireOfficiel.Preparer avant
''' d'être conservé ; les écrans Rapports › T4 et Relevés 1 s'en servent dès qu'il est là.
''' </summary>
Public Class PageConfigFormulaires
    Inherits PageBase

    Private Const TailleMaximale As Integer = 10 * 1024 * 1024

    Private Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            For a = Date.Today.Year To Date.Today.Year - 3 Step -1
                ddlAnnee.Items.Add(a.ToString())
            Next
            ' Les feuillets se produisent surtout en janvier et février, pour l'année qui vient de finir.
            If Date.Today.Month <= 3 Then ddlAnnee.SelectedValue = (Date.Today.Year - 1).ToString()
            Charger()
        End If
    End Sub

    Private Sub Charger()
        Dim t = Db.Table("paie.spFormulaireFeuillet_Liste", Db.P("@c", Contexte.CompagnieId))
        rptFormulaires.DataSource = t
        rptFormulaires.DataBind()
        rptFormulaires.Visible = t.Rows.Count > 0
        lblAucun.Visible = t.Rows.Count = 0

        ' Les formulaires de la plateforme (console d'administration) : ils servent à défaut des vôtres.
        ' Les instructions T4 de l'ARC (type TI) y figurent aussi, avec un lien : le document est offert tel quel à toutes les compagnies.
        Dim plateforme As New List(Of String)()
        For Each r As DataRow In Db.Table("paie.spFormulaireFeuillet_Liste", Db.P("@c", FormulaireOfficiel.Plateforme)).Rows
            Dim libelle = Server.HtmlEncode(r.Ent("Annee").ToString() & " " & LibelleType(r("Type")))
            If r.Txt("Type") = FormulaireOfficiel.TypeInstructionsT4 Then
                libelle = "<a href=""../Documents.aspx?doc=instructions-t4&amp;annee=" & r.Ent("Annee").ToString() & """ target=""_blank"" rel=""noopener"">" & libelle & "</a>"
            End If
            plateforme.Add(libelle)
        Next
        litPlateforme.Text = If(plateforme.Count = 0, Server.HtmlEncode(Tr("Aucun formulaire de la plateforme (console d'administration).")),
                               String.Format(Server.HtmlEncode(Tr("Formulaires de la plateforme (console d'administration), utilisés à défaut des vôtres : {0}.")), String.Join(", ", plateforme)))
    End Sub

    Protected Function LibelleType(type As Object) As String
        Select Case Convert.ToString(type)
            Case FormulaireOfficiel.TypeT4 : Return "T4 (ARC)"
            Case FormulaireOfficiel.TypeInstructionsT4 : Return "Instructions T4 (ARC)"
            Case Else : Return "Relevé 1 (Revenu Québec)"
        End Select
    End Function

    Protected Function Taille(octets As Object) As String
        If octets Is Nothing OrElse IsDBNull(octets) Then Return ""
        Return (Convert.ToInt64(octets) / 1024D).ToString("N0", I18n.Culture) & " Ko"
    End Function

    Private Sub btnTeleverser_Click(sender As Object, e As EventArgs) Handles btnTeleverser.Click
        Try
            If Not fuFichier.HasFile Then Throw New SaisieInvalideException("Choisissez d'abord un fichier.")
            If Not fuFichier.FileName.ToLowerInvariant().EndsWith(".pdf") Then Throw New SaisieInvalideException("Seul un fichier PDF est accepté.")
            If fuFichier.PostedFile.ContentLength > TailleMaximale Then Throw New SaisieInvalideException("Fichier trop volumineux : 10 Mo au maximum.")

            Dim type = ddlType.SelectedValue
            Dim annee = Integer.Parse(ddlAnnee.SelectedValue)
            Dim prepare = FormulaireOfficiel.Preparer(fuFichier.FileBytes, type)
            Dim nom = IO.Path.GetFileName(fuFichier.FileName)
            Db.Exec("paie.spFormulaireFeuillet_Enregistrer", Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee), Db.P("@type", type),
                    Db.P("@nom", nom), Db.P("@contenu", prepare), Db.P("@u", Contexte.Utilisateur))
            Contexte.Journaliser("Formulaire " & LibelleType(type) & " " & annee.ToString() & " téléversé (" & nom & ").", "~/Config/Formulaires.aspx")
            Charger()
            Succes(Tr("Formulaire {0} {#1} téléversé. Les feuillets de cette année sortiront dessus.", LibelleType(type), annee))
        Catch ex As SaisieInvalideException
            Erreur(ex.Message)
        End Try
    End Sub

    Private Sub rptFormulaires_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptFormulaires.ItemCommand
        If e.CommandName <> "Supprimer" Then Return
        Dim parts = Convert.ToString(e.CommandArgument).Split("|"c)
        Dim annee As Integer
        If parts.Length <> 2 OrElse Not Integer.TryParse(parts(0), annee) Then Return
        Dim type = parts(1)
        Db.Exec("paie.spFormulaireFeuillet_Supprimer", Db.P("@c", Contexte.CompagnieId), Db.P("@a", annee), Db.P("@type", type))
        Contexte.Journaliser("Formulaire " & LibelleType(type) & " " & annee.ToString() & " retiré.", "~/Config/Formulaires.aspx")
        Charger()
        Succes("Formulaire retiré.")
    End Sub

End Class