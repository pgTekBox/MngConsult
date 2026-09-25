Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Net.Http
Imports System.Net.Http.Headers
Imports System.Text
Imports System.Threading.Tasks
Imports System.Web.Script.Serialization

''' <summary>Un tour de conversation : la question de l'utilisateur ou la réponse de l'assistant.</summary>
<Serializable>
Public Class TourIA
    Public Property Role As String        ' "user" ou "assistant"
    Public Property Texte As String
    Public Property Quand As Date
End Class

''' <summary>
''' L'assistant IA de l'ERP (le même que dans 60secPaie) : une question, l'aide en
''' ligne, le profil de la compagnie, et la réponse du modèle. Tout ce qui part
''' est assemblé ici, en un seul endroit :
'''   1. le prompt système (PROMPT_ASSISTANT_ERP, modifiable dans Sec60Admin › Prompts OpenAI) ;
'''   2. l'aide en ligne dans la langue de l'utilisateur (clsAide.Texte, en cache) ;
'''   3. le profil de la compagnie (clsAssistantProfil : jamais de nom, de numéro ni de compte) ;
'''   4. les derniers tours de la conversation, puis la question.
''' Le tout est journalisé dans T147AssistantConversation avec son coût.
''' Accès aux données par procédures stockées (s0856-s0862), hors page : la classe
''' n'hérite pas de clsData, elle lit la même chaîne de connexion.
''' </summary>
Public NotInheritable Class clsAssistantIA

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

    ' ------------------------------------------------------------------
    ' Accès aux données (procédures stockées seulement)
    ' ------------------------------------------------------------------

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

    ''' <summary>La clé d'accès, là où vivent celles de l'ERP (paramètre CHATGPT).</summary>
    Private Shared Function Cle() As String
        Dim v As String = Parametre("CHATGPT")
        If v.Length = 0 Then Throw New SaisieAssistantException("La clé d'accès à l'IA n'est pas configurée.")
        Return v
    End Function

    Private Shared Function PromptSysteme() As String
        Dim v As String = Parametre("PROMPT_ASSISTANT_ERP")
        If v.Length = 0 Then Throw New SaisieAssistantException("Le prompt de l'assistant (PROMPT_ASSISTANT_ERP) n'est pas configuré.")
        Return v
    End Function

    ' ------------------------------------------------------------------
    ' La question
    ' ------------------------------------------------------------------

    ''' <summary>Pose la question, avec les tours précédents, et rend la réponse. Journalise toujours, même l'échec.</summary>
    Public Shared Async Function DemanderAsync(companyGuid As Guid, utilisateur As String, question As String,
                                              historique As List(Of TourIA), langue As String,
                                              Optional section As String = Nothing) As Task(Of Reponse)
        If String.IsNullOrWhiteSpace(question) Then Throw New SaisieAssistantException(Tr(langue, "Écrivez une question.", "Write a question.", "Escriba una pregunta."))
        If question.Length > LongueurMaxQuestion Then Throw New SaisieAssistantException(Tr(langue, "La question est trop longue (4000 caractères au plus).", "The question is too long (4000 characters at most).", "La pregunta es demasiado larga (4000 caracteres como máximo)."))
        If companyGuid = Guid.Empty Then Throw New SaisieAssistantException(Tr(langue, "Aucune compagnie active.", "No active company.", "Ninguna compañía activa."))

        Dim chrono = Diagnostics.Stopwatch.StartNew()
        Dim journalId As Integer = 0
        Dim dj As DataSet = Ds("s0859LogAssistantQuestion", P("@CompanyGUID", companyGuid), P("@Utilisateur", utilisateur),
                               P("@Langue", If(langue = "en" OrElse langue = "es", langue, "fr")), P("@Section", section),
                               P("@Question", question.Trim()), P("@Modele", Modele))
        If dj.Tables.Count > 0 AndAlso dj.Tables(0).Rows.Count > 0 Then journalId = Convert.ToInt32(dj.Tables(0).Rows(0)("Id"))

        Try
            Dim systeme As New StringBuilder()
            systeme.AppendLine(PromptSysteme())
            systeme.AppendLine()
            If Not String.IsNullOrEmpty(section) Then
                systeme.AppendLine("=== SECTION D'AIDE D'OÙ PART LA QUESTION : " & clsAide.Titre(section, langue) & " (" & section & ") ===")
                systeme.AppendLine()
            End If
            systeme.AppendLine("=== L'AIDE ===")
            systeme.AppendLine(clsAide.Texte(langue))
            systeme.AppendLine()
            systeme.AppendLine("=== LE PROFIL DE LA COMPAGNIE ===")
            systeme.AppendLine(clsAssistantProfil.Obtenir(companyGuid))

            Dim entrees As New List(Of Object)()
            entrees.Add(New Dictionary(Of String, Object) From {{"role", "system"}, {"content", systeme.ToString()}})
            For Each t In historique.Skip(Math.Max(0, historique.Count - ToursGardes))
                entrees.Add(New Dictionary(Of String, Object) From {{"role", t.Role}, {"content", t.Texte}})
            Next
            entrees.Add(New Dictionary(Of String, Object) From {{"role", "user"}, {"content", question.Trim()}})

            Dim js As New JavaScriptSerializer() With {.MaxJsonLength = Integer.MaxValue}
            Dim charge As String = js.Serialize(New Dictionary(Of String, Object) From {
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

    Friend Shared Function Tr(langue As String, fr As String, en As String, es As String) As String
        Select Case langue
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    ''' <summary>Coût cumulé des questions de la compagnie ce mois-ci, pour l'afficher.</summary>
    Public Shared Function CoutDuMois(companyGuid As Guid) As Decimal
        Dim d As DataSet = Ds("s0861GetAssistantCoutMois", P("@CompanyGUID", companyGuid))
        If d.Tables.Count = 0 OrElse d.Tables(0).Rows.Count = 0 Then Return 0D
        Return Convert.ToDecimal(d.Tables(0).Rows(0)("CoutUsd"))
    End Function

End Class

''' <summary>Une erreur à montrer telle quelle à l'utilisateur (saisie ou configuration), pas une panne.</summary>
Public Class SaisieAssistantException
    Inherits Exception
    Public Sub New(message As String)
        MyBase.New(message)
    End Sub
End Class

''' <summary>
''' Le profil d'une compagnie pour l'assistant IA : tout ce que le logiciel sait
''' d'elle, en texte, et rien de ce qui identifie une personne ou un compte.
''' Ni nom de client, de fournisseur, d'employé ou d'utilisateur ; ni NEQ, NAS,
''' numéros de taxes, adresse, téléphone, courriel, compte bancaire. Les
''' identifiants apparaissent seulement comme « renseigné / manquant ».
'''
''' Le profil généré est conservé (T146AssistantProfil) et refait quand il date
''' de plus d'une heure, quand les volumes ont changé, ou à la demande.
''' L'utilisateur y ajoute ses « particularités », qui partent telles quelles.
''' </summary>
Public NotInheritable Class clsAssistantProfil

    Private Sub New()
    End Sub

    Private Const FraicheurMinutes As Integer = 60
    Private Shared ReadOnly Fr As CultureInfo = CultureInfo.GetCultureInfo("fr-CA")

    Private Shared Function Donnees(companyGuid As Guid) As DataSet
        Return clsAssistantIA.Ds("s0862GetAssistantProfilData", clsAssistantIA.P("@CompanyGUID", companyGuid))
    End Function

    Private Shared Function Ligne(d As DataSet, i As Integer) As DataRow
        If d.Tables.Count <= i OrElse d.Tables(i).Rows.Count = 0 Then Return Nothing
        Return d.Tables(i).Rows(0)
    End Function

    ''' <summary>Un résumé des volumes : si un chiffre bouge, le profil est refait.</summary>
    Private Shared Function Empreinte(d As DataSet) As String
        Dim sb As New StringBuilder()
        Dim t3 = Ligne(d, 2)
        If t3 IsNot Nothing Then sb.Append(t3("Clients")).Append("/").Append(t3("Fournisseurs")).Append("/").Append(t3("ProduitsActifs"))
        If d.Tables.Count > 3 Then
            For Each r As DataRow In d.Tables(3).Rows
                sb.Append(";").Append(r("TypeDocument")).Append(":").Append(r("Nb"))
            Next
        End If
        If d.Tables.Count > 5 Then sb.Append(";plan=").Append(d.Tables(5).Rows.Count)
        If d.Tables.Count > 8 Then
            For Each r As DataRow In d.Tables(8).Rows
                sb.Append(";ec").Append(r("Statut")).Append(":").Append(r("Nb"))
            Next
        End If
        Dim s As String = sb.ToString()
        Return If(s.Length > 400, s.Substring(0, 400), s)
    End Function

    ''' <summary>Le profil à envoyer : celui en base s'il est frais, sinon un neuf.</summary>
    Public Shared Function Obtenir(companyGuid As Guid, Optional forcer As Boolean = False) As String
        Dim enreg As DataRow = Nothing
        Dim de As DataSet = clsAssistantIA.Ds("s0856GetAssistantProfil", clsAssistantIA.P("@CompanyGUID", companyGuid))
        If de.Tables.Count > 0 AndAlso de.Tables(0).Rows.Count > 0 Then enreg = de.Tables(0).Rows(0)

        Dim d As DataSet = Donnees(companyGuid)
        Dim signature As String = Empreinte(d)
        Dim particularites As String = If(enreg Is Nothing OrElse IsDBNull(enreg("Particularites")), "", Convert.ToString(enreg("Particularites")))

        Dim frais As Boolean = enreg IsNot Nothing AndAlso Not IsDBNull(enreg("GenereLe")) AndAlso Not IsDBNull(enreg("ProfilGenere")) AndAlso
                               Convert.ToString(enreg("Empreinte")) = signature AndAlso
                               Convert.ToDateTime(enreg("GenereLe")) > Date.Now.AddMinutes(-FraicheurMinutes)
        If frais AndAlso Not forcer Then Return Assembler(Convert.ToString(enreg("ProfilGenere")), particularites)

        Dim genere As String = Generer(d)
        clsAssistantIA.Exec("s0857SaveAssistantProfil", clsAssistantIA.P("@CompanyGUID", companyGuid),
                            clsAssistantIA.P("@ProfilGenere", genere), clsAssistantIA.P("@Empreinte", signature))
        Return Assembler(genere, particularites)
    End Function

    Public Shared Function GenereLe(companyGuid As Guid) As Date?
        Dim de As DataSet = clsAssistantIA.Ds("s0856GetAssistantProfil", clsAssistantIA.P("@CompanyGUID", companyGuid))
        If de.Tables.Count = 0 OrElse de.Tables(0).Rows.Count = 0 OrElse IsDBNull(de.Tables(0).Rows(0)("GenereLe")) Then Return Nothing
        Return Convert.ToDateTime(de.Tables(0).Rows(0)("GenereLe"))
    End Function

    Public Shared Function ProfilGenere(companyGuid As Guid) As String
        Dim de As DataSet = clsAssistantIA.Ds("s0856GetAssistantProfil", clsAssistantIA.P("@CompanyGUID", companyGuid))
        If de.Tables.Count = 0 OrElse de.Tables(0).Rows.Count = 0 OrElse IsDBNull(de.Tables(0).Rows(0)("ProfilGenere")) Then Return ""
        Return Convert.ToString(de.Tables(0).Rows(0)("ProfilGenere"))
    End Function

    Public Shared Function Particularites(companyGuid As Guid) As String
        Dim de As DataSet = clsAssistantIA.Ds("s0856GetAssistantProfil", clsAssistantIA.P("@CompanyGUID", companyGuid))
        If de.Tables.Count = 0 OrElse de.Tables(0).Rows.Count = 0 OrElse IsDBNull(de.Tables(0).Rows(0)("Particularites")) Then Return ""
        Return Convert.ToString(de.Tables(0).Rows(0)("Particularites"))
    End Function

    Public Shared Sub EnregistrerParticularites(companyGuid As Guid, texte As String, utilisateur As String)
        clsAssistantIA.Exec("s0858SaveAssistantParticularites", clsAssistantIA.P("@CompanyGUID", companyGuid),
                            clsAssistantIA.P("@Particularites", If(texte, "")), clsAssistantIA.P("@Utilisateur", utilisateur))
    End Sub

    Private Shared Function Assembler(genere As String, particularites As String) As String
        Dim sb As New StringBuilder(genere)
        sb.AppendLine()
        sb.AppendLine("## Particularités écrites par l'utilisateur")
        sb.AppendLine(If(String.IsNullOrWhiteSpace(particularites), "(aucune)", particularites.Trim()))
        Return sb.ToString()
    End Function

    ' ------------------------------------------------------------------
    ' La génération
    ' ------------------------------------------------------------------

    Private Shared Function Generer(d As DataSet) As String
        Dim sb As New StringBuilder()
        sb.AppendLine("# Profil de la compagnie (généré le " & Date.Now.ToString("yyyy-MM-dd HH:mm") & ")")
        sb.AppendLine("Aucun nom, aucune adresse, aucun numéro d'identification ni de compte n'y figure : ce sont des réglages et des volumes.")
        sb.AppendLine()

        ' 1. paramètres
        sb.AppendLine("## Paramètres (Paramètres › onglets)")
        If d.Tables.Count > 0 Then
            Dim categorie As String = ""
            For Each r As DataRow In d.Tables(0).Rows
                Dim cat As String = Convert.ToString(r("Categorie"))
                If cat <> categorie Then
                    categorie = cat
                    sb.AppendLine("### " & LibelleCategorie(cat))
                End If
                Dim v As String = If(IsDBNull(r("Valeur")), "", Convert.ToString(r("Valeur")).Trim())
                sb.AppendLine("- " & Convert.ToString(r("Name")) & " (" & Convert.ToString(r("ShortName")) & ") : " & If(v.Length = 0, "(vide)", v))
            Next
        End If

        ' 2. identifiants : renseignés ou non
        If d.Tables.Count > 1 Then
            sb.AppendLine("### Identifiants et coordonnées (renseignés ou non, jamais la valeur)")
            For Each r As DataRow In d.Tables(1).Rows
                sb.AppendLine("- " & Convert.ToString(r("Name")) & " : " & If(Convert.ToInt32(r("Renseigne")) = 1, "renseigné", "manquant"))
            Next
        End If

        ' 3. tiers et catalogue
        Dim t3 = Ligne(d, 2)
        sb.AppendLine()
        sb.AppendLine("## Tiers et catalogue")
        If t3 IsNot Nothing Then
            sb.AppendLine("- Clients : " & t3("Clients") & " (dont " & t3("ClientsSquare") & " liés à Square)")
            sb.AppendLine("- Fournisseurs : " & t3("Fournisseurs") & " (dont " & t3("FournisseursStripe") & " avec un compte Stripe Connect)")
            sb.AppendLine("- Produits et services actifs : " & t3("ProduitsActifs") & " ; inactifs : " & t3("ProduitsInactifs") & " ; sans compte de vente ni catégorie : " & t3("ProduitsSansCompteNiCategorie"))
            sb.AppendLine("- Catégories de produits : " & t3("Categories") & " ; sans compte de vente : " & t3("CategoriesSansCompteVente"))
        End If

        ' 4. documents
        sb.AppendLine()
        sb.AppendLine("## Documents (factures) par type, état comptable et statut de paiement")
        If d.Tables.Count > 3 AndAlso d.Tables(3).Rows.Count > 0 Then
            For Each r As DataRow In d.Tables(3).Rows
                sb.AppendLine("- " & LibelleType(Convert.ToString(r("TypeDocument"))) & " — " & LibelleEtat(Convert.ToString(r("EtatComptable"))) & " — " & LibelleStatut(Convert.ToString(r("Statut"))) & " : " & r("Nb") & " document(s), total " & Montant(r("Total")))
            Next
        Else
            sb.AppendLine("(aucun document)")
        End If

        ' 5. échéances
        If d.Tables.Count > 4 AndAlso d.Tables(4).Rows.Count > 0 Then
            sb.AppendLine()
            sb.AppendLine("## Échéances (documents comptabilisés non payés)")
            For Each r As DataRow In d.Tables(4).Rows
                sb.AppendLine("- " & LibelleType(Convert.ToString(r("TypeDocument"))) & " : en retard " & r("NbEnRetard") & " (" & Montant(r("TotalEnRetard")) & ")" &
                              If(IsDBNull(r("PlusAncienneEcheance")), "", ", la plus ancienne échue le " & Convert.ToDateTime(r("PlusAncienneEcheance")).ToString("yyyy-MM-dd")) &
                              " ; à venir " & r("NbAVenir") & " (" & Montant(r("TotalAVenir")) & ")")
            Next
        End If

        ' 6. plan comptable
        sb.AppendLine()
        sb.AppendLine("## Plan comptable")
        If d.Tables.Count > 5 AndAlso d.Tables(5).Rows.Count > 0 Then
            Dim actifs As Integer = 0, inactifs As Integer = 0
            For Each r As DataRow In d.Tables(5).Rows
                If Convert.ToBoolean(r("Actif")) Then actifs += 1 Else inactifs += 1
            Next
            sb.AppendLine("- " & actifs & " compte(s) actif(s), " & inactifs & " inactif(s). Liste des comptes actifs (numéro | nom | classe | sens) :")
            For Each r As DataRow In d.Tables(5).Rows
                If Not Convert.ToBoolean(r("Actif")) Then Continue For
                sb.AppendLine("  - " & r("Compte") & " | " & r("Nom") & " | " & If(IsDBNull(r("ClasseCode")), "", Convert.ToString(r("ClasseCode"))) & " | " & r("Sens") & If(Convert.ToBoolean(r("Systeme")), " | système", ""))
            Next
        Else
            sb.AppendLine("(plan comptable vide)")
        End If

        ' 7. exercices
        sb.AppendLine()
        sb.AppendLine("## Exercices financiers")
        If d.Tables.Count > 6 AndAlso d.Tables(6).Rows.Count > 0 Then
            For Each r As DataRow In d.Tables(6).Rows
                sb.AppendLine("- " & r("annee") & " : du " & Convert.ToDateTime(r("date_debut")).ToString("yyyy-MM-dd") & " au " & Convert.ToDateTime(r("date_fin")).ToString("yyyy-MM-dd") & ", statut " & r("statut") & ", " & r("Periodes") & " période(s) dont " & r("PeriodesFermees") & " fermée(s)")
            Next
        Else
            sb.AppendLine("(aucun exercice : la comptabilisation refusera les documents)")
        End If

        ' 8. journaux
        sb.AppendLine()
        sb.AppendLine("## Journaux")
        If d.Tables.Count > 7 AndAlso d.Tables(7).Rows.Count > 0 Then
            For Each r As DataRow In d.Tables(7).Rows
                sb.AppendLine("- " & r("Code") & " : " & r("Libelle") & " (" & r("Type") & ")" & If(Convert.ToBoolean(r("Actif")), "", " — inactif"))
            Next
        Else
            sb.AppendLine("(aucun journal)")
        End If

        ' 9. écritures
        sb.AppendLine()
        sb.AppendLine("## Écritures")
        If d.Tables.Count > 8 AndAlso d.Tables(8).Rows.Count > 0 Then
            For Each r As DataRow In d.Tables(8).Rows
                sb.AppendLine("- " & If(Convert.ToString(r("Statut")).Length = 0, "(sans statut)", Convert.ToString(r("Statut"))) & " : " & r("Nb") & ", de " & DateTxt(r("Premiere")) & " à " & DateTxt(r("Derniere")))
            Next
        Else
            sb.AppendLine("(aucune écriture)")
        End If

        ' 10. banque
        Dim t10 = Ligne(d, 9)
        sb.AppendLine()
        sb.AppendLine("## Banque, relevé et paiements automatiques")
        If t10 IsNot Nothing Then
            sb.AppendLine("- Comptes bancaires connectés (Plaid) : " & t10("ComptesBancairesActifs") & If(IsDBNull(t10("Banques")), "", " — institutions : " & t10("Banques")) & " ; import automatique : " & OuiNon(Convert.ToBoolean(t10("ImportAutomatique"))))
            sb.AppendLine("- Relevé bancaire : " & t10("MouvementsReleve") & " mouvement(s), " & t10("MouvementsNonRegles") & " non réglé(s)" & If(IsDBNull(t10("DernierMouvement")), "", ", dernier le " & Convert.ToDateTime(t10("DernierMouvement")).ToString("yyyy-MM-dd")))
            sb.AppendLine("- Règlements (encaissements et décaissements) : " & t10("Reglements"))
            sb.AppendLine("- Autorisations de paiement automatique actives : " & t10("AutorisationsAutoPay") & " ; paiements programmés : " & t10("PaiementsAutoProgrammes"))
        End If

        ' 11. intégrations, utilisateurs, abonnement
        Dim t11 = Ligne(d, 10)
        sb.AppendLine()
        sb.AppendLine("## Intégrations, utilisateurs, abonnement")
        If t11 IsNot Nothing Then
            sb.AppendLine("- Square : " & If(Convert.ToInt32(t11("SquareConnecte")) = 1, "connecté" & If(IsDBNull(t11("SquareConnectedDate")), "", " depuis le " & Convert.ToDateTime(t11("SquareConnectedDate")).ToString("yyyy-MM-dd")), "non connecté"))
            sb.AppendLine("- Courriel d'expéditeur vérifié : " & OuiNon(Convert.ToInt32(t11("CourrielVerifie")) = 1) & " ; boîte @60sec.ca de la compagnie : " & OuiNon(Convert.ToInt32(t11("BoiteSec60")) = 1) & " ; logo : " & OuiNon(Convert.ToInt32(t11("LogoPresent")) = 1))
            sb.AppendLine("- Comptable externe relié : " & OuiNon(Convert.ToInt32(t11("ComptableRelie")) = 1))
            sb.AppendLine("- Utilisateurs actifs : " & t11("UtilisateursActifs") & " dont " & t11("Administrateurs") & " administrateur(s)")
            If Not IsDBNull(t11("PlanName")) Then
                sb.AppendLine("- Abonnement : " & t11("PlanName") & ", statut " & t11("StatutAbonnement") & If(Not IsDBNull(t11("IsTrial")) AndAlso Convert.ToBoolean(t11("IsTrial")), " (essai gratuit" & If(IsDBNull(t11("TrialEndOn")), "", " jusqu'au " & Convert.ToDateTime(t11("TrialEndOn")).ToString("yyyy-MM-dd")) & ")", "") & If(IsDBNull(t11("NextBillingDate")), "", " ; prochaine facturation le " & Convert.ToDateTime(t11("NextBillingDate")).ToString("yyyy-MM-dd")))
            Else
                sb.AppendLine("- Abonnement : aucun enregistré")
            End If
        End If

        ' 12. agenda, employés, reçus
        Dim t12 = Ligne(d, 11)
        sb.AppendLine()
        sb.AppendLine("## Agenda, employés, reçus")
        If t12 IsNot Nothing Then
            sb.AppendLine("- Employés actifs : " & t12("EmployesActifs") & " dont " & t12("EmployesAvecBoite") & " avec une boîte @60sec.ca")
            sb.AppendLine("- Rendez-vous à venir : " & t12("RendezVousAVenir") & " ; dans les 30 derniers jours : " & t12("RendezVous30Jours"))
            sb.AppendLine("- Reçus déposés : " & t12("Recus") & " dont " & t12("RecusNonAnalyses") & " pas encore lus par l'IA")
        End If
        Return sb.ToString()
    End Function

    Private Shared Function LibelleCategorie(c As String) As String
        Select Case c
            Case "ENTREPRISE" : Return "Entreprise"
            Case "TAXES" : Return "Taxes"
            Case "PDF" : Return "Facture (PDF et numérotation)"
            Case "TRAITEMENT" : Return "Traitement"
            Case "COMPTABILITE" : Return "Comptabilité (comptes par défaut)"
            Case "BANCAIRE" : Return "Bancaire"
            Case "EMAIL" : Return "Email"
            Case Else : Return c
        End Select
    End Function

    Private Shared Function LibelleType(t As String) As String
        Select Case t
            Case "FactureClient" : Return "Factures clients"
            Case "FactureFournisseur" : Return "Factures fournisseurs"
            Case "CreditClient" : Return "Crédits clients"
            Case "CreditFournisseur" : Return "Crédits fournisseurs"
            Case "ReceiptOCR" : Return "Reçus lus par l'IA"
            Case "Expense" : Return "Dépenses"
            Case "RecuVente" : Return "Reçus de vente"
            Case Else : Return t
        End Select
    End Function

    Private Shared Function LibelleEtat(e As String) As String
        Select Case e
            Case "COMPTABILISE" : Return "comptabilisé"
            Case "NON_COMPTABILISE" : Return "brouillon (non comptabilisé)"
            Case Else : Return "état comptable non renseigné"
        End Select
    End Function

    Private Shared Function LibelleStatut(s As String) As String
        Select Case s
            Case "Draft" : Return "brouillon"
            Case "Posted" : Return "émis / ouvert"
            Case "Paid" : Return "payé"
            Case "Cancelled" : Return "annulé"
            Case "" : Return "sans statut"
            Case Else : Return s
        End Select
    End Function

    Private Shared Function Montant(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value Then Return "—"
        Return Convert.ToDecimal(v).ToString("N2", Fr) & " $"
    End Function

    Private Shared Function DateTxt(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value Then Return "—"
        Return Convert.ToDateTime(v).ToString("yyyy-MM-dd")
    End Function

    Private Shared Function OuiNon(b As Boolean) As String
        Return If(b, "oui", "non")
    End Function

End Class
