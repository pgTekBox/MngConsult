Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text
Imports System.Threading.Tasks
Imports System.Web.Script.Serialization

''' <summary>
''' L'assistant IA de la console, pour un compte QuickBooks candidat au plan par
''' défaut : la version courte de clsAssistantIA de l'ERP (un prompt système, une
''' question, la réponse du modèle), journalisée dans T147AssistantConversation
''' (s0859/s0860) sous la compagnie d'où vient le compte, section « importation ».
''' La clé et les prompts sont ceux de l'ERP (T0000Parameters via s0032).
'''
''' Vit dans MyClass, pas dans App_Code : App_Code est compilé par ASP.NET sans
''' System.Net.Http (le HttpClient y serait introuvable — piège connu de l'ERP).
''' </summary>
Public NotInheritable Class clsAssistantCompteQBO
    Public Const Modele As String = "gpt-4.1-mini"
    Private Const Url As String = "https://api.openai.com/v1/responses"

    Public Class Reponse
        Public Property Texte As String
        Public Property InputTokens As Integer
        Public Property OutputTokens As Integer
        Public ReadOnly Property CoutUsd As Decimal
            Get
                Return (InputTokens * 0.0000004D) + (OutputTokens * 0.0000016D)
            End Get
        End Property
    End Class

    Private Sub New()
    End Sub

    Friend Shared ReadOnly Property ConnectionString As String
        Get
            Return ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    Friend Shared Function Ds(proc As String, ParamArray params As SqlParameter()) As DataSet
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(proc, conn) With {.CommandType = CommandType.StoredProcedure, .CommandTimeout = 60}
                For Each prm As SqlParameter In params
                    cmd.Parameters.Add(prm)
                Next
                Dim da As New SqlDataAdapter(cmd)
                Dim d As New DataSet()
                da.Fill(d)
                Return d
            End Using
        End Using
    End Function

    Friend Shared Sub Exec(proc As String, ParamArray params As SqlParameter())
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand(proc, conn) With {.CommandType = CommandType.StoredProcedure, .CommandTimeout = 60}
                For Each prm As SqlParameter In params
                    cmd.Parameters.Add(prm)
                Next
                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Friend Shared Function P(nom As String, valeur As Object) As SqlParameter
        Return New SqlParameter(nom, If(valeur, DBNull.Value))
    End Function

    Private Shared Function Parametre(nom As String) As String
        Dim d As DataSet = Ds("s0032GetPromptOpenAPI", P("@Parameter", nom))
        If d.Tables.Count = 0 OrElse d.Tables(0).Rows.Count = 0 Then Return ""
        Return Convert.ToString(d.Tables(0).Rows(0)(0)).Trim()
    End Function

    Private Shared Function Cle() As String
        Dim v As String = Parametre("CHATGPT")
        If v.Length = 0 Then Throw New SaisieAssistantException("La clé d'accès à l'IA (paramètre CHATGPT) n'est pas configurée.")
        Return v
    End Function

    ''' <summary>Un prompt nommé de T0000Parameters (vide → erreur de configuration à montrer).</summary>
    Public Shared Function PromptNomme(nom As String) As String
        Dim v As String = Parametre(nom)
        If v.Length = 0 Then Throw New SaisieAssistantException("Le prompt " & nom & " n'est pas configuré (Prompts OpenAI).")
        Return v
    End Function

    ''' <summary>Un appel isolé : prompt système + question → réponse, journalisée avec son coût.</summary>
    Public Shared Async Function RepondreAsync(companyGuid As Guid, utilisateur As String, systeme As String, question As String,
                                              journalQuestion As String, Optional maxTokens As Integer = 1500) As Task(Of Reponse)
        Dim chrono = Diagnostics.Stopwatch.StartNew()
        Dim journalId As Integer = 0
        Try
            Dim dj As DataSet = Ds("s0859LogAssistantQuestion", P("@CompanyGUID", companyGuid), P("@Utilisateur", utilisateur),
                                   P("@Langue", "fr"), P("@Section", "importation"), P("@Question", If(journalQuestion, question)), P("@Modele", Modele))
            If dj.Tables.Count > 0 AndAlso dj.Tables(0).Rows.Count > 0 Then journalId = Convert.ToInt32(dj.Tables(0).Rows(0)("Id"))
        Catch
            journalId = 0
        End Try

        Try
            Dim entrees As New List(Of Object)()
            entrees.Add(New Dictionary(Of String, Object) From {{"role", "system"}, {"content", systeme}})
            entrees.Add(New Dictionary(Of String, Object) From {{"role", "user"}, {"content", question}})

            Dim js As New JavaScriptSerializer() With {.MaxJsonLength = Integer.MaxValue}
            Dim charge As String = js.Serialize(New Dictionary(Of String, Object) From {
                {"model", Modele}, {"input", entrees}, {"max_output_tokens", maxTokens}})

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
            If journalId > 0 Then
                Exec("s0860UpdateAssistantReponse", P("@Id", journalId), P("@Reponse", r.Texte), P("@InputTokens", r.InputTokens),
                     P("@OutputTokens", r.OutputTokens), P("@CoutUsd", r.CoutUsd), P("@DureeMs", CInt(chrono.ElapsedMilliseconds)), P("@Erreur", Nothing))
            End If
            Return r
        Catch ex As Exception
            chrono.Stop()
            If journalId > 0 Then
                Try
                    Exec("s0860UpdateAssistantReponse", P("@Id", journalId), P("@Reponse", Nothing), P("@InputTokens", 0), P("@OutputTokens", 0),
                         P("@CoutUsd", 0D), P("@DureeMs", CInt(chrono.ElapsedMilliseconds)), P("@Erreur", Gauche(ex.Message, 1000)))
                Catch
                End Try
            End If
            Throw
        End Try
    End Function

    Private Shared Function Valeur(d As Dictionary(Of String, Object), cle As String) As Object
        Dim v As Object = Nothing
        If d IsNot Nothing AndAlso d.TryGetValue(cle, v) Then Return v
        Return Nothing
    End Function

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

    ''' <summary>Coût cumulé des questions de la compagnie ce mois-ci.</summary>
    Public Shared Function CoutDuMois(companyGuid As Guid) As Decimal
        Try
            Dim d As DataSet = Ds("s0861GetAssistantCoutMois", P("@CompanyGUID", companyGuid))
            If d.Tables.Count = 0 OrElse d.Tables(0).Rows.Count = 0 Then Return 0D
            Return Convert.ToDecimal(d.Tables(0).Rows(0)("CoutUsd"))
        Catch
            Return 0D
        End Try
    End Function

End Class

''' <summary>Une erreur à montrer telle quelle (saisie ou configuration), pas une panne.</summary>
Public Class SaisieAssistantException
    Inherits Exception
    Public Sub New(message As String)
        MyBase.New(message)
    End Sub
End Class
