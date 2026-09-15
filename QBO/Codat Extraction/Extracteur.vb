Imports System.Globalization

Public Class OptionsExtraction
    Public Property Dossier As String
    Public Property Separateur As Char = ";"c
    Public Property DateDebut As Date
    Public Property DateBascule As Date
    Public Property FiltrerTransactions As Boolean
    Public Property PeriodesAgees As Integer = 4
    Public Property CompanyId As String
    Public Property ConnectionId As String
End Class

''' <summary>Exécute une extraction du catalogue et écrit ses fichiers.</summary>
Public Module Extracteur

    Public Async Function ExecuterAsync(ext As Extraction, client As CodatClient, opt As OptionsExtraction,
                                        journal As Action(Of String), ct As CancellationToken) As Task(Of String)

        If ext.Rapport <> GenreRapport.Aucun Then
            Dim reponse = Await client.GetAsync(Rapports.Url(ext.Rapport, opt.CompanyId, opt), ct)
            Return EcrireRapport(ext, reponse, opt)
        End If

        If ext.ParConnexion AndAlso String.IsNullOrEmpty(opt.ConnectionId) Then
            Throw New CodatException("Ce type de données se lit par connexion : cliquez d'abord « Vérifier la connexion » pour trouver la connexion QuickBooks.")
        End If

        Dim chemin = "/companies/" & Uri.EscapeDataString(opt.CompanyId) & "/" &
                     ext.Chemin.Replace("{connectionId}", Uri.EscapeDataString(If(opt.ConnectionId, "")))

        If ext.Unique Then
            Dim objet = Await client.GetAsync(chemin, ct)
            Return EcrireEntites(ext, New List(Of JsonNode) From {objet}, opt)
        End If

        Dim requete = ""
        If ext.ChampDate <> "" AndAlso opt.FiltrerTransactions Then
            requete = ext.ChampDate & ">=" & opt.DateDebut.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
        End If

        Dim entites = Await client.ListeToutAsync(chemin, requete, Sub(n) journal($"   {ext.Libelle} : {n} lu(s)…"), ct)
        Return EcrireEntites(ext, entites, opt)
    End Function

    ''' <summary>
    ''' Écrit l'entête (Fichier.csv) et, si le type a des lignes, le détail
    ''' (Fichier_Lignes.csv). Chaque ligne rappelle son document : identifiant,
    ''' numéro et date, et son rang dans le document.
    ''' </summary>
    Public Function EcrireEntites(ext As Extraction, entites As List(Of JsonNode), opt As OptionsExtraction) As String
        Dim fichier = Path.Combine(opt.Dossier, ext.Fichier & ".csv")
        Csv.Ecrire(fichier, ext.Colonnes.Select(Function(c) c.Titre),
                   entites.Select(Function(e) ext.Colonnes.Select(Function(c) c.Lire(e))),
                   opt.Separateur)

        Dim bilan = $"{Path.GetFileName(fichier)} : {entites.Count} ligne(s)"
        If ext.CheminLignes = "" Then Return bilan

        Const Numero As String = "invoiceNumber|creditNoteNumber|billCreditNoteNumber|purchaseOrderNumber|salesOrderNumber|reference|transactionId"
        Const DateDoc As String = "issueDate|date|postedOn"

        Dim entetes = New List(Of String) From {"parent.id", "parent.number", "parent.date", "lineIndex"}
        entetes.AddRange(ext.ColonnesLignes.Select(Function(c) c.Titre))

        Dim lignes As New List(Of IEnumerable(Of String))
        For Each e In entites
            Dim tableau = TryCast(JsonChemin.Enfant(e, ext.CheminLignes), JsonArray)
            If tableau Is Nothing Then Continue For

            Dim tete = {JsonChemin.Valeur(e, "id"), JsonChemin.Valeur(e, Numero), JsonChemin.Valeur(e, DateDoc)}
            For i = 0 To tableau.Count - 1
                Dim l = tableau(i)
                lignes.Add(tete.Append((i + 1).ToString(CultureInfo.InvariantCulture)) _
                               .Concat(ext.ColonnesLignes.Select(Function(c) c.Lire(l))).ToList())
            Next
        Next

        Dim fichierLignes = Path.Combine(opt.Dossier, ext.Fichier & "_Lignes.csv")
        Csv.Ecrire(fichierLignes, entetes, lignes, opt.Separateur)
        Return bilan & $", {Path.GetFileName(fichierLignes)} : {lignes.Count} ligne(s)"
    End Function

    Public Function EcrireRapport(ext As Extraction, reponse As JsonNode, opt As OptionsExtraction) As String
        Dim tableau As Rapports.Tableau
        Select Case ext.Rapport
            Case GenreRapport.BalanceAgeeClients : tableau = Rapports.AplatirEcheancier(reponse, False)
            Case GenreRapport.BalanceAgeeFournisseurs : tableau = Rapports.AplatirEcheancier(reponse, True)
            Case Else : tableau = Rapports.AplatirEtatFinancier(reponse)
        End Select

        Dim nom = ext.Fichier & "_" & Rapports.Iso(opt.DateBascule) & ".csv"
        Csv.Ecrire(Path.Combine(opt.Dossier, nom), tableau.Entetes, tableau.Lignes, opt.Separateur)
        Return $"{nom} : {tableau.Lignes.Count} ligne(s)"
    End Function

End Module
