Imports System.Collections.Generic
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text
Imports System.Web

''' <summary>
''' Récapitulatif d'un abonnement (forfait choisi) affiché pendant l'inscription :
''' wbfRegister (forfait choisi sur la page d'accueil), wbfPayment (avant Stripe)
''' et wbfPaymentSuccess (après le paiement). Une seule mise en forme pour les trois
''' pages (css/abo-recap.css), trilingue fr/en/es.
'''
''' Contenu : nom et accroche du forfait, prix avant taxes, TPS et TVQ estimées,
''' total, facturation (mensuelle ou annuelle, renouvelée automatiquement), essai
''' gratuit et date du premier prélèvement, tranche d'employés, limites (si le
''' forfait en a) et fonctions incluses. Tout vient de T021Plan (s0631GetPlanByCode),
''' dont le prix est synchronisé avec Stripe.
''' </summary>
Public NotInheritable Class clsAbonnementResume

    Private Sub New()
    End Sub

    ''' <summary>Options d'affichage du récapitulatif.</summary>
    Public Class Options
        ''' <summary>Afficher le titre « Votre abonnement » et le nom du forfait.</summary>
        Public Entete As Boolean = True
        ''' <summary>Afficher le bloc prix / taxes / total.</summary>
        Public Prix As Boolean = True
        ''' <summary>Afficher la liste des fonctions incluses.</summary>
        Public Fonctions As Boolean = True
        ''' <summary>Date réelle du premier prélèvement (lue dans Stripe), sinon estimée d'après l'essai.</summary>
        Public PremierPrelevement As Date = Date.MinValue
    End Class

    Public Const TauxTps As Decimal = 0.05D
    Public Const TauxTvq As Decimal = 0.09975D

    ''' <summary>
    ''' Lit le forfait par son code (cycle mensuel par défaut) dans la langue demandée ;
    ''' accepte les anciens codes solo/comsolo/com119 (renommés TA / CIE 0 / CIE 1-50
    ''' le 2026-11-25). Nothing si introuvable.
    ''' </summary>
    Public Shared Function LirePlan(page As clsData, code As String, lang As String,
                                    Optional cycle As String = "monthly") As DataRow
        If String.IsNullOrWhiteSpace(code) Then Return Nothing
        Dim codes As New List(Of String) From {code.Trim()}
        Select Case code.Trim().ToLowerInvariant()
            Case "solo" : codes.Add("TA")
            Case "comsolo" : codes.Add("CIE 0")
            Case "com119" : codes.Add("CIE 1-50")
        End Select
        For Each c As String In codes
            Dim p As New Collection
            p.Add(New SqlParameter("@Code", c))
            p.Add(New SqlParameter("@BillingCycle", cycle))
            p.Add(New SqlParameter("@Lang", lang))
            Dim ds As DataSet = page.ExecuteSQLds("s0631GetPlanByCode", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return ds.Tables(0).Rows(0)
            End If
        Next
        Return Nothing
    End Function

    ''' <summary>Montant au format de la langue (en : « $69.99 » ; fr/es : « 69,99 $ »).</summary>
    Public Shared Function Argent(montant As Decimal, lang As String) As String
        If lang = "en" Then Return "$" & montant.ToString("N2", New CultureInfo("en-CA"))
        Return montant.ToString("N2", New CultureInfo(If(lang = "es", "es-ES", "fr-CA"))) & " $"
    End Function

    ''' <summary>Jours d'essai du forfait (0 si aucun).</summary>
    Public Shared Function JoursEssai(row As DataRow) As Integer
        If row Is Nothing OrElse Not row.Table.Columns.Contains("TrialDays") OrElse IsDBNull(row("TrialDays")) Then Return 0
        Return Math.Max(0, CInt(row("TrialDays")))
    End Function

    ''' <summary>Vrai si le forfait est facturé à l'année.</summary>
    Public Shared Function EstAnnuel(row As DataRow) As Boolean
        Dim c As String = Txt(row, "BillingCycle").ToLowerInvariant()
        Return c = "annual" OrElse c = "yearly"
    End Function

    ''' <summary>« 69,99 $ / mois » (ou / an) dans la langue demandée.</summary>
    Public Shared Function PrixParPeriode(row As DataRow, lang As String) As String
        If row Is Nothing OrElse IsDBNull(row("Amount")) Then Return ""
        Return Argent(CDec(row("Amount")), lang) & " " & Periode(EstAnnuel(row), lang)
    End Function

    ''' <summary>Date au format de la langue (« 10 décembre 2026 », « December 10, 2026 »).</summary>
    Public Shared Function DateLongue(d As Date, lang As String) As String
        Return d.ToString(If(lang = "en", "MMMM d, yyyy", "d MMMM yyyy"), Culture(lang))
    End Function

    ''' <summary>
    ''' Le contenu du récapitulatif, calculé une fois pour les deux présentations
    ''' (page : Html ; courriel : HtmlCourriel). Chaque ligne = { libellé, valeur }.
    ''' </summary>
    Private Class Contenu
        Public Nom As String
        Public Accroche As String
        Public Prix As New List(Of String())
        Public TotalLibelle As String
        Public TotalValeur As String
        Public Note As String
        Public Conditions As New List(Of String())
        Public Fonctions As New List(Of String)
    End Class

    Private Shared Function Preparer(row As DataRow, lang As String, opt As Options) As Contenu
        Dim c As New Contenu()
        Dim annuel As Boolean = EstAnnuel(row)
        Dim montant As Decimal = If(IsDBNull(row("Amount")), 0D, CDec(row("Amount")))
        Dim essai As Integer = JoursEssai(row)
        c.Nom = Txt(row, "Name")
        c.Accroche = Txt(row, "Tagline")

        ' Prix, taxes, total
        Dim tps As Decimal = Math.Round(montant * TauxTps, 2)
        Dim tvq As Decimal = Math.Round(montant * TauxTvq, 2)
        c.Prix.Add({T(lang, "Prix du forfait (avant taxes)", "Plan price (before tax)", "Precio del plan (antes de impuestos)"), Argent(montant, lang) & " " & Periode(annuel, lang)})
        c.Prix.Add({T(lang, "TPS (5 %)", "GST (5%)", "GST (5 %)"), Argent(tps, lang)})
        c.Prix.Add({T(lang, "TVQ (9,975 %)", "QST (9.975%)", "QST (9,975 %)"), Argent(tvq, lang)})
        c.TotalLibelle = If(annuel, T(lang, "Total annuel estimé", "Estimated annual total", "Total anual estimado"), T(lang, "Total mensuel estimé", "Estimated monthly total", "Total mensual estimado"))
        c.TotalValeur = Argent(montant + tps + tvq, lang)
        c.Note = T(lang,
            "Taxes estimées pour le Québec ; le montant exact est calculé par Stripe selon votre adresse de facturation.",
            "Estimated Quebec taxes; Stripe calculates the exact amount from your billing address.",
            "Impuestos estimados para Quebec; Stripe calcula el importe exacto según su dirección de facturación.")

        ' Conditions de l'abonnement
        c.Conditions.Add({T(lang, "Facturation", "Billing", "Facturación"),
              If(annuel, T(lang, "Annuelle, renouvelée automatiquement chaque année", "Yearly, renews automatically every year", "Anual, se renueva automáticamente cada año"),
                         T(lang, "Mensuelle, renouvelée automatiquement chaque mois", "Monthly, renews automatically every month", "Mensual, se renueva automáticamente cada mes"))})
        If essai > 0 Then
            c.Conditions.Add({T(lang, "Essai gratuit", "Free trial", "Prueba gratuita"),
                  String.Format(T(lang, "{0} jours, aucun prélèvement pendant l'essai", "{0} days, no charge during the trial", "{0} días, sin cargo durante la prueba"), essai)})
        End If
        Dim premier As String
        If opt.PremierPrelevement <> Date.MinValue Then
            premier = DateLongue(opt.PremierPrelevement, lang)
        ElseIf essai > 0 Then
            premier = String.Format(T(lang, "{0} (si vous payez aujourd'hui)", "{0} (if you pay today)", "{0} (si paga hoy)"), DateLongue(Date.Today.AddDays(essai), lang))
        Else
            premier = T(lang, "Au moment du paiement", "At checkout", "Al momento del pago")
        End If
        c.Conditions.Add({T(lang, "Premier prélèvement", "First charge", "Primer cargo"), premier})
        c.Conditions.Add({T(lang, "Paiement", "Payment", "Pago"), T(lang, "Carte de crédit, par Stripe (paiement sécurisé)", "Credit card, through Stripe (secure payment)", "Tarjeta de crédito, mediante Stripe (pago seguro)")})
        Dim employes As String = Txt(row, "EmployeeRange")
        If employes.Length > 0 Then c.Conditions.Add({T(lang, "Employés", "Employees", "Empleados"), employes})
        Limite(c, row, "MaxUsers", T(lang, "Utilisateurs", "Users", "Usuarios"), "")
        Limite(c, row, "MaxClients", T(lang, "Clients", "Clients", "Clientes"), "")
        Limite(c, row, "MaxDocuments", T(lang, "Documents", "Documents", "Documentos"), "")
        Limite(c, row, "MaxStorageMB", T(lang, "Stockage", "Storage", "Almacenamiento"), " Mo")

        ' Fonctions incluses
        For Each l As String In Txt(row, "Features").Split(New String() {vbCrLf, vbLf, vbCr}, StringSplitOptions.RemoveEmptyEntries)
            If l.Trim().Length > 0 Then c.Fonctions.Add(l.Trim())
        Next
        Return c
    End Function

    ''' <summary>
    ''' Le récapitulatif complet, en HTML (classe racine .abo-recap). Chaîne vide si row est Nothing.
    ''' </summary>
    Public Shared Function Html(row As DataRow, lang As String, Optional opt As Options = Nothing) As String
        If row Is Nothing Then Return ""
        If opt Is Nothing Then opt = New Options()
        Dim c As Contenu = Preparer(row, lang, opt)
        Dim sb As New StringBuilder()

        sb.Append("<div class=""abo-recap"">")

        ' --- En-tête : forfait choisi ---
        If opt.Entete Then
            sb.Append("<div class=""abo-head""><span class=""abo-lbl"">").Append(E(T(lang, "Votre abonnement", "Your subscription", "Su suscripción"))).Append("</span>")
            sb.Append("<div class=""abo-nom"">").Append(E(c.Nom)).Append("</div>")
            If c.Accroche.Length > 0 Then sb.Append("<div class=""abo-accroche"">").Append(E(c.Accroche)).Append("</div>")
            sb.Append("</div>")
        End If

        ' --- Prix, taxes, total ---
        If opt.Prix Then
            sb.Append("<table class=""abo-tab abo-prix"">")
            For Each l As String() In c.Prix
                Ligne(sb, l(0), l(1))
            Next
            sb.Append("<tr class=""abo-total""><td>").Append(E(c.TotalLibelle)).Append("</td><td>").Append(E(c.TotalValeur)).Append("</td></tr>")
            sb.Append("</table>")
            sb.Append("<div class=""abo-note"">").Append(E(c.Note)).Append("</div>")
        End If

        ' --- Conditions de l'abonnement ---
        sb.Append("<table class=""abo-tab abo-cond"">")
        For Each l As String() In c.Conditions
            Ligne(sb, l(0), l(1))
        Next
        sb.Append("</table>")

        ' --- Fonctions incluses ---
        If opt.Fonctions AndAlso c.Fonctions.Count > 0 Then
            sb.Append("<div class=""abo-inclus""><div class=""abo-lbl"">").Append(E(T(lang, "Inclus dans votre forfait", "Included in your plan", "Incluido en su plan"))).Append("</div><ul>")
            For Each f As String In c.Fonctions
                sb.Append("<li>").Append(E(f)).Append("</li>")
            Next
            sb.Append("</ul></div>")
        End If

        sb.Append("</div>")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Le même récapitulatif pour un courriel : tableaux et styles en ligne (les
    ''' logiciels de courriel ignorent les feuilles de style), largeur fluide, sans
    ''' image. Chaîne vide si row est Nothing. Utilisé par le courriel d'activation.
    ''' </summary>
    Public Shared Function HtmlCourriel(row As DataRow, lang As String, Optional opt As Options = Nothing) As String
        If row Is Nothing Then Return ""
        If opt Is Nothing Then opt = New Options()
        Dim c As Contenu = Preparer(row, lang, opt)
        Dim sb As New StringBuilder()
        Dim police As String = "font-family:Arial,Helvetica,sans-serif;"
        Dim ligneCourriel = Sub(libelle As String, valeur As String, fort As Boolean)
                                sb.Append("<tr><td style=""padding:6px 12px 6px 0;border-top:1px solid #E3E8F0;").Append(police).Append("font-size:13px;color:#5B6B82;vertical-align:top;"">").Append(E(libelle)).Append("</td>")
                                sb.Append("<td align=""right"" style=""padding:6px 0;border-top:1px solid #E3E8F0;").Append(police).Append(If(fort, "font-size:15px;font-weight:800;", "font-size:13px;font-weight:700;")).Append("color:#0E1F3D;vertical-align:top;"">").Append(E(valeur)).Append("</td></tr>")
                            End Sub

        sb.Append("<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""margin:20px 0;background:#F6F8FC;border:1px solid #E3E8F0;border-radius:14px;"">")
        sb.Append("<tr><td style=""padding:16px 20px;"">")

        If opt.Entete Then
            sb.Append("<div style=""").Append(police).Append("font-size:11px;font-weight:800;letter-spacing:.08em;text-transform:uppercase;color:#5B6B82;"">").Append(E(T(lang, "Votre abonnement", "Your subscription", "Su suscripción"))).Append("</div>")
            sb.Append("<div style=""").Append(police).Append("font-size:18px;font-weight:800;color:#0E1F3D;margin-top:4px;"">").Append(E(c.Nom)).Append("</div>")
            If c.Accroche.Length > 0 Then sb.Append("<div style=""").Append(police).Append("font-size:13px;color:#5B6B82;margin:2px 0 8px;"">").Append(E(c.Accroche)).Append("</div>")
        End If

        sb.Append("<table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" border=""0"" style=""margin-top:6px;"">")
        If opt.Prix Then
            For Each l As String() In c.Prix
                ligneCourriel(l(0), l(1), False)
            Next
            ligneCourriel(c.TotalLibelle, c.TotalValeur, True)
        End If
        For Each l As String() In c.Conditions
            ligneCourriel(l(0), l(1), False)
        Next
        sb.Append("</table>")
        If opt.Prix Then sb.Append("<div style=""").Append(police).Append("font-size:11px;color:#7A879C;margin-top:6px;"">").Append(E(c.Note)).Append("</div>")

        If opt.Fonctions AndAlso c.Fonctions.Count > 0 Then
            sb.Append("<div style=""").Append(police).Append("font-size:11px;font-weight:800;letter-spacing:.08em;text-transform:uppercase;color:#5B6B82;margin:14px 0 4px;"">").Append(E(T(lang, "Inclus dans votre forfait", "Included in your plan", "Incluido en su plan"))).Append("</div>")
            For Each f As String In c.Fonctions
                sb.Append("<div style=""").Append(police).Append("font-size:13px;color:#0E1F3D;padding:2px 0;""><span style=""color:#10B981;font-weight:800;"">&#10003;</span>&nbsp; ").Append(E(f)).Append("</div>")
            Next
        End If

        sb.Append("</td></tr></table>")
        Return sb.ToString()
    End Function

    ' ---------------------------------------------------------------------------

    Private Shared Sub Ligne(sb As StringBuilder, libelle As String, valeur As String)
        sb.Append("<tr><td>").Append(E(libelle)).Append("</td><td>").Append(E(valeur)).Append("</td></tr>")
    End Sub

    ''' <summary>Ligne d'une limite, seulement si le forfait en fixe une (NULL = rien d'affiché).</summary>
    Private Shared Sub Limite(c As Contenu, row As DataRow, col As String, libelle As String, suffixe As String)
        If Not row.Table.Columns.Contains(col) OrElse IsDBNull(row(col)) Then Return
        c.Conditions.Add({libelle, CInt(row(col)).ToString("N0", CultureInfo.InvariantCulture) & suffixe})
    End Sub

    Private Shared Function Periode(annuel As Boolean, lang As String) As String
        If annuel Then Return T(lang, "/ an", "/ year", "/ año")
        Return T(lang, "/ mois", "/ month", "/ mes")
    End Function

    Private Shared Function Culture(lang As String) As CultureInfo
        Select Case lang
            Case "en" : Return New CultureInfo("en-CA")
            Case "es" : Return New CultureInfo("es-ES")
            Case Else : Return New CultureInfo("fr-CA")
        End Select
    End Function

    Private Shared Function Txt(row As DataRow, col As String) As String
        If row Is Nothing OrElse Not row.Table.Columns.Contains(col) OrElse IsDBNull(row(col)) Then Return ""
        Return row(col).ToString().Trim()
    End Function

    Private Shared Function T(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Shared Function E(s As String) As String
        Return HttpUtility.HtmlEncode(s)
    End Function

End Class
