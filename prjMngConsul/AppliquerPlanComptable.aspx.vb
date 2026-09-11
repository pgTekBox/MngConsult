Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Étape 3 de la reprise comptable : créer, dans le plan de la compagnie, les
''' comptes que l'étape 2 a marqués « Créer ».
'''
''' C'est le premier écran de la reprise qui écrit dans la comptabilité. Les
''' deux précédents remplissaient la préparation, qu'on pouvait abandonner sans
''' laisser de trace ; ici les comptes existent pour de bon.
'''
''' Ce que l'utilisateur décide : la classe du compte. Elle lui donne sa place
''' dans les états financiers, et ce n'est pas une question technique. Tout le
''' reste — classe mère, type de bilan, sens, ordre — se déduit de la classe,
''' et le numéro s'attribue tout seul dans sa plage si personne n'en impose un.
''' </summary>
Public Class AppliquerPlanComptable
    Inherits clsData

#Region "Cycle de vie"

    Private Property LotCourant As Integer
        Get
            Return If(ViewState("Lot") Is Nothing, 0, CInt(ViewState("Lot")))
        End Get
        Set(value As Integer)
            ViewState("Lot") = value
        End Set
    End Property

    ''' <summary>
    ''' Les classes, une lecture par nature et pas une par ligne : vingt
    ''' comptes de charge ne justifient pas vingt allers-retours.
    ''' </summary>
    Private ReadOnly _classesParNature As New Dictionary(Of String, DataTable)(StringComparer.OrdinalIgnoreCase)
    ''' <summary>
    ''' Le fil des étapes porte le lot en cours, pour que les deux autres
    ''' écrans ouvrent celui qu'on regarde et non le dernier chargé. Posé au
    ''' pré-rendu : à ce moment le lot est connu, quoi qu'ait fait la page.
    ''' </summary>
    Protected Sub Page_PreRenderEtapes(sender As Object, e As EventArgs) Handles Me.PreRender
        ucEtapes.LotId = LotCourant
    End Sub


    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            ChargerLots()

            ' L'écran précédent renvoie ici en nommant son lot.
            Dim n As Integer
            If Integer.TryParse(Request.QueryString("lot"), n) Then
                Dim item = ddlLot.Items.FindByValue(n.ToString())
                If item IsNot Nothing Then ddlLot.SelectedValue = item.Value
            End If

            If ddlLot.Items.Count > 0 Then
                LotCourant = CInt(ddlLot.SelectedValue)
                Rafraichir()
            Else
                pnlAucunLot.Visible = True
            End If
        End If
    End Sub

    Private Sub ChargerLots()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@TypeDonnees", "PLAN_COMPTABLE"))
        p.Add(New SqlParameter("@Top", 20))

        Dim ds As DataSet = ExecuteSQLds("s0754GetImportLots", p)
        ddlLot.Items.Clear()

        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return

        For Each r As DataRow In ds.Tables(0).Rows
            Dim libelle = String.Format("Lot {0} — {1} — {2} ({3})",
                                        r("Id"),
                                        Convert.ToDateTime(r("Created")).ToString("yyyy-MM-dd HH:mm"),
                                        Convert.ToString(r("SystemeSource")),
                                        Convert.ToString(r("Statut")))
            ddlLot.Items.Add(New ListItem(libelle, Convert.ToString(r("Id"))))
        Next
    End Sub

    Protected Sub ddlLot_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlLot.SelectedIndexChanged
        CacherMessages()
        pnlCrees.Visible = False
        LotCourant = CInt(ddlLot.SelectedValue)
        Rafraichir()
    End Sub

#End Region

#Region "Affichage"

    Private Sub Rafraichir()
        If LotCourant = 0 Then Return

        hlRetour.NavigateUrl = "~/CorrespondanceComptes.aspx?lot=" & LotCourant.ToString()

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@LotId", LotCourant))
            p.Add(New SqlParameter("@CompanyGUID", Company))

            Dim ds As DataSet = ExecuteSQLds("s0766GetAAppliquer", p)
            If ds Is Nothing OrElse ds.Tables.Count < 2 Then Return

            ' ── Les compteurs ───────────────────────────────────────────────
            Dim aCreer As Integer = 0
            Dim aDecider As Integer = 0

            If ds.Tables(1).Rows.Count > 0 Then
                Dim s = ds.Tables(1).Rows(0)
                aCreer = Nombre(s("ACreer"))
                aDecider = Nombre(s("ADecider"))

                litACreer.Text = aCreer.ToString()
                litDejaCrees.Text = Nombre(s("DejaCrees")).ToString()
                litLies.Text = Nombre(s("Lies")).ToString()
                litIgnores.Text = Nombre(s("Ignores")).ToString()
                litADecider.Text = aDecider.ToString()
            End If

            ' ── Les lignes ──────────────────────────────────────────────────
            Dim lignes = ds.Tables(0)

            rptLignes.DataSource = lignes
            rptLignes.DataBind()

            pnlLignes.Visible = (lignes.Rows.Count > 0)
            pnlRien.Visible = (lignes.Rows.Count = 0)

            ' Un compte encore à décider ne sera pas repris. Le dire ici évite
            ' de découvrir le trou trois étapes plus loin.
            If aDecider > 0 Then
                Alerte(pnlAvertissement, litAvertissement,
                       String.Format("<b>{0} compte(s) ne sont pas encore décidés</b> à l'étape 2. " &
                                     "Ils ne seront pas repris. Vous pouvez créer les autres " &
                                     "maintenant et revenir ensuite.", aDecider))
            End If

        Catch ex As Exception
            Alerte(pnlErreur, litErreur, "Lecture du lot : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

    ''' <summary>
    ''' Remplit la liste des classes de chaque ligne, bornée à la nature du
    ''' compte d'origine : une charge ne se range pas dans l'actif, et on ne
    ''' propose donc même pas de le faire.
    ''' </summary>
    Protected Sub rptLignes_ItemDataBound(sender As Object, e As RepeaterItemEventArgs) Handles rptLignes.ItemDataBound
        If e.Item.ItemType <> ListItemType.Item AndAlso e.Item.ItemType <> ListItemType.AlternatingItem Then Return

        Dim ddl = TryCast(e.Item.FindControl("ddlClasse"), DropDownList)
        Dim hfNature = TryCast(e.Item.FindControl("hfNature"), HiddenField)
        If ddl Is Nothing Then Return

        Dim nature = If(hfNature Is Nothing, "", hfNature.Value)

        ddl.Items.Clear()
        ddl.Items.Add(New ListItem("— choisir une classe —", ""))

        For Each r As DataRow In ClassesPour(nature).Rows
            Dim libelle = String.Format("{0} — {1}  ({2}-{3})",
                                        Convert.ToString(r("Code")),
                                        Convert.ToString(r("Description")),
                                        Convert.ToString(r("NumeroDebut")),
                                        Convert.ToString(r("NumeroFin")))
            ddl.Items.Add(New ListItem(libelle, Convert.ToString(r("Id"))))
        Next
    End Sub

    Private Function ClassesPour(nature As String) As DataTable
        Dim cle = If(nature, "")
        If _classesParNature.ContainsKey(cle) Then Return _classesParNature(cle)

        Dim vide As New DataTable()

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Nature", If(cle = "", CType(DBNull.Value, Object), cle)))

            Dim ds As DataSet = ExecuteSQLds("s0765GetSousClasses", p)
            Dim dt = If(ds Is Nothing OrElse ds.Tables.Count = 0, vide, ds.Tables(0))

            _classesParNature(cle) = dt
            Return dt

        Catch
            _classesParNature(cle) = vide
            Return vide
        End Try
    End Function

#End Region

#Region "Créer"

    ''' <summary>
    ''' Écrit dans le plan comptable. Tout ou rien : s0767 refuse le lot
    ''' entier si une seule ligne est fautive — un plan à moitié repris serait
    ''' plus difficile à démêler qu'un plan pas repris du tout.
    ''' </summary>
    Protected Sub btnCreer_Click(sender As Object, e As EventArgs) Handles btnCreer.Click
        CacherMessages()
        pnlCrees.Visible = False
        If LotCourant = 0 Then Return

        Try
            Dim lignes As New List(Of Object)
            Dim sansClasse As Integer = 0

            For Each item As RepeaterItem In rptLignes.Items
                Dim hfCle = TryCast(item.FindControl("hfCleSource"), HiddenField)
                Dim ddl = TryCast(item.FindControl("ddlClasse"), DropDownList)
                Dim txtNum = TryCast(item.FindControl("txtNumero"), TextBox)
                Dim txtNom = TryCast(item.FindControl("txtNom"), TextBox)

                If hfCle Is Nothing OrElse ddl Is Nothing Then Continue For

                ' Une ligne sans classe n'est pas une erreur : c'est un compte
                ' qu'on remet à plus tard. On l'écarte, on le signale.
                If ddl.SelectedValue = "" Then
                    sansClasse += 1
                    Continue For
                End If

                lignes.Add(New With {
                    .CleSource = hfCle.Value,
                    .ClasseId = CInt(ddl.SelectedValue),
                    .Compte = If(txtNum Is Nothing, "", txtNum.Text.Trim()),
                    .Nom = If(txtNom Is Nothing, "", txtNom.Text.Trim())
                })
            Next

            If lignes.Count = 0 Then
                Alerte(pnlAvertissement, litAvertissement,
                       "Aucune classe n'a été choisie : il n'y a rien à créer.")
                Return
            End If

            Dim p As New Collection
            p.Add(New SqlParameter("@LotId", LotCourant))
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@UserId", UserId))
            p.Add(New SqlParameter("@Lignes", Newtonsoft.Json.JsonConvert.SerializeObject(lignes)))

            Dim ds As DataSet = ExecuteSQLds("s0767AppliquerPlanComptable", p)
            Dim crees As DataTable = If(ds Is Nothing OrElse ds.Tables.Count = 0, Nothing, ds.Tables(0))
            Dim n As Integer = If(crees Is Nothing, 0, crees.Rows.Count)

            If n > 0 Then
                rptCrees.DataSource = crees
                rptCrees.DataBind()
                pnlCrees.Visible = True
            End If

            Rafraichir()

            Dim msg As New StringBuilder()
            msg.AppendFormat("<b>{0} compte(s) créé(s)</b> dans votre plan comptable.", n)

            If sansClasse > 0 Then
                msg.AppendFormat(" {0} ligne(s) laissée(s) de côté, faute de classe choisie.", sansClasse)
            End If

            Alerte(pnlSucces, litSucces, msg.ToString())

        Catch ex As SqlException
            ' s0767 renvoie ses refus en clair : ils sont faits pour être lus.
            Alerte(pnlErreur, litErreur,
                   "<b>Rien n'a été créé.</b><br />" & Server.HtmlEncode(ex.Message))

        Catch ex As Exception
            Alerte(pnlErreur, litErreur, "Création : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

#End Region

#Region "Menus"

    Private Shared Function Nombre(v As Object) As Integer
        If v Is Nothing OrElse IsDBNull(v) Then Return 0
        Return Convert.ToInt32(v)
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
