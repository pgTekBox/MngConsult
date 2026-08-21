Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web.UI

Partial Public Class LandingPage
    Inherits clsData

    ' Jeton remplacé, dans la section des forfaits, par les cartes générées
    ' dynamiquement depuis T021Plan.
    Private Const PLANS_TOKEN As String = "{{PLANS}}"

    ''' <summary>
    ''' Langue courante : ?lang=fr|en|es (défaut fr). Le contenu retombe sur fr
    ''' côté procédure si la langue demandée n'existe pas.
    ''' </summary>

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            BuildLangSwitcher()
            RenderPages()
        End If
    End Sub

    ''' <summary>
    ''' Sélecteur de langue de la nav (FR/EN/ES). Chaque lien recharge la page
    ''' en ?lang=xx ; la langue courante est surlignée.
    ''' </summary>
    Private Sub BuildLangSwitcher()
        Dim cur As String = CurrentLang
        Dim codes() As String = {"fr", "en", "es"}
        Dim labels() As String = {"FR", "EN", "ES"}
        Dim sb As New StringBuilder()
        sb.Append("<div class=""flex items-center gap-1 text-sm font-medium"">")
        sb.Append("<i data-lucide=""globe"" class=""w-4 h-4 text-slate-500 mr-1""></i>")
        For i As Integer = 0 To codes.Length - 1
            Dim cls As String = If(codes(i) = cur, "text-blue-700 font-bold", "text-slate-600 hover:text-slate-900")
            sb.Append("<a href=""?lang=" & codes(i) & """ class=""px-1.5 py-1 rounded transition-colors " & cls & """>" & labels(i) & "</a>")
        Next
        sb.Append("</div>")
        litLang.Text = sb.ToString()
    End Sub

    ''' <summary>
    ''' Construit tout le contenu du &lt;main&gt; depuis la BD : toutes les pages
    ''' actives (T022LandingPage) et leurs sections (T023/T024) dans la langue
    ''' courante. Chaque page est enveloppée dans son &lt;div data-page&gt; ;
    ''' la page par défaut est visible, les autres masquées (routage JS).
    ''' </summary>
    Private Sub RenderPages()
        Dim sb As New StringBuilder()

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@PageCode", DBNull.Value))   ' NULL = toutes les pages
            p.Add(New SqlParameter("@Lang", CurrentLang))
            Dim ds As DataSet = ExecuteSQLds("s0673GetLandingSections", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                Dim currentPage As String = Nothing
                For Each row As DataRowView In ds.Tables(0).DefaultView
                    Dim pageCode As String = GetStr(row, "PageCode")
                    If Not String.Equals(pageCode, currentPage, StringComparison.Ordinal) Then
                        If currentPage IsNot Nothing Then sb.Append("</div>")
                        currentPage = pageCode
                        Dim cssClass As String = If(GetBool(row, "IsDefault"), "page", "page hidden")
                        sb.Append("<div class=""" & cssClass & """ data-page=""" & pageCode & """>")
                    End If
                    sb.Append(RenderSectionHtml(row))
                Next
                If currentPage IsNot Nothing Then sb.Append("</div>")
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("LandingPage RenderPages error: " & ex.Message)
        End Try

        ' La page « Application mobile » n'est pas en BD : son contenu dépend de
        ' l'APK présent sur disque. Elle est donc toujours ajoutée ici, même si
        ' la lecture des sections a échoué.
        sb.Append(BuildMobilePageHtml())

        litPages.Text = sb.ToString()
    End Sub

    ''' <summary>
    ''' Rend le HTML d'une section : vient de HtmlContent ; si la section contient
    ''' le jeton {{PLANS}}, il est remplacé par les cartes de forfaits.
    ''' </summary>
    Private Function RenderSectionHtml(row As DataRowView) As String
        Dim html As String = GetStr(row, "HtmlContent")
        If html.Length = 0 Then Return ""
        If html.IndexOf(PLANS_TOKEN, StringComparison.Ordinal) >= 0 Then
            html = html.Replace(PLANS_TOKEN, BuildPlansHtml())
        End If
        Return html
    End Function

    ''' <summary>
    ''' Construit le HTML des cartes de forfaits actifs (T021Plan via s0630).
    ''' </summary>
    Private Function BuildPlansHtml() As String
        Dim sb As New StringBuilder()
        Try
            Dim pp As New Collection
            pp.Add(New SqlParameter("@Lang", CurrentLang))
            Dim ds As DataSet = ExecuteSQLds("s0630GetPlansForLanding", pp)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each row As DataRowView In ds.Tables(0).DefaultView
                    sb.Append(RenderPlanCard(row))
                Next
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("LandingPage BuildPlansHtml error: " & ex.Message)
        End Try
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Rend la cartouche complète d'un forfait (Tailwind). Le thème (slate / sky
    ''' recommandé / emerald) est déterminé à partir de IsRecommended et
    ''' PlanIconCssClass. Le bouton pointe vers wbfRegister.aspx?ab=&lt;Code&gt;.
    ''' </summary>
    Public Function RenderPlanCard(item As Object) As String
        Dim row As DataRowView = TryCast(item, DataRowView)
        If row Is Nothing Then Return ""

        Dim code As String = GetStr(row, "Code")
        Dim name As String = GetStr(row, "Name")
        Dim tagline As String = GetStr(row, "Tagline")
        Dim empRange As String = GetStr(row, "EmployeeRange")
        Dim descr As String = GetStr(row, "Description")
        Dim badge As String = GetStr(row, "BadgeText")
        Dim iconClass As String = GetStr(row, "PlanIconCssClass")
        Dim recommended As Boolean = GetBool(row, "IsRecommended")
        Dim price As String = FormatPrice(row("Amount"))

        ' Libellés fixes des cartes traduits selon la langue courante.
        Dim perMonth As String = Choose3(CurrentLang, "/ mois", "/ month", "/ mes")
        Dim ctaText As String = Choose3(CurrentLang, "Commencer gratuitement", "Start for free", "Comenzar gratis")

        Dim cardCls, iconWrap, iconName, nameCls, tagCls, pillCls As String
        Dim descCls, priceCls, permoCls, featCheck, featText, btnCls As String

        If recommended Then
            cardCls = "relative flex flex-col rounded-2xl border-2 bg-slate-950 border-sky-500/40 p-7 transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-slate-900/40"
            iconWrap = "bg-sky-500/20 text-sky-300"
            iconName = "user-check"
            nameCls = "text-white"
            tagCls = "text-sky-300"
            pillCls = "bg-sky-500/20 text-sky-300"
            descCls = "text-slate-300"
            priceCls = "text-white"
            permoCls = "text-slate-400"
            featCheck = "text-sky-400"
            featText = "text-slate-300"
            btnCls = "w-full text-center font-semibold py-3 px-5 rounded-xl text-sm transition-all duration-200 bg-sky-500 hover:bg-sky-400 text-white hover:shadow-lg hover:shadow-sky-500/30"
        ElseIf iconClass.IndexOf("emerald", StringComparison.OrdinalIgnoreCase) >= 0 Then
            cardCls = "relative flex flex-col rounded-2xl border-2 bg-slate-50 border-emerald-200 p-7 transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-slate-200/80"
            iconWrap = "bg-emerald-100 text-emerald-700"
            iconName = "users"
            nameCls = "text-slate-950"
            tagCls = "text-slate-500"
            pillCls = "bg-emerald-100 text-emerald-700"
            descCls = "text-slate-500"
            priceCls = "text-slate-950"
            permoCls = "text-slate-500"
            featCheck = "text-emerald-600"
            featText = "text-slate-600"
            btnCls = "w-full text-center font-semibold py-3 px-5 rounded-xl text-sm transition-all duration-200 bg-slate-950 hover:bg-slate-800 text-white"
        Else
            cardCls = "relative flex flex-col rounded-2xl border-2 bg-slate-50 border-slate-200 p-7 transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-slate-200/80"
            iconWrap = "bg-slate-200 text-slate-700"
            iconName = "user"
            nameCls = "text-slate-950"
            tagCls = "text-slate-500"
            pillCls = "bg-slate-100 text-slate-600"
            descCls = "text-slate-500"
            priceCls = "text-slate-950"
            permoCls = "text-slate-500"
            featCheck = "text-slate-600"
            featText = "text-slate-600"
            btnCls = "w-full text-center font-semibold py-3 px-5 rounded-xl text-sm transition-all duration-200 bg-slate-950 hover:bg-slate-800 text-white"
        End If

        Dim sb As New StringBuilder()
        sb.Append("<div class=""" & cardCls & """>")

        If badge.Length > 0 Then
            sb.Append("<div class=""absolute -top-3.5 left-1/2 -translate-x-1/2""><span class=""bg-sky-500 text-white text-xs font-bold px-4 py-1.5 rounded-full shadow-lg shadow-sky-500/30 whitespace-nowrap"">")
            sb.Append(Server.HtmlEncode(badge))
            sb.Append("</span></div>")
        End If

        sb.Append("<div class=""mb-6"">")
        sb.Append("<div class=""w-12 h-12 rounded-xl flex items-center justify-center mb-5 " & iconWrap & """><i data-lucide=""" & iconName & """ class=""w-6 h-6""></i></div>")
        sb.Append("<h3 class=""text-xl font-bold mb-1 " & nameCls & """>" & Server.HtmlEncode(name) & "</h3>")
        If tagline.Length > 0 Then
            sb.Append("<p class=""text-sm font-semibold mb-1 " & tagCls & """>" & Server.HtmlEncode(tagline) & "</p>")
        End If
        If empRange.Length > 0 Then
            sb.Append("<span class=""inline-block text-xs font-medium px-2.5 py-1 rounded-full mb-4 " & pillCls & """>" & Server.HtmlEncode(empRange) & "</span>")
        End If
        If descr.Length > 0 Then
            sb.Append("<p class=""text-sm leading-relaxed " & descCls & """>" & Server.HtmlEncode(descr) & "</p>")
        End If
        sb.Append("</div>")

        sb.Append("<div class=""mb-6""><div class=""flex items-baseline gap-1""><span class=""text-3xl font-bold " & priceCls & """>" & Server.HtmlEncode(price) & "</span><span class=""text-sm font-medium " & permoCls & """>" & perMonth & "</span></div></div>")

        sb.Append("<ul class=""space-y-3 mb-8 flex-1"">")
        sb.Append(BuildFeatures(row("Features"), featCheck, featText))
        sb.Append("</ul>")

        Dim url As String = "wbfRegister.aspx?ab=" & Server.UrlEncode(code) & "&lang=" & CurrentLang
        sb.Append("<a href=""" & url & """ class=""" & btnCls & """>" & ctaText & "</a>")

        sb.Append("</div>")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Convertit le texte multi-ligne de la colonne Features en HTML &lt;li&gt; avec
    ''' icône check (lucide). Une ligne = une fonctionnalité.
    ''' </summary>
    Private Function BuildFeatures(featuresValue As Object, checkCls As String, textCls As String) As String
        If featuresValue Is Nothing OrElse IsDBNull(featuresValue) Then Return ""
        Dim featuresText As String = featuresValue.ToString()
        If String.IsNullOrWhiteSpace(featuresText) Then Return ""

        Dim sb As New StringBuilder()
        Dim lines() As String = featuresText.Split(New String() {vbCrLf, vbLf, vbCr}, StringSplitOptions.RemoveEmptyEntries)
        For Each line As String In lines
            Dim cleanLine As String = line.Trim()
            If cleanLine.Length > 0 Then
                sb.Append("<li class=""flex items-start gap-3""><i data-lucide=""check"" class=""w-4 h-4 mt-0.5 flex-shrink-0 " & checkCls & """></i><span class=""text-sm " & textCls & """>" & Server.HtmlEncode(cleanLine) & "</span></li>")
            End If
        Next
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Formate un montant en devise québécoise (séparateur virgule, espace milliers).
    ''' Exemple : 69.99 -> "69,99 $"
    ''' </summary>
    Public Function FormatPrice(amount As Object) As String
        If amount Is Nothing OrElse IsDBNull(amount) Then Return ""
        Dim val As Decimal = CDec(amount)
        ' Anglais : symbole devant (« $69.99 ») ; français/espagnol : après (« 69,99 $ »).
        If CurrentLang = "en" Then
            Return "$" & val.ToString("N2", New Globalization.CultureInfo("en-CA"))
        End If
        Return val.ToString("N2", New Globalization.CultureInfo("fr-CA")) & " $"
    End Function

    ''' <summary>Retourne fr/en/es selon la langue passée.</summary>
    Private Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function


    ' ------------------------------------------------------------------
    ' Page « Application mobile » (data-page="mobile")
    '
    ' Contrairement aux autres pages du site vitrine, celle-ci n'est PAS
    ' stockée en BD (T022/T023/T024) : son contenu dépend de la présence
    ' réelle de l'APK sur le disque (version, taille, date, bouton actif ou
    ' état « bientôt disponible »). Elle est donc rendue par le code, puis
    ' ajoutée aux pages venant de la BD. Le routage JS (data-nav) et le
    ' lien profond ?page=mobile fonctionnent de la même façon.
    ' ------------------------------------------------------------------

    ''' <summary>Code de la page mobile, utilisé par data-page / data-nav / ?page=.</summary>
    Private Const MOBILE_PAGE_CODE As String = "mobile"

    ''' <summary>
    ''' Construit la page complète de téléchargement de l'application Android.
    ''' </summary>
    Private Function BuildMobilePageHtml() As String
        Dim lang As String = CurrentLang
        Dim available As Boolean = clsAndroidApp.IsAvailable()

        Dim sb As New StringBuilder()
        sb.Append("<div class=""page hidden"" data-page=""" & MOBILE_PAGE_CODE & """>")
        sb.Append(BuildMobileHeroHtml(lang, available))
        sb.Append(BuildMobileStepsHtml(lang))
        sb.Append(BuildMobileFeaturesHtml(lang))
        sb.Append(BuildMobileCtaHtml(lang, available))
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    ''' <summary>Section héro : accroche, bouton de téléchargement, maquette du téléphone.</summary>
    Private Function BuildMobileHeroHtml(lang As String, available As Boolean) As String
        Dim sb As New StringBuilder()

        sb.Append("<section class=""relative overflow-hidden bg-gradient-to-br from-slate-50 via-sky-50/60 to-white"">")
        sb.Append("<div class=""absolute inset-0"">")
        sb.Append("<div class=""absolute top-0 left-1/4 w-96 h-96 bg-sky-400/15 rounded-full blur-3xl""></div>")
        sb.Append("<div class=""absolute bottom-0 right-1/4 w-96 h-96 bg-blue-400/10 rounded-full blur-3xl""></div>")
        sb.Append("</div>")
        sb.Append("<div class=""relative max-w-7xl mx-auto px-6 lg:px-8 pt-32 pb-20 lg:pb-24"">")
        sb.Append("<div class=""grid grid-cols-1 lg:grid-cols-2 gap-16 items-center"">")

        ' --- Colonne texte ---
        sb.Append("<div>")
        sb.Append("<div class=""inline-flex items-center gap-2 bg-blue-50 border border-blue-200 text-blue-700 text-sm font-medium px-4 py-2 rounded-full mb-8"">")
        sb.Append("<i data-lucide=""smartphone"" class=""w-4 h-4""></i>")
        sb.Append(Choose3(lang, "Application Android", "Android app", "Aplicación Android"))
        sb.Append("</div>")

        sb.Append("<h1 class=""text-4xl md:text-5xl lg:text-6xl font-bold text-slate-950 tracking-tight leading-tight mb-6"">")
        sb.Append(Choose3(lang, "Toute votre gestion ", "Your whole business ", "Toda su gestión "))
        sb.Append("<span class=""text-blue-600"">")
        sb.Append(Choose3(lang, "dans votre poche", "in your pocket", "en su bolsillo"))
        sb.Append("</span></h1>")

        sb.Append("<p class=""text-lg text-slate-600 leading-relaxed mb-10 max-w-xl"">")
        sb.Append(Choose3(lang,
                          "Numérisez vos reçus, créez vos factures et suivez vos finances où que vous soyez. L'application Android 60sec-AI utilise le même compte que le site web : tout est synchronisé en temps réel.",
                          "Scan your receipts, create invoices and follow your finances anywhere. The 60sec-AI Android app uses the same account as the website: everything stays in sync, in real time.",
                          "Digitalice sus recibos, cree sus facturas y siga sus finanzas desde donde esté. La aplicación Android de 60sec-AI usa la misma cuenta que el sitio web: todo se sincroniza en tiempo real."))
        sb.Append("</p>")

        sb.Append(BuildMobileDownloadBlockHtml(lang, available))
        sb.Append("</div>")

        ' --- Colonne maquette ---
        sb.Append("<div class=""apk-stage"">")
        sb.Append(BuildPhoneMockupHtml(lang))
        sb.Append("</div>")

        sb.Append("</div></div></section>")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Bloc d'appel à l'action du héro : soit les boutons de téléchargement et
    ''' les métadonnées du fichier, soit l'état « bientôt disponible » quand
    ''' aucun APK n'a encore été déposé dans ~/android.
    ''' </summary>
    Private Function BuildMobileDownloadBlockHtml(lang As String, available As Boolean) As String
        Dim sb As New StringBuilder()

        If Not available Then
            sb.Append("<div class=""flex items-start gap-4 bg-amber-50 border border-amber-200 rounded-2xl p-6 max-w-xl"">")
            sb.Append("<i data-lucide=""clock"" class=""w-6 h-6 text-amber-600 flex-shrink-0 mt-0.5""></i>")
            sb.Append("<div>")
            sb.Append("<p class=""font-semibold text-amber-800 mb-1"">")
            sb.Append(Choose3(lang, "Bientôt disponible", "Coming soon", "Próximamente"))
            sb.Append("</p>")
            sb.Append("<p class=""text-sm text-amber-700 leading-relaxed"">")
            sb.Append(Choose3(lang,
                              "La version Android est en cours de préparation. Écrivez-nous et nous vous préviendrons dès qu'elle sera publiée.",
                              "The Android build is being prepared. Write to us and we will let you know as soon as it is published.",
                              "La versión Android está en preparación. Escríbanos y le avisaremos en cuanto se publique."))
            sb.Append("</p></div></div>")
            Return sb.ToString()
        End If

        Dim version As String = clsAndroidApp.GetVersion()
        Dim sizeTxt As String = clsAndroidApp.FormatSize(clsAndroidApp.GetSizeBytes(), lang)
        Dim dateTxt As String = clsAndroidApp.FormatDate(clsAndroidApp.GetPublishedOn(), lang)

        sb.Append("<div class=""flex flex-col sm:flex-row items-center gap-4 mb-8"">")
        sb.Append("<a href=""" & clsAndroidApp.DownloadUrl & """ class=""w-full sm:w-auto inline-flex items-center justify-center gap-3 bg-blue-700 hover:bg-blue-600 text-white font-semibold px-8 py-4 rounded-xl text-base transition-all duration-200 hover:shadow-2xl hover:shadow-blue-700/30 hover:-translate-y-0.5"">")
        sb.Append("<i data-lucide=""download"" class=""w-5 h-5""></i>")
        sb.Append(Choose3(lang, "Télécharger l'APK", "Download the APK", "Descargar el APK"))
        sb.Append("</a>")
        sb.Append("<a data-nav=""" & MOBILE_PAGE_CODE & """ href=""#installation"" class=""w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-white hover:bg-slate-50 text-slate-800 font-semibold px-8 py-4 rounded-xl text-base border border-slate-200 transition-all duration-200 hover:shadow-lg"">")
        sb.Append("<i data-lucide=""list-checks"" class=""w-5 h-5""></i>")
        sb.Append(Choose3(lang, "Guide d'installation", "Installation guide", "Guía de instalación"))
        sb.Append("</a>")
        sb.Append("</div>")

        sb.Append("<div class=""flex flex-wrap items-center gap-5 text-sm text-slate-500"">")
        If version.Length > 0 Then
            sb.Append(MetaChip("package", "text-slate-400", Choose3(lang, "Version ", "Version ", "Versión ") & Server.HtmlEncode(version)))
        End If
        If sizeTxt.Length > 0 Then
            sb.Append(MetaChip("hard-drive", "text-slate-400", sizeTxt))
        End If
        If dateTxt.Length > 0 Then
            sb.Append(MetaChip("calendar", "text-slate-400", dateTxt))
        End If
        sb.Append(MetaChip("shield-check", "text-emerald-500",
                           Choose3(lang, "Android 6.0 ou plus récent", "Android 6.0 or later", "Android 6.0 o posterior")))
        sb.Append("</div>")

        sb.Append(BuildQrCardHtml(lang))

        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Carte « Scannez pour installer » : code QR généré côté serveur (SVG
    ''' inline, aucun appel réseau ni service externe) pointant sur l'URL
    ''' absolue de téléchargement. Retourne "" si l'encodage échoue, auquel
    ''' cas la page se contente des boutons.
    ''' </summary>
    Private Function BuildQrCardHtml(lang As String) As String
        Dim alt As String = Choose3(lang,
                                    "Code QR vers le téléchargement de l'application Android",
                                    "QR code linking to the Android app download",
                                    "Código QR que enlaza con la descarga de la aplicación Android")
        Dim svg As String = clsQrCode.BuildSvg(BuildAbsoluteDownloadUrl(), 132, "#020617", alt)
        If svg.Length = 0 Then Return ""

        Dim sb As New StringBuilder()
        ' Masquée sous 640 px : sur un téléphone le visiteur touche simplement
        ' le bouton, et la carte y serait à l'étroit (voir .apk-qr-card).
        sb.Append("<div class=""apk-qr-card mt-8 items-center gap-5 bg-white border border-slate-200 rounded-2xl p-5 shadow-sm max-w-xl"">")
        sb.Append("<div class=""apk-qr flex-shrink-0"">").Append(svg).Append("</div>")
        sb.Append("<div class=""min-w-0"">")
        sb.Append("<p class=""font-semibold text-slate-900 mb-1"">")
        sb.Append(Choose3(lang, "Scannez pour installer", "Scan to install", "Escanee para instalar"))
        sb.Append("</p>")
        sb.Append("<p class=""text-sm text-slate-600 leading-relaxed mb-2"">")
        sb.Append(Choose3(lang,
                          "Pointez l'appareil photo de votre téléphone vers ce code : le téléchargement démarre directement sur l'appareil.",
                          "Point your phone camera at this code: the download starts straight on the device.",
                          "Apunte la cámara de su teléfono a este código: la descarga empieza directamente en el dispositivo."))
        sb.Append("</p>")
        sb.Append("<span class=""font-mono text-xs text-slate-500"">")
        sb.Append(Server.HtmlEncode(BuildDisplayDownloadUrl()))
        sb.Append("</span>")
        sb.Append("</div></div>")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' URL absolue, schéma compris, encodée dans le code QR — un appareil
    ''' photo de téléphone n'ouvre pas une adresse sans schéma.
    ''' </summary>
    Private Function BuildAbsoluteDownloadUrl() As String
        Try
            Return New Uri(Request.Url, ResolveUrl("~/" & clsAndroidApp.DownloadUrl)).AbsoluteUri
        Catch ex As Exception
            Return clsAndroidApp.DownloadUrl
        End Try
    End Function

    ''' <summary>Petite pastille « icône + texte » de la ligne de métadonnées.</summary>
    Private Function MetaChip(icon As String, iconCls As String, text As String) As String
        Return "<span class=""inline-flex items-center gap-2""><i data-lucide=""" & icon &
               """ class=""w-4 h-4 " & iconCls & """></i>" & text & "</span>"
    End Function

    ''' <summary>
    ''' Maquette CSS du téléphone (aucune image) : entête dégradé, solde, trois
    ''' lignes d'activité et barre d'onglets. Purement décoratif.
    ''' </summary>
    Private Function BuildPhoneMockupHtml(lang As String) As String
        Dim balance As String = Choose3(lang, "12 480,55 $", "$12,480.55", "12 480,55 $")
        Dim delta As String = Choose3(lang, "+8,2 % ce mois", "+8.2% this month", "+8,2 % este mes")

        Dim sb As New StringBuilder()
        sb.Append("<div class=""apk-phone"" aria-hidden=""true""><div class=""apk-screen"">")

        sb.Append("<div class=""apk-top"">")
        sb.Append("<div class=""apk-brand""><span>60sec-AI</span><span class=""apk-avatar"">PG</span></div>")
        sb.Append("<div class=""apk-label"">" & Choose3(lang, "Solde net", "Net balance", "Saldo neto") & "</div>")
        sb.Append("<div class=""apk-amount"">" & balance & "</div>")
        sb.Append("<div class=""apk-delta""><i data-lucide=""trending-up""></i>" & delta & "</div>")
        sb.Append("</div>")

        sb.Append("<div class=""apk-body"">")
        sb.Append(PhoneCard("scan-line", "apk-ico-blue",
                            Choose3(lang, "Reçu numérisé", "Receipt scanned", "Recibo escaneado"),
                            "Métro — " & Choose3(lang, "aujourd'hui", "today", "hoy"),
                            Choose3(lang, "84,37 $", "$84.37", "84,37 $"),
                            Choose3(lang, "Comptabilisé", "Booked", "Contabilizado")))
        sb.Append(PhoneCard("file-text", "apk-ico-emerald",
                            Choose3(lang, "Facture #1042", "Invoice #1042", "Factura n° 1042"),
                            "Clinique Belvédère",
                            Choose3(lang, "1 250,00 $", "$1,250.00", "1 250,00 $"),
                            Choose3(lang, "Payée", "Paid", "Pagada")))
        sb.Append(PhoneCard("banknote", "apk-ico-blue",
                            Choose3(lang, "Virement fournisseur", "Supplier payout", "Pago a proveedor"),
                            Choose3(lang, "Programmé demain", "Scheduled tomorrow", "Programado mañana"),
                            Choose3(lang, "612,90 $", "$612.90", "612,90 $"),
                            Choose3(lang, "En attente", "Pending", "Pendiente")))
        sb.Append("</div>")

        sb.Append("<div class=""apk-tabs"">")
        sb.Append("<span class=""apk-tab is-on""><i data-lucide=""layout-dashboard""></i></span>")
        sb.Append("<span class=""apk-tab""><i data-lucide=""scan-line""></i></span>")
        sb.Append("<span class=""apk-tab""><i data-lucide=""file-text""></i></span>")
        sb.Append("<span class=""apk-tab""><i data-lucide=""settings""></i></span>")
        sb.Append("</div>")

        sb.Append("</div></div>")
        Return sb.ToString()
    End Function

    ''' <summary>Une ligne d'activité de la maquette du téléphone.</summary>
    Private Function PhoneCard(icon As String, iconCls As String, title As String,
                               subtitle As String, amount As String, pill As String) As String
        Dim sb As New StringBuilder()
        sb.Append("<div class=""apk-card"">")
        sb.Append("<span class=""apk-ico " & iconCls & """><i data-lucide=""" & icon & """></i></span>")
        sb.Append("<span class=""apk-card-txt""><span class=""apk-card-t"">" & Server.HtmlEncode(title) & "</span>")
        sb.Append("<span class=""apk-card-s"">" & Server.HtmlEncode(subtitle) & "</span></span>")
        sb.Append("<span class=""apk-card-v""><span class=""apk-card-a"">" & Server.HtmlEncode(amount) & "</span>")
        sb.Append("<span class=""apk-pill"">" & Server.HtmlEncode(pill) & "</span></span>")
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    ''' <summary>Section « installation en trois étapes » + note sur l'avertissement Android.</summary>
    Private Function BuildMobileStepsHtml(lang As String) As String
        Dim sb As New StringBuilder()

        sb.Append("<section id=""installation"" class=""py-20 lg:py-24 bg-white"">")
        sb.Append("<div class=""max-w-7xl mx-auto px-6 lg:px-8"">")

        sb.Append("<div class=""max-w-3xl mb-16"">")
        sb.Append("<h2 class=""text-3xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-4"">")
        sb.Append(Choose3(lang, "Installation en trois étapes", "Install in three steps", "Instalación en tres pasos"))
        sb.Append("</h2>")
        sb.Append("<p class=""text-lg text-slate-600 leading-relaxed"">")
        sb.Append(Choose3(lang,
                          "Android demande une confirmation avant d'installer une application qui ne provient pas du Play Store. C'est normal, et cela prend moins d'une minute.",
                          "Android asks for a confirmation before installing an app that does not come from the Play Store. That is expected, and it takes less than a minute.",
                          "Android pide una confirmación antes de instalar una aplicación que no procede de Play Store. Es normal y toma menos de un minuto."))
        sb.Append("</p></div>")

        ' Le nom annoncé est celui du fichier réellement déposé dans ~/android,
        ' pour que le visiteur retrouve exactement ce nom dans ses téléchargements.
        Dim apkName As String = clsAndroidApp.GetFileName()
        If apkName.Length = 0 Then apkName = "*.apk"

        sb.Append("<div class=""grid grid-cols-1 md:grid-cols-3 gap-8"">")
        sb.Append(StepCard("1",
                           Choose3(lang, "Télécharger le fichier", "Download the file", "Descargar el archivo"),
                           Choose3(lang,
                                   "Depuis votre téléphone Android, touchez le bouton de téléchargement. Le fichier " & apkName & " se dépose dans vos téléchargements.",
                                   "From your Android phone, tap the download button. The " & apkName & " file lands in your Downloads folder.",
                                   "Desde su teléfono Android, toque el botón de descarga. El archivo " & apkName & " se guarda en Descargas.")))
        sb.Append(StepCard("2",
                           Choose3(lang, "Autoriser l'installation", "Allow the installation", "Permitir la instalación"),
                           Choose3(lang,
                                   "Ouvrez le fichier téléchargé. Android affiche « Installer des applications inconnues » : accordez l'autorisation à votre navigateur, puis revenez en arrière.",
                                   "Open the downloaded file. Android shows « Install unknown apps »: grant the permission to your browser, then go back.",
                                   "Abra el archivo descargado. Android mostrará « Instalar aplicaciones desconocidas »: conceda el permiso a su navegador y vuelva atrás.")))
        sb.Append(StepCard("3",
                           Choose3(lang, "Installer et se connecter", "Install and sign in", "Instalar e iniciar sesión"),
                           Choose3(lang,
                                   "Touchez « Installer », ouvrez l'application et connectez-vous avec les mêmes identifiants que sur le site web.",
                                   "Tap « Install », open the app and sign in with the same credentials you use on the website.",
                                   "Toque « Instalar », abra la aplicación e inicie sesión con las mismas credenciales del sitio web.")))
        sb.Append("</div>")

        sb.Append("<div class=""mt-12 flex items-start gap-4 bg-sky-50 border border-sky-100 rounded-2xl p-6"">")
        sb.Append("<i data-lucide=""shield-check"" class=""w-6 h-6 text-sky-600 flex-shrink-0 mt-0.5""></i>")
        sb.Append("<div>")
        sb.Append("<p class=""font-semibold text-slate-900 mb-1"">")
        sb.Append(Choose3(lang, "Pourquoi Android demande-t-il une autorisation ?",
                                "Why does Android ask for a permission?",
                                "¿Por qué Android pide un permiso?"))
        sb.Append("</p>")
        sb.Append("<p class=""text-sm text-slate-600 leading-relaxed"">")
        sb.Append(Choose3(lang,
                          "L'application est distribuée directement par 60s Technologies plutôt que par le Play Store. Le paquet est signé par nos soins et servi en HTTPS depuis nos serveurs : l'avertissement d'Android porte sur la provenance du fichier, pas sur sa sécurité.",
                          "The app is distributed directly by 60s Technologies rather than through the Play Store. The package is signed by us and served over HTTPS from our own servers: Android's warning is about where the file comes from, not about its safety.",
                          "La aplicación se distribuye directamente por 60s Technologies y no a través de Play Store. El paquete está firmado por nosotros y se sirve por HTTPS desde nuestros servidores: el aviso de Android se refiere al origen del archivo, no a su seguridad."))
        sb.Append("</p></div></div>")

        sb.Append("</div></section>")
        Return sb.ToString()
    End Function

    ''' <summary>Une carte numérotée du guide d'installation.</summary>
    Private Function StepCard(number As String, title As String, text As String) As String
        Dim sb As New StringBuilder()
        sb.Append("<div class=""bg-slate-50 border border-slate-200 rounded-2xl p-8 transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-slate-200/80"">")
        sb.Append("<div class=""w-12 h-12 rounded-xl bg-blue-700 text-white flex items-center justify-center font-bold text-lg mb-5"">" & number & "</div>")
        sb.Append("<h3 class=""text-xl font-bold text-slate-950 mb-2"">" & Server.HtmlEncode(title) & "</h3>")
        sb.Append("<p class=""text-sm text-slate-600 leading-relaxed"">" & Server.HtmlEncode(text) & "</p>")
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    ''' <summary>Section « ce que l'application permet de faire ».</summary>
    Private Function BuildMobileFeaturesHtml(lang As String) As String
        Dim sb As New StringBuilder()

        sb.Append("<section class=""py-20 lg:py-24 bg-slate-50 border-t border-slate-200"">")
        sb.Append("<div class=""max-w-7xl mx-auto px-6 lg:px-8"">")

        sb.Append("<div class=""max-w-3xl mb-16"">")
        sb.Append("<h2 class=""text-3xl lg:text-5xl font-bold text-slate-950 tracking-tight mb-4"">")
        sb.Append(Choose3(lang, "Tout 60sec-AI, pensé pour le mobile",
                                "The whole of 60sec-AI, built for mobile",
                                "Todo 60sec-AI, pensado para el móvil"))
        sb.Append("</h2>")
        sb.Append("<p class=""text-lg text-slate-600 leading-relaxed"">")
        sb.Append(Choose3(lang,
                          "Les fonctions que vous utilisez le plus souvent, adaptées à l'écran d'un téléphone.",
                          "The features you use most often, adapted to a phone screen.",
                          "Las funciones que más utiliza, adaptadas a la pantalla de un teléfono."))
        sb.Append("</p></div>")

        sb.Append("<div class=""grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"">")
        sb.Append(FeatureCard("scan-line",
                              Choose3(lang, "Scan de reçus", "Receipt scanning", "Escaneo de recibos"),
                              Choose3(lang,
                                      "Photographiez un reçu : l'IA lit le marchand, le montant et les taxes, puis prépare l'écriture.",
                                      "Snap a receipt: the AI reads the merchant, the amount and the taxes, then prepares the entry.",
                                      "Fotografíe un recibo: la IA lee el comercio, el importe y los impuestos y prepara el asiento.")))
        sb.Append(FeatureCard("file-text",
                              Choose3(lang, "Factures clients", "Customer invoices", "Facturas de clientes"),
                              Choose3(lang,
                                      "Créez et envoyez une facture en quelques touches, avec le PDF généré automatiquement.",
                                      "Create and send an invoice in a few taps, with the PDF generated for you.",
                                      "Cree y envíe una factura en pocos toques, con el PDF generado automáticamente.")))
        sb.Append(FeatureCard("wallet",
                              Choose3(lang, "Encaissements et paiements", "Payments in and out", "Cobros y pagos"),
                              Choose3(lang,
                                      "Suivez les encaissements et réglez vos fournisseurs par virement ou par Interac.",
                                      "Follow incoming payments and pay your suppliers by transfer or Interac.",
                                      "Siga los cobros y pague a sus proveedores por transferencia o Interac.")))
        sb.Append(FeatureCard("bar-chart-3",
                              Choose3(lang, "États financiers", "Financial statements", "Estados financieros"),
                              Choose3(lang,
                                      "Bilan, état des résultats et flux de trésorerie à jour, consultables en tout temps.",
                                      "Balance sheet, income statement and cash flow, up to date and available at any time.",
                                      "Balance, estado de resultados y flujo de caja al día, disponibles en todo momento.")))
        sb.Append(FeatureCard("calendar-days",
                              Choose3(lang, "Agenda", "Schedule", "Agenda"),
                              Choose3(lang,
                                      "Vos rendez-vous et vos tâches, synchronisés avec votre poste de travail.",
                                      "Your appointments and tasks, synced with your workstation.",
                                      "Sus citas y tareas, sincronizadas con su puesto de trabajo.")))
        sb.Append(FeatureCard("refresh-cw",
                              Choose3(lang, "Synchronisation en temps réel", "Real-time sync", "Sincronización en tiempo real"),
                              Choose3(lang,
                                      "Un seul compte, une seule base de données : ce qui est saisi au téléphone apparaît aussitôt sur le web.",
                                      "One account, one database: whatever you enter on the phone shows up on the web right away.",
                                      "Una sola cuenta y una sola base de datos: lo que registra en el móvil aparece al instante en la web.")))
        sb.Append("</div>")

        sb.Append("</div></section>")
        Return sb.ToString()
    End Function

    ''' <summary>Une carte de la grille des fonctionnalités mobiles.</summary>
    Private Function FeatureCard(icon As String, title As String, text As String) As String
        Dim sb As New StringBuilder()
        sb.Append("<div class=""bg-white border border-slate-200 rounded-2xl p-7 transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-slate-200/80"">")
        sb.Append("<div class=""w-11 h-11 rounded-xl bg-blue-50 text-blue-700 flex items-center justify-center mb-5""><i data-lucide=""" & icon & """ class=""w-5 h-5""></i></div>")
        sb.Append("<h3 class=""text-base font-semibold text-slate-950 mb-2"">" & Server.HtmlEncode(title) & "</h3>")
        sb.Append("<p class=""text-sm text-slate-600 leading-relaxed"">" & Server.HtmlEncode(text) & "</p>")
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    ''' <summary>Bandeau final : rappel du bouton et lien à ouvrir depuis le téléphone.</summary>
    Private Function BuildMobileCtaHtml(lang As String, available As Boolean) As String
        Dim sb As New StringBuilder()

        sb.Append("<section class=""py-20 lg:py-24 bg-gradient-to-br from-blue-700 via-blue-600 to-sky-500"">")
        sb.Append("<div class=""max-w-3xl mx-auto px-6 text-center"">")
        sb.Append("<div class=""w-14 h-14 rounded-2xl bg-white/15 border border-white/25 flex items-center justify-center mx-auto mb-6""><i data-lucide=""smartphone"" class=""w-7 h-7 text-white""></i></div>")
        sb.Append("<h2 class=""text-3xl lg:text-5xl font-bold text-white tracking-tight mb-4"">")
        sb.Append(Choose3(lang, "Prêt à gérer votre entreprise depuis votre téléphone ?",
                                "Ready to run your business from your phone?",
                                "¿Listo para gestionar su empresa desde el teléfono?"))
        sb.Append("</h2>")
        sb.Append("<p class=""text-lg text-sky-100 leading-relaxed mb-10"">")
        sb.Append(Choose3(lang,
                          "Téléchargez l'application, connectez-vous : vos données sont déjà là.",
                          "Download the app and sign in: your data is already there.",
                          "Descargue la aplicación e inicie sesión: sus datos ya están ahí."))
        sb.Append("</p>")

        If available Then
            sb.Append("<a href=""" & clsAndroidApp.DownloadUrl & """ class=""inline-flex items-center justify-center gap-3 bg-white hover:bg-slate-50 text-blue-700 font-semibold px-8 py-4 rounded-xl text-base transition-all duration-200 hover:shadow-2xl hover:shadow-blue-900/20 hover:-translate-y-0.5"">")
            sb.Append("<i data-lucide=""download"" class=""w-5 h-5""></i>")
            sb.Append(Choose3(lang, "Télécharger l'APK", "Download the APK", "Descargar el APK"))
            sb.Append("</a>")

            sb.Append("<p class=""text-sm text-sky-100/80 mt-10 mb-3"">")
            sb.Append(Choose3(lang, "Ou ouvrez ce lien directement depuis votre téléphone",
                                    "Or open this link straight from your phone",
                                    "O abra este enlace directamente desde su teléfono"))
            sb.Append("</p>")
            sb.Append("<div class=""inline-flex items-center gap-3 bg-white/15 border border-white/25 rounded-xl px-5 py-3"">")
            sb.Append("<i data-lucide=""link"" class=""w-4 h-4 text-sky-100""></i>")
            sb.Append("<span class=""font-mono text-sm text-white"">" & Server.HtmlEncode(BuildDisplayDownloadUrl()) & "</span>")
            sb.Append("</div>")
        Else
            sb.Append("<a data-nav=""contact"" href=""#"" class=""inline-flex items-center justify-center gap-3 bg-white hover:bg-slate-50 text-blue-700 font-semibold px-8 py-4 rounded-xl text-base transition-all duration-200 hover:shadow-2xl hover:shadow-blue-900/20 hover:-translate-y-0.5"">")
            sb.Append("<i data-lucide=""mail"" class=""w-5 h-5""></i>")
            sb.Append(Choose3(lang, "Me prévenir de la sortie", "Notify me when it ships", "Avisarme cuando salga"))
            sb.Append("</a>")
        End If

        sb.Append("</div></section>")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' URL de téléchargement telle qu'on l'affiche pour être retapée sur un
    ''' téléphone (hôte + chemin, sans le schéma). Ex. « 60sec.ca/AppAndroid.ashx ».
    ''' </summary>
    Private Function BuildDisplayDownloadUrl() As String
        Try
            Dim u As New Uri(Request.Url, ResolveUrl("~/" & clsAndroidApp.DownloadUrl))
            Dim host As String = u.Host
            If Not u.IsDefaultPort Then host &= ":" & u.Port.ToString()
            Return host & u.AbsolutePath
        Catch ex As Exception
            Return clsAndroidApp.DownloadUrl
        End Try
    End Function

    Private Shared Function GetStr(row As DataRowView, col As String) As String
        Dim v As Object = row(col)
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Return v.ToString().Trim()
    End Function

    Private Shared Function GetBool(row As DataRowView, col As String) As Boolean
        Dim v As Object = row(col)
        If v Is Nothing OrElse IsDBNull(v) Then Return False
        Return Convert.ToBoolean(v)
    End Function

End Class
