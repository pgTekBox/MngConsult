Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text
Imports System.Text.RegularExpressions

''' <summary>
''' Créer au plan, un compte à la fois, les comptes de l'ancien logiciel marqués
''' « Créer » : le même genre de fenêtre que « Associer un compte »
''' (AssocierCompte.aspx). À gauche le compte d'origine, à droite le nouveau
''' compte — sa classe, sa sous-classe (bornées à la nature du compte d'origine)
''' et son nom. Le numéro s'attribue tout seul dans la plage de la sous-classe.
'''
''' La création passe par la même procédure que la page en grille
''' (s0767AppliquerPlanComptable), avec une seule ligne. « Plus tard » ne
''' retient le compte que pour la session.
''' </summary>
Public Class CreerCompte
    Inherits clsData

    Private Const CleSautes As String = "CreerCompte.Sautes"
    Private Shared ReadOnly FrCa As CultureInfo = CultureInfo.GetCultureInfo("fr-CA")

    ''' <summary>Les comptes reportés à plus tard, pour la session seulement.</summary>
    Private ReadOnly Property Sautes As List(Of String)
        Get
            Dim l = TryCast(Session(CleSautes), List(Of String))
            If l Is Nothing Then
                l = New List(Of String)()
                Session(CleSautes) = l
            End If
            Return l
        End Get
    End Property

#Region "Cycle de vie"

    ''' <summary>Dans une fenêtre par-dessus une autre page (?popup=1) : ni menu ni en-tête ; un bouton Fermer.</summary>
    Private ReadOnly Property EnFenetre As Boolean
        Get
            Return Request.QueryString("popup") = "1"
        End Get
    End Property

    ''' <summary>Venu de « Décider d'un compte » (?retour=associer&amp;cle=…) : ce compte-là, puis retour.</summary>
    Private ReadOnly Property RetourAssocier As Boolean
        Get
            Return Request.QueryString("retour") = "associer" AndAlso CleDemandee <> ""
        End Get
    End Property

    Private ReadOnly Property CleDemandee As String
        Get
            Return If(Request.QueryString("cle"), "").Trim()
        End Get
    End Property

    ''' <summary>Revient à « Décider d'un compte » avec un message, dans la même fenêtre.</summary>
    Private Sub RevenirAssocier(message As String)
        If Not String.IsNullOrEmpty(message) Then Session(AssocierCompte.CleMessageRetour) = message
        Response.Redirect(If(EnFenetre, "~/AssocierCompte.aspx?popup=1", "~/AssocierCompte.aspx"), False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        DirectCast(Master, SiteMaster).FondDePage = True
        If Not isAuthenticated Then
            Response.Redirect("~/Default.aspx")
            Return
        End If
        btnFermer.Visible = True
        If EnFenetre Then
            litPopupCss.Text = "<style>" &
                ".mc-sidebar, .mc-app > *:not(.mc-shell), .ia-flottant { display: none !important }" &
                ".mc-shell, .mc-maincol { padding: 0 !important; margin: 0 !important; display: block !important }" &
                ".mc-mainwrap { margin: 0 !important; padding: 0 !important; border: 0 !important; box-shadow: none !important; border-radius: 0 !important }" &
                ".asc-page { max-width: none; padding: 10px 16px 16px }" &
                "</style>"
        End If
        If Not IsPostBack Then Charger()
    End Sub

    ''' <summary>Le prochain compte à créer qui n'a pas été reporté ; sinon la fin.</summary>
    Private Sub Charger()
        Try
            Dim lignes As DataTable = LignesACreer()
            Dim total As Integer = If(lignes Is Nothing, 0, lignes.Rows.Count)
            Dim courant As DataRow = Nothing
            Dim reportes As Integer = 0
            If RetourAssocier Then
                ' Seulement le compte demandé ; s'il n'est plus à créer, on revient.
                If lignes IsNot Nothing Then
                    For Each x As DataRow In lignes.Rows
                        If Convert.ToString(x("CleSource")) = CleDemandee Then courant = x : Exit For
                    Next
                End If
                If courant Is Nothing Then
                    RevenirAssocier(Nothing)
                    Return
                End If
            ElseIf lignes IsNot Nothing Then
                For Each x As DataRow In lignes.Rows
                    If Sautes.Contains(Convert.ToString(x("CleSource"))) Then
                        reportes += 1
                    ElseIf courant Is Nothing Then
                        courant = x
                    End If
                Next
            End If
            If courant Is Nothing Then
                Fin(total, reportes)
                Return
            End If
            pnlCarte.Visible = True
            pnlFin.Visible = False
            hfCle.Value = Convert.ToString(courant("CleSource"))
            litProgres.Text = If(RetourAssocier,
                "<p class='asc-progres'>Création immédiate ; vous reviendrez ensuite aux comptes à décider.</p>",
                "<p class='asc-progres'>" & total.ToString() & " compte(s) encore à créer" &
                              If(reportes > 0, ", dont " & reportes.ToString() & " reporté(s) à plus tard", "") & ".</p>")
            litCarte.Text = Carte(courant)
        Catch ex As Exception
            Alerte("Erreur", "Lecture des comptes à créer : " & ex.Message)
        End Try
    End Sub

    Private Sub Fin(total As Integer, reportes As Integer)
        pnlCarte.Visible = False
        pnlFin.Visible = True
        litProgres.Text = ""
        btnReprendre.Visible = (reportes > 0)
        If total = 0 Then
            litFin.Text = "<h2>Tous les comptes sont créés</h2><p>Chaque compte marqué « Créer » existe maintenant dans votre plan comptable.</p>"
            ' Dans la fenêtre par-dessus le tableau : plus rien à faire ici, elle se
            ' ferme et le tableau se recharge (les produits suivent le plan terminé).
            If EnFenetre Then
                ClientScript.RegisterStartupScript(Me.GetType(), "fermer",
                    "try { if (window.parent && window.parent !== window && window.parent.fermerFenetre) { window.parent.fermerFenetre(); } } catch (e) { }", True)
            End If
        Else
            litFin.Text = "<h2>" & reportes.ToString() & " compte(s) reporté(s) à plus tard</h2><p>Il ne reste que les comptes que vous avez " &
                          "mis de côté. Reprenez-les ici quand vous serez prêt.</p>"
        End If
    End Sub

#End Region

#Region "Lecture"

    ''' <summary>Les comptes marqués « Créer » et pas encore créés (s0766, 1er jeu).</summary>
    Private Function LignesACreer() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0766GetAAppliquer", p)
        Return If(ds Is Nothing OrElse ds.Tables.Count = 0, Nothing, ds.Tables(0))
    End Function

    Private Function LigneParCle(cle As String) As DataRow
        Dim lignes As DataTable = LignesACreer()
        If lignes Is Nothing Then Return Nothing
        For Each x As DataRow In lignes.Rows
            If Convert.ToString(x("CleSource")) = cle Then Return x
        Next
        Return Nothing
    End Function

    ''' <summary>Les classes (niveau 1) ou sous-classes (niveau 2) compatibles avec la nature.</summary>
    Private Function Classes(nature As String, niveau As Integer) As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Nature", If(String.IsNullOrEmpty(nature), CType(DBNull.Value, Object), nature)))
        p.Add(New SqlParameter("@Niveau", niveau))
        Dim ds As DataSet = ExecuteSQLds("s0765GetSousClasses", p)
        Return If(ds Is Nothing OrElse ds.Tables.Count = 0, New DataTable(), ds.Tables(0))
    End Function

    Private Function NomLogiciel() As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0884GetNomLogicielSource", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return "l'ancien logiciel"
            Dim v = ds.Tables(0).Rows(0)("NomLogiciel")
            Return If(IsDBNull(v), "l'ancien logiciel", Convert.ToString(v))
        Catch
            Return "l'ancien logiciel"
        End Try
    End Function

#End Region

#Region "La carte"

    ''' <summary>La carte d'un compte : le compte d'origine à gauche, le nouveau compte à droite.</summary>
    Private Function Carte(r As DataRow) As String
        Dim numSrc As String = Texte(r, "CompteSource")
        If numSrc = "" Then numSrc = Texte(r, "Compte")
        Dim nomSrc As String = Texte(r, "NomComplet")
        If nomSrc = "" Then nomSrc = Texte(r, "NomSource")
        If nomSrc = "" Then nomSrc = Texte(r, "Nom")
        Dim nature As String = Texte(r, "TypeNormalise")
        Dim nomPropose As String = Texte(r, "NomPropose")
        If nomPropose = "" Then nomPropose = Texte(r, "NomSource")
        If nomPropose = "" Then nomPropose = Texte(r, "Nom")
        ' Un nom QuickBooks « Parent:Enfant » : le nouveau compte prend le nom de l'enfant.
        If nomPropose.Contains(":") Then nomPropose = nomPropose.Substring(nomPropose.LastIndexOf(":"c) + 1).Trim()

        Dim sb As New StringBuilder()
        sb.Append("<div class='asc-corps'><h2>Créer un nouveau compte</h2><div class='asc-deux'>")

        ' ── Le compte d'origine ─────────────────────────────────────────────
        sb.Append("<div class='asc-source'><div class='asc-titre'>Compte dans ").Append(Enc(NomLogiciel())).Append("</div>")
        sb.Append("<div class='num'>").Append(If(numSrc <> "", Enc(numSrc), "<i>sans numéro</i>")).Append("</div>")
        sb.Append("<div class='nom'>").Append(Enc(nomSrc)).Append("</div><div class='meta'>")
        sb.Append("Nature : <b>").Append(Enc(NatureLibelle(nature))).Append("</b>")
        Dim sousType As String = Texte(r, "SousTypeSource")
        If sousType <> "" Then sb.Append(" · ").Append(Enc(sousType))
        sb.Append("<br />")
        If r.Table.Columns.Contains("Solde") AndAlso Not IsDBNull(r("Solde")) Then
            sb.Append("Solde au chargement : <b>").Append(Enc(String.Format(FrCa, "{0:C2}", Convert.ToDecimal(r("Solde"))))).Append("</b>")
            Dim sens As String = Texte(r, "SensSource")
            If sens <> "" Then sb.Append(" (").Append(Enc(sens.ToLowerInvariant())).Append(")")
        Else
            sb.Append("Solde non fourni")
        End If
        Dim description As String = Texte(r, "DescriptionSource")
        If description <> "" Then sb.Append("<br /><i>").Append(Enc(description)).Append("</i>")
        sb.Append("</div></div>")
        sb.Append("<div class='asc-fleche'>→</div>")

        ' ── Le nouveau compte ───────────────────────────────────────────────
        sb.Append("<div><div class='asc-titre'>Nouveau compte dans 60secondes</div><div class='cc-form'>")

        ' 1. La classe : bornée à la nature du compte d'origine.
        Dim dtClasses As DataTable = Classes(nature, 1)
        Dim seuleClasse As String = If(dtClasses.Rows.Count = 1, Convert.ToString(dtClasses.Rows(0)("Id")), "")
        sb.Append("<div class='cc-champ'><label for='ccClasse'>Classe</label>")
        sb.Append("<select id='ccClasse' name='classe' onchange='ccChoisirClasse()'>")
        sb.Append("<option value=''>— choisir une classe —</option>")
        For Each c As DataRow In dtClasses.Rows
            Dim id As String = Convert.ToString(c("Id"))
            sb.Append("<option value='").Append(Att(id)).Append("'").Append(If(id = seuleClasse, " selected", "")).Append(">")
            sb.Append(Enc(Libelle(c))).Append("</option>")
        Next
        sb.Append("</select>")
        sb.Append("<div class='cc-aide'>Seules les classes de nature « ").Append(Enc(NatureLibelle(nature).ToLowerInvariant())).Append(" » sont proposées.</div></div>")

        ' 2. La sous-classe : c'est elle qui range le compte et fixe la plage du numéro.
        sb.Append("<div class='cc-champ'><label for='ccSousClasse'>Sous-classe</label>")
        sb.Append("<select id='ccSousClasse' name='sousClasse' onchange='ccChoisirSousClasse()' disabled>")
        sb.Append("<option value=''>— choisir une sous-classe —</option>")
        For Each c As DataRow In Classes(nature, 2).Rows
            sb.Append("<option value='").Append(Att(Convert.ToString(c("Id")))).Append("'")
            sb.Append(" data-parent='").Append(Att(Convert.ToString(c("ParentId")))).Append("'")
            sb.Append(" data-debut='").Append(Att(Convert.ToString(c("NumeroDebut")))).Append("'")
            sb.Append(" data-fin='").Append(Att(Convert.ToString(c("NumeroFin")))).Append("'>")
            sb.Append(Enc(Libelle(c))).Append("</option>")
        Next
        sb.Append("</select>")
        sb.Append("<div class='cc-aide'>Elle donne au compte sa place dans vos états financiers.</div></div>")

        ' 3. Le nom du nouveau compte.
        sb.Append("<div class='cc-champ'><label for='ccNom'>Nom du nouveau compte</label>")
        sb.Append("<input type='text' id='ccNom' name='nomCompte' maxlength='100' value='").Append(Att(nomPropose)).Append("' />")
        sb.Append("<div class='cc-aide'>Proposé d'après le nom dans ").Append(Enc(NomLogiciel())).Append(" ; modifiez-le au besoin.</div></div>")

        sb.Append("<div class='cc-numero' id='ccNumero'>Numéro : attribué automatiquement, une fois la sous-classe choisie.</div>")
        sb.Append("</div></div></div></div>")
        Return sb.ToString()
    End Function

    Private Shared Function Libelle(r As DataRow) As String
        Return String.Format("{0} — {1}  ({2}-{3})",
                             Convert.ToString(r("Code")), Convert.ToString(r("Description")),
                             Convert.ToString(r("NumeroDebut")), Convert.ToString(r("NumeroFin")))
    End Function

#End Region

#Region "Les réponses"

    ''' <summary>Créer : une seule ligne envoyée à s0767, qui attribue le numéro dans la plage.</summary>
    Protected Sub btnCreer_Click(sender As Object, e As EventArgs) Handles btnCreer.Click
        Dim cle As String = hfCle.Value
        Dim sousClasse As String = If(Request.Form("sousClasse"), "").Trim()
        Dim nom As String = If(Request.Form("nomCompte"), "").Trim()
        Dim classeId As Integer
        If cle = "" OrElse Not Integer.TryParse(sousClasse, classeId) Then
            Alerte("Attention", "Choisissez la classe, puis la sous-classe du nouveau compte.")
            Charger()
            Return
        End If
        If nom = "" Then
            Alerte("Attention", "Donnez un nom au nouveau compte.")
            Charger()
            Return
        End If
        Try
            If LigneParCle(cle) Is Nothing Then
                Alerte("Attention", "Ce compte n'est plus à créer : il a été créé ou décidé ailleurs.")
                Charger()
                Return
            End If
            Dim ligne = New With {.CleSource = cle, .ClasseId = classeId, .Compte = "", .Nom = nom}
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@UserId", UserId))
            p.Add(New SqlParameter("@Lignes", Newtonsoft.Json.JsonConvert.SerializeObject(New Object() {ligne})))
            Dim ds As DataSet = ExecuteSQLds("s0767AppliquerPlanComptable", p)
            Dim numero As String = ""
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                numero = Convert.ToString(ds.Tables(0).Rows(0)("Compte"))
            End If
            Dim fait As String = "Le compte " & If(numero <> "", numero & " ", "") & "« " & nom & " » est créé dans votre plan comptable."
            If RetourAssocier Then
                RevenirAssocier(fait)
                Return
            End If
            Alerte("Fait", fait)
            ClientScript.RegisterStartupScript(Me.GetType(), "fenModifie", "try { if (window.parent && window.parent !== window) window.parent.fenModifie = true; } catch (e) { }", True)
            Charger()
        Catch ex As SqlException
            ' s0767 renvoie ses refus en clair : ils sont faits pour être lus.
            Alerte("Création impossible", ex.Message)
            Charger()
        Catch ex As Exception
            Alerte("Erreur", "Création : " & ex.Message)
            Charger()
        End Try
    End Sub

    ''' <summary>Plus tard : le compte est mis de côté pour la session, rien n'est créé.</summary>
    Protected Sub btnPlusTard_Click(sender As Object, e As EventArgs) Handles btnPlusTard.Click
        If RetourAssocier Then
            ' Il reste marqué « Créer » : il sera repris à la fin, avec les autres comptes à créer.
            RevenirAssocier("Le compte reste marqué « Créer » : vous le créerez une fois tous les comptes décidés.")
            Return
        End If
        If hfCle.Value <> "" AndAlso Not Sautes.Contains(hfCle.Value) Then Sautes.Add(hfCle.Value)
        Charger()
    End Sub

    Protected Sub btnReprendre_Click(sender As Object, e As EventArgs) Handles btnReprendre.Click
        Sautes.Clear()
        Charger()
    End Sub

#End Region

#Region "Outils"

    Private Shared Function Texte(r As DataRow, nom As String) As String
        If Not r.Table.Columns.Contains(nom) OrElse IsDBNull(r(nom)) Then Return ""
        Return Convert.ToString(r(nom)).Trim()
    End Function

    Private Shared Function Enc(s As String) As String
        Return HttpUtility.HtmlEncode(If(s, ""))
    End Function

    Private Shared Function Att(s As String) As String
        Return HttpUtility.HtmlAttributeEncode(If(s, ""))
    End Function

    Private Shared Function NatureLibelle(typeNormalise As String) As String
        Select Case If(typeNormalise, "").ToUpperInvariant()
            Case "ACTIF" : Return "Actif"
            Case "PASSIF" : Return "Passif"
            Case "CAPITAUX" : Return "Capitaux propres"
            Case "PRODUIT" : Return "Revenus"
            Case "CHARGE" : Return "Dépenses"
            Case Else : Return "Nature inconnue"
        End Select
    End Function

    Private Sub Alerte(titre As String, message As String)
        Dim t = Regex.Replace(If(message, ""), "<[^>]+>", "")
        ShowMessageBox(HttpUtility.HtmlDecode(t).Trim(), titre)
    End Sub

#End Region

End Class
