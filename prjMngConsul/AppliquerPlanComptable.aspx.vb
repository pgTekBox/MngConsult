Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Text.RegularExpressions

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

    ''' <summary>
    ''' Y a-t-il un plan comptable en préparation ? Remplace l'ancien numéro de
    ''' lot : il n'y en a plus qu'un par compagnie, la seule question est de
    ''' savoir s'il existe.
    ''' </summary>
    Private Property PlanCharge As Boolean
        Get
            Return If(ViewState("PlanCharge") Is Nothing, False, CBool(ViewState("PlanCharge")))
        End Get
        Set(value As Boolean)
            ViewState("PlanCharge") = value
        End Set
    End Property

    ''' <summary>
    ''' Les classes, une lecture par nature et pas une par ligne : vingt
    ''' comptes de charge ne justifient pas vingt allers-retours.
    ''' </summary>
    Private ReadOnly _classesParNature As New Dictionary(Of String, DataTable)(StringComparer.OrdinalIgnoreCase)


    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            PlanCharge = LirePlanCharge()

            If PlanCharge Then
                Rafraichir()
            Else
                pnlAucunLot.Visible = True
            End If
        End If
    End Sub

    ''' <summary>
    ''' Un plan comptable attend-il en préparation ? Une seule question, là où
    ''' il fallait auparavant lister les lots et en choisir un.
    ''' </summary>
    Private Function LirePlanCharge() As Boolean
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))

        Dim ds As DataSet = ExecuteSQLds("s0758StatsCorrespondance", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return False
        Return Convert.ToInt32(ds.Tables(0).Rows(0)("Total")) > 0
    End Function

#End Region

#Region "Affichage"

    Private Sub Rafraichir()
        If Not PlanCharge Then Return

        hlRetour.NavigateUrl = "~/CorrespondanceComptes.aspx"

        Try
            Dim p As New Collection
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
            ' Une seule fois, à l'arrivée : après une création, c'est le résultat qui s'affiche.
            If aDecider > 0 AndAlso Not IsPostBack Then
                Alerte("Attention",
                       String.Format("<b>{0} compte(s) ne sont pas encore décidés</b> à l'étape 2. " &
                                     "Ils ne seront pas repris. Vous pouvez créer les autres " &
                                     "maintenant et revenir ensuite.", aDecider))
            End If

        Catch ex As Exception
            Alerte("Erreur", "Lecture du lot : " & Server.HtmlEncode(ex.Message))
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
        Dim ddlSous = TryCast(e.Item.FindControl("ddlSousClasse"), DropDownList)
        Dim hfNature = TryCast(e.Item.FindControl("hfNature"), HiddenField)
        If ddl Is Nothing OrElse ddlSous Is Nothing Then Return

        Dim nature = If(hfNature Is Nothing, "", hfNature.Value)

        ' 1er cran : les grandes classes compatibles avec la nature.
        ddl.Items.Clear()
        ddl.Items.Add(New ListItem("— choisir une classe —", ""))
        For Each r As DataRow In ClassesPour(nature, 1).Rows
            ddl.Items.Add(New ListItem(LibelleClasse(r), Convert.ToString(r("Id"))))
        Next

        ' 2e cran : toutes les sous-classes compatibles, chacune marquée de sa
        ' classe ; le navigateur ne montre que celles de la classe choisie.
        ' C'est elle qui est envoyée à la création : elle fixe la plage.
        ddlSous.Items.Clear()
        ddlSous.Items.Add(New ListItem("— choisir une sous-classe —", ""))
        For Each r As DataRow In ClassesPour(nature, 2).Rows
            Dim li As New ListItem(LibelleClasse(r), Convert.ToString(r("Id")))
            li.Attributes("data-parent") = Convert.ToString(r("ParentId"))
            ddlSous.Items.Add(li)
        Next
    End Sub

    Private Shared Function LibelleClasse(r As DataRow) As String
        Return String.Format("{0} — {1}  ({2}-{3})",
                             Convert.ToString(r("Code")),
                             Convert.ToString(r("Description")),
                             Convert.ToString(r("NumeroDebut")),
                             Convert.ToString(r("NumeroFin")))
    End Function

    Private Function ClassesPour(nature As String, Optional niveau As Integer = 2) As DataTable
        Dim cle = niveau.ToString() & "|" & If(nature, "")
        If _classesParNature.ContainsKey(cle) Then Return _classesParNature(cle)

        Dim vide As New DataTable()

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Nature", If(String.IsNullOrEmpty(nature), CType(DBNull.Value, Object), nature)))
            p.Add(New SqlParameter("@Niveau", niveau))

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

#Region "La fiche du compte d'origine"

    ''' <summary>
    ''' La même fiche qu'à l'étape 2 (CorrespondanceComptes.FicheSource) : ce
    ''' que la source dit du compte — nature, type et sous-type QuickBooks,
    ''' numéro et nom d'origine, solde source, d'où il vient, sous-compte de
    ''' qui, description — et ce que le chargement en a conclu.
    ''' </summary>
    Protected Function FicheSource(item As Object) As String
        Dim r As DataRowView = TryCast(item, DataRowView)
        If r Is Nothing Then Return ""

        Dim nature As String = Champ(r, "TypeNormalise")
        Dim typeQbo As String = Champ(r, "TypeSource")
        Dim sousType As String = Champ(r, "SousTypeSource")
        Dim numeroSrc As String = Champ(r, "CompteSource")
        Dim nomSrc As String = Champ(r, "NomSource")
        Dim soldeSrc As String = Champ(r, "SoldeSource")
        Dim sensSrc As String = Champ(r, "SensSource")
        Dim systeme As String = Champ(r, "SystemeSource")
        Dim anomalie As String = Champ(r, "AnomalieChargement")
        Dim statut As String = Champ(r, "StatutChargement")
        Dim origine As String = Champ(r, "OrigineSource")
        Dim creeLe As String = If(Not r.Row.Table.Columns.Contains("CreeLe") OrElse IsDBNull(r("CreeLe")), "", CDate(r("CreeLe")).ToString("yyyy-MM-dd"))
        Dim descriptionSrc As String = Champ(r, "DescriptionSource")
        Dim nomComplet As String = Champ(r, "NomComplet")
        Dim sousCompte As Boolean = (Champ(r, "SousCompte") = "True")
        Dim solde As String = If(Not r.Row.Table.Columns.Contains("Solde") OrElse IsDBNull(r("Solde")), "", Convert.ToDecimal(r("Solde")).ToString("N2"))

        Dim sb As New StringBuilder()

        ' 1) la nature, puis ce que QuickBooks en dit
        Dim ligne1 As New List(Of String)
        If nature <> "" Then ligne1.Add("<b>" & Server.HtmlEncode(nature) & "</b>")
        If typeQbo <> "" Then ligne1.Add(Server.HtmlEncode(typeQbo))
        If sousType <> "" Then ligne1.Add(Server.HtmlEncode(sousType))
        If solde <> "" Then ligne1.Add("solde " & solde)
        If ligne1.Count > 0 Then sb.Append("<div class='nature'>").Append(String.Join(" · ", ligne1)).Append("</div>")

        ' 2) ce que la source donnait, quand ça diffère de ce qui est affiché
        Dim ligne2 As New List(Of String)
        If numeroSrc <> "" AndAlso numeroSrc <> Champ(r, "Compte") Then ligne2.Add("n° source " & Server.HtmlEncode(numeroSrc))
        If nomSrc <> "" AndAlso Not String.Equals(nomSrc, Champ(r, "Nom"), StringComparison.OrdinalIgnoreCase) Then ligne2.Add("« " & Server.HtmlEncode(nomSrc) & " »")
        If soldeSrc <> "" AndAlso soldeSrc <> solde Then ligne2.Add("solde source " & Server.HtmlEncode(soldeSrc) & If(sensSrc <> "", " " & Server.HtmlEncode(sensSrc), ""))
        If systeme <> "" Then ligne2.Add(Server.HtmlEncode(systeme.ToLowerInvariant()))
        If ligne2.Count > 0 Then sb.Append("<div class='nature'>").Append(String.Join(" · ", ligne2)).Append("</div>")

        ' 3) d'où il vient, sous-compte de qui, description
        Dim ligne3 As New List(Of String)
        If origine = "AJOUTE" Then
            ligne3.Add("<b>ajouté" & If(creeLe <> "", " le " & creeLe, "") & "</b>")
        ElseIf origine = "DEFAUT" Then
            ligne3.Add("par défaut dans QuickBooks")
        End If
        If sousCompte AndAlso nomComplet <> "" AndAlso nomComplet.Contains(":") Then
            ligne3.Add("sous-compte de « " & Server.HtmlEncode(nomComplet.Substring(0, nomComplet.LastIndexOf(":"c))) & " »")
        End If
        If descriptionSrc <> "" Then ligne3.Add("<i>" & Server.HtmlEncode(descriptionSrc) & "</i>")
        If ligne3.Count > 0 Then sb.Append("<div class='nature' style='white-space:normal'>").Append(String.Join(" · ", ligne3)).Append("</div>")

        ' 4) ce que le chargement a conclu
        If statut = "EXISTE" AndAlso anomalie <> "" Then
            sb.Append("<div class='nature' style='color:#047857'>").Append(Server.HtmlEncode(anomalie)).Append("</div>")
        ElseIf anomalie <> "" Then
            sb.Append("<div class='nature' style='color:#b45309;white-space:normal'>").Append(Server.HtmlEncode(anomalie)).Append("</div>")
        End If

        Return sb.ToString()
    End Function

    Private Shared Function Champ(r As DataRowView, nom As String) As String
        If Not r.Row.Table.Columns.Contains(nom) OrElse IsDBNull(r(nom)) Then Return ""
        Return Convert.ToString(r(nom)).Trim()
    End Function

    ''' <summary>Le numéro du compte d'origine, ou « sans numéro » — courant avec QuickBooks.</summary>
    Protected Function CleAffichee(compte As Object) As String
        Dim c = If(compte Is Nothing OrElse compte Is DBNull.Value, "", Convert.ToString(compte))
        If c <> "" Then Return Server.HtmlEncode(c)
        Return "<span class='sans-num'>sans numéro</span>"
    End Function

#End Region

#Region "Créer"

    ''' <summary>
    ''' Écrit dans le plan comptable. Tout ou rien : s0767 refuse le lot
    ''' entier si une seule ligne est fautive — un plan à moitié repris serait
    ''' plus difficile à démêler qu'un plan pas repris du tout.
    ''' </summary>
    Protected Sub btnCreer_Click(sender As Object, e As EventArgs) Handles btnCreer.Click
        pnlCrees.Visible = False
        If Not PlanCharge Then Return

        Try
            Dim lignes As New List(Of Object)
            Dim sansClasse As Integer = 0

            For Each item As RepeaterItem In rptLignes.Items
                Dim hfCle = TryCast(item.FindControl("hfCleSource"), HiddenField)
                ' C'est la sous-classe qui range le compte (T312) : la classe
                ' n'est qu'un filtre pour la trouver.
                Dim ddl = TryCast(item.FindControl("ddlSousClasse"), DropDownList)
                Dim txtNum = TryCast(item.FindControl("txtNumero"), TextBox)
                Dim txtNom = TryCast(item.FindControl("txtNom"), TextBox)

                If hfCle Is Nothing OrElse ddl Is Nothing Then Continue For

                ' Une ligne sans sous-classe n'est pas une erreur : c'est un compte
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
                Alerte("Attention",
                       "Aucune classe n'a été choisie : il n'y a rien à créer.")
                Return
            End If

            Dim p As New Collection
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

            Alerte("Fait", msg.ToString())

        Catch ex As SqlException
            ' s0767 renvoie ses refus en clair : ils sont faits pour être lus.
            Alerte("Erreur",
                   "<b>Rien n'a été créé.</b><br />" & Server.HtmlEncode(ex.Message))

        Catch ex As Exception
            Alerte("Erreur", "Création : " & Server.HtmlEncode(ex.Message))
        End Try
    End Sub

#End Region

#Region "Menus"

    Private Shared Function Nombre(v As Object) As Integer
        If v Is Nothing OrElse IsDBNull(v) Then Return 0
        Return Convert.ToInt32(v)
    End Function

    ''' <summary>
    ''' Le résultat, l'avertissement ou le refus s'affiche dans la fenêtre de message du site
    ''' (Site.Master), par-dessus la grille : le bouton est en bas de page, un bandeau en haut
    ''' passerait inaperçu. Le message peut porter un peu de HTML (gras, &lt;br /&gt;) : il est ramené en texte.
    ''' </summary>
    Private Sub Alerte(titre As String, message As String)
        Dim texte = Regex.Replace(If(message, ""), "<br\s*/?>", vbLf, RegexOptions.IgnoreCase)
        texte = Regex.Replace(texte, "<[^>]+>", "")
        ShowMessageBox(HttpUtility.HtmlDecode(texte).Trim(), titre)
    End Sub

#End Region

End Class
