Imports System.Text.Json

''' <summary>
''' Lit une valeur dans un objet QuickBooks par un chemin pointé :
''' « CustomerRef.name », « BillAddr.City ».
'''
'''  • Un tableau rencontré en route est parcouru en entier, et ses valeurs
'''    jointes par « | » : « LinkedTxn.TxnId » donne « 12 | 15 ».
'''  • Plusieurs chemins séparés par « | » sont essayés dans l'ordre ; le
'''    premier qui donne une valeur l'emporte.
'''  • Un chemin absent donne une chaîne vide, jamais une erreur : QuickBooks
'''    omet les champs vides.
''' </summary>
Public Module JsonChemin

    Public Function Valeur(noeud As JsonNode, chemin As String) As String
        For Each variante In chemin.Split("|"c)
            Dim v = Resoudre(noeud, variante.Trim().Split("."c), 0)
            If v <> "" Then Return v
        Next
        Return ""
    End Function

    Public Function Enfant(noeud As JsonNode, nom As String) As JsonNode
        Dim o = TryCast(noeud, JsonObject)
        If o Is Nothing Then Return Nothing
        Dim e As JsonNode = Nothing
        Return If(o.TryGetPropertyValue(nom, e), e, Nothing)
    End Function

    Private Function Resoudre(noeud As JsonNode, parties As String(), i As Integer) As String
        If noeud Is Nothing Then Return ""

        Dim tableau = TryCast(noeud, JsonArray)
        If tableau IsNot Nothing Then
            Return String.Join(" | ", tableau.Select(Function(e) Resoudre(e, parties, i)).Where(Function(s) s <> ""))
        End If

        If i = parties.Length Then Return Texte(noeud)

        Return Resoudre(Enfant(noeud, parties(i)), parties, i + 1)
    End Function

    ''' <summary>
    ''' La valeur telle que QuickBooks l'envoie : les nombres gardent leur point
    ''' décimal, les dates leur format ISO — rien ne dépend de la culture du poste.
    ''' </summary>
    Public Function Texte(noeud As JsonNode) As String
        If noeud Is Nothing Then Return ""

        Dim v = TryCast(noeud, JsonValue)
        If v Is Nothing Then Return noeud.ToJsonString()

        Select Case noeud.GetValueKind()
            Case JsonValueKind.String : Return v.GetValue(Of String)()
            Case JsonValueKind.True : Return "true"
            Case JsonValueKind.False : Return "false"
            Case JsonValueKind.Null : Return ""
            Case Else : Return noeud.ToJsonString()
        End Select
    End Function

End Module
