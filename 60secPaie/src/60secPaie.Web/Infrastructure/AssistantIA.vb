Imports System.IO
Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text
Imports System.Text.RegularExpressions
Imports System.Threading.Tasks
Imports System.Web.Caching
Imports System.Web.Script.Serialization

''' <summary>Un tour de conversation : la question de l'utilisateur ou la réponse de l'assistant.</summary>
<Serializable>
Public Class TourIA
    Public Property Role As String        ' "user" ou "assistant"
    Public Property Texte As String
    Public Property Quand As Date
End Class

''' <summary>
''' L'assistant de paie : une question, le guide, le profil de la compagnie, et
''' la réponse du modèle. Cette classe ne fait qu'interroger ; ce qui part est
''' assemblé ici, en un seul endroit, pour qu'on sache exactement quoi.
'''
'''   1. le prompt système (PROMPT_ASSISTANT_PAIE, modifiable dans Sec60Admin) ;
'''   2. le guide d'aide dans la langue de l'utilisateur, en texte (Aide*.html
'''      débarrassé de ses balises, mis en cache tant que le fichier ne change pas) ;
'''   3. le profil de la compagnie (ServiceProfilIA : jamais de nom, de NAS, de compte) ;
'''   4. les derniers tours de la conversation, puis la question.
''' Le tout est journalisé dans paie.ConversationIA avec son coût.
''' </summary>
Public NotInheritable Class AssistantIA

    Public Const Modele As String = "gpt-4.1-mini"
    Private Const Url As String = "https://api.openai.com/v1/responses"
    Private Const ToursGardes As Integer = 10
    Private Const LongueurMaxQuestion As Integer = 4000

    Public Class Reponse
        Public Property Texte As String
        Public Property InputTokens As Integer
        Public Property OutputTokens As Integer
        Public ReadOnly Property CoutUsd As Decimal
            Get
                ' Tarifs gpt-4.1-mini : une estimation, pour que personne ne découvre la facture après coup.
                Return (InputTokens * 0.0000004D) + (OutputTokens * 0.0000016D)
            End Get
        End Property
    End Class

    Private Sub New()
    End Sub

    ''' <summary>La clé d'accès, là où vivent celles de l'ERP (paramètre CHATGPT).</summary>
    Private Shared Function Cle() As String
        Dim valeur = Convert.ToString(Db.Scalaire("SELECT [Value] FROM dbo.T0000Parameters WHERE [ParamName] = 'CHATGPT'"))
        If valeur.Trim().Length = 0 Then Throw New SaisieInvalideException(Tr("La clé d'accès à l'IA n'est pas configurée."))
        Return valeur.Trim()
    End Function

    Private Shared Function PromptSysteme() As String
        Dim v = Convert.ToString(Db.Scalaire("SELECT [Value] FROM dbo.T0000Parameters WHERE [ParamName] = 'PROMPT_ASSISTANT_PAIE'"))
        If v.Trim().Length = 0 Then Throw New SaisieInvalideException(Tr("Le prompt de l'assistant n'est pas configuré."))
        Return v
    End Function

    ''' <summary>Le guide d'aide en texte, dans la langue demandée. Relu quand le fichier change.</summary>
    Public Shared Function TexteAide(langue As String) As String
        Dim nom = If(langue = "en", "Aide-en.html", If(langue = "es", "Aide-es.html", "Aide.html"))
        Dim chemin = HttpContext.Current.Server.MapPath("~/" & nom)
        Dim cle = "AideTexte:" & nom
        Dim enCache = TryCast(HttpRuntime.Cache(cle), String)
        If enCache IsNot Nothing Then Return enCache

        Dim html = File.ReadAllText(chemin, Encoding.UTF8)
        ' On ne garde que le contenu : ni style, ni script, ni sommaire (il répète les titres).
        html = Regex.Replace(html, "<style[\s\S]*?</style>|<script[\s\S]*?</script>|<nav[\s\S]*?</nav>|<header[\s\S]*?</header>", " ", RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "</(h1|h2|h3|h4|p|li|tr|div|dt|dd|details|summary)>", vbLf, RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "<(td|th)[^>]*>", " | ", RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "<h2[^>]*>", vbLf & "## ", RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "<h3[^>]*>", vbLf & "### ", RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "<li[^>]*>", "- ", RegexOptions.IgnoreCase)
        html = Regex.Replace(html, "<[^>]+>", "")
        html = HttpUtility.HtmlDecode(html)
        html = Regex.Replace(html, "[ \t]+", " ")
        html = Regex.Replace(html, "(\r?\n\s*){3,}", vbLf & vbLf)
        Dim texte = html.Trim()
        HttpRuntime.Cache.Insert(cle, texte, New CacheDependency(chemin))
        Return texte
    End Function

    ''' <summary>Pose la question, avec les tours précédents, et rend la réponse. Journalise toujours, même l'échec.</summary>
    Public Shared Async Function DemanderAsync(question As String, historique As List(Of TourIA), langue As String) As Task(Of Reponse)
        If String.IsNullOrWhiteSpace(question) Then Throw New SaisieInvalideException(Tr("Écrivez une question."))
        If question.Length > LongueurMaxQuestion Then Throw New SaisieInvalideException(Tr("La question est trop longue ({0} caractères au plus).", LongueurMaxQuestion))

        Dim chrono = Diagnostics.Stopwatch.StartNew()
        Dim journalId = Db.Inserer(
            "INSERT INTO paie.ConversationIA (CompagnieId, Utilisateur, Langue, Question, Modele) VALUES (@c, @u, @l, @q, @m)",
            Db.P("@c", Contexte.CompagnieId), Db.P("@u", Contexte.Utilisateur), Db.P("@l", langue), Db.P("@q", question.Trim()), Db.P("@m", Modele))

        Try
            Dim systeme As New StringBuilder()
            systeme.AppendLine(PromptSysteme())
            systeme.AppendLine()
            systeme.AppendLine("=== LE GUIDE ===")
            systeme.AppendLine(TexteAide(langue))
            systeme.AppendLine()
            systeme.AppendLine("=== LE PROFIL DE LA COMPAGNIE ===")
            systeme.AppendLine(ServiceProfilIA.Obtenir())

            Dim entrees As New List(Of Object)()
            entrees.Add(New Dictionary(Of String, Object) From {{"role", "system"}, {"content", systeme.ToString()}})
            For Each t In historique.Skip(Math.Max(0, historique.Count - ToursGardes))
                entrees.Add(New Dictionary(Of String, Object) From {{"role", t.Role}, {"content", t.Texte}})
            Next
            entrees.Add(New Dictionary(Of String, Object) From {{"role", "user"}, {"content", question.Trim()}})

            Dim js As New JavaScriptSerializer() With {.MaxJsonLength = Integer.MaxValue}
            Dim charge = js.Serialize(New Dictionary(Of String, Object) From {
                {"model", Modele}, {"input", entrees}, {"max_output_tokens", 1200}})

            Dim brut As String
            Using http As New HttpClient()
                http.Timeout = TimeSpan.FromSeconds(90)
                http.DefaultRequestHeaders.Authorization = New AuthenticationHeaderValue("Bearer", Cle())
                Dim rep = Await http.PostAsync(Url, New StringContent(charge, Encoding.UTF8, "application/json")).ConfigureAwait(False)
                brut = Await rep.Content.ReadAsStringAsync().ConfigureAwait(False)
                If Not rep.IsSuccessStatusCode Then Throw New InvalidOperationException("OpenAI " & CInt(rep.StatusCode).ToString() & " : " & Gauche(brut, 400))
            End Using

            Dim jo = TryCast(js.DeserializeObject(brut), Dictionary(Of String, Object))
            If jo Is Nothing Then Throw New InvalidOperationException("Réponse illisible du modèle.")
            Dim r As New Reponse With {.Texte = ExtraireTexte(jo)}
            Dim usage = TryCast(Valeur(jo, "usage"), Dictionary(Of String, Object))
            If usage IsNot Nothing Then
                r.InputTokens = Convert.ToInt32(If(Valeur(usage, "input_tokens"), 0))
                r.OutputTokens = Convert.ToInt32(If(Valeur(usage, "output_tokens"), 0))
            End If
            chrono.Stop()
            Db.Exec("UPDATE paie.ConversationIA SET Reponse = @r, InputTokens = @i, OutputTokens = @o, CoutUsd = @cout, DureeMs = @d WHERE Id = @id",
                    Db.P("@r", r.Texte), Db.P("@i", r.InputTokens), Db.P("@o", r.OutputTokens), Db.P("@cout", r.CoutUsd), Db.P("@d", CInt(chrono.ElapsedMilliseconds)), Db.P("@id", journalId))
            Return r
        Catch ex As Exception
            chrono.Stop()
            Db.Exec("UPDATE paie.ConversationIA SET Erreur = @e, DureeMs = @d WHERE Id = @id",
                    Db.P("@e", Gauche(ex.Message, 1000)), Db.P("@d", CInt(chrono.ElapsedMilliseconds)), Db.P("@id", journalId))
            Throw
        End Try
    End Function

    Private Shared Function Valeur(d As Dictionary(Of String, Object), cle As String) As Object
        Dim v As Object = Nothing
        If d IsNot Nothing AndAlso d.TryGetValue(cle, v) Then Return v
        Return Nothing
    End Function

    ''' <summary>Le texte de la réponse, où qu'il soit dans la structure « output » du modèle.</summary>
    Private Shared Function ExtraireTexte(jo As Dictionary(Of String, Object)) As String
        Dim sb As New StringBuilder()
        Dim sortie = TryCast(Valeur(jo, "output"), Object())
        If sortie IsNot Nothing Then
            For Each item In sortie
                Dim d = TryCast(item, Dictionary(Of String, Object))
                Dim contenu = TryCast(Valeur(d, "content"), Object())
                If contenu Is Nothing Then Continue For
                For Each c In contenu
                    Dim cd = TryCast(c, Dictionary(Of String, Object))
                    If cd IsNot Nothing AndAlso Convert.ToString(Valeur(cd, "type")) = "output_text" Then sb.Append(Convert.ToString(Valeur(cd, "text")))
                Next
            Next
        End If
        If sb.Length = 0 Then sb.Append(Convert.ToString(Valeur(jo, "output_text")))
        Return sb.ToString().Trim()
    End Function

    Private Shared Function Gauche(s As String, n As Integer) As String
        If s Is Nothing Then Return ""
        Return If(s.Length > n, s.Substring(0, n), s)
    End Function

    ''' <summary>Coût cumulé des questions de la compagnie ce mois-ci, pour l'afficher.</summary>
    Public Shared Function CoutDuMois() As Decimal
        Dim v = Db.Scalaire("SELECT ISNULL(SUM(CoutUsd), 0) FROM paie.ConversationIA WHERE CompagnieId = @c AND CreeLe >= @d",
                            Db.P("@c", Contexte.CompagnieId), Db.P("@d", New Date(Date.Today.Year, Date.Today.Month, 1)))
        Return If(v Is Nothing, 0D, Convert.ToDecimal(v))
    End Function

End Class
