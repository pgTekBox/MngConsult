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
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
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
        If Not IsPostBack Then Charger()
    End Sub

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
        pnlFin.Visible = True
        btnReprendre.Visible = (reportes > 0)
        If message IsNot Nothing Then
            litFin.Text = "<h2>Rien à associer</h2><p>" & HttpUtility.HtmlEncode(message) & "</p>"
        ElseIf total = 0 Then
            litFin.Text = "<h2>Tout est décidé</h2><p>Chaque compte de l'ancien logiciel est lié, à créer ou ignoré. " &
                          "Faites relire la correspondance dans la grille, puis créez au plan les comptes qui manquent à l'étape 3.</p>"
        Else
            litFin.Text = "<h2>" & reportes.ToString() & " compte(s) reporté(s) à plus tard</h2><p>Il ne reste que les comptes que vous avez " &
                          "mis de côté. Reprenez-les ici, ou décidez-les dans la grille de l'étape 2.</p>"
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
        For Each r As DataRow In ds.Tables(0).Rows
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
                      If(numSrc = "", " ; le numéro sera attribué à l'étape 3, dans la classe choisie", " ; la classe se choisit à l'étape 3")}

        ' ── Ce que l'assistant dit ──────────────────────────────────────────
        Dim dit As String
        If cibles.Count = 0 Then
            dit = "Je n'ai trouvé aucun compte " & NatureLibelle(natureSrc, False) & " qui ressemble à « " & nomSrc & " » dans 60secondes. " &
                  "Créez-le, ou choisissez vous-même un compte dans la grille."
        ElseIf exact Then
            dit = "J'ai trouvé un compte " & NatureLibelle(natureSrc, False) & " dans " & logiciel & " qui existe déjà dans 60secondes sous « " &
                  cibles(0).Compte & " " & cibles(0).Nom & " ». Je vous propose de les lier, mais c'est vous qui décidez."
        Else
            dit = "J'ai trouvé un compte " & NatureLibelle(natureSrc, False) & " dans " & logiciel & " qui n'a pas d'équivalent exact dans 60secondes. " &
                  "Je vous propose le plus proche, mais c'est vous qui décidez."
        End If

        ' ── Le rendu ────────────────────────────────────────────────────────
        Dim sb As New StringBuilder()
        sb.Append("<div class='asc-assist'><div class='asc-avatar'>🙂<b>60</b></div><div>")
        sb.Append("<div class='qui'>Le 60, votre assistant <span class='asc-badge'>Action requise</span></div>")
        sb.Append("<div class='dit'>").Append(HttpUtility.HtmlEncode(dit)).Append("</div></div></div>")
        sb.Append("<div class='asc-corps'><h2>Associer un compte du plan comptable</h2><div class='asc-deux'>")
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
        If usage(0) > 0 OrElse usage(1) > 0 Then
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
        sb.Append("</div></div></div>")
        sb.Append("<div class='asc-enjeu' id='ascEnjeu' hidden><span class='pic'>⚠️</span><div id='ascEnjeuTexte'></div></div>")
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    Private Shared Sub Option_(sb As StringBuilder, valeur As String, c As Cible, coche As Boolean)
        sb.Append("<label class='asc-opt").Append(If(coche, " active", "")).Append("' data-enjeu='").Append(HttpUtility.HtmlAttributeEncode(c.Enjeu)).Append("'>")
        sb.Append("<div class='ligne'><input type='radio' name='cible' value='").Append(HttpUtility.HtmlAttributeEncode(valeur)).Append("'")
        If coche Then sb.Append(" checked='checked'")
        sb.Append(" onclick='ascChoisir(this)' />")
        If valeur <> "CREER" Then sb.Append("<span class='num'>").Append(HttpUtility.HtmlEncode(c.Compte)).Append("</span>")
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
            Dim decision = New With {
                .CleSource = cle,
                .TypeCle = Texte(r("TypeCle")),
                .CompteSource = Texte(r("CompteSource")),
                .NomSource = nomSrc,
                .Action = If(creer, "CREER", "LIER"),
                .CompteCible = If(creer, Texte(r("CompteSource")), choix),
                .NomCible = nomSrc,
                .TypeCible = Texte(r("TypeSource")),
                .Note = "Associé un par un"
            }
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@UserId", UserId))
            p.Add(New SqlParameter("@Decisions", Newtonsoft.Json.JsonConvert.SerializeObject(New Object() {decision})))
            Dim stats = PremiereLigne(ExecuteSQLds("s0757SaveCorrespondances", p))
            Dim reste As String = If(stats Is Nothing, "", " Il reste " & Convert.ToString(stats("ADecider")) & " compte(s) à décider.")
            Alerte("Fait", If(creer, "« " & nomSrc & " » sera créé au plan à l'étape 3.", "« " & nomSrc & " » est lié au compte " & choix & " de 60secondes.") & reste)
            ClientScript.RegisterStartupScript(Me.GetType(), "fenModifie", "try { if (window.parent && window.parent !== window) window.parent.fenModifie = true; } catch (e) { }", True)
            Charger()
        Catch ex As SqlException
            Alerte("Enregistrement impossible", ex.Message)
        Catch ex As Exception
            Alerte("Erreur", "Enregistrement : " & ex.Message)
        End Try
    End Sub

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
