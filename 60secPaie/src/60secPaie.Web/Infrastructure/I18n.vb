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
''' Un texte absent du dictionnaire reste en français. Les textes construits avec des données utilisent T("... {0} ...", valeur).
''' </summary>
Public NotInheritable Class I18n

    Public Shared ReadOnly Langues As String() = {"fr", "en", "es"}
    Private Const CleSession As String = "Lang"
    Private Const NomTemoin As String = "Lang60sec"
    Private Const FichierTraductions As String = "~/Langues/traductions.txt"

    Private Sub New()
    End Sub

    ' ---------- Langue courante ----------

    Private Shared Function Valide(code As String) As Boolean
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

    Private Shared Sub Memoriser(ctx As HttpContext, code As String)
        If ctx.Session IsNot Nothing Then ctx.Session(CleSession) = code
        ctx.Response.Cookies.Set(New HttpCookie(NomTemoin, code) With {.Expires = Date.Now.AddYears(1), .HttpOnly = True})
    End Sub

    ''' <summary>Culture de mise en forme des nombres et des mois (les dates s'affichent toujours en AAAA-MM-JJ).</summary>
    Public Shared ReadOnly Property Culture As CultureInfo
        Get
            Select Case Langue
                Case "en" : Return CultureInfo.GetCultureInfo("en-CA")
                Case "es" : Return CultureInfo.GetCultureInfo("es-MX")
                Case Else : Return CultureInfo.GetCultureInfo("fr-CA")
            End Select
        End Get
    End Property

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

    ''' <summary>Dictionnaire de la langue : texte français normalisé → traduction. Rechargé dès que le fichier change.</summary>
    Private Shared Function Dictionnaire(code As String) As Dictionary(Of String, String)
        Dim cle = "I18n." & code
        Dim d = TryCast(HttpRuntime.Cache(cle), Dictionary(Of String, String))
        If d IsNot Nothing Then Return d

        Dim chemin = If(CheminFichier, HttpContext.Current.Server.MapPath(FichierTraductions))
        d = Charger(chemin, code)
        HttpRuntime.Cache.Insert(cle, d, New CacheDependency(chemin))
        Return d
    End Function

    ''' <summary>
    ''' Format du fichier : des blocs séparés par une ligne vide.
    '''   fr: Texte français
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

    ''' <summary>Traduction d'un texte français ; le français est retourné tel quel s'il n'y a pas de traduction.</summary>
    Public Shared Function T(fr As String) As String
        If String.IsNullOrEmpty(fr) Then Return fr
        Dim code = Langue
        If code = "fr" Then Return fr
        Dim traduction As String = Nothing
        Return If(Dictionnaire(code).TryGetValue(Normaliser(fr), traduction), traduction, fr)
    End Function

    ''' <summary>Texte avec des données : T("{0} employés actifs", 3). Le gabarit est traduit, puis les valeurs y sont insérées.</summary>
    Public Shared Function T(fr As String, ParamArray valeurs As Object()) As String
        Return String.Format(Culture, T(fr), valeurs)
    End Function

    ' ---------- Traduction du HTML produit ----------

    Private Shared ReadOnly Decoupage As New Regex(
        "(<script\b.*?</script\s*>|<style\b.*?</style\s*>|<textarea\b.*?</textarea\s*>|<pre\b.*?</pre\s*>|<!--.*?-->|<[^>]+>)",
        RegexOptions.Compiled Or RegexOptions.Singleline Or RegexOptions.IgnoreCase)
    Private Shared ReadOnly AttributsTexte As New Regex("\b(placeholder|title|alt)=""([^""]+)""", RegexOptions.Compiled Or RegexOptions.IgnoreCase)
    Private Shared ReadOnly AttributValeur As New Regex("\bvalue=""([^""]+)""", RegexOptions.Compiled Or RegexOptions.IgnoreCase)
    Private Shared ReadOnly EstBouton As New Regex("\btype=""(submit|button)""", RegexOptions.Compiled Or RegexOptions.IgnoreCase)
    Private Shared ReadOnly Confirmation As New Regex("confirm\(&#39;(.*?)&#39;\)|confirm\('(.*?)'\)", RegexOptions.Compiled)

    Public Shared Function TraduireHtml(html As String) As String
        If Langue = "fr" OrElse String.IsNullOrEmpty(html) Then Return html

        Dim morceaux = Decoupage.Split(html)
        Dim sb As New StringBuilder(html.Length + 256)
        For i = 0 To morceaux.Length - 1
            Dim m = morceaux(i)
            If i Mod 2 = 0 Then
                sb.Append(TraduireTexte(m))                 ' texte entre deux balises
            ElseIf m.StartsWith("<input", StringComparison.OrdinalIgnoreCase) OrElse m.StartsWith("<a ", StringComparison.OrdinalIgnoreCase) OrElse
                   m.StartsWith("<button", StringComparison.OrdinalIgnoreCase) OrElse m.StartsWith("<img", StringComparison.OrdinalIgnoreCase) OrElse
                   m.StartsWith("<textarea", StringComparison.OrdinalIgnoreCase) OrElse m.StartsWith("<span", StringComparison.OrdinalIgnoreCase) Then
                sb.Append(TraduireBalise(m))
            Else
                sb.Append(m)
            End If
        Next
        Return sb.ToString()
    End Function

    Private Shared Function TraduireTexte(texte As String) As String
        If texte.Trim().Length = 0 Then Return texte
        Dim coeur = texte.Trim()
        Dim fr = HttpUtility.HtmlDecode(coeur)
        Dim traduction = T(fr)
        If Object.ReferenceEquals(traduction, fr) OrElse traduction = fr Then Return texte

        Dim debut = texte.Substring(0, texte.Length - texte.TrimStart().Length)
        Dim fin = texte.Substring(texte.TrimEnd().Length)
        Return debut & Encoder(traduction) & fin
    End Function

    ''' <summary>Encodage minimal : la page est en UTF-8, les lettres accentuées n'ont pas à devenir des entités.</summary>
    Private Shared Function Encoder(texte As String) As String
        Return texte.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("""", "&quot;")
    End Function

    Private Shared Function TraduireBalise(balise As String) As String
        Dim r = AttributsTexte.Replace(balise, Function(m) m.Groups(1).Value & "=""" & TraduireAttribut(m.Groups(2).Value) & """")
        If EstBouton.IsMatch(r) Then r = AttributValeur.Replace(r, Function(m) "value=""" & TraduireAttribut(m.Groups(1).Value) & """")
        r = Confirmation.Replace(r, Function(m)
                                        Dim encode = m.Groups(1).Success
                                        Dim fr = HttpUtility.HtmlDecode(If(encode, m.Groups(1).Value, m.Groups(2).Value)).Replace("\'", "'")
                                        Dim js = T(fr).Replace("\", "\\").Replace("'", "\'")
                                        Return If(encode, "confirm(&#39;" & Encoder(js).Replace("'", "&#39;") & "&#39;)", "confirm('" & js & "')")
                                    End Function)
        Return r
    End Function

    Private Shared Function TraduireAttribut(valeurEncodee As String) As String
        Dim fr = HttpUtility.HtmlDecode(valeurEncodee)
        Dim traduction = T(fr)
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
