Imports System.Globalization

Public Class OptionsExtraction
    Public Property Dossier As String
    Public Property Separateur As Char = ";"c
    Public Property DateDebut As Date
    Public Property DateBascule As Date
    Public Property FiltrerTransactions As Boolean
    Public Property PeriodesAgees As Integer = 4
    Public Property MethodeComptable As String = "accrual"
End Class

''' <summary>Exécute une extraction du catalogue et écrit ses fichiers.</summary>
Public Module Extracteur

    Public Async Function ExecuterAsync(ext As Extraction, client As ApideckClient, opt As OptionsExtraction,
                                        journal As Action(Of String), ct As CancellationToken) As Task(Of String)

        If ext.Rapport <> GenreRapport.Aucun Then
            Dim donnees = Await client.UnAsync(Rapports.Url(ext, opt), ct)
            Return EcrireRapport(ext, donnees, opt)
        End If

        Dim chemin = "/accounting/" & ext.Ressource

        If ext.Unique Then
            Dim objet = Await client.UnAsync(chemin, ct)
            Return EcrireEntites(ext, New List(Of JsonNode) From {objet}, opt)
        End If

        Dim filtres = ""
        If opt.FiltrerTransactions AndAlso ext.FiltreDate <> "" Then
            Dim f = ext.FiltreDate.Replace("{date}", opt.DateDebut.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)) _
                                  .Replace("{datetime}", opt.DateDebut.ToString("yyyy-MM-dd'T'00:00:00.000'Z'", CultureInfo.InvariantCulture))
            Dim egal = f.IndexOf("="c)
            filtres = "&" & Uri.EscapeDataString(f.Substring(0, egal)) & "=" & Uri.EscapeDataString(f.Substring(egal + 1))
        End If

        Dim entites = Await client.ListeToutAsync(chemin, filtres, Sub(n) journal($"   {ext.Libelle} : {n} lu(s)…"), ct)

        Dim bilan = EcrireEntites(ext, entites, opt)
        If opt.FiltrerTransactions AndAlso ext.FiltreDate = "" AndAlso ext.CheminLignes <> "" Then
            bilan &= " — Apideck n'offre pas de filtre de date ici : tout l'historique est extrait"
        End If
        Return bilan
    End Function

    ''' <summary>
    ''' Écrit l'entête (Fichier.csv) et, si la ressource a des lignes, le détail
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

        Const Numero As String = "number|bill_number|po_number|display_id|reference"
        Const DateDoc As String = "invoice_date|bill_date|date_issued|transaction_date|refund_date|quote_date|issued_date|posted_at"

        Dim entetes = New List(Of String) From {"parent.id", "parent.number", "parent.date", "line_index"}
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

    Public Function EcrireRapport(ext As Extraction, donnees As JsonNode, opt As OptionsExtraction) As String
        Dim tableau = If(ext.Rapport = GenreRapport.BalanceAgeeClients OrElse ext.Rapport = GenreRapport.BalanceAgeeFournisseurs,
                         Rapports.AplatirEcheancier(donnees),
                         Rapports.AplatirEtatFinancier(donnees))

        Dim nom = ext.Fichier & "_" & Rapports.Iso(opt.DateBascule) & ".csv"
        Csv.Ecrire(Path.Combine(opt.Dossier, nom), tableau.Entetes, tableau.Lignes, opt.Separateur)
        Return $"{nom} : {tableau.Lignes.Count} ligne(s)"
    End Function

End Module
