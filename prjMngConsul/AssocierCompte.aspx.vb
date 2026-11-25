Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text
Imports System.Text.RegularExpressions

''' <summary>
''' Étape 2 de la reprise du plan comptable, un compte à la fois : le compte de
''' l'ancien logiciel encore « à décider », ce que l'assistant en pense (la
''' proposition de l'IA ou du plan standard, les comptes proches de même
''' nature), ce que changerait une mauvaise association, et trois réponses —
''' Associer, Plus tard, Demander à mon cabinet certifié.
'''
''' Les décisions passent par la même procédure que la grille (s0757) : rien
''' n'est écrit en comptabilité, tout se range en préparation. « Plus tard »
''' ne retient le compte que pour la session ; « Demander à mon cabinet »
''' envoie la fiche par courriel aux utilisateurs comptables de la compagnie.
''' </summary>
Public Class AssocierCompte
    Inherits clsData

    Private Const CleSautes As String = "AssocierCompte.Sautes"
    Private Shared ReadOnly FrCa As CultureInfo = CultureInfo.GetCultureInfo("fr-CA")

    ''' <summary>Les comptes de l'ancien logiciel dont la déduction est limitée : une mauvaise cible fausse la déclaration.</summary>
    Private Shared ReadOnly RepasRepresentation As New Regex("repas|repr[ée]sentation|meals?|entertainment|divertissement|restaurant", RegexOptions.IgnoreCase Or RegexOptions.Compiled)

    ''' <summary>Un compte de 60secondes qu'on peut choisir, avec ce que l'assistant en dit.</summary>
    Private Class Cible
        Public Property Id As Integer
        Public Property Compte As String = ""
        Public Property Nom As String = ""
        Public Property TypeBilan As String = ""
        Public Property Badge As String = ""
        Public Property Raison As String = ""
        Public Property RaisonMal As Boolean
        Public Property Enjeu As String = ""
        Public Property Score As Double
    End Class

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

    ''' <summary>Dans une fenêtre par-dessus une autre page (?popup=1) : ni menu, ni en-tête, ni fil des étapes ; un bouton Fermer.</summary>
    Private ReadOnly Property EnFenetre As Boolean
        Get
            Return Request.QueryString("popup") = "1"
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Les boîtes posent sur le fond de la page, sans cadre blanc autour (aussi dans la fenêtre).
        DirectCast(Master, SiteMaster).FondDePage = True
        If Not isAuthenticated Then
            Response.Redirect("~/Default.aspx")
            Return
        End If
        If EnFenetre Then
            ucEtapes.Visible = False
            btnFermer.Visible = True
            litPopupCss.Text = "<style>" &
                ".mc-sidebar, .mc-app > *:not(.mc-shell), .ia-flottant { display: none !important }" &
                ".mc-shell, .mc-maincol { padding: 0 !important; margin: 0 !important; display: block !important }" &
                ".mc-mainwrap { margin: 0 !important; padding: 0 !important; border: 0 !important; box-shadow: none !important; border-radius: 0 !important }" &
                ".asc-page { max-width: none; padding: 10px 16px 16px }" &
                "</style>"
        End If
        If Not IsPostBack Then
            ' Au retour de la création immédiate d'un compte (CreerCompte.aspx?retour=associer).
            Dim msg = TryCast(Session(CleMessageRetour), String)
            If Not String.IsNullOrEmpty(msg) Then
                Session.Remove(CleMessageRetour)
                Alerte("Fait", msg)
                ClientScript.RegisterStartupScript(Me.GetType(), "fenModifie", "try { if (window.parent && window.parent !== window) window.parent.fenModifie = true; } catch (e) { }", True)
            End If
            Charger()
        End If
    End Sub

    ''' <summary>Le message à afficher au retour de CreerCompte.aspx (création immédiate).</summary>
    Public Const CleMessageRetour As String = "AssocierCompte.MessageRetour"

    ''' <summary>Le prochain compte à décider qui n'a pas été reporté ; sinon la fin.</summary>
    Private Sub Charger()
        Try
            Dim lignes As DataTable = LignesADecider()
            Dim total As Integer = If(lignes Is Nothing, 0, lignes.Rows.Count)
            Dim courant As DataRow = Nothing
            Dim reportes As Integer = 0
            If lignes IsNot Nothing Then
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
            pnlTest.Visible = True
            pnlFin.Visible = False
            hfCle.Value = Convert.ToString(courant("CleSource"))
            litProgres.Text = "<p class='asc-progres'>" & total.ToString() & " compte(s) encore à décider" &
                              If(reportes > 0, ", dont " & reportes.ToString() & " reporté(s) à plus tard", "") & ".</p>"
            litCarte.Text = Carte(courant)
        Catch ex As SqlException When ex.Number = 50310
            Fin(0, 0, "Aucun plan comptable n'a encore été chargé pour cette compagnie : commencez par l'étape 1.")
        Catch ex As Exception
            Alerte("Erreur", "Lecture des comptes à décider : " & ex.Message)
        End Try
    End Sub

    Private Sub Fin(total As Integer, reportes As Integer, Optional message As String = Nothing)
        pnlCarte.Visible = False
        pnlTest.Visible = False
        pnlFin.Visible = True
        btnReprendre.Visible = (reportes > 0)
        If message IsNot Nothing Then
            litFin.Text = "<h2>Rien à associer</h2><p>" & HttpUtility.HtmlEncode(message) & "</p>"
        ElseIf total = 0 Then
            ' Tout est décidé : l'étape suivante est la création des comptes marqués « Créer ».
            Dim aCreer As Integer = 0
            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", Company))
                Dim ds As DataSet = ExecuteSQLds("s0766GetAAppliquer", p)
                If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then aCreer = ds.Tables(0).Rows.Count
            Catch
            End Try
            If aCreer > 0 Then
                ' Tout est décidé et des comptes attendent leur création : on y passe
                ' tout de suite, dans la même fenêtre, sans écran intermédiaire.
                Response.Redirect(If(EnFenetre, "~/CreerCompte.aspx?popup=1", "~/CreerCompte.aspx"), False)
                Context.ApplicationInstance.CompleteRequest()
                Return
            Else
                litFin.Text = "<h2>Tout est décidé</h2><p>Chaque compte de " & HttpUtility.HtmlEncode(NomLogiciel()) & " est lié ou ignoré, " &
                              "et les comptes à créer existent déjà dans votre plan comptable. Le plan comptable est terminé.</p>"
                ' Dans la fenêtre par-dessus le tableau : plus rien à décider ni à
                ' créer, elle se ferme et le tableau se recharge.
                If EnFenetre Then
                    ClientScript.RegisterStartupScript(Me.GetType(), "fermer",
                        "try { if (window.parent && window.parent !== window) { window.parent.fenModifie = true; if (window.parent.fermerFenetre) window.parent.fermerFenetre(); } } catch (e) { }", True)
                End If
            End If
        Else
            litFin.Text = "<h2>" & reportes.ToString() & " compte(s) reporté(s) à plus tard</h2><p>Il ne reste que les comptes que vous avez " &
                          "mis de côté. Reprenez-les ici quand vous serez prêt.</p>"
        End If
    End Sub

#End Region

#Region "Lecture"

    Private Function LignesADecider() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Filtre", "A_DECIDER"))
        p.Add(New SqlParameter("@Top", 1000))
        p.Add(New SqlParameter("@Origine", DBNull.Value))
        Dim ds As DataSet = ExecuteSQLds("s0756GetCorrespondances", p)
        Return If(ds Is Nothing OrElse ds.Tables.Count = 0, Nothing, ds.Tables(0))
    End Function

    Private Function LigneParCle(cle As String) As DataRow
        Dim lignes As DataTable = LignesADecider()
        If lignes Is Nothing Then Return Nothing
        For Each x As DataRow In lignes.Rows
            If Convert.ToString(x("CleSource")) = cle Then Return x
        Next
        Return Nothing
    End Function

    ''' <summary>Le plan comptable de la compagnie, tel que s0759 le rend.</summary>
    Private Function PlanCompagnie() As List(Of Cible)
        Dim l As New List(Of Cible)()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0759GetPlanCompagnie", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return l
        ' Un compte d'ici déjà lié à un autre compte source n'est plus un choix (T405).
        Dim pris As New HashSet(Of Integer)()
        Dim dsPris As DataSet = ExecuteSQLds("s1029GetComptesDejaLies", New Collection From {New SqlParameter("@CompanyGUID", Company)})
        If dsPris IsNot Nothing AndAlso dsPris.Tables.Count > 0 Then
            For Each x As DataRow In dsPris.Tables(0).Rows
                pris.Add(Convert.ToInt32(x("PlanComptableId")))
            Next
        End If
        For Each r As DataRow In ds.Tables(0).Rows
            If pris.Contains(Convert.ToInt32(r("Id"))) Then Continue For
            l.Add(New Cible With {.Id = Convert.ToInt32(r("Id")), .Compte = Texte(r("Compte")), .Nom = Texte(r("Nom")), .TypeBilan = Texte(r("TypeBilan"))})
        Next
        Return l
    End Function

    Private Function NomLogiciel() As String
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim r = PremiereLigne(ExecuteSQLds("s0884GetNomLogicielSource", p))
        Return If(r Is Nothing OrElse IsDBNull(r("NomLogiciel")), "l'ancien logiciel", Convert.ToString(r("NomLogiciel")))
    End Function

    ''' <summary>Ce qui, en préparation, se sert du compte : lignes de facture et produits.</summary>
    Private Function Usages(cle As String) As Integer()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0885GetComptesSourceUtilises", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                If Convert.ToString(r("CleSource")) = cle Then
                    Return New Integer() {Convert.ToInt32(r("NbLignesFactures")), Convert.ToInt32(r("NbProduits"))}
                End If
            Next
        End If
        Return New Integer() {0, 0}
    End Function

    Private Shared Function PremiereLigne(ds As DataSet) As DataRow
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return Nothing
        Return ds.Tables(0).Rows(0)
    End Function

#End Region

#Region "La carte"

    ''' <summary>La carte d'un compte : l'assistant, le compte source, les cibles, l'enjeu.</summary>
    Private Function Carte(r As DataRow) As String
        Dim logiciel As String = NomLogiciel()
        Dim plan As List(Of Cible) = PlanCompagnie()
        Dim cle As String = Convert.ToString(r("CleSource"))
        Dim numSrc As String = Texte(r("CompteSource"))
        If numSrc = "" Then numSrc = Texte(r("Compte"))
        Dim nomSrc As String = Texte(r("NomComplet"))
        If nomSrc = "" Then nomSrc = Texte(r("Nom"))
        If nomSrc = "" Then nomSrc = Texte(r("NomSource"))
        Dim natureSrc As String = Texte(r("TypeNormalise"))
        Dim lettreSrc As String = NatureLettre(natureSrc)
        Dim solde As Decimal? = Nothing
        If Not IsDBNull(r("Solde")) Then solde = Convert.ToDecimal(r("Solde"))
        Dim usage As Integer() = Usages(cle)

        ' ── Les cibles ──────────────────────────────────────────────────────
        Dim cibles As New List(Of Cible)()
        Dim exact As Boolean = False
        Dim ia As Cible = Trouver(plan, Texte(r("IACompte")))
        If ia IsNot Nothing Then
            Dim conf As String = If(IsDBNull(r("IAConfiance")), "", Convert.ToInt32(r("IAConfiance")).ToString() & " %")
            ia.Badge = "Recommandé" & If(conf <> "", " · " & conf, "")
            ia.Raison = Texte(r("IARaison"))
            cibles.Add(ia)
        End If
        Dim prop As Cible = Trouver(plan, Texte(r("ProposeCompte")))
        If prop IsNot Nothing AndAlso Not cibles.Any(Function(c) c.Id = prop.Id) Then
            Dim origine As String = Texte(r("Origine")).ToUpperInvariant()
            If origine.Contains("QBO") Then
                prop.Badge = "Même compte au plan standard (alias QuickBooks)"
            ElseIf origine.Contains("NUM") Then
                prop.Badge = "Même numéro" : exact = True
            ElseIf origine.Contains("NOM") Then
                prop.Badge = "Même nom" : exact = True
            Else
                prop.Badge = "Proposé par 60secondes"
            End If
            If ia Is Nothing Then prop.Badge = "Recommandé · " & prop.Badge
            prop.Raison = "Proposé d'après ce que 60secondes sait de ce compte."
            cibles.Add(prop)
        End If
        ' Les comptes proches de même nature, par le nom.
        Dim proches = plan.Where(Function(c) c.TypeBilan = lettreSrc AndAlso Not cibles.Any(Function(x) x.Id = c.Id)).
            Select(Function(c)
                       c.Score = Similarite(nomSrc, c.Nom)
                       Return c
                   End Function).
            Where(Function(c) c.Score >= 0.34).OrderByDescending(Function(c) c.Score).Take(2).ToList()
        For Each c In proches
            If cibles.Count = 0 AndAlso c Is proches(0) Then
                c.Badge = "Le plus proche · " & CInt(Math.Round(c.Score * 100)).ToString() & " %"
            End If
            c.Raison = "Même nature (" & NatureLibelle(natureSrc, False) & ") ; nom proche."
            cibles.Add(c)
        Next
        ' L'enjeu de chaque cible : la nature, puis les règles fiscales connues.
        For Each c In cibles
            c.Enjeu = EnjeuDe(c, nomSrc, natureSrc, lettreSrc, solde)
            If c.Enjeu <> "" AndAlso c.Raison <> "" AndAlso c.TypeBilan <> lettreSrc Then c.RaisonMal = True
        Next
        Dim creer As New Cible With {.Compte = "CREER", .Nom = "Créer un nouveau compte",
            .Raison = If(numSrc <> "", numSrc & " · ", "") & nomSrc & ", " & NatureLibelle(natureSrc, True) &
                      " ; créé tout de suite : vous choisirez sa classe, sa sous-classe et son nom"}

        ' ── Le rendu ────────────────────────────────────────────────────────
        Dim sb As New StringBuilder()
        sb.Append("<div class='asc-corps'><h2>Décider d'un compte</h2><div class='asc-deux'>")
        ' le compte source
        sb.Append("<div class='asc-source'><div class='asc-titre'>Compte dans ").Append(HttpUtility.HtmlEncode(logiciel)).Append("</div>")
        sb.Append("<div class='num'>").Append(If(numSrc <> "", HttpUtility.HtmlEncode(numSrc), "<i>sans numéro</i>")).Append("</div>")
        sb.Append("<div class='nom'>").Append(HttpUtility.HtmlEncode(nomSrc)).Append("</div><div class='meta'>")
        sb.Append("Nature : ").Append(HttpUtility.HtmlEncode(NatureLibelle(natureSrc, True)))
        If Not IsDBNull(r("SousTypeSource")) AndAlso Texte(r("SousTypeSource")) <> "" Then
            sb.Append(" · ").Append(HttpUtility.HtmlEncode(Texte(r("SousTypeSource"))))
        End If
        sb.Append("<br />")
        If solde.HasValue Then
            sb.Append("Solde au chargement : <b>").Append(HttpUtility.HtmlEncode(Argent(solde.Value))).Append("</b>")
            Dim sens As String = Texte(r("SensSource"))
            If sens <> "" Then sb.Append(" (").Append(HttpUtility.HtmlEncode(sens.ToLowerInvariant())).Append(")")
        Else
            sb.Append("Solde non fourni")
        End If
        sb.Append("<br />")
        ' Ce que les données importées en font (T317) : tout, pas seulement les
        ' factures et les produits ; et quand rien ne s'en sert à solde 0, la
        ' grille de l'étape 2 propose Ignorer — on le dit ici aussi.
        Dim usagesTous As String = CorrespondanceComptes.TexteUsages(r)
        If r.Table.Columns.Contains("Inutilise") AndAlso Not IsDBNull(r("Inutilise")) AndAlso Convert.ToInt32(r("Inutilise")) = 1 Then
            sb.Append("<b>Inutilisé</b> : solde 0, et aucune donnée importée ne s'en sert — l'étape 2 propose Ignorer")
        ElseIf usagesTous <> "" Then
            sb.Append("Utilisé : ").Append(HttpUtility.HtmlEncode(usagesTous))
        ElseIf usage(0) > 0 OrElse usage(1) > 0 Then
            sb.Append(usage(0).ToString()).Append(" ligne(s) de facture · ").Append(usage(1).ToString()).Append(" produit(s) en préparation")
        Else
            sb.Append("Aucune facture ni produit en préparation ne l'utilise")
        End If
        sb.Append("</div></div>")
        sb.Append("<div class='asc-fleche'>→</div>")
        ' les cibles
        sb.Append("<div><div class='asc-titre'>Compte dans 60secondes</div><div class='asc-choix'>")
        Dim premier As Boolean = True
        For Each c In cibles
            Option_(sb, c.Compte, c, premier)
            premier = False
        Next
        Option_(sb, "CREER", creer, premier)
        ' Un compte à 0 n'a rien à reprendre : on peut l'ignorer. s0757 refuse
        ' encore s'il sert à une donnée importée (T304), et le dit en clair.
        ' Un compte dont se servent des produits ne peut pas être ignoré : leurs
        ' comptes de vente ou d'achat n'auraient plus de compte où tomber.
        ' Ni s'il sert à quoi que ce soit d'importé : ligne d'écriture, de facture,
        ' du grand livre, de la balance… (NbUsages, T317).
        If solde.HasValue AndAlso solde.Value = 0D AndAlso usage(1) = 0 AndAlso NbUsages(r) = 0 Then
            Dim ignorer As New Cible With {.Compte = "IGNORER", .Nom = "Ignorer ce compte",
                .Raison = "Solde à 0 : rien à reprendre. Le compte ne sera pas créé dans 60secondes."}
            Option_(sb, "IGNORER", ignorer, False)
        End If
        sb.Append("</div></div></div>")
        sb.Append("<div class='asc-enjeu' id='ascEnjeu' hidden><span class='pic'><i class='ic ic-alert' aria-hidden='true'></i></span><div id='ascEnjeuTexte'></div></div>")
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    Private Shared Sub Option_(sb As StringBuilder, valeur As String, c As Cible, coche As Boolean)
        sb.Append("<label class='asc-opt").Append(If(coche, " active", "")).Append("' data-enjeu='").Append(HttpUtility.HtmlAttributeEncode(c.Enjeu)).Append("'>")
        sb.Append("<div class='ligne'><input type='radio' name='cible' value='").Append(HttpUtility.HtmlAttributeEncode(valeur)).Append("'")
        If coche Then sb.Append(" checked='checked'")
        sb.Append(" onclick='ascChoisir(this)' />")
        If valeur <> "CREER" AndAlso valeur <> "IGNORER" Then sb.Append("<span class='num'>").Append(HttpUtility.HtmlEncode(c.Compte)).Append("</span>")
        sb.Append("<span class='nom'>").Append(HttpUtility.HtmlEncode(c.Nom)).Append("</span></div>")
        If c.Badge <> "" Then sb.Append("<span class='reco'>").Append(HttpUtility.HtmlEncode(c.Badge)).Append("</span>")
        If c.Raison <> "" Then sb.Append("<div class='raison").Append(If(c.RaisonMal, " mal", "")).Append("'>").Append(HttpUtility.HtmlEncode(c.Raison)).Append("</div>")
        sb.Append("</label>")
    End Sub

    ''' <summary>Ce qu'une mauvaise association changerait : la nature d'abord, puis les règles fiscales connues.</summary>
    Private Shared Function EnjeuDe(c As Cible, nomSrc As String, natureSrc As String, lettreSrc As String, solde As Decimal?) As String
        If c.TypeBilan <> "" AndAlso lettreSrc <> "" AndAlso c.TypeBilan <> lettreSrc Then
            Return "<b>Enjeu :</b> « " & HttpUtility.HtmlEncode(c.Nom) & " » est un compte " & NatureLibelle(NatureDeLettre(c.TypeBilan), False) &
                   ", alors que « " & HttpUtility.HtmlEncode(nomSrc) & " » est un compte " & NatureLibelle(natureSrc, False) &
                   ". Les montants changeraient de côté dans vos états financiers."
        End If
        Dim srcRepas As Boolean = RepasRepresentation.IsMatch(nomSrc)
        Dim cibleRepas As Boolean = RepasRepresentation.IsMatch(c.Nom)
        If srcRepas AndAlso Not cibleRepas Then
            Dim s As String = "<b>Enjeu fiscal :</b> les repas et frais de représentation ne sont déductibles qu'à 50 %, comme l'exigent l'ARC et Revenu Québec."
            If solde.HasValue AndAlso solde.Value <> 0D Then
                s &= " Une mauvaise association ajouterait environ <b>" & HttpUtility.HtmlEncode(Argent(Math.Abs(solde.Value) / 2D)) & "</b> de dépenses déductibles en trop à votre déclaration."
            End If
            Return s
        End If
        If cibleRepas AndAlso Not srcRepas Then
            Return "<b>Enjeu fiscal :</b> « " & HttpUtility.HtmlEncode(c.Nom) & " » n'est déductible qu'à 50 % : ces dépenses seraient sous-évaluées dans votre déclaration."
        End If
        Return ""
    End Function

#End Region

#Region "Les trois réponses"

    ''' <summary>Associer : la même décision que la grille, pour ce seul compte.</summary>
    Protected Sub btnAssocier_Click(sender As Object, e As EventArgs) Handles btnAssocier.Click
        Dim cle As String = hfCle.Value
        Dim choix As String = If(Request.Form("cible"), "").Trim()
        If cle = "" OrElse choix = "" Then
            Alerte("Attention", "Choisissez un compte de 60secondes, ou « Créer un nouveau compte », avant d'associer.")
            Return
        End If
        Try
            Dim r As DataRow = LigneParCle(cle)
            If r Is Nothing Then
                Alerte("Attention", "Ce compte n'est plus à décider : il a été décidé ailleurs, ou le plan a été rechargé.")
                Charger()
                Return
            End If
            Dim nomSrc As String = Texte(r("NomSource"))
            Dim creer As Boolean = (choix = "CREER")
            Dim ignorer As Boolean = (choix = "IGNORER")
            If ignorer AndAlso (IsDBNull(r("Solde")) OrElse Convert.ToDecimal(r("Solde")) <> 0D) Then
                Alerte("Attention", "Seul un compte à 0 peut être ignoré : ce compte a un solde à reprendre.")
                Charger()
                Return
            End If
            If ignorer AndAlso NbUsages(r) > 0 Then
                Dim usagesTexte As String = CorrespondanceComptes.TexteUsages(r)
                Alerte("Attention", "Ce compte ne peut pas être ignoré : des données importées s'en servent" &
                       If(usagesTexte <> "", " (" & usagesTexte & ")", "") & ". Liez-le à un compte de 60secondes, ou créez-le.")
                Charger()
                Return
            End If
            If ignorer Then
                Dim nbProduits As Integer = Usages(cle)(1)
                If nbProduits > 0 Then
                    Alerte("Attention", "Ce compte ne peut pas être ignoré : " & nbProduits.ToString() & " produit(s) en préparation s'en servent comme compte de vente ou d'achat. Liez-le à un compte de 60secondes, ou créez-le.")
                    Charger()
                    Return
                End If
            End If
            Dim decision = New With {
                .CleSource = cle,
                .TypeCle = Texte(r("TypeCle")),
                .CompteSource = Texte(r("CompteSource")),
                .NomSource = nomSrc,
                .Action = If(ignorer, "IGNORER", If(creer, "CREER", "LIER")),
                .CompteCible = If(ignorer, "", If(creer, Texte(r("CompteSource")), choix)),
                .NomCible = nomSrc,
                .TypeCible = Texte(r("TypeSource")),
                .Note = "Associé un par un"
            }
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@UserId", UserId))
            p.Add(New SqlParameter("@Decisions", Newtonsoft.Json.JsonConvert.SerializeObject(New Object() {decision})))
            Dim stats = PremiereLigne(ExecuteSQLds("s0757SaveCorrespondances", p))
            If creer Then
                ' Créer : on le fait tout de suite, dans la même fenêtre — classe,
                ' sous-classe et nom —, puis on revient au compte suivant à décider.
                Response.Redirect("~/CreerCompte.aspx?retour=associer&cle=" & HttpUtility.UrlEncode(cle) & If(EnFenetre, "&popup=1", ""), False)
                Context.ApplicationInstance.CompleteRequest()
                Return
            End If
            Dim reste As String = If(stats Is Nothing, "", " Il reste " & Convert.ToString(stats("ADecider")) & " compte(s) à décider.")
            Alerte("Fait", If(ignorer, "« " & nomSrc & " » est ignoré : il ne sera pas repris.",
                           If(creer, "« " & nomSrc & " » sera créé au plan à l'étape 3.", "« " & nomSrc & " » est lié au compte " & choix & " de 60secondes.")) & reste)
            ClientScript.RegisterStartupScript(Me.GetType(), "fenModifie", "try { if (window.parent && window.parent !== window) window.parent.fenModifie = true; } catch (e) { }", True)
            Charger()
        Catch ex As SqlException
            Alerte("Enregistrement impossible", ex.Message)
        Catch ex As Exception
            Alerte("Erreur", "Enregistrement : " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' POUR FIN DE TEST : lie d'un coup tous les comptes admissibles — les propositions
    ''' sûres (même numéro, même nom, alias QuickBooks : s0760) puis celles de l'IA
    ''' d'au moins 70 % (s0899). Mêmes garde-fous que la grille ; le reste reste à décider.
    ''' </summary>
    Protected Sub btnLierTout_Click(sender As Object, e As EventArgs) Handles btnLierTout.Click
        Dim refus As New List(Of String)()
        Try
            Dim avant As Integer = ADecider()
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@UserId", UserId))
            ExecuteSQLds("s0760AccepterPropositions", p)

            Dim p2 As New Collection
            p2.Add(New SqlParameter("@CompanyGUID", Company))
            p2.Add(New SqlParameter("@UserId", UserId))
            p2.Add(New SqlParameter("@Seuil", CByte(70)))
            ExecuteSQLds("s0899LierParConfianceIA", p2)

            ' Puis chaque compte encore à décider qui a une proposition dans cette
            ' fenêtre — la recommandation de l'IA, le compte proposé, sinon le plus
            ' proche de même nature — est lié à cette proposition. Un compte d'ici
            ' n'est jamais pris deux fois.
            Dim lignes As DataTable = LignesADecider()
            If lignes IsNot Nothing AndAlso lignes.Rows.Count > 0 Then
                Dim plan As List(Of Cible) = PlanCompagnie()
                Dim pris As New HashSet(Of Integer)()
                Dim decisions As New List(Of Object)()
                For Each r As DataRow In lignes.Rows
                    Dim c As Cible = CibleProposee(r, plan, pris)
                    If c Is Nothing Then Continue For
                    pris.Add(c.Id)
                    decisions.Add(New With {
                        .CleSource = Convert.ToString(r("CleSource")),
                        .TypeCle = Texte(r("TypeCle")),
                        .CompteSource = Texte(r("CompteSource")),
                        .NomSource = Texte(r("NomSource")),
                        .Action = "LIER",
                        .CompteCible = c.Compte,
                        .NomCible = Texte(r("NomSource")),
                        .TypeCible = Texte(r("TypeSource")),
                        .Note = "Lié automatiquement (test) : proposition de la fenêtre"})
                Next
                If decisions.Count > 0 Then
                    Try
                        EnregistrerDecisions(decisions)
                    Catch ex As SqlException
                        ' Un seul refus de s0757 annule tout le lot : on reprend alors
                        ' compte par compte, et seuls les refusés restent à décider.
                        For Each d In decisions
                            Try
                                EnregistrerDecisions(New List(Of Object) From {d})
                            Catch ex2 As SqlException
                                refus.Add(ex2.Message)
                            End Try
                        Next
                    End Try
                End If
            End If

            Dim apres As Integer = ADecider()
            Alerte("Fait", (avant - apres).ToString() & " compte(s) lié(s) automatiquement. Il reste " & apres.ToString() & " compte(s) à décider." &
                   If(refus.Count > 0, " " & refus.Count.ToString() & " liaison(s) refusée(s) : " & String.Join(" ", refus), ""))
            ClientScript.RegisterStartupScript(Me.GetType(), "fenModifie", "try { if (window.parent && window.parent !== window) window.parent.fenModifie = true; } catch (e) { }", True)
        Catch ex As Exception
            Alerte("Erreur", "Liaison automatique : " & ex.Message)
        End Try
        Charger()
    End Sub

    ''' <summary>
    ''' La proposition que la fenêtre mettrait en tête pour ce compte : la
    ''' recommandation de l'IA, sinon le compte proposé (numéro, nom, alias), sinon
    ''' le compte le plus proche de même nature (nom ressemblant à 34 % au moins).
    ''' Nothing s'il n'y en a pas, ou si elle est déjà prise.
    ''' </summary>
    Private Function CibleProposee(r As DataRow, plan As List(Of Cible), pris As HashSet(Of Integer)) As Cible
        Dim ia As Cible = Trouver(plan, Texte(r("IACompte")))
        If ia IsNot Nothing AndAlso Not pris.Contains(ia.Id) Then Return ia
        Dim prop As Cible = Trouver(plan, Texte(r("ProposeCompte")))
        If prop IsNot Nothing AndAlso Not pris.Contains(prop.Id) Then Return prop

        Dim nomSrc As String = Texte(r("NomComplet"))
        If nomSrc = "" Then nomSrc = Texte(r("Nom"))
        If nomSrc = "" Then nomSrc = Texte(r("NomSource"))
        Dim lettreSrc As String = NatureLettre(Texte(r("TypeNormalise")))
        Return plan.Where(Function(c) c.TypeBilan = lettreSrc AndAlso Not pris.Contains(c.Id)).
                    Select(Function(c) New With {.C = c, .S = Similarite(nomSrc, c.Nom)}).
                    Where(Function(x) x.S >= 0.34).
                    OrderByDescending(Function(x) x.S).
                    Select(Function(x) x.C).FirstOrDefault()
    End Function

    ''' <summary>
    ''' POUR FIN DE TEST : ignore d'un coup chaque compte encore à décider dont le
    ''' solde est 0 et dont aucune donnée importée ne se sert (lignes de facture,
    ''' produits : s0885). Les autres restent à décider.
    ''' </summary>
    Protected Sub btnIgnorerZero_Click(sender As Object, e As EventArgs) Handles btnIgnorerZero.Click
        Try
            Dim avant As Integer = ADecider()
            ' Les comptes source dont se servent des données importées.
            Dim utilises As New HashSet(Of String)(StringComparer.Ordinal)
            Dim pu As New Collection
            pu.Add(New SqlParameter("@CompanyGUID", Company))
            Dim dsU As DataSet = ExecuteSQLds("s0885GetComptesSourceUtilises", pu)
            If dsU IsNot Nothing AndAlso dsU.Tables.Count > 0 Then
                For Each u As DataRow In dsU.Tables(0).Rows
                    utilises.Add(Convert.ToString(u("CleSource")))
                Next
            End If

            Dim decisions As New List(Of Object)()
            Dim lignes As DataTable = LignesADecider()
            If lignes IsNot Nothing Then
                For Each r As DataRow In lignes.Rows
                    If IsDBNull(r("Solde")) OrElse Convert.ToDecimal(r("Solde")) <> 0D Then Continue For
                    Dim cle As String = Convert.ToString(r("CleSource"))
                    If utilises.Contains(cle) Then Continue For
                    ' QuickBooks rend 0 pour tout compte de revenus ou de dépenses, même
                    ' utilisé : on s'appuie aussi sur « Inutilisé » (T317 : solde 0 ET
                    ' aucune donnée importée ne s'en sert — écritures, dépenses, etc.).
                    If r.Table.Columns.Contains("Inutilise") AndAlso (IsDBNull(r("Inutilise")) OrElse Convert.ToInt32(r("Inutilise")) <> 1) Then Continue For
                    decisions.Add(New With {
                        .CleSource = cle,
                        .TypeCle = Texte(r("TypeCle")),
                        .CompteSource = Texte(r("CompteSource")),
                        .NomSource = Texte(r("NomSource")),
                        .Action = "IGNORER",
                        .CompteCible = "",
                        .NomCible = Texte(r("NomSource")),
                        .TypeCible = Texte(r("TypeSource")),
                        .Note = "Ignoré automatiquement (test) : solde 0, inutilisé"})
                Next
            End If
            If decisions.Count > 0 Then
                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", Company))
                p.Add(New SqlParameter("@UserId", UserId))
                p.Add(New SqlParameter("@Decisions", Newtonsoft.Json.JsonConvert.SerializeObject(decisions)))
                ExecuteSQLds("s0757SaveCorrespondances", p)
            End If

            Dim apres As Integer = ADecider()
            Alerte("Fait", (avant - apres).ToString() & " compte(s) à solde 0 ignoré(s) automatiquement. Il reste " & apres.ToString() & " compte(s) à décider.")
            ClientScript.RegisterStartupScript(Me.GetType(), "fenModifie", "try { if (window.parent && window.parent !== window) window.parent.fenModifie = true; } catch (e) { }", True)
        Catch ex As SqlException
            Alerte("Enregistrement impossible", ex.Message)
        Catch ex As Exception
            Alerte("Erreur", "Ignorer les comptes à 0 : " & ex.Message)
        End Try
        Charger()
    End Sub

    ''' <summary>Combien de données importées se servent du compte (T317 : écritures, factures, grand livre, balance…).</summary>
    Private Shared Function NbUsages(r As DataRow) As Integer
        If Not r.Table.Columns.Contains("NbUsages") OrElse IsDBNull(r("NbUsages")) Then Return 0
        Return Convert.ToInt32(r("NbUsages"))
    End Function

    Private Sub EnregistrerDecisions(decisions As List(Of Object))
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@UserId", UserId))
        p.Add(New SqlParameter("@Decisions", Newtonsoft.Json.JsonConvert.SerializeObject(decisions)))
        ExecuteSQLds("s0757SaveCorrespondances", p)
    End Sub

    Private Function ADecider() As Integer
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim r = PremiereLigne(ExecuteSQLds("s0758StatsCorrespondance", p))
        Return If(r Is Nothing OrElse IsDBNull(r("ADecider")), 0, Convert.ToInt32(r("ADecider")))
    End Function

    ''' <summary>Plus tard : le compte est mis de côté pour la session, rien n'est enregistré.</summary>
    Protected Sub btnPlusTard_Click(sender As Object, e As EventArgs) Handles btnPlusTard.Click
        If hfCle.Value <> "" AndAlso Not Sautes.Contains(hfCle.Value) Then Sautes.Add(hfCle.Value)
        Charger()
    End Sub

    Protected Sub btnReprendre_Click(sender As Object, e As EventArgs) Handles btnReprendre.Click
        Sautes.Clear()
        Charger()
    End Sub

    ''' <summary>
    ''' Demander à mon cabinet certifié : la fiche du compte part par courriel aux
    ''' utilisateurs comptables de la compagnie, au nom de la compagnie ; le compte
    ''' reste à décider et passe à plus tard.
    ''' </summary>
    Protected Sub btnCabinet_Click(sender As Object, e As EventArgs) Handles btnCabinet.Click
        Dim cle As String = hfCle.Value
        Try
            Dim r As DataRow = LigneParCle(cle)
            If r Is Nothing Then
                Alerte("Attention", "Ce compte n'est plus à décider.")
                Charger()
                Return
            End If
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0897GetComptablesCompagnie", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                Alerte("Attention", "Aucun utilisateur comptable n'est rattaché à cette compagnie : ajoutez votre cabinet dans Administration › Utilisateurs (case « Comptable »), puis réessayez.")
                Return
            End If
            Dim sujet As String = "Question sur l'association du compte « " & Texte(r("NomSource")) & " » — " & CompanyName
            Dim corps As String = CourrielCabinet(r)
            Dim envoyes As New List(Of String)()
            For Each u As DataRow In ds.Tables(0).Rows
                Dim courriel As String = Texte(u("Email"))
                If courriel = "" Then Continue For
                DeposerCourriel(courriel, sujet, corps)
                envoyes.Add(courriel)
            Next
            If Not Sautes.Contains(cle) Then Sautes.Add(cle)
            Alerte("Fait", "Question envoyée à " & String.Join(", ", envoyes) & ". Le compte reste à décider : il reviendra quand vous reprendrez les comptes reportés.")
            Charger()
        Catch ex As Exception
            Alerte("Erreur", "Envoi au cabinet : " & ex.Message)
        End Try
    End Sub

    Private Function CourrielCabinet(r As DataRow) As String
        Dim sb As New StringBuilder()
        sb.Append("<p>Bonjour,</p><p>Dans la reprise du plan comptable de <b>").Append(HttpUtility.HtmlEncode(CompanyName)).Append("</b>, ce compte de ")
        sb.Append(HttpUtility.HtmlEncode(NomLogiciel())).Append(" attend votre avis :</p><ul>")
        sb.Append("<li>Compte : ").Append(HttpUtility.HtmlEncode(If(Texte(r("CompteSource")) <> "", Texte(r("CompteSource")) & " · ", "") & Texte(r("NomSource")))).Append("</li>")
        sb.Append("<li>Nature : ").Append(HttpUtility.HtmlEncode(NatureLibelle(Texte(r("TypeNormalise")), True))).Append("</li>")
        If Not IsDBNull(r("Solde")) Then sb.Append("<li>Solde au chargement : ").Append(HttpUtility.HtmlEncode(Argent(Convert.ToDecimal(r("Solde"))))).Append("</li>")
        If Texte(r("IACompte")) <> "" Then sb.Append("<li>Proposition de l'assistant : ").Append(HttpUtility.HtmlEncode(Texte(r("IACompte")) & " " & Texte(r("IANom")))).Append("</li>")
        If Texte(r("ProposeCompte")) <> "" Then sb.Append("<li>Compte proposé : ").Append(HttpUtility.HtmlEncode(Texte(r("ProposeCompte")) & " " & Texte(r("ProposeNom")))).Append("</li>")
        sb.Append("</ul><p>À quel compte de 60secondes le lier, ou faut-il le créer ? La décision se prend dans 60Sec-AI, Importation › Correspondance des comptes.</p>")
        sb.Append("<p>— envoyé par 60Sec-AI au nom de ").Append(HttpUtility.HtmlEncode(CompanyName)).Append("</p>")
        Return sb.ToString()
    End Function

    ''' <summary>Dépose le courriel dans la file du service (T400Mails) ; le From reste celui du service, l'adresse de la compagnie va en Reply-To.</summary>
    Private Sub DeposerCourriel(destinataire As String, sujet As String, corpsHtml As String)
        Dim replyTo As String = CompanyMail.GetVerifiedReplyTo(ConnectionString, CType(Company, Guid))
        Using cn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionStringMail"))
            Using cmd As New SqlCommand("s0610InsertOutboundMail", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@To", destinataire)
                cmd.Parameters.AddWithValue("@Subject", sujet)
                cmd.Parameters.AddWithValue("@HTMLBody", corpsHtml)
                cmd.Parameters.AddWithValue("@ReplyTo", If(String.IsNullOrEmpty(replyTo), CType(DBNull.Value, Object), replyTo))
                cn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

#End Region

#Region "Outils"

    Private Shared Function Texte(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Return Convert.ToString(v).Trim()
    End Function

    Private Shared Function Argent(v As Decimal) As String
        Return String.Format(FrCa, "{0:C2}", v)
    End Function

    Private Shared Function Trouver(plan As List(Of Cible), compte As String) As Cible
        If compte = "" Then Return Nothing
        Dim c = plan.FirstOrDefault(Function(x) x.Compte = compte)
        If c Is Nothing Then Return Nothing
        Return New Cible With {.Id = c.Id, .Compte = c.Compte, .Nom = c.Nom, .TypeBilan = c.TypeBilan}
    End Function

    ''' <summary>TypeNormalise de la préparation → TypeBilan du plan de 60secondes.</summary>
    Private Shared Function NatureLettre(typeNormalise As String) As String
        Select Case typeNormalise.ToUpperInvariant()
            Case "ACTIF" : Return "A"
            Case "PASSIF" : Return "P"
            Case "CAPITAUX" : Return "CP"
            Case "PRODUIT" : Return "R"
            Case "CHARGE" : Return "C"
            Case Else : Return ""
        End Select
    End Function

    Private Shared Function NatureDeLettre(lettre As String) As String
        Select Case lettre
            Case "A" : Return "ACTIF"
            Case "P" : Return "PASSIF"
            Case "CP" : Return "CAPITAUX"
            Case "R" : Return "PRODUIT"
            Case "C" : Return "CHARGE"
            Case Else : Return ""
        End Select
    End Function

    ''' <summary>« de dépenses » (après « un compte ») ou « Dépenses » (seul).</summary>
    Private Shared Function NatureLibelle(typeNormalise As String, seul As Boolean) As String
        Dim n As String
        Select Case typeNormalise.ToUpperInvariant()
            Case "ACTIF" : n = If(seul, "Actif", "d'actif")
            Case "PASSIF" : n = If(seul, "Passif", "de passif")
            Case "CAPITAUX" : n = If(seul, "Capitaux propres", "de capitaux propres")
            Case "PRODUIT" : n = If(seul, "Revenus", "de revenus")
            Case "CHARGE" : n = If(seul, "Dépenses", "de dépenses")
            Case Else : n = If(seul, "Nature inconnue", "de nature inconnue")
        End Select
        Return n
    End Function

    ''' <summary>Ressemblance de deux noms de compte, de 0 à 1 : mots en commun, sans accents ni ponctuation.</summary>
    Private Shared Function Similarite(a As String, b As String) As Double
        Dim ma = Mots(a)
        Dim mb = Mots(b)
        If ma.Count = 0 OrElse mb.Count = 0 Then Return 0
        Dim communs As Integer = ma.Intersect(mb).Count()
        Dim jaccard As Double = communs / CDbl(ma.Union(mb).Count())
        Dim inclusion As Double = communs / CDbl(Math.Min(ma.Count, mb.Count))
        Return Math.Max(jaccard, inclusion * 0.9)
    End Function

    Private Shared ReadOnly Vides As HashSet(Of String) = New HashSet(Of String)({"de", "du", "des", "la", "le", "les", "et", "a", "au", "aux", "en", "d", "l", "the", "of", "and", "for", "pour", "sur", "un", "une"})

    Private Shared Function Mots(s As String) As HashSet(Of String)
        Dim t As String = If(s, "").Normalize(NormalizationForm.FormD)
        Dim sb As New StringBuilder()
        For Each ch In t
            If CharUnicodeInfo.GetUnicodeCategory(ch) = UnicodeCategory.NonSpacingMark Then Continue For
            sb.Append(If(Char.IsLetterOrDigit(ch), Char.ToLowerInvariant(ch), " "c))
        Next
        Dim h As New HashSet(Of String)()
        For Each m In sb.ToString().Split(New Char() {" "c}, StringSplitOptions.RemoveEmptyEntries)
            If m.Length >= 2 AndAlso Not Vides.Contains(m) Then h.Add(If(m.EndsWith("s") AndAlso m.Length > 3, m.Substring(0, m.Length - 1), m))
        Next
        Return h
    End Function

    Private Sub Alerte(titre As String, message As String)
        Dim texte = Regex.Replace(If(message, ""), "<br\s*/?>", vbLf, RegexOptions.IgnoreCase)
        texte = Regex.Replace(texte, "<[^>]+>", "")
        ShowMessageBox(HttpUtility.HtmlDecode(texte).Trim(), titre)
    End Sub

#End Region

End Class
