Imports System.Text.Json

''' <summary>
''' Reads a value out of a JSON response using a dotted path:
''' "payee.payeeId", "bankAccount.bankAccountId".
'''
'''  • An array met along the way is walked in full, its values joined.
'''  • Several paths separated by "|" are tried in order; the first one that
'''    yields a value wins.
'''  • A missing path yields an empty string, never an error: Dream leaves
'''    empty fields out.
''' </summary>
Public Module JsonPath

    Public Function Value(node As JsonNode, path As String) As String
        For Each candidate In path.Split("|"c)
            Dim v = Resolve(node, candidate.Trim().Split("."c), 0)
            If v <> "" Then Return v
        Next
        Return ""
    End Function

    Public Function Child(node As JsonNode, name As String) As JsonNode
        Dim o = TryCast(node, JsonObject)
        If o Is Nothing Then Return Nothing
        Dim found As JsonNode = Nothing
        Return If(o.TryGetPropertyValue(name, found), found, Nothing)
    End Function

    Private Function Resolve(node As JsonNode, parts As String(), i As Integer) As String
        If node Is Nothing Then Return ""

        Dim items = TryCast(node, JsonArray)
        If items IsNot Nothing Then
            Return String.Join(" | ", items.Select(Function(e) Resolve(e, parts, i)).Where(Function(s) s <> ""))
        End If

        If i = parts.Length Then Return AsText(node)

        Return Resolve(Child(node, parts(i)), parts, i + 1)
    End Function

    ''' <summary>
    ''' The value exactly as Dream sends it: numbers keep their decimal point,
    ''' dates their ISO shape — nothing depends on the machine's culture.
    ''' </summary>
    Public Function AsText(node As JsonNode) As String
        If node Is Nothing Then Return ""

        Dim v = TryCast(node, JsonValue)
        If v Is Nothing Then Return node.ToJsonString()

        Select Case node.GetValueKind()
            Case JsonValueKind.String : Return v.GetValue(Of String)()
            Case JsonValueKind.True : Return "true"
            Case JsonValueKind.False : Return "false"
            Case JsonValueKind.Null : Return ""
            Case Else : Return node.ToJsonString()
        End Select
    End Function

End Module
