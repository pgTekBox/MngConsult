Imports System.Data
Imports System.Globalization
Imports System.IO
Imports System.Text
Imports System.Threading.Tasks
Imports System.Web.Script.Serialization
Imports System.Web.SessionState

''' <summary>
''' Le bouton « Assistant » d'une ligne de la Correspondance des comptes :
''' POST { "stagingId": n } → { "titre": "…", "reponse": "…", "cout": 0.0021 }.
''' La fiche du compte source (s0870) et le plan comptable de la compagnie (s0764)
''' partent au modèle avec le prompt PROMPT_ASSISTANT_COMPTE ; la réponse est
''' journalisée (section « importation ») comme les autres questions.
''' Session ouverte avec une compagnie obligatoire ; le compte doit lui appartenir.
''' </summary>
Public Class AssistantCompteHandler
    Inherits HttpTaskAsyncHandler
    Implements IRequiresSessionState

    Public Overrides Async Function ProcessRequestAsync(context As HttpContext) As Task
        context.Response.ContentType = "application/json; charset=utf-8"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Dim js As New JavaScriptSerializer() With {.MaxJsonLength = Integer.MaxValue}

        Dim userId As Integer = 0
        Dim companyGuid As Guid = Guid.Empty
        Try
            If context.Session("UserId") IsNot Nothing Then userId = Convert.ToInt32(context.Session("UserId"))
            If context.Session("Company") IsNot Nothing Then companyGuid = CType(context.Session("Company"), Guid)
        Catch
        End Try
        Dim langue As String = TryCast(context.Session("Lang"), String)
        If langue <> "en" AndAlso langue <> "es" Then langue = "fr"
        Dim utilisateur As String = Convert.ToString(context.Session("UserEmail"))

        If userId = 0 OrElse companyGuid = Guid.Empty Then
            context.Response.StatusCode = 403
            context.Response.Write(js.Serialize(New With {.erreur = clsAssistantIA.Tr(langue, "Ouvrez une session pour utiliser l'assistant.", "Sign in to use the assistant.", "Inicie sesión para usar el asistente.")}))
            Return
        End If
        If context.Request.HttpMethod <> "POST" Then
            context.Response.StatusCode = 405
            context.Response.Write(js.Serialize(New With {.erreur = "POST attendu."}))
            Return
        End If

        Dim stagingId As Integer = 0
        Try
            Using lecteur As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                Dim corps = TryCast(js.DeserializeObject(lecteur.ReadToEnd()), Dictionary(Of String, Object))
                If corps IsNot Nothing AndAlso corps.ContainsKey("stagingId") Then stagingId = Convert.ToInt32(corps("stagingId"))
            End Using
        Catch
            stagingId = 0
        End Try

        Try
            Dim d As DataSet = clsAssistantIA.Ds("s0870GetImportCompteFiche", clsAssistantIA.P("@CompanyGUID", companyGuid), clsAssistantIA.P("@StagingId", stagingId))
            If d.Tables.Count = 0 OrElse d.Tables(0).Rows.Count = 0 Then
                context.Response.StatusCode = 404
                context.Response.Write(js.Serialize(New With {.erreur = clsAssistantIA.Tr(langue, "Compte introuvable dans la préparation.", "Account not found in staging.", "Cuenta no encontrada en la preparación.")}))
                Return
            End If
            Dim f As DataRow = d.Tables(0).Rows(0)
            Dim decision As DataRow = If(d.Tables.Count > 1 AndAlso d.Tables(1).Rows.Count > 0, d.Tables(1).Rows(0), Nothing)

            ' ---- la fiche, en clair, pour le modèle ----
            Dim fiche As New StringBuilder()
            fiche.AppendLine("=== LE COMPTE DE L'ANCIEN LOGICIEL ===")
            Ligne(fiche, "Logiciel d'origine", Txt(f, "SystemeSource"))
            Ligne(fiche, "Numéro retenu", Txt(f, "Compte"))
            Ligne(fiche, "Nom retenu", Txt(f, "Nom"))
            Ligne(fiche, "Nom complet (avec le compte parent)", Txt(f, "NomComplet"))
            Ligne(fiche, "Numéro dans la source", Txt(f, "CompteSource"))
            Ligne(fiche, "Nom dans la source", Txt(f, "NomSource"))
            Ligne(fiche, "Clé d'identification", Txt(f, "CleSource") & If(Txt(f, "TypeCle").Length > 0, " (par " & Txt(f, "TypeCle").ToLowerInvariant() & ")", ""))
            Ligne(fiche, "Nature normalisée", Txt(f, "TypeNormalise"))
            Ligne(fiche, "Type dans la source", Txt(f, "TypeSource"))
            Ligne(fiche, "Sous-type dans la source", Txt(f, "SousTypeSource"))
            Ligne(fiche, "Sens normal du solde", Txt(f, "Sens"))
            Ligne(fiche, "Solde (source)", Txt(f, "SoldeSource") & If(Txt(f, "SensSource").Length > 0, " " & Txt(f, "SensSource"), ""))
            If Not IsDBNull(f("Solde")) Then Ligne(fiche, "Solde (normalisé)", Convert.ToDecimal(f("Solde")).ToString("N2", CultureInfo.GetCultureInfo("fr-CA")) & " $")
            Ligne(fiche, "Origine", If(Txt(f, "Origine") = "AJOUTE", "ajouté par l'entreprise après l'ouverture du dossier", If(Txt(f, "Origine") = "DEFAUT", "créé par défaut par le logiciel d'origine", "")))
            If Not IsDBNull(f("CreeLe")) Then Ligne(fiche, "Créé le", Convert.ToDateTime(f("CreeLe")).ToString("yyyy-MM-dd"))
            If Not IsDBNull(f("ModifieLe")) Then Ligne(fiche, "Modifié le", Convert.ToDateTime(f("ModifieLe")).ToString("yyyy-MM-dd"))
            Ligne(fiche, "Sous-compte", If(Not IsDBNull(f("SousCompte")) AndAlso Convert.ToBoolean(f("SousCompte")), "oui", "non"))
            Ligne(fiche, "Description saisie dans la source", Txt(f, "DescriptionSource"))
            Ligne(fiche, "Verdict du chargement", Txt(f, "Statut"))
            Ligne(fiche, "Anomalie signalée", Txt(f, "Anomalie"))
            If Txt(f, "PlanCompte").Length > 0 Then Ligne(fiche, "Compte déjà lié ou créé dans 60Sec-AI", Txt(f, "PlanCompte") & " " & Txt(f, "PlanNom"))
            If Txt(f, "ProposeIACompte").Length > 0 Then
                Ligne(fiche, "Proposition de l'IA (étape 2)", Txt(f, "ProposeIACompte") & " " & Txt(f, "ProposeIANom") &
                      If(IsDBNull(f("ProposeIAConfiance")), "", " (confiance " & f("ProposeIAConfiance").ToString() & " %)") &
                      If(Txt(f, "ProposeIARaison").Length > 0, " — " & Txt(f, "ProposeIARaison"), ""))
            End If
            If decision IsNot Nothing Then
                fiche.AppendLine()
                fiche.AppendLine("=== LA DÉCISION DÉJÀ PRISE PAR L'UTILISATEUR ===")
                Ligne(fiche, "Action", Txt(decision, "Action"))
                Ligne(fiche, "Compte cible", Txt(decision, "CompteCible") & " " & Txt(decision, "NomCible"))
                Ligne(fiche, "Type cible", Txt(decision, "TypeCible"))
                Ligne(fiche, "Note", Txt(decision, "Note"))
            End If

            ' ---- le plan comptable de la compagnie, comme pour le mappeur ----
            Dim plan As New StringBuilder()
            plan.AppendLine("=== LE PLAN COMPTABLE DE LA COMPAGNIE (numéro | nom | nom anglais | nature | classe | sous-classe | sens | description) ===")
            Dim dp As DataSet = clsAssistantIA.Ds("s0764GetPlanPourIA", clsAssistantIA.P("@CompanyGUID", companyGuid))
            If dp.Tables.Count > 0 Then
                For Each r As DataRow In dp.Tables(0).Rows
                    plan.AppendLine(String.Join(" | ", Txt(r, "Compte"), Txt(r, "Nom"), Txt(r, "NomEn"), Txt(r, "Nature"), Txt(r, "ClasseParent"), Txt(r, "Classe"), Txt(r, "Sens"), Txt(r, "Description")))
                Next
            End If

            Dim systeme As String = clsAssistantIA.PromptNomme("PROMPT_ASSISTANT_COMPTE") & vbLf & vbLf & plan.ToString()
            Dim titre As String = (Txt(f, "Compte") & " " & Txt(f, "Nom")).Trim()
            Dim question As String = fiche.ToString() & vbLf & "Explique ce compte le plus complètement possible et dis où le ranger."

            Dim rep = Await clsAssistantIA.RepondreAsync(companyGuid, utilisateur, langue, "importation", systeme, question,
                                                         "Assistant compte source : " & titre)
            context.Response.Write(js.Serialize(New With {.titre = titre, .reponse = rep.Texte, .cout = clsAssistantIA.CoutDuMois(companyGuid)}))
        Catch ex As SaisieAssistantException
            context.Response.StatusCode = 400
            context.Response.Write(js.Serialize(New With {.erreur = ex.Message}))
        Catch ex As Exception
            context.Response.StatusCode = 502
            context.Response.Write(js.Serialize(New With {.erreur = clsAssistantIA.Tr(langue, "L'assistant n'a pas pu répondre : ", "The assistant could not answer: ", "El asistente no pudo responder: ") & ex.Message}))
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
