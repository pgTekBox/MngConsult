Imports System.Globalization

Public Class OptionsExtraction
    Public Property Dossier As String
    Public Property Separateur As Char = ";"c
    Public Property DateDebut As Date
    Public Property DateBascule As Date
    Public Property FiltrerTransactions As Boolean
    Public Property MethodeComptable As String = "Accrual"
End Class

''' <summary>Exécute une extraction du catalogue et écrit ses fichiers.</summary>
Public Module Extracteur

    Public Async Function ExecuterAsync(ext As Extraction, client As QboClient, opt As OptionsExtraction,
                                        journal As Action(Of String), ct As CancellationToken) As Task(Of String)

        If ext.Rapport <> "" Then
            Dim rapport = Await client.RapportAsync(ext.Rapport, ext.ParametresRapport(opt), ct)
            Return EcrireRapport(ext, rapport, opt)
        End If

        Dim conditions As New List(Of String)
        If ext.Datee AndAlso opt.FiltrerTransactions Then
            conditions.Add("TxnDate >= '" & opt.DateDebut.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) & "'")
        End If

        Dim progres As Action(Of Integer) = Sub(n) journal($"   {ext.Libelle} : {n} lu(s)…")
        Dim entites As List(Of JsonNode) = Nothing
        Dim sansInactifs = False

        If ext.ActifsEtInactifs Then
            Try
                entites = Await client.RequeteToutAsync(ext.Entite, String.Join(" AND ", conditions.Append("Active IN (true, false)")), progres, ct)
            Catch ex As QboException When ex.CodeHttp = 400
                ' Certaines listes n'acceptent pas le filtre Active : on se contente des actifs.
                sansInactifs = True
            End Try
        End If

        If entites Is Nothing Then
            entites = Await client.RequeteToutAsync(ext.Entite, String.Join(" AND ", conditions), progres, ct)
            If sansInactifs Then journal($"   {ext.Libelle} : filtre des inactifs refusé par QuickBooks, seuls les actifs sont extraits.")
        End If

        Return EcrireEntites(ext, entites, opt)
    End Function

    ''' <summary>
    ''' Écrit l'entête (Fichier.csv) et, si l'entité a des lignes, le détail
    ''' (Fichier_Lignes.csv). Chaque ligne rappelle sa transaction : Id, numéro
    ''' et date. Les lignes d'un groupe (ensemble de produits) suivent la ligne
    ''' du groupe, avec son identifiant dans « GroupLine.Id ».
    ''' </summary>
    Public Function EcrireEntites(ext As Extraction, entites As List(Of JsonNode), opt As OptionsExtraction) As String
        Dim fichier = Path.Combine(opt.Dossier, ext.Fichier & ".csv")
        Csv.Ecrire(fichier, ext.Colonnes.Select(Function(c) c.Titre),
                   entites.Select(Function(e) ext.Colonnes.Select(Function(c) c.Lire(e))),
                   opt.Separateur)

        Dim bilan = $"{Path.GetFileName(fichier)} : {entites.Count} ligne(s)"
        If ext.ColonnesLignes Is Nothing Then Return bilan

        Dim entetes = New List(Of String) From {"Parent.Id", "Parent.DocNumber", "Parent.TxnDate", "GroupLine.Id"}
        entetes.AddRange(ext.ColonnesLignes.Select(Function(c) c.Titre))

        Dim lignes As New List(Of IEnumerable(Of String))
        For Each e In entites
            Dim tete = {JsonChemin.Valeur(e, "Id"), JsonChemin.Valeur(e, "DocNumber"), JsonChemin.Valeur(e, "TxnDate")}
            Dim tableau = TryCast(JsonChemin.Enfant(e, "Line"), JsonArray)
            If tableau Is Nothing Then Continue For

            For Each l In tableau
                lignes.Add(tete.Append("").Concat(ext.ColonnesLignes.Select(Function(c) c.Lire(l))).ToList())

                Dim composants = TryCast(JsonChemin.Enfant(JsonChemin.Enfant(l, "GroupLineDetail"), "Line"), JsonArray)
                If composants Is Nothing Then Continue For
                Dim idGroupe = JsonChemin.Valeur(l, "Id")
                For Each sous In composants
                    lignes.Add(tete.Append(idGroupe).Concat(ext.ColonnesLignes.Select(Function(c) c.Lire(sous))).ToList())
                Next
            Next
        Next

        Dim fichierLignes = Path.Combine(opt.Dossier, ext.Fichier & "_Lignes.csv")
        Csv.Ecrire(fichierLignes, entetes, lignes, opt.Separateur)
        Return bilan & $", {Path.GetFileName(fichierLignes)} : {lignes.Count} ligne(s)"
    End Function

    Public Function EcrireRapport(ext As Extraction, rapport As JsonNode, opt As OptionsExtraction) As String
        Dim tableau = RapportPlat.Aplatir(rapport)
        Dim nom = ext.Fichier & "_" & opt.DateBascule.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) & ".csv"
        Csv.Ecrire(Path.Combine(opt.Dossier, nom), tableau.Entetes, tableau.Lignes, opt.Separateur)

        Dim debut = JsonChemin.Valeur(rapport, "Header.StartPeriod")
        Dim fin = JsonChemin.Valeur(rapport, "Header.EndPeriod|Header.ReportDate")
        Dim periode = If(debut <> "", $" (du {debut} au {fin})", If(fin <> "", $" (au {fin})", ""))
        Return $"{nom} : {tableau.Lignes.Count} ligne(s){periode}"
    End Function

End Module
