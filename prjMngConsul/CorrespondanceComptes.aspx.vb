Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Étape 2 de la reprise comptable : dire, pour chaque compte de l'ancien
''' logiciel, à quel compte de notre plan il correspond.
'''
''' C'est le seul travail de la migration qu'un programme ne peut pas décider
''' seul. La page propose — même numéro, puis même nom — mais ne tranche jamais
''' à la place de l'utilisateur : une correspondance fausse déplace des montants
''' sans que rien ne le signale.
'''
''' Elle n'écrit toujours rien en comptabilité. Les décisions vont dans
''' <c>staging.CorrespondanceCompte</c>, qui survit aux lots parce que les
''' étapes suivantes — factures, écritures — en auront besoin.
''' </summary>
Public Class CorrespondanceComptes
    Inherits clsData

#Region "Cycle de vie"

    Private Property LotCourant As Integer
        Get
            Dim v = ViewState("Lot")
            Return If(v Is Nothing, 0, CInt(v))
        End Get
        Set(value As Integer)
            ViewState("Lot") = value
        End Set
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            ChargerLots()
            If ddlLot.Items.Count > 0 Then
                LotCourant = CInt(ddlLot.SelectedValue)
                ChargerPlanPourSaisie()
                Rafraichir()
            Else
                pnlAucunLot.Visible = True
            End If
        End If
    End Sub

    ''' <summary>Les lots de plan comptable déjà chargés pour cette compagnie.</summary>
    Private Sub ChargerLots()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@TypeDonnees", "PLAN_COMPTABLE"))
        p.Add(New SqlParameter("@Top", 20))

        Dim ds As DataSet = ExecuteSQLds("s0754GetImportLots", p)
        ddlLot.Items.Clear()

        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return

        For Each r As DataRow In ds.Tables(0).Rows
            Dim libelle = String.Format("Lot {0} — {1} — {2} ({3} comptes)",
                                        r("Id"),
                                        Convert.ToDateTime(r("Created")).ToString("yyyy-MM-dd HH:mm"),
                                        Convert.ToString(r("SystemeSource")),
                                        r("NbLignesRetenues"))
            ddlLot.Items.Add(New ListItem(libelle, Convert.ToString(r("Id"))))
        Next
    End Sub

    Protected Sub ddlLot_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlLot.SelectedIndexChanged
        LotCourant = CInt(ddlLot.SelectedValue)
        Rafraichir()
    End Sub

    Protected Sub ddlFiltre_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlFiltre.SelectedIndexChanged
        Rafraichir()
    End Sub

#End Region

#Region "Le plan de la compagnie, pour la saisie assistée"

    ''' <summary>
    ''' Alimente la liste de saisie du navigateur. Une seule liste pour toute la
    ''' page : la répéter par ligne alourdirait le document sans rien apporter.
    ''' </summary>
    Private Sub ChargerPlanPourSaisie()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))

            Dim ds As DataSet = ExecuteSQLds("s0759GetPlanCompagnie", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return

            Dim options As New StringBuilder()
            Dim noms As New StringBuilder()
            noms.Append("{")

            Dim premier As Boolean = True
            For Each r As DataRow In ds.Tables(0).Rows
                Dim compte = Convert.ToString(r("Compte"))
                Dim nom = Convert.ToString(r("Nom"))

                options.Append("<option value=""")
                options.Append(Server.HtmlEncode(compte))
                options.Append(""">")
                options.Append(Server.HtmlEncode(nom))
                options.Append("</option>")

                If Not premier Then noms.Append(",")
                noms.Append(Newtonsoft.Json.JsonConvert.ToString(compte))
                noms.Append(":")
                noms.Append(Newtonsoft.Json.JsonConvert.ToString(nom))
                premier = False
            Next

            noms.Append("}")

            litPlanOptions.Text = options.ToString()
            litPlanJson.Text = noms.ToString()
            litNbComptesPlan.Text = ds.Tables(0).Rows.Count.ToString()

        Catch ex As Exception
            Alerte(pnlErreur, litErreur, "Lecture du plan comptable : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

#End Region

#Region "Affichage"

    Private Sub Rafraichir()
        ChargerStats()
        ChargerLignes()
    End Sub

    Private Sub ChargerStats()
        If LotCourant = 0 Then Return

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@LotId", LotCourant))
            p.Add(New SqlParameter("@CompanyGUID", Company))

            AfficherStats(PremiereLigne(ExecuteSQLds("s0758StatsCorrespondance", p)))

        Catch ex As Exception
            Alerte(pnlErreur, litErreur, "Lecture de l'avancement : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

    Private Sub AfficherStats(r As DataRow)
        If r Is Nothing Then Return

        Dim total = Convert.ToInt32(r("Total"))
        Dim decides = Convert.ToInt32(r("Decides"))

        litTotal.Text = total.ToString()
        litDecides.Text = decides.ToString()
        litADecider.Text = Convert.ToString(r("ADecider"))
        litLies.Text = Convert.ToString(r("Lies"))
        litACreer.Text = Convert.ToString(r("ACreer"))
        litIgnores.Text = Convert.ToString(r("Ignores"))

        Dim pct As Integer = If(total = 0, 0, CInt(Math.Floor(decides * 100.0 / total)))
        litPct.Text = pct.ToString()
        divBarre.Style("width") = pct.ToString() & "%"

        pnlTermine.Visible = (total > 0 AndAlso decides = total)
    End Sub

    Private Sub ChargerLignes()
        If LotCourant = 0 Then Return

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@LotId", LotCourant))
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Filtre", If(ddlFiltre.SelectedValue = "", CType(DBNull.Value, Object), ddlFiltre.SelectedValue)))
            p.Add(New SqlParameter("@Top", 1000))

            Dim ds As DataSet = ExecuteSQLds("s0756GetCorrespondances", p)
            Dim dt As DataTable = If(ds Is Nothing OrElse ds.Tables.Count = 0, Nothing, ds.Tables(0))

            rptLignes.DataSource = dt
            rptLignes.DataBind()

            pnlVide.Visible = (dt Is Nothing OrElse dt.Rows.Count = 0)
            pnlLignes.Visible = Not pnlVide.Visible

        Catch ex As SqlException When ex.Number = 50310
            Alerte(pnlErreur, litErreur, "Ce lot n'existe plus.")
            ChargerLots()
        Catch ex As Exception
            Alerte(pnlErreur, litErreur, "Lecture des correspondances : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

#End Region

#Region "Ce que la ligne affiche"

    ''' <summary>Ce que la page propose, en clair, et d'où ça vient.</summary>
    Protected Function TexteProposition(origine As Object, compte As Object, nom As Object) As String
        Dim c = Convert.ToString(compte)
        Dim n = Convert.ToString(nom)

        Select Case Convert.ToString(origine)
            Case "DECIDE"
                Return ""
            Case "PROPOSE_NUMERO"
                Return "<span class='pr pr-sur'>même numéro</span> " &
                       Server.HtmlEncode(c) & " — " & Server.HtmlEncode(n)
            Case "PROPOSE_NOM"
                Return "<span class='pr pr-moyen'>même nom</span> " &
                       Server.HtmlEncode(c) & " — " & Server.HtmlEncode(n)
            Case Else
                Return "<span class='pr pr-aucun'>aucune proposition</span>"
        End Select
    End Function

    ''' <summary>La valeur à mettre dans le champ : la décision, sinon la proposition.</summary>
    Protected Function CompteChoisi(action As Object, compteCible As Object, proposeCompte As Object) As String
        Select Case Convert.ToString(action)
            Case "CREER" : Return Convert.ToString(compteCible)
            Case "IGNORER" : Return ""
            Case "LIER" : Return Convert.ToString(proposeCompte)
            Case Else : Return Convert.ToString(proposeCompte)   ' proposition non encore acceptée
        End Select
    End Function

    ''' <summary>L'action déjà décidée, ou rien.</summary>
    Protected Function ActionChoisie(action As Object) As String
        Return Convert.ToString(action)
    End Function

    Protected Function EstDecide(origine As Object) As Boolean
        Return Convert.ToString(origine) = "DECIDE"
    End Function

    ''' <summary>
    ''' Ce qui identifie le compte d'origine. Quand l'ancien logiciel n'a pas
    ''' de numéros — c'est courant avec QuickBooks, qui les rend facultatifs —
    ''' c'est le nom qui tient ce rôle, et la colonne le dit plutôt que de
    ''' rester vide.
    ''' </summary>
    Protected Function CleAffichee(compte As Object, typeCle As Object) As String
        Dim c = Convert.ToString(compte)
        If c <> "" Then Return Server.HtmlEncode(c)
        Return "<span class='sans-num'>sans numéro</span>"
    End Function

#End Region

#Region "Enregistrer"

    ''' <summary>
    ''' Accepte d'un coup les correspondances où le numéro de compte concorde.
    ''' Sur un plan bâti sur la même base, c'est le gros du travail ; ce qui
    ''' reste demande un avis.
    ''' </summary>
    Protected Sub btnAccepter_Click(sender As Object, e As EventArgs) Handles btnAccepter.Click
        CacherMessages()
        If LotCourant = 0 Then Return

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@LotId", LotCourant))
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@UserId", UserId))

            AfficherStats(PremiereLigne(ExecuteSQLds("s0760AccepterPropositions", p)))
            ChargerLignes()

            Alerte(pnlSucces, litSucces,
                   "Les correspondances par numéro de compte ont été retenues. " &
                   "Ce qui reste demande une décision.")

        Catch ex As Exception
            Alerte(pnlErreur, litErreur, "Enregistrement : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

    ''' <summary>
    ''' Enregistre ce que l'utilisateur a saisi. Une ligne sans action revient
    ''' « à décider » : c'est ainsi qu'on se dédit.
    ''' </summary>
    Protected Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
        CacherMessages()
        If LotCourant = 0 Then Return

        Try
            Dim decisions As New List(Of Object)
            Dim aCreerSansNumero As Integer = 0

            For Each item As RepeaterItem In rptLignes.Items
                If item.ItemType <> ListItemType.Item AndAlso item.ItemType <> ListItemType.AlternatingItem Then Continue For

                Dim hfCle = TryCast(item.FindControl("hfCleSource"), HiddenField)
                Dim hfTypeCle = TryCast(item.FindControl("hfTypeCle"), HiddenField)
                Dim hfSource = TryCast(item.FindControl("hfCompteSource"), HiddenField)
                Dim hfNom = TryCast(item.FindControl("hfNomSource"), HiddenField)
                Dim hfType = TryCast(item.FindControl("hfTypeSource"), HiddenField)
                Dim ddlAct = TryCast(item.FindControl("ddlAction"), DropDownList)
                Dim txtCpt = TryCast(item.FindControl("txtCompte"), TextBox)
                Dim txtNot = TryCast(item.FindControl("txtNote"), TextBox)

                If hfCle Is Nothing OrElse ddlAct Is Nothing Then Continue For

                Dim action = ddlAct.SelectedValue
                Dim compte = If(txtCpt Is Nothing, "", txtCpt.Text.Trim())

                ' « Créer » sans numéro saisi : on reprend celui de l'ancien
                ' logiciel quand il en a un. Sinon on laisse vide, et la
                ' procédure refusera — notre plan n'accepte pas de compte sans
                ' numéro, et l'inventer serait pire que de le demander.
                If action = "CREER" AndAlso compte = "" AndAlso hfSource IsNot Nothing Then
                    compte = hfSource.Value
                End If

                If action = "CREER" AndAlso compte = "" Then aCreerSansNumero += 1

                decisions.Add(New With {
                    .CleSource = hfCle.Value,
                    .TypeCle = If(hfTypeCle Is Nothing, "", hfTypeCle.Value),
                    .CompteSource = If(hfSource Is Nothing, "", hfSource.Value),
                    .NomSource = If(hfNom Is Nothing, "", hfNom.Value),
                    .Action = If(action = "", Nothing, action),
                    .CompteCible = compte,
                    .NomCible = If(hfNom Is Nothing, "", hfNom.Value),
                    .TypeCible = If(hfType Is Nothing, "", hfType.Value),
                    .Note = If(txtNot Is Nothing, "", txtNot.Text.Trim())
                })
            Next

            If decisions.Count = 0 Then
                Alerte(pnlAvertissement, litAvertissement, "Rien à enregistrer.")
                Return
            End If

            Dim p As New Collection
            p.Add(New SqlParameter("@LotId", LotCourant))
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@UserId", UserId))
            p.Add(New SqlParameter("@Decisions", Newtonsoft.Json.JsonConvert.SerializeObject(decisions)))

            Dim r = PremiereLigne(ExecuteSQLds("s0757SaveCorrespondances", p))
            AfficherStats(r)
            ChargerLignes()

            ' Un « Lier » vers un compte que le plan ne connaît pas n'est pas
            ' enregistré : la procédure l'écarte, et la ligne revient à décider.
            Dim aDecider = If(r Is Nothing, 0, Convert.ToInt32(r("ADecider")))

            If aDecider = 0 Then
                Alerte(pnlSucces, litSucces, "Correspondances enregistrées. Tous les comptes sont décidés.")

            ElseIf aCreerSansNumero > 0 Then
                ' Cas propre aux plans sans numéros : « Créer » ne peut pas
                ' reprendre un numéro d'origine qui n'existe pas.
                Alerte(pnlAvertissement, litAvertissement,
                       String.Format("Correspondances enregistrées, mais {0} compte(s) restent à décider. " &
                                     "{1} d'entre eux sont marqués « Créer » <b>sans numéro</b> : votre plan " &
                                     "comptable exige un numéro pour chaque compte, et votre ancien logiciel " &
                                     "n'en fournit pas. Saisissez le numéro à donner à ces comptes chez vous.",
                                     aDecider, aCreerSansNumero))
            Else
                Alerte(pnlSucces, litSucces,
                       String.Format("Correspondances enregistrées. {0} compte(s) restent à décider — " &
                                     "vérifiez qu'un « Lier » pointe bien vers un compte de votre plan.", aDecider))
            End If

        Catch ex As Exception
            Alerte(pnlErreur, litErreur, "Enregistrement : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

#End Region

#Region "Outils"

    Private Shared Function PremiereLigne(ds As DataSet) As DataRow
        If ds Is Nothing Then Return Nothing
        For Each t As DataTable In ds.Tables
            If t.Rows.Count > 0 AndAlso t.Columns.Contains("Total") Then Return t.Rows(0)
        Next
        If ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then Return ds.Tables(0).Rows(0)
        Return Nothing
    End Function

    Private Sub CacherMessages()
        pnlSucces.Visible = False
        pnlErreur.Visible = False
        pnlAvertissement.Visible = False
    End Sub

    Private Shared Sub Alerte(panneau As Panel, texte As Literal, message As String)
        texte.Text = message
        panneau.Visible = True
    End Sub

#End Region

End Class
