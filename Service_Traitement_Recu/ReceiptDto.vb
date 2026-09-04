Imports Newtonsoft.Json
Imports Newtonsoft.Json.Linq

''' <summary>
''' Validation du JSON rendu par ChatGPT, avant de le confier aux procedures
''' qui creent le marchand et le document.
'''
''' L'application web fait la meme chose dans ReceiptAI.ParseReceiptJson : elle
''' deserialise pour verifier que le JSON tient debout, puis laisse SQL lire le
''' JSON stocke dans T0001Receipt.AI_JSON. On garde ce fonctionnement pour ne
''' pas avoir deux verites sur la forme attendue du document.
''' </summary>
Public Class ReceiptJsonValidator

    ''' <summary>
    ''' Verifie que le texte est un objet JSON exploitable, et le renvoie tel
    ''' quel. C'est exactement le contrat de SQL : s0006SaveAIReturn refuse ce
    ''' qui n'est pas du JSON (ISJSON = 0), et s0008/s0009 relisent ensuite le
    ''' texte avec JSON_VALUE.
    '''
    ''' On ne va pas plus loin volontairement. Lier la validation au DTO
    ''' bloquait des recus parfaitement traitables : il suffisait que le modele
    ''' ecrive « 167.8L » ou « 20.32 » dans un champ decimal pour que la
    ''' deserialisation echoue, alors que JSON_VALUE s'en accommode.
    ''' </summary>
    Public Shared Function EnsureValidJson(json As String) As String
        If String.IsNullOrWhiteSpace(json) Then
            Throw New Exception("JSON vide")
        End If

        Dim token As JToken
        Try
            token = JToken.Parse(json)
        Catch ex As Exception
            Throw New Exception("JSON invalide : " & ex.Message)
        End Try

        If token.Type <> JTokenType.Object Then
            Throw New Exception("JSON invalide : un objet était attendu, reçu " & token.Type.ToString() & ".")
        End If

        Return json
    End Function

    ''' <summary>
    ''' Lecture au mieux du JSON pour le DTO. Renvoie Nothing si le document ne
    ''' s'y plie pas : c'est sans consequence, le DTO ne sert qu'a fabriquer le
    ''' libelle du journal.
    ''' </summary>
    Public Shared Function TryParse(json As String) As ReceiptDto
        If String.IsNullOrWhiteSpace(json) Then Return Nothing

        Try
            Dim obj = JsonConvert.DeserializeObject(Of ReceiptDto)(json)
            If obj Is Nothing Then Return Nothing
            If obj.items Is Nothing Then obj.items = New List(Of ReceiptItemDto)
            If obj.taxes Is Nothing Then obj.taxes = New List(Of ReceiptTaxDto)
            Return obj
        Catch
            Return Nothing
        End Try
    End Function

    ''' <summary>
    ''' Resume d'une ligne pour le journal : de quoi reconnaitre le recu.
    ''' Si le DTO n'a pas pu etre lu, on retombe sur les champs bruts du JSON,
    ''' pour que la grille reste lisible meme quand le modele a mal ecrit un
    ''' montant.
    ''' </summary>
    Public Shared Function Describe(json As String) As String
        Dim dto As ReceiptDto = TryParse(json)

        Dim parts As New List(Of String)

        If dto IsNot Nothing Then
            If Not String.IsNullOrWhiteSpace(dto.merchant_name) Then parts.Add(dto.merchant_name)
            If Not String.IsNullOrWhiteSpace(dto.receipt_number) Then parts.Add("#" & dto.receipt_number)
            If dto.total.HasValue Then parts.Add(dto.total.Value.ToString("N2") & " " & If(dto.currency, ""))
        Else
            Try
                Dim o As JObject = JObject.Parse(json)
                Dim nom As String = o.Value(Of String)("merchant_name")
                Dim num As String = o.Value(Of String)("receipt_number")
                Dim tot As String = Convert.ToString(o("total"))
                If Not String.IsNullOrWhiteSpace(nom) Then parts.Add(nom)
                If Not String.IsNullOrWhiteSpace(num) Then parts.Add("#" & num)
                If Not String.IsNullOrWhiteSpace(tot) Then parts.Add(tot & " " & Convert.ToString(o("currency")))
            Catch
            End Try
        End If

        Return String.Join(" — ", parts)
    End Function

End Class

Public Class ReceiptDto
    Public Property merchant_phonenumber As String
    Public Property merchand_postalcode As String
    Public Property number_tps As String
    Public Property number_tvq As String
    Public Property merchant_street As String
    Public Property merchant_city As String
    Public Property merchant_state As String
    Public Property merchant_website As String
    Public Property merchant_email As String
    Public Property receipt_number As String
    Public Property merchant_type As String
    Public Property merchant_name As String
    Public Property merchant_address As String
    Public Property receipt_date As String
    Public Property currency As String
    Public Property subtotal As Decimal?
    Public Property total As Decimal?
    Public Property tip As Decimal?
    Public Property payment_method As String
    Public Property last4 As String
    Public Property items As List(Of ReceiptItemDto)
    Public Property taxes As List(Of ReceiptTaxDto)
End Class

Public Class ReceiptItemDto
    Public Property desc As String
    Public Property qty As Decimal?
    Public Property unit_price As Decimal?
    Public Property amount As Decimal?
End Class

Public Class ReceiptTaxDto
    Public Property name As String
    Public Property amount As Decimal?
End Class
