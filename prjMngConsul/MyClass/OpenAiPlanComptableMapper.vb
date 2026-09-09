Imports Newtonsoft.Json.Linq
Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text
Imports System.Threading.Tasks

''' <summary>Une correspondance proposée par le modèle, avant tout contrôle.</summary>
Public Class PropositionCompte
    Public Property CleSource As String
    Public Property Compte As String
    Public Property Confiance As Integer
    Public Property Raison As String
End Class

Public Class ResultatMappingIA
    Public Property Propositions As New List(Of PropositionCompte)
    Public Property Appels As Integer
    Public Property InputTokens As Integer
    Public Property OutputTokens As Integer

    ''' <summary>
    ''' Coût estimé, aux tarifs gpt-4.1-mini. C'est une estimation : elle sert
    ''' à ce que personne ne découvre la facture après coup.
    ''' </summary>
    Public ReadOnly Property CoutUsd As Decimal
        Get
            Return (InputTokens * 0.00000015D) + (OutputTokens * 0.0000006D)
        End Get
    End Property
End Class

''' <summary>
''' Soumet au modèle les comptes de l'ancien logiciel et le plan de la
''' compagnie, et rapporte la correspondance qu'il propose.
'''
''' Cette classe ne fait qu'interroger et lire la réponse. Elle ne décide
''' rien : c'est la procédure s0761EnregistrerPropositionsIA qui vérifie que
''' les comptes rendus existent et que leur nature s'accorde, et l'écran de
''' correspondance qui laisse l'utilisateur trancher.
''' </summary>
Public Class OpenAiPlanComptableMapper

    Private Const MODELE As String = "gpt-4.1-mini"
    Private Const URL As String = "https://api.openai.com/v1/responses"

    ''' <summary>
    ''' Les comptes d'origine partent par paquets. Un plan de 500 comptes dans
    ''' un seul appel donne des réponses tronquées ou bâclées ; par tranches,
    ''' le modèle reste appliqué et un paquet raté n'emporte pas le reste.
    ''' </summary>
    Private Const TAILLE_PAQUET As Integer = 25

    Private ReadOnly _http As HttpClient

    Public Sub New(apiKey As String)
        _http = New HttpClient()
        _http.Timeout = TimeSpan.FromMinutes(5)
        _http.DefaultRequestHeaders.Authorization =
            New AuthenticationHeaderValue("Bearer", apiKey)
    End Sub

    ''' <summary>
    ''' <paramref name="source"/> : les comptes à reprendre, sous la forme
    ''' « clé | nom | nature | type d'origine ».
    ''' <paramref name="plan"/> : le plan de destination, déjà mis en forme.
    ''' </summary>
    Public Async Function ProposerAsync(prompt As String,
                                        source As List(Of String),
                                        plan As String) As Task(Of ResultatMappingIA)

        Dim res As New ResultatMappingIA()

        For depart As Integer = 0 To source.Count - 1 Step TAILLE_PAQUET
            Dim paquet = source.Skip(depart).Take(TAILLE_PAQUET).ToList()

            Dim demande As New StringBuilder()
            demande.AppendLine(prompt)
            demande.AppendLine()
            demande.AppendLine("=== LISTE A — comptes à reprendre ===")
            demande.AppendLine("clé | nom | nature | type d'origine")
            For Each l In paquet
                demande.AppendLine(l)
            Next
            demande.AppendLine()
            demande.AppendLine("=== LISTE B — plan comptable de destination ===")
            demande.AppendLine("numéro | nom | nom anglais | nature | classe")
            demande.AppendLine(plan)

            Dim brut = Await AppelerAsync(demande.ToString(), res).ConfigureAwait(False)
            res.Appels += 1

            For Each p In Lire(brut)
                res.Propositions.Add(p)
            Next
        Next

        Return res
    End Function

    ''' <summary>Un appel, et la comptabilisation des jetons consommés.</summary>
    Private Async Function AppelerAsync(texte As String, res As ResultatMappingIA) As Task(Of String)

        Dim payload = New JObject(
            New JProperty("model", MODELE),
            New JProperty("input", New JArray(
                New JObject(
                    New JProperty("role", "user"),
                    New JProperty("content", New JArray(
                        New JObject(
                            New JProperty("type", "input_text"),
                            New JProperty("text", texte)
                        )
                    ))
                )
            ))
        ).ToString()

        Dim contenu = New StringContent(payload, Encoding.UTF8, "application/json")
        Dim reponse = Await _http.PostAsync(URL, contenu).ConfigureAwait(False)
        Dim txt = Await reponse.Content.ReadAsStringAsync().ConfigureAwait(False)

        If Not reponse.IsSuccessStatusCode Then
            Throw New Exception("OpenAI : " & txt)
        End If

        Dim jo = JObject.Parse(txt)

        If jo("usage") IsNot Nothing Then
            res.InputTokens += CInt(jo("usage")("input_tokens"))
            res.OutputTokens += CInt(jo("usage")("output_tokens"))
        End If

        Return Convert.ToString(jo("output")(0)("content")(0)("text"))
    End Function

    ''' <summary>
    ''' Le modèle répond parfois dans un bloc de code, malgré la consigne. On
    ''' retient ce qui va du premier crochet au dernier ; ce qui n'est pas du
    ''' JSON exploitable est abandonné sans bruit — le paquet suivant, lui,
    ''' passera peut-être.
    ''' </summary>
    Private Shared Function Lire(brut As String) As List(Of PropositionCompte)
        Dim liste As New List(Of PropositionCompte)
        If String.IsNullOrWhiteSpace(brut) Then Return liste

        Dim debut = brut.IndexOf("["c)
        Dim fin = brut.LastIndexOf("]"c)
        If debut < 0 OrElse fin <= debut Then Return liste

        Try
            Dim tableau = JArray.Parse(brut.Substring(debut, fin - debut + 1))

            For Each e In tableau
                Dim cle = Convert.ToString(e("CleSource"))
                Dim compte = Convert.ToString(e("Compte"))
                If String.IsNullOrWhiteSpace(cle) OrElse String.IsNullOrWhiteSpace(compte) Then Continue For

                Dim conf As Integer = 0
                Integer.TryParse(Convert.ToString(e("Confiance")), conf)

                liste.Add(New PropositionCompte With {
                    .CleSource = cle.Trim(),
                    .Compte = compte.Trim(),
                    .Confiance = conf,
                    .Raison = Convert.ToString(e("Raison"))
                })
            Next

        Catch
            ' Réponse illisible : ce paquet ne donne rien.
        End Try

        Return liste
    End Function

End Class
