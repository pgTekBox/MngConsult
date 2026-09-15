''' <summary>
''' Met à plat un rapport QuickBooks (Reports API) en tableau.
'''
''' Un rapport est un arbre : des sections (« Comptes clients », puis chaque
''' client), qui contiennent des lignes de données et se ferment sur un total.
''' Chaque ligne du CSV garde son chemin de section et dit ce qu'elle est —
''' entête de section, donnée ou total — pour que l'arbre se reconstruise.
''' Quand une colonne porte un identifiant QuickBooks (client, transaction,
''' compte), il sort dans une colonne « (Id) » à côté.
''' </summary>
Public Module RapportPlat

    Public Class Tableau
        Public Property Entetes As New List(Of String)
        Public Property Lignes As New List(Of IEnumerable(Of String))
    End Class

    Private Class LigneBrute
        Public Section As String
        Public Genre As String
        Public Cellules As JsonArray
    End Class

    Public Function Aplatir(rapport As JsonNode) As Tableau
        Dim titres As New List(Of String)
        Dim colonnes = TryCast(JsonChemin.Enfant(JsonChemin.Enfant(rapport, "Columns"), "Column"), JsonArray)
        If colonnes IsNot Nothing Then
            For Each c In colonnes
                Dim t = JsonChemin.Valeur(c, "ColTitle|ColType")
                titres.Add(If(t = "", "Colonne " & (titres.Count + 1), t))
            Next
        End If

        Dim brutes As New List(Of LigneBrute)
        Parcourir(JsonChemin.Enfant(JsonChemin.Enfant(rapport, "Rows"), "Row"), "", brutes)

        ' Une colonne d'identifiants seulement là où le rapport en donne.
        Dim avecId = titres.Select(Function(t, j) brutes.Any(Function(b) IdCellule(b.Cellules, j) <> "")).ToList()

        Dim tableau As New Tableau()
        tableau.Entetes.Add("Section")
        tableau.Entetes.Add("Type de ligne")
        For j = 0 To titres.Count - 1
            tableau.Entetes.Add(titres(j))
            If avecId(j) Then tableau.Entetes.Add(titres(j) & " (Id)")
        Next

        For Each b In brutes
            Dim l As New List(Of String) From {b.Section, b.Genre}
            For j = 0 To titres.Count - 1
                l.Add(ValeurCellule(b.Cellules, j))
                If avecId(j) Then l.Add(IdCellule(b.Cellules, j))
            Next
            tableau.Lignes.Add(l)
        Next

        Return tableau
    End Function

    Private Sub Parcourir(lignes As JsonNode, section As String, sortie As List(Of LigneBrute))
        Dim tableau = TryCast(lignes, JsonArray)
        If tableau Is Nothing Then Return

        For Each ligne In tableau
            Dim entete = TryCast(JsonChemin.Enfant(JsonChemin.Enfant(ligne, "Header"), "ColData"), JsonArray)
            Dim sousSection = section

            If entete IsNot Nothing Then
                Dim nom = ValeurCellule(entete, 0)
                sousSection = If(section = "", nom, section & " > " & nom)
                sortie.Add(New LigneBrute With {.Section = sousSection, .Genre = "Entête", .Cellules = entete})
            End If

            Dim donnees = TryCast(JsonChemin.Enfant(ligne, "ColData"), JsonArray)
            If donnees IsNot Nothing Then
                sortie.Add(New LigneBrute With {.Section = section, .Genre = "Donnée", .Cellules = donnees})
            End If

            Parcourir(JsonChemin.Enfant(JsonChemin.Enfant(ligne, "Rows"), "Row"), sousSection, sortie)

            Dim total = TryCast(JsonChemin.Enfant(JsonChemin.Enfant(ligne, "Summary"), "ColData"), JsonArray)
            If total IsNot Nothing Then
                sortie.Add(New LigneBrute With {.Section = sousSection, .Genre = "Total", .Cellules = total})
            End If
        Next
    End Sub

    Private Function ValeurCellule(cellules As JsonArray, j As Integer) As String
        If cellules Is Nothing OrElse j >= cellules.Count Then Return ""
        Return JsonChemin.Valeur(cellules(j), "value")
    End Function

    Private Function IdCellule(cellules As JsonArray, j As Integer) As String
        If cellules Is Nothing OrElse j >= cellules.Count Then Return ""
        Return JsonChemin.Valeur(cellules(j), "id")
    End Function

End Module
