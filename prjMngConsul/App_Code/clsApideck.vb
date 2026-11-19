Imports System
Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Net
Imports System.Text
Imports Newtonsoft.Json.Linq

''' <summary>
''' Helper Apideck pour MngConsul — la lecture directe d'une comptabilité source.
'''
''' Apideck est une API « unifiée » : un seul appel, traduit à la volée vers
''' QuickBooks Online, Sage ou un autre logiciel, pour le compte d'un
''' consommateur. Ici, le consommateur est la compagnie : son CompanyGUID.
'''
''' Relier la source se fait une fois, dans Vault — la page hébergée par Apideck
''' où le client entre ses identifiants QuickBooks. MngConsul ne voit jamais ces
''' identifiants ; il ne détient que sa propre clé d'API.
'''
''' Même approche que clsDreamPayments/clsSquare : HttpWebRequest + Newtonsoft,
''' pas de SDK, configuration lue depuis Web.config &lt;appSettings&gt;.
'''
''' Clés Web.config :
'''   Apideck.ApiKey     (clé d'API — À GARDER CÔTÉ SERVEUR)
'''   Apideck.AppId      (identifiant d'application, tableau de bord Apideck)
'''   Apideck.ServiceId  (optionnel — défaut « quickbooks » ; « sage… » plus tard)
'''   Apideck.BaseUrl    (optionnel — défaut https://unify.apideck.com)
''' </summary>
Public Class clsApideck

    Private Const DEFAULT_BASE As String = "https://unify.apideck.com"
    Private Const DEFAULT_SERVICE As String = "quickbooks"

    ' Le maximum accepté par Apideck. Descendre en dessous multiplie les
    ' allers-retours sans rien gagner.
    Private Const PAGE_SIZE As Integer = 200

    ' Une reprise peut ramener des milliers de factures : la valeur par défaut
    ' de 100 secondes ne suffit pas toujours.
    Private Const TIMEOUT_MS As Integer = 180000

    Private ReadOnly _consumerId As String

    ''' <param name="consumerId">
    ''' Le consommateur Apideck. C'est le CompanyGUID : chaque compagnie relie
    ''' sa propre source, et ne voit que la sienne.
    ''' </param>
    Public Sub New(consumerId As String)
        _consumerId = If(consumerId, "").Trim()
    End Sub

    ' =========================================================================
    ' CONFIGURATION
    ' =========================================================================

    Private Shared Function ApiKey() As String
        Dim v As String = If(ConfigurationManager.AppSettings("Apideck.ApiKey"), "").Trim()
        ' La console d'Apideck affiche parfois la clé préfixée : on l'accepte.
        If v.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) Then v = v.Substring(7).Trim()
        Return v
    End Function

    Private Shared Function AppId() As String
        Return If(ConfigurationManager.AppSettings("Apideck.AppId"), "").Trim()
    End Function

    ''' <summary>Le logiciel source chez Apideck. QuickBooks aujourd'hui ; Sage viendra ici.</summary>
    Public Shared Function ServiceId() As String
        Dim v As String = If(ConfigurationManager.AppSettings("Apideck.ServiceId"), "").Trim()
        Return If(String.IsNullOrEmpty(v), DEFAULT_SERVICE, v)
    End Function

    Private Shared Function BaseUrl() As String
        Dim v As String = If(ConfigurationManager.AppSettings("Apideck.BaseUrl"), "").Trim()
        Return If(String.IsNullOrEmpty(v), DEFAULT_BASE, v.TrimEnd("/"c))
    End Function

    ''' <summary>True si la clé d'API et l'App ID sont présents dans Web.config.</summary>
    Public Shared Function IsConfigured() As Boolean
        If clsApideckFake.Actif() Then Return True ' FAKE APIDECK — à retirer
        Return Not String.IsNullOrEmpty(ApiKey()) AndAlso Not String.IsNullOrEmpty(AppId())
    End Function

    ' =========================================================================
    ' VAULT — relier la source, une fois
    ' =========================================================================

    ''' <summary>
    ''' Ouvre une session Vault et retourne l'adresse de la page où le client
    ''' relie son QuickBooks. L'adresse expire : on en ouvre une à chaque fois
    ''' plutôt que de la conserver.
    ''' </summary>
    Public Function CreateVaultSession(companyName As String) As String
        ' FAKE APIDECK — à retirer : pas de Vault, on reste dans l'application.
        If clsApideckFake.Actif() Then Return Web.VirtualPathUtility.ToAbsolute("~/ImportApideck.aspx")

        Dim body As New JObject()
        body("consumer_metadata") = New JObject(New JProperty("account_name", If(companyName, "")))
        body("settings") = New JObject(New JProperty("unified_apis", New JArray("accounting")))

        Dim r As JObject = SendJson("/vault/sessions", "POST", body.ToString())
        Return JStr(r.SelectToken("data.session_uri"))
    End Function

    ''' <summary>
    ''' Les connexions comptables de ce consommateur. Vide : la compagnie n'a
    ''' pas encore relié sa source, et toute extraction échouerait en 404.
    ''' </summary>
    Public Function Connections() As JArray
        Dim r As JObject = SendJson("/vault/connections?api=accounting", "GET", Nothing)
        Return TryCast(r("data"), JArray)
    End Function

    ''' <summary>
    ''' True si une connexion est reliée et prête. Apideck marque l'état dans
    ''' « state » : seul CALLABLE permet de lire.
    ''' </summary>
    Public Function IsConnected() As Boolean
        Return IsConnected(ServiceId())
    End Function

    ''' <summary>Même chose pour un service précis (« quickbooks », « xero »…), sans changer Web.config (Importation 2).</summary>
    Public Function IsConnected(serviceVoulu As String) As Boolean
        If clsApideckFake.Actif() Then Return True ' FAKE APIDECK — à retirer
        Dim liste As JArray = Connections()
        If liste Is Nothing Then Return False

        For Each c As JToken In liste
            Dim service As String = JStr(c("service_id"))
            If service <> serviceVoulu Then Continue For
            If String.Equals(JStr(c("state")), "callable", StringComparison.OrdinalIgnoreCase) Then Return True
        Next
        Return False
    End Function

    ' =========================================================================
    ' LECTURE DES DONNÉES
    ' =========================================================================

    ''' <summary>
    ''' Toutes les pages d'une ressource comptable, en suivant le curseur
    ''' meta.cursors.next. <paramref name="filtres"/> est déjà encodé
    ''' (« &amp;filter[updated_since]=2026-01-01 »), ou vide.
    '''
    ''' <paramref name="plafond"/> arrête la lecture après ce nombre
    ''' d'enregistrements : une garde, pour qu'un compte volumineux ne fasse pas
    ''' expirer la page. 0 : pas de plafond.
    ''' </summary>
    Public Function ListAll(ressource As String, Optional filtres As String = "",
                            Optional plafond As Integer = 0) As JArray
        Dim tout As New JArray()
        Dim curseur As String = ""

        Do
            Dim url As String = "/accounting/" & ressource & "?limit=" & PAGE_SIZE & If(filtres, "")
            If curseur <> "" Then url &= "&cursor=" & Uri.EscapeDataString(curseur)

            Dim r As JObject = SendJson(url, "GET", Nothing)
            Dim lot As JArray = TryCast(r("data"), JArray)
            If lot Is Nothing OrElse lot.Count = 0 Then Exit Do

            For Each item As JToken In lot
                tout.Add(item)
            Next

            If plafond > 0 AndAlso tout.Count >= plafond Then Exit Do

            Dim suivant As String = JStr(r.SelectToken("meta.cursors.next"))
            If suivant = "" OrElse suivant = curseur Then Exit Do
            curseur = suivant
        Loop

        Return tout
    End Function

    ''' <summary>
    ''' Un seul objet plutôt qu'une liste : les informations de la société, un
    ''' rapport. C'est le contenu de « data ».
    ''' </summary>
    Public Function One(ressource As String, Optional filtres As String = "") As JToken
        Dim url As String = "/accounting/" & ressource
        If filtres <> "" Then url &= "?" & filtres.TrimStart("&"c)

        Dim r As JObject = SendJson(url, "GET", Nothing)
        Return r("data")
    End Function


    ''' <summary>
    ''' Les pièces jointes d'UN document. Apideck n'en donne pas de liste :
    ''' l'adresse est /accounting/attachments/{type}/{id}, donc un appel par
    ''' document. C'est lent par nature, et l'appelant doit le savoir.
    '''
    ''' Types acceptés, vérifiés en direct : invoice, bill, expense, credit-note,
    ''' bill-credit-note, journal-entry, quote. Les reçus de vente, les bons de
    ''' commande et les paiements sont refusés par Apideck.
    ''' </summary>
    Public Function AttachmentsOf(referenceType As String, referenceId As String) As JArray
        Dim url As String = "/accounting/attachments/" &
                            Uri.EscapeDataString(referenceType) & "/" &
                            Uri.EscapeDataString(referenceId)

        Dim r As JObject = SendJson(url, "GET", Nothing)
        Dim d As JArray = TryCast(r("data"), JArray)
        Return If(d, New JArray())
    End Function

    ''' <summary>
    ''' L'identifiant de la société chez QuickBooks (« realm »), lu dans la
    ''' connexion. Il est indispensable au passe-plat : toutes les adresses
    ''' natives d'Intuit le portent.
    ''' </summary>
    Public Function RealmId() As String
        If clsApideckFake.Actif() Then Return "fake-realm" ' FAKE APIDECK — à retirer
        Dim r As JObject = SendJson("/vault/connections/accounting/" & ServiceId(), "GET", Nothing)
        Dim d As JToken = r("data")
        If d Is Nothing Then Return ""

        Dim s As JToken = d("settings")
        If s Is Nothing OrElse s("realm_id") Is Nothing Then Return ""
        Return s("realm_id").ToString()
    End Function

    ''' <summary>
    ''' Le passe-plat : appelle l'API NATIVE de la source en réutilisant le jeton
    ''' de la connexion Apideck. Sert à ce que l'API unifiée ne couvre pas — les
    ''' conditions de paiement, par exemple, qu'Apideck ne cartographie pas.
    '''
    ''' Ce que ça coûte : la réponse est celle d'Intuit, pas d'Apideck. Aucune
    ''' traduction, aucune forme commune. Un connecteur différent — Sage — ne
    ''' répondra pas la même chose, alors on ne s'en sert que là où l'API unifiée
    ''' ne donne rien.
    ''' </summary>
    Public Function Proxy(downstreamUrl As String) As JObject
        Return SendJson("/proxy", "GET", Nothing, downstreamUrl)
    End Function

    ''' <summary>
    ''' Interroge QuickBooks dans son propre langage de requête et rend la liste
    ''' demandée. Le nom de l'entité sert aussi de clé dans la réponse : Intuit
    ''' répond { QueryResponse: { Term: [...] } }.
    ''' </summary>
    Public Function QuickBooksQuery(entite As String, realm As String) As JArray
        If realm = "" Then Throw New Exception("Apideck : identifiant de société QuickBooks introuvable.")

        Dim requete As String = Uri.EscapeDataString("select * from " & entite)
        Dim url As String = "https://quickbooks.api.intuit.com/v3/company/" & realm &
                            "/query?query=" & requete & "&minorversion=70"

        Dim r As JObject = Proxy(url)
        Dim reponse As JToken = r("QueryResponse")
        If reponse Is Nothing Then Return New JArray()

        ' Une réponse vide n'a pas la clé de l'entité : c'est normal, pas une
        ' erreur — la société n'a simplement rien de ce genre.
        Dim liste As JArray = TryCast(reponse(entite), JArray)
        Return If(liste, New JArray())
    End Function

    ' =========================================================================
    ' BAS NIVEAU HTTP
    ' =========================================================================

    ''' <summary>
    ''' Un appel à Apideck. Les 429 et les 5xx sont réessayés : une reprise
    ''' complète enchaîne des centaines d'appels, et un seul refus passager ne
    ''' doit pas la faire échouer.
    ''' </summary>
    Private Function SendJson(chemin As String, methode As String, jsonBody As String,
                              Optional aval As String = "") As JObject
        ' FAKE APIDECK — à retirer. Garde-fou : en mode simulé, rien ne part
        ' chez Apideck. Un appel qui arrive ici n'a pas de réponse simulée.
        If clsApideckFake.Actif() Then
            Throw New Exception("Apideck simulé (Apideck.Fake) : aucune réponse simulée pour " & methode & " " & chemin & If(aval <> "", " → " & aval, "") & ".")
        End If

        If Not IsConfigured() Then
            Journaliser(methode, chemin, aval, 1, 0, False, 0, "Apideck : clé d'API ou App ID manquants (Web.config appSettings).", jsonBody, Nothing, 0)
            Throw New Exception("Apideck : clé d'API ou App ID manquants (Web.config appSettings).")
        End If
        If String.IsNullOrEmpty(_consumerId) Then
            Journaliser(methode, chemin, aval, 1, 0, False, 0, "Apideck : aucun consommateur (la compagnie n'est pas identifiée).", jsonBody, Nothing, 0)
            Throw New Exception("Apideck : aucun consommateur (la compagnie n'est pas identifiée).")
        End If

        Const ESSAIS As Integer = 5
        Dim derniere As Exception = Nothing

        For essai As Integer = 1 To ESSAIS
            Try
                Return Envoyer(chemin, methode, jsonBody, aval, essai)

            Catch ex As ApideckHttpException
                derniere = ex
                ' Le 403 n'est pas toujours un refus de droits : QuickBooks
                ' limite à dix appels simultanés par société, et Apideck rend
                ' alors un 403. Une reprise qui enchaîne vingt-neuf ressources
                ' le déclenche systématiquement, donc on réessaie comme un 429.
                Dim recuperable As Boolean = (ex.CodeHttp = 429 OrElse ex.CodeHttp = 403 OrElse ex.CodeHttp >= 500)
                If Not recuperable OrElse essai = ESSAIS Then Throw

                ' Attente qui double à chaque essai : 2, 4, 8, 16 secondes.
                Threading.Thread.Sleep(CInt(Math.Pow(2, essai)) * 1000)
            End Try
        Next

        Throw If(derniere, New Exception("Apideck ne répond pas."))
    End Function

    Private Function Envoyer(chemin As String, methode As String, jsonBody As String,
                             Optional aval As String = "", Optional essai As Integer = 1) As JObject
        EnsureTls12()

        Dim req As HttpWebRequest = DirectCast(WebRequest.Create(BaseUrl() & chemin), HttpWebRequest)
        req.Method = methode
        req.Accept = "application/json"
        req.Timeout = TIMEOUT_MS
        req.ReadWriteTimeout = TIMEOUT_MS
        req.Headers.Add("Authorization", "Bearer " & ApiKey())
        req.Headers.Add("x-apideck-app-id", AppId())
        req.Headers.Add("x-apideck-consumer-id", _consumerId)

        ' Le service ne concerne que l'API comptable et le passe-plat : Vault
        ' couvre toutes les connexions du consommateur, et le préciser là ferait
        ' un 400.
        If chemin.StartsWith("/accounting/", StringComparison.OrdinalIgnoreCase) OrElse
           chemin.StartsWith("/proxy", StringComparison.OrdinalIgnoreCase) Then
            req.Headers.Add("x-apideck-service-id", ServiceId())
        End If

        ' Le passe-plat a besoin de savoir où aller : c'est tout ce qui le
        ' distingue d'un appel ordinaire.
        If aval <> "" Then req.Headers.Add("x-apideck-downstream-url", aval)

        ' T399 : chaque appel est inscrit au journal (T027ApideckLog), réussi ou non.
        Dim chrono As Diagnostics.Stopwatch = Diagnostics.Stopwatch.StartNew()
        Try
            If jsonBody IsNot Nothing Then
                req.ContentType = "application/json"
                Dim bytes As Byte() = Encoding.UTF8.GetBytes(jsonBody)
                req.ContentLength = bytes.Length
                Using rs As IO.Stream = req.GetRequestStream()
                    rs.Write(bytes, 0, bytes.Length)
                End Using
            End If

            Using resp As HttpWebResponse = DirectCast(req.GetResponse(), HttpWebResponse)
                Using sr As New IO.StreamReader(resp.GetResponseStream(), Encoding.UTF8)
                    Dim texte As String = sr.ReadToEnd()
                    Journaliser(methode, chemin, aval, essai, CInt(resp.StatusCode), True, chrono.ElapsedMilliseconds,
                                Nothing, jsonBody, texte, If(texte, "").Length)
                    If String.IsNullOrWhiteSpace(texte) Then Return New JObject()
                    Return JObject.Parse(texte)
                End Using
            End Using

        Catch ex As WebException
            Dim code As Integer = 0
            Dim corps As String = ""

            Dim rep As HttpWebResponse = TryCast(ex.Response, HttpWebResponse)
            If rep IsNot Nothing Then
                code = CInt(rep.StatusCode)
                Using sr As New IO.StreamReader(rep.GetResponseStream(), Encoding.UTF8)
                    corps = sr.ReadToEnd()
                End Using
            End If

            Dim message As String = MessageErreur(code, corps, ex.Message)
            Journaliser(methode, chemin, aval, essai, code, False, chrono.ElapsedMilliseconds,
                        If(code = 0, ex.Status.ToString() & " — " & ex.Message, message), jsonBody, corps, If(corps, "").Length)
            Throw New ApideckHttpException(message, code)

        Catch ex As Newtonsoft.Json.JsonReaderException
            ' Réponse 2xx qui n'est pas du JSON : déjà inscrite comme reçue, on note l'échec de lecture
            Journaliser(methode, chemin, aval, essai, 0, False, chrono.ElapsedMilliseconds,
                        "Réponse illisible (pas du JSON) : " & ex.Message, jsonBody, Nothing, 0)
            Throw
        End Try
    End Function

    ' =========================================================================
    ' JOURNAL (T399) — consulté dans la console d'admin (wbfApideckLog)
    ' =========================================================================

    Private Const EXTRAIT_MAX As Integer = 4000

    ''' <summary>
    ''' Inscrit un appel au journal T027ApideckLog (s1020). Ne lève jamais :
    ''' un journal en panne ne doit pas empêcher une reprise. Jamais la clé
    ''' d'API : seuls les corps (extraits) sont gardés, pas les en-têtes.
    ''' </summary>
    Private Sub Journaliser(methode As String, chemin As String, aval As String, essai As Integer,
                            statut As Integer, succes As Boolean, dureeMs As Long,
                            erreur As String, requete As String, reponse As String, tailleReponse As Integer)
        Try
            Dim company As Object = DBNull.Value
            Dim g As Guid
            If Guid.TryParse(_consumerId, g) Then company = g

            Dim userId As Object = DBNull.Value
            Dim page As Object = DBNull.Value
            Dim ctx As Web.HttpContext = Web.HttpContext.Current
            If ctx IsNot Nothing Then
                Try
                    If ctx.Session IsNot Nothing AndAlso ctx.Session("UserId") IsNot Nothing Then userId = Convert.ToInt32(ctx.Session("UserId"))
                Catch
                End Try
                Try
                    page = ctx.Request.Path
                Catch
                End Try
            End If

            Dim service As Object = DBNull.Value
            If chemin.StartsWith("/accounting/", StringComparison.OrdinalIgnoreCase) OrElse
               chemin.StartsWith("/proxy", StringComparison.OrdinalIgnoreCase) Then service = ServiceId()

            Using cn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s1020InsertApideckLog", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@CompanyGUID", company)
                    cmd.Parameters.AddWithValue("@UserId", userId)
                    cmd.Parameters.AddWithValue("@Page", page)
                    cmd.Parameters.AddWithValue("@Methode", If(methode, "GET"))
                    cmd.Parameters.AddWithValue("@Chemin", If(chemin, ""))
                    cmd.Parameters.AddWithValue("@ServiceId", service)
                    cmd.Parameters.AddWithValue("@Aval", If(String.IsNullOrEmpty(aval), CObj(DBNull.Value), aval))
                    cmd.Parameters.AddWithValue("@Essai", essai)
                    cmd.Parameters.AddWithValue("@StatutHttp", statut)
                    cmd.Parameters.AddWithValue("@Succes", succes)
                    cmd.Parameters.AddWithValue("@DureeMs", CInt(Math.Min(dureeMs, Integer.MaxValue)))
                    cmd.Parameters.AddWithValue("@Erreur", If(String.IsNullOrEmpty(erreur), CObj(DBNull.Value), erreur))
                    cmd.Parameters.AddWithValue("@Requete", Extrait(requete))
                    cmd.Parameters.AddWithValue("@Reponse", Extrait(reponse))
                    cmd.Parameters.AddWithValue("@TailleReponse", tailleReponse)
                    cn.Open()
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch
            ' Le journal ne doit jamais faire échouer l'appel à Apideck.
        End Try
    End Sub

    Private Shared Function Extrait(s As String) As Object
        If String.IsNullOrEmpty(s) Then Return DBNull.Value
        Return If(s.Length > EXTRAIT_MAX, s.Substring(0, EXTRAIT_MAX - 1) & "…", s)
    End Function

    ''' <summary>
    ''' Le message d'Apideck, traduit en quelque chose d'actionnable. Le code
    ''' brut ne dit jamais quoi faire ; ces quatre-là reviennent tout le temps.
    ''' </summary>
    Private Shared Function MessageErreur(code As Integer, corps As String, defaut As String) As String
        Dim detail As String = corps
        Dim suivi As String = ""

        Try
            Dim j As JObject = JObject.Parse(corps)
            Dim msg As String = JStr(j("message"))
            If msg = "" Then msg = JStr(j("error"))
            Dim det As String = JStr(j("detail"))
            If msg <> "" Then detail = msg & If(det <> "" AndAlso det <> msg, " — " & det, "")
            Dim ref As String = JStr(j("ref"))
            If ref <> "" Then suivi = " [réf. " & ref & "]"
        Catch
            ' Le corps n'est pas du JSON : on le garde tel quel.
        End Try

        If String.IsNullOrWhiteSpace(detail) Then detail = defaut
        If detail.Length > 600 Then detail = detail.Substring(0, 600) & "…"

        Select Case code
            Case 401
                Return "Apideck refuse la clé d'API ou l'App ID (401). Vérifiez-les dans le tableau de bord Apideck, section Configuration ▸ API Keys." & suivi
            Case 402
                Return "Apideck demande un forfait couvrant cette opération (402). " & detail & suivi
            Case 404
                Return "Introuvable (404) : " & detail & " — la ressource n'existe pas pour ce connecteur, ou la compagnie n'a pas encore relié sa comptabilité." & suivi
            Case 422
                Return "Apideck refuse la demande (422) : " & detail & suivi
            Case Else
                Return "Erreur Apideck (" & code & ") : " & detail & suivi
        End Select
    End Function

    Private Shared Sub EnsureTls12()
        ' Requis sous .NET Framework pour les endpoints HTTPS modernes.
        ServicePointManager.SecurityProtocol = ServicePointManager.SecurityProtocol Or SecurityProtocolType.Tls12
    End Sub

    Private Shared Function JStr(t As JToken) As String
        If t Is Nothing OrElse t.Type = JTokenType.Null Then Return ""
        Return t.ToString()
    End Function

End Class

''' <summary>
''' Une erreur HTTP d'Apideck, avec son code : c'est lui qui décide si l'appel
''' se réessaie ou s'abandonne.
''' </summary>
Public Class ApideckHttpException
    Inherits Exception

    Public ReadOnly Property CodeHttp As Integer

    Public Sub New(message As String, codeHttp As Integer)
        MyBase.New(message)
        Me.CodeHttp = codeHttp
    End Sub
End Class

' =============================================================================
' FAKE APIDECK — TEMPORAIRE, À RETIRER quand l'essai Apideck sera renouvelé.
'
' Pour retirer : supprimer cette classe, les lignes marquées « FAKE APIDECK »
' (clsApideck.vb, ApideckExtraction.vb), la clé Apideck.Fake de Web.config,
' le dossier App_Data\ApideckFake et Database\Outils\ExporterApideckFake.ps1.
' =============================================================================

''' <summary>
''' Apideck simulé. Activé par &lt;add key="Apideck.Fake" value="true" /&gt;.
'''
''' Rejoue une extraction réelle déjà faite : chaque ressource est lue dans
''' App_Data\ApideckFake\{ressource}.json — le même JArray que l'extraction
''' avait déposé dans staging.ConnecteurDonnee. Le versement (Verser…) reçoit
''' donc exactement ce qu'il recevait d'Apideck. Les fichiers se produisent avec
''' Database\Outils\ExporterApideckFake.ps1.
'''
''' Une ressource sans fichier rend une liste vide. Aucun appel ne sort.
''' </summary>
Public NotInheritable Class clsApideckFake

    Private Sub New()
    End Sub

    Public Shared Function Actif() As Boolean
        Return String.Equals(If(ConfigurationManager.AppSettings("Apideck.Fake"), "").Trim(), "true",
                             StringComparison.OrdinalIgnoreCase)
    End Function

    ''' <summary>Apideck.FakeDossier, ou ~/App_Data/ApideckFake par défaut.</summary>
    Public Shared Function Dossier() As String
        Dim v As String = If(ConfigurationManager.AppSettings("Apideck.FakeDossier"), "").Trim()
        If v = "" Then v = "~/App_Data/ApideckFake"
        If Not v.StartsWith("~") Then Return v

        ' MapPath fonctionne aussi hors requête (extraction en fond).
        Dim chemin As String = Web.Hosting.HostingEnvironment.MapPath(v)
        If String.IsNullOrEmpty(chemin) Then
            chemin = IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, v.TrimStart("~"c, "/"c).Replace("/"c, IO.Path.DirectorySeparatorChar))
        End If
        Return chemin
    End Function

    ''' <summary>Les enregistrements simulés d'une ressource (« customers », « invoices »…).</summary>
    Public Shared Function Lire(ressource As String) As JArray
        Dim fichier As String = IO.Path.Combine(Dossier(), ressource & ".json")
        If Not IO.File.Exists(fichier) Then Return New JArray()

        Dim t As JToken = JToken.Parse(IO.File.ReadAllText(fichier, Encoding.UTF8))
        If t.Type = JTokenType.Array Then Return DirectCast(t, JArray)

        ' Tolère une réponse Apideck copiée telle quelle : { "data": [...] }.
        Dim d As JToken = If(t.Type = JTokenType.Object, t("data"), Nothing)
        If d IsNot Nothing AndAlso d.Type = JTokenType.Array Then Return DirectCast(d, JArray)
        If d IsNot Nothing AndAlso d.Type = JTokenType.Object Then Return New JArray(d)
        Return New JArray(t)
    End Function

End Class
