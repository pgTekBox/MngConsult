Imports Newtonsoft.Json

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
    ''' Verifie que le texte est un JSON de recu exploitable et le renvoie.
    ''' Leve une exception explicite sinon : le service la journalise et
    ''' marque le recu en erreur plutot que de creer un document bancal.
    ''' </summary>
    Public Shared Function Parse(json As String) As ReceiptDto
        If String.IsNullOrWhiteSpace(json) Then
            Throw New Exception("JSON vide")
        End If

        Dim obj As ReceiptDto
        Try
            obj = JsonConvert.DeserializeObject(Of ReceiptDto)(json)
        Catch ex As Exception
            Throw New Exception("Erreur parsing JSON reçu : " & ex.Message)
        End Try

        If obj Is Nothing Then
            Throw New Exception("JSON invalide")
        End If

        If obj.items Is Nothing Then obj.items = New List(Of ReceiptItemDto)
        If obj.taxes Is Nothing Then obj.taxes = New List(Of ReceiptTaxDto)

        Return obj
    End Function

    ''' <summary>Resume d'une ligne pour le journal : de quoi reconnaitre le recu.</summary>
    Public Shared Function Describe(dto As ReceiptDto) As String
        If dto Is Nothing Then Return ""

        Dim parts As New List(Of String)
        If Not String.IsNullOrWhiteSpace(dto.merchant_name) Then parts.Add(dto.merchant_name)
        If Not String.IsNullOrWhiteSpace(dto.receipt_number) Then parts.Add("#" & dto.receipt_number)
        If dto.total.HasValue Then parts.Add(dto.total.Value.ToString("N2") & " " & If(dto.currency, ""))

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
