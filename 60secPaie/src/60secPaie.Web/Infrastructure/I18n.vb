Imports System.Globalization
Imports System.IO
Imports System.Text
Imports System.Text.RegularExpressions
Imports System.Web.Caching

''' <summary>
''' Trois langues : français (langue source), anglais, espagnol.
'''
''' Choix de la langue, même convention que MngConsul : ?lang=fr|en|es, puis Session("Lang"), puis « fr ».
''' 60secPaie ajoute un témoin pour que le choix survive à la déconnexion.
'''
''' Traduction : les pages sont écrites en français. À la sortie, <see cref="TraduireHtml"/> remplace chaque texte
''' (nœuds de texte, boutons, placeholder, title, confirm) par sa traduction, cherchée dans Langues\traductions.txt.
''' Un texte absent du dictionnaire reste en français.
''' Le dictionnaire accepte des modèles pour les textes qui contiennent des données :
'''   {0} = texte quelconque (traduit à son tour s'il est connu), {#0} = nombre, montant ou date.
''' </summary>
Public NotInheritable Class I18n

    Public Shared ReadOnly Langues As String() = {"fr", "en", "es"}
    Private Const CleSession As String = "Lang"
    Private Const NomTemoin As String = "Lang60sec"
    Private Const FichierTraductions As String = "~/Langues/traductions.txt"

    Private Sub New()
    End Sub

    ' ---------- Langue courante ----------

    Public Shared Function Valide(code As String) As Boolean
        Return code = "fr" OrElse code = "en" OrElse code = "es"
    End Function

    Public Shared Property Langue As String
        Get
            Dim ctx = HttpContext.Current
            If ctx Is Nothing Then Return "fr"
            If ctx.Items.Contains(CleSession) Then Return DirectCast(ctx.Items(CleSession), String)

            Dim choix = "fr"
            Dim q = If(ctx.Request.QueryString("lang"), "").Trim().ToLowerInvariant()
            Dim s = If(ctx.Session Is Nothing, Nothing, TryCast(ctx.Session(CleSession), String))
            Dim temoin = ctx.Request.Cookies(NomTemoin)
            If Valide(q) Then
                choix = q
                Memoriser(ctx, q)
            ElseIf Valide(s) Then
                choix = s
            ElseIf temoin IsNot Nothing AndAlso Valide(temoin.Value) Then
                choix = temoin.Value
                If ctx.Session IsNot Nothing Then ctx.Session(CleSession) = choix
            End If
            ctx.Items(CleSession) = choix
            Return choix
        End Get
        Set(value As String)
            If Not Valide(value) Then Return
            Dim ctx = HttpContext.Current
            ctx.Items(CleSession) = value
            Memoriser(ctx, value)
        End Set
    End Property

    ''' <summary>
    ''' Exécute un rendu dans une autre langue que celle de l'utilisateur (courriel dans la langue de l'employé) :
    ''' les montants et les textes produits par <paramref name="rendu"/> suivent cette langue. Rien n'est mémorisé.
    ''' </summary>
    Public Shared Function DansLaLangue(code As String, rendu As Func(Of String)) As String
        code = If(code, "").Trim().ToLowerInvariant()
        If Not Valide(code) Then code = "fr"
        Dim ctx = HttpContext.Current
        Dim avant = Langue
        ctx.Items(CleSession) = code
        Try
            Return rendu()
        Finally
            ctx.Items(CleSession) = avant
        End Try
    End Function

    Private Shared Sub Memoriser(ctx As HttpContext, code As String)
        If ctx.Session IsNot Nothing Then ctx.Session(CleSession) = code
        ctx.Response.Cookies.Set(New HttpCookie(NomTemoin, code) With {.Expires = Date.Now.AddYears(1), .HttpOnly = True})
    End Sub

    ''' <summary>Culture de mise en forme des nombres et des mois (les dates s'affichent toujours en AAAA-MM-JJ).</summary>
    Public Shared ReadOnly Property Culture As CultureInfo
        Get
            Return CultureDe(Langue)
        End Get
    End Property

    Public Shared Function CultureDe(code As String) As CultureInfo
        Select Case code
            Case "en" : Return CultureInfo.GetCultureInfo("en-CA")
            Case "es" : Return CultureInfo.GetCultureInfo("es-MX")
            Case Else : Return CultureInfo.GetCultureInfo("fr-CA")
        End Select
    End Function

    ''' <summary>Liens FR | EN | ES vers la page courante, en conservant les autres paramètres de l'URL.</summary>
    Public Shared Function SelecteurLangues(requete As HttpRequest) As String
        Dim sb As New StringBuilder()
        For Each code In Langues
            Dim qs = HttpUtility.ParseQueryString(requete.QueryString.ToString())
            qs("lang") = code
            If sb.Length > 0 Then sb.Append(" | ")
            If code = Langue Then
                sb.Append("<strong>").Append(code.ToUpperInvariant()).Append("</strong>")
            Else
                sb.Append("<a href=""").Append(HttpUtility.HtmlAttributeEncode(requete.Url.AbsolutePath & "?" & qs.ToString())).Append(""">")
                sb.Append(code.ToUpperInvariant()).Append("</a>")
            End If
        Next
        Return sb.ToString()
    End Function

    ' ---------- Dictionnaire ----------

    ''' <summary>Emplacement du fichier de traductions lorsqu'il n'est pas celui du site (tests).</summary>
    Public Shared Property CheminFichier As String

    ''' <summary>Traductions d'une langue : textes exacts, et modèles contenant des données.</summary>
    Private Class Lexique
        Public ReadOnly Exacts As New Dictionary(Of String, String)(StringComparer.Ordinal)
        Public ReadOnly Modeles As New List(Of KeyValuePair(Of Regex, String))()
        ''' <summary>Les modèles tels qu'écrits dans le fichier, pour T(gabarit, valeurs).</summary>
        Public ReadOnly Gabarits As New Dictionary(Of String, String)(StringComparer.Ordinal)
    End Class

    Private Shared Function LexiqueDe(code As String) As Lexique
        Dim chemin = If(CheminFichier, HttpContext.Current.Server.MapPath(FichierTraductions))
        Dim cle = "I18n." & code & "|" & chemin
        Dim l = TryCast(HttpRuntime.Cache(cle), Lexique)
        If l IsNot Nothing Then Return l

        l = New Lexique()
        ' Les modèles les plus longs d'abord : le plus précis l'emporte.
        For Each paire In Charger(chemin, code).OrderByDescending(Function(p) p.Key.Length)
            If paire.Key.Contains("{") Then
                l.Modeles.Add(New KeyValuePair(Of Regex, String)(ModeleVersRegex(paire.Key), paire.Value))
                l.Gabarits(paire.Key) = paire.Value
            Else
                l.Exacts(paire.Key) = paire.Value
            End If
        Next
        HttpRuntime.Cache.Insert(cle, l, New CacheDependency(chemin))
        Return l
    End Function

    ' Après Regex.Escape, « {#0} » devient « \{\#0} » et « {0} » devient « \{0} ».
    Private Shared ReadOnly JetonNombreEchappe As New Regex("\\\{\\#(\d)\}", RegexOptions.Compiled)
    Private Shared ReadOnly JetonTexteEchappe As New Regex("\\\{(\d)\}", RegexOptions.Compiled)
    Private Shared ReadOnly Jeton As New Regex("\{#?(\d)\}", RegexOptions.Compiled)

    Private Shared Function ModeleVersRegex(modele As String) As Regex
        Dim motif = Regex.Escape(modele)
        motif = JetonNombreEchappe.Replace(motif, "(?<g$1>[\d\s.,:$$%/\-]+?)")
        motif = JetonTexteEchappe.Replace(motif, "(?<g$1>.+?)")
        Return New Regex("^" & motif & "$", RegexOptions.Singleline)
    End Function

    ''' <summary>
    ''' Format du fichier : des blocs séparés par une ligne vide.
    '''   fr: Texte français          (peut contenir {0} = texte variable, {#0} = nombre, montant ou date)
    '''   en: English text
    '''   es: Texto en español
    ''' Les lignes qui commencent par # sont des commentaires.
    ''' </summary>
    Public Shared Function Charger(chemin As String, code As String) As Dictionary(Of String, String)
        Dim d As New Dictionary(Of String, String)(StringComparer.Ordinal)
        If Not File.Exists(chemin) Then Return d

        Dim fr As String = Nothing
        For Each brute In File.ReadAllLines(chemin, Encoding.UTF8)
            Dim ligne = brute.Trim()
            If ligne.Length = 0 Then fr = Nothing : Continue For
            If ligne.StartsWith("#") OrElse ligne.Length < 4 OrElse ligne(2) <> ":"c Then Continue For
            Dim prefixe = ligne.Substring(0, 2)
            Dim texte = ligne.Substring(3).Trim()
            If prefixe = "fr" Then
                fr = Normaliser(texte)
            ElseIf prefixe = code AndAlso fr IsNot Nothing AndAlso texte.Length > 0 Then
                d(fr) = texte
            End If
        Next
        Return d
    End Function

    Private Shared ReadOnly Espaces As New Regex("\s+", RegexOptions.Compiled)

    Private Shared Function Normaliser(texte As String) As String
        Return Espaces.Replace(texte.Replace(ChrW(160), " "c), " ").Trim()
    End Function

    ''' <summary>Traduction dans une langue donnée ; Nothing s'il n'y en a pas.</summary>
    Private Shared Function Chercher(fr As String, code As String, avecModeles As Boolean) As String
        Dim cle = Normaliser(fr)
        If cle.Length = 0 Then Return Nothing
        Dim l = LexiqueDe(code)
        Dim traduction As String = Nothing
        If l.Exacts.TryGetValue(cle, traduction) Then Return traduction
        If Not avecModeles Then Return Nothing

        For Each modele In l.Modeles
            Dim m = modele.Key.Match(cle)
            If Not m.Success Then Continue For
            ' Les données capturées sont traduites à leur tour lorsqu'elles sont connues (ex. « Receveur général du Canada »).
            Return Jeton.Replace(modele.Value, Function(j)
                                                   Dim valeur = m.Groups("g" & j.Groups(1).Value).Value
                                                   If j.Value.Contains("#") Then Return MontantDansLaLangue(valeur, code)
                                                   Return If(Chercher(valeur, code, True), valeur)
                                               End Function)
        Next
        Return Nothing
    End Function

    Private Shared ReadOnly MontantFrancais As New Regex("^(-?)([\d ]+),(\d{2}) \$$", RegexOptions.Compiled)

    ''' <summary>Un montant enregistré en français (journal d'activités : « 1 234,50 $ ») s'affiche au format de la langue.</summary>
    Private Shared Function MontantDansLaLangue(valeur As String, code As String) As String
        Dim m = MontantFrancais.Match(valeur)
        If Not m.Success Then Return valeur
        Dim montant = Decimal.Parse(m.Groups(2).Value.Replace(" ", "") & "." & m.Groups(3).Value, CultureInfo.InvariantCulture)
        Return m.Groups(1).Value & "$" & montant.ToString("N2", CultureDe(code))
    End Function

    ''' <summary>Traduction d'un texte français dans la langue courante ; le français est retourné s'il n'y a pas de traduction.</summary>
    Public Shared Function T(fr As String) As String
        Return Traduire(fr, Langue)
    End Function

    Public Shared Function Traduire(fr As String, code As String) As String
        If String.IsNullOrEmpty(fr) OrElse code = "fr" OrElse Not Valide(code) Then Return fr
        Return If(Chercher(fr, code, True), fr)
    End Function

    ''' <summary>Texte avec des données : T("{0} employés actifs", 3). Le gabarit est traduit, puis les valeurs y sont insérées.</summary>
    Public Shared Function T(fr As String, ParamArray valeurs As Object()) As String
        Dim code = Langue
        Dim gabarit = fr
        If code <> "fr" Then
            Dim l = LexiqueDe(code)
            Dim traduit As String = Nothing
            If l.Gabarits.TryGetValue(Normaliser(fr), traduit) OrElse l.Exacts.TryGetValue(Normaliser(fr), traduit) Then gabarit = traduit
        End If
        Return String.Format(Culture, gabarit.Replace("{#", "{"), valeurs)
    End Function

    ' ---------- Traduction du HTML produit ----------

    Private Shared ReadOnly Decoupage As New Regex(
        "(<script\b.*?</script\s*>|<style\b.*?</style\s*>|<textarea\b.*?</textarea\s*>|<pre\b.*?</pre\s*>|<!--.*?-->|<[^>]+>)",
        RegexOptions.Compiled Or RegexOptions.Singleline Or RegexOptions.IgnoreCase)
    Private Shared ReadOnly AttributsTexte As New Regex("\b(placeholder|title|alt)=""([^""]+)""", RegexOptions.Compiled Or RegexOptions.IgnoreCase)
    Private Shared ReadOnly AttributValeur As New Regex("\bvalue=""([^""]+)""", RegexOptions.Compiled Or RegexOptions.IgnoreCase)
    Private Shared ReadOnly EstBouton As New Regex("\btype=""(submit|button)""", RegexOptions.Compiled Or RegexOptions.IgnoreCase)
    Private Shared ReadOnly Confirmation As New Regex("confirm\(&#39;(.*?)&#39;\)|confirm\('(.*?)'\)", RegexOptions.Compiled)

    ''' <summary>Traduit le HTML dans la langue courante, ou dans la langue donnée (courriels dans la langue de l'employé).</summary>
    Public Shared Function TraduireHtml(html As String, Optional code As String = Nothing) As String
        If code Is Nothing Then code = Langue
        If code = "fr" OrElse Not Valide(code) OrElse String.IsNullOrEmpty(html) Then Return html

        Dim morceaux = Decoupage.Split(html)
        Dim sb As New StringBuilder(html.Length + 256)
        Dim intouchable = False     ' le texte qui suit une balise translate="no" (nom du produit) n'est pas traduit
        For i = 0 To morceaux.Length - 1
            Dim m = morceaux(i)
            If i Mod 2 = 0 Then
                sb.Append(If(intouchable, m, TraduireTexte(m, code)))           ' texte entre deux balises
                intouchable = False
            ElseIf EstBaliseOuvrante(m) Then
                intouchable = m.IndexOf("translate=""no""", StringComparison.OrdinalIgnoreCase) >= 0
                sb.Append(TraduireBalise(m, code))
            Else
                sb.Append(m)                                ' script, style, pre, textarea, commentaire, balise fermante
            End If
        Next
        Return sb.ToString()
    End Function

    Private Shared Function EstBaliseOuvrante(m As String) As Boolean
        If m.Length < 3 OrElse m(1) = "/"c OrElse m(1) = "!"c Then Return False
        For Each exclue In {"<script", "<style", "<pre", "<textarea"}
            If m.StartsWith(exclue, StringComparison.OrdinalIgnoreCase) Then Return False
        Next
        Return True
    End Function

    Private Shared Function TraduireTexte(texte As String, code As String) As String
        If texte.Trim().Length = 0 Then Return texte
        Dim fr = HttpUtility.HtmlDecode(texte.Trim())
        Dim traduction = Traduire(fr, code)
        If traduction = fr Then Return texte

        Dim debut = texte.Substring(0, texte.Length - texte.TrimStart().Length)
        Dim fin = texte.Substring(texte.TrimEnd().Length)
        Return debut & Encoder(traduction) & fin
    End Function

    ''' <summary>Encodage minimal : la page est en UTF-8, les lettres accentuées n'ont pas à devenir des entités.</summary>
    Private Shared Function Encoder(texte As String) As String
        Return texte.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("""", "&quot;")
    End Function

    Private Shared Function TraduireBalise(balise As String, code As String) As String
        If balise.IndexOf("="c) < 0 Then Return balise
        Dim r = AttributsTexte.Replace(balise, Function(m) m.Groups(1).Value & "=""" & TraduireAttribut(m.Groups(2).Value, code) & """")
        If EstBouton.IsMatch(r) Then r = AttributValeur.Replace(r, Function(m) "value=""" & TraduireAttribut(m.Groups(1).Value, code) & """")
        If r.IndexOf("confirm(", StringComparison.Ordinal) >= 0 Then
            r = Confirmation.Replace(r, Function(m)
                                            Dim encode = m.Groups(1).Success
                                            Dim fr = HttpUtility.HtmlDecode(If(encode, m.Groups(1).Value, m.Groups(2).Value))
                                            Dim js = Traduire(fr, code).Replace("\", "\\").Replace("'", "\'")
                                            Return If(encode, "confirm(&#39;" & Encoder(js).Replace("'", "&#39;") & "&#39;)", "confirm('" & js & "')")
                                        End Function)
        End If
        Return r
    End Function

    Private Shared Function TraduireAttribut(valeurEncodee As String, code As String) As String
        Dim fr = HttpUtility.HtmlDecode(valeurEncodee)
        Dim traduction = Traduire(fr, code)
        Return If(traduction = fr, valeurEncodee, Encoder(traduction))
    End Function

    ''' <summary>Exécute le rendu normal de la page dans un tampon, traduit le HTML, puis l'écrit dans la réponse.</summary>
    Public Shared Sub RendreTraduit(sortie As HtmlTextWriter, rendu As Action(Of HtmlTextWriter))
        If Langue = "fr" Then
            rendu(sortie)
            Return
        End If
        Using tampon As New StringWriter(CultureInfo.InvariantCulture), w As New HtmlTextWriter(tampon)
            rendu(w)
            w.Flush()
            sortie.Write(TraduireHtml(tampon.ToString()))
        End Using
    End Sub

End Class
