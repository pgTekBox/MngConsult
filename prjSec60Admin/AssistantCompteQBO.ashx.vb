Imports System.Data
Imports System.Globalization
Imports System.IO
Imports System.Text
Imports System.Threading.Tasks
Imports System.Web.Script.Serialization
Imports System.Web.SessionState

''' <summary>
''' Le bouton « ✨ Assistant » d'un compte QuickBooks candidat au plan par défaut
''' (Sec60Admin › Plan comptable par défaut › Ajouter depuis un import QuickBooks) :
''' POST { "stagingId": n, "companyGuid": "…" } → { "titre", "reponse", "cout" }.
''' La fiche du compte source (s0870, chez la compagnie d'origine) et le PLAN PAR
''' DÉFAUT (s0764 sur la compagnie modèle) partent au modèle avec le prompt
''' PROMPT_ASSISTANT_COMPTE de l'ERP, complété du contexte « personnel qui décide
''' s'il entre dans le plan de tout le monde ». Session administrateur obligatoire.
''' </summary>
Public Class AssistantCompteQBOHandler
    Inherits HttpTaskAsyncHandler
    Implements IRequiresSessionState

    Private Shared ReadOnly ModelGUID As Guid = New Guid("00000000-0000-0000-0000-000000000001")

    Public Overrides Async Function ProcessRequestAsync(context As HttpContext) As Task
        context.Response.ContentType = "application/json; charset=utf-8"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Dim js As New JavaScriptSerializer() With {.MaxJsonLength = Integer.MaxValue}

        Dim adminId As Integer = 0
        Try
            If context.Session("AdminId") IsNot Nothing Then adminId = Convert.ToInt32(context.Session("AdminId"))
        Catch
        End Try
        If adminId <= 0 Then
            context.Response.StatusCode = 403
            context.Response.Write(js.Serialize(New With {.erreur = "Ouvrez une session d'administration pour utiliser l'assistant."}))
            Return
        End If
        If context.Request.HttpMethod <> "POST" Then
            context.Response.StatusCode = 405
            context.Response.Write(js.Serialize(New With {.erreur = "POST attendu."}))
            Return
        End If
        Dim utilisateur As String = Convert.ToString(context.Session("AdminEmail"))
        If utilisateur = "" Then utilisateur = "sec60admin"

        Dim stagingId As Integer = 0
        Dim companyGuid As Guid = Guid.Empty
        Try
            Using lecteur As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                Dim corps = TryCast(js.DeserializeObject(lecteur.ReadToEnd()), Dictionary(Of String, Object))
                If corps IsNot Nothing Then
                    If corps.ContainsKey("stagingId") Then stagingId = Convert.ToInt32(corps("stagingId"))
                    If corps.ContainsKey("companyGuid") Then Guid.TryParse(Convert.ToString(corps("companyGuid")), companyGuid)
                End If
            End Using
        Catch
            stagingId = 0
        End Try
        If stagingId = 0 OrElse companyGuid = Guid.Empty Then
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.erreur = "Compte ou compagnie manquant."}))
            Return
        End If

        Try
            Dim d As DataSet = clsAssistantCompteQBO.Ds("s0870GetImportCompteFiche", clsAssistantCompteQBO.P("@CompanyGUID", companyGuid), clsAssistantCompteQBO.P("@StagingId", stagingId))
            If d.Tables.Count = 0 OrElse d.Tables(0).Rows.Count = 0 Then
                context.Response.StatusCode = 404
                context.Response.Write(js.Serialize(New With {.erreur = "Compte introuvable dans la préparation de cette compagnie."}))
                Return
            End If
            Dim f As DataRow = d.Tables(0).Rows(0)
            Dim decision As DataRow = If(d.Tables.Count > 1 AndAlso d.Tables(1).Rows.Count > 0, d.Tables(1).Rows(0), Nothing)

            ' ---- la fiche du compte QuickBooks ----
            Dim fiche As New StringBuilder()
            fiche.AppendLine("=== LE COMPTE DE L'ANCIEN LOGICIEL (QuickBooks) ===")
            Ligne(fiche, "Logiciel d'origine", Txt(f, "SystemeSource"))
            Ligne(fiche, "Nom retenu", Txt(f, "Nom"))
            Ligne(fiche, "Nom complet (avec le compte parent)", Txt(f, "NomComplet"))
            Ligne(fiche, "Nom dans la source", Txt(f, "NomSource"))
            Ligne(fiche, "Numéro dans la source", Txt(f, "CompteSource"))
            Ligne(fiche, "Nature normalisée", Txt(f, "TypeNormalise"))
            Ligne(fiche, "Type dans la source", Txt(f, "TypeSource"))
            Ligne(fiche, "Sous-type dans la source", Txt(f, "SousTypeSource"))
            Ligne(fiche, "Sens normal du solde", Txt(f, "Sens"))
            If Not IsDBNull(f("Solde")) Then Ligne(fiche, "Solde chez la compagnie d'origine", Convert.ToDecimal(f("Solde")).ToString("N2", CultureInfo.GetCultureInfo("fr-CA")) & " $")
            Ligne(fiche, "Origine", If(Txt(f, "Origine") = "AJOUTE", "ajouté par l'entreprise après l'ouverture du dossier (nom probablement propre à elle)", If(Txt(f, "Origine") = "DEFAUT", "créé par défaut par QuickBooks (compte générique)", "")))
            Ligne(fiche, "Sous-compte", If(Not IsDBNull(f("SousCompte")) AndAlso Convert.ToBoolean(f("SousCompte")), "oui", "non"))
            Ligne(fiche, "Description saisie dans la source", Txt(f, "DescriptionSource"))
            If decision IsNot Nothing Then
                fiche.AppendLine()
                fiche.AppendLine("=== LA DÉCISION PRISE PAR LA COMPAGNIE D'ORIGINE ===")
                Ligne(fiche, "Action", Txt(decision, "Action") & " (aucun équivalent trouvé dans son plan)")
                Ligne(fiche, "Compte cible", (Txt(decision, "CompteCible") & " " & Txt(decision, "NomCible")).Trim())
                Ligne(fiche, "Nature cible", Txt(decision, "TypeCible"))
            End If

            ' ---- le plan par défaut (compagnie modèle) ----
            Dim plan As New StringBuilder()
            plan.AppendLine("=== LE PLAN COMPTABLE PAR DÉFAUT DE 60SEC-AI (numéro | nom | nom anglais | nature | classe | sous-classe | sens | description) ===")
            Dim dp As DataSet = clsAssistantCompteQBO.Ds("s0764GetPlanPourIA", clsAssistantCompteQBO.P("@CompanyGUID", ModelGUID))
            If dp.Tables.Count > 0 Then
                For Each r As DataRow In dp.Tables(0).Rows
                    plan.AppendLine(String.Join(" | ", Txt(r, "Compte"), Txt(r, "Nom"), Txt(r, "NomEn"), Txt(r, "Nature"), Txt(r, "ClasseParent"), Txt(r, "Classe"), Txt(r, "Sens"), Txt(r, "Description")))
                Next
            End If

            Dim contexte As String =
                "CONTEXTE PARTICULIER : tu parles au personnel de 60Sec-AI, pas à un client. Il décide si ce compte QuickBooks doit entrer " &
                "dans le PLAN COMPTABLE PAR DÉFAUT (celui que reçoit chaque nouvelle compagnie). Le plan fourni ci-dessous est ce plan par défaut, " &
                "pas celui d'une compagnie. Dans « Où le ranger », dis clairement : soit LIER à un compte existant du plan par défaut (lequel, et " &
                "pourquoi c'est le même), soit AJOUTER un nouveau compte (dans quelle sous-classe, sous quel nom générique, et pourquoi aucun compte " &
                "existant ne convient). Termine par un avis en une phrase : « Recommandation : ajouter / lier à NNNN / ne pas ajouter (nom propre à " &
                "l'entreprise) »."
            Dim systeme As String = clsAssistantCompteQBO.PromptNomme("PROMPT_ASSISTANT_COMPTE") & vbLf & vbLf & contexte & vbLf & vbLf & plan.ToString()
            Dim titre As String = Txt(f, "NomSource")
            If titre = "" Then titre = Txt(f, "Nom")
            Dim question As String = fiche.ToString() & vbLf & "Explique ce compte le plus complètement possible et dis s'il doit entrer dans le plan par défaut, et où."

            Dim rep = Await clsAssistantCompteQBO.RepondreAsync(companyGuid, utilisateur, systeme, question, "Assistant compte QBO (plan par défaut) : " & titre)
            context.Response.Write(js.Serialize(New With {.titre = titre, .reponse = rep.Texte, .cout = clsAssistantCompteQBO.CoutDuMois(companyGuid)}))
        Catch ex As SaisieAssistantException
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.erreur = ex.Message}))
        Catch ex As Exception
            context.Response.StatusCode = 502
            context.Response.Write(js.Serialize(New With {.erreur = "L'assistant n'a pas pu répondre : " & ex.Message}))
        End Try
    End Function

    Private Shared Function Txt(r As DataRow, col As String) As String
        If r Is Nothing OrElse Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return ""
        Return Convert.ToString(r(col)).Trim()
    End Function

    Private Shared Sub Ligne(sb As StringBuilder, libelle As String, valeur As String)
        If String.IsNullOrWhiteSpace(valeur) Then Return
        sb.Append("- ").Append(libelle).Append(" : ").AppendLine(valeur.Trim())
    End Sub

End Class
