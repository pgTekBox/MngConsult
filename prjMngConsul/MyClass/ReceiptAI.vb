Imports Newtonsoft.Json

Public Class ReceiptAI
    Inherits clsData

    Public Sub New(sJson As String, uimageGUID As Guid)
        json = sJson
        imageGUID = uimageGUID
    End Sub
    Dim odto As ReceiptDto
    'Public Sub ReceiptAI(sJson As String)
    '    json = sJson
    'End Sub
    Dim imageGUID As Guid
    Public Function Strore2BD()



        Dim MyParamHeader As New Collection
        MyParamHeader.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
        Dim Myds As DataSet = ExecuteSQLds("s0008SaveMerchant", MyParamHeader)

        Dim MyParamDoc As New Collection
        MyParamDoc.Add(New Data.SqlClient.SqlParameter("@imageGUID", imageGUID))
        Dim MydsDoc As DataSet = ExecuteSQLds("s0009SaveDocument", MyParamDoc)

    End Function


    Public json As String
    Public MyReceiptDto As ReceiptDto

    Public Sub ProcesJSON()

        ParseReceiptJson()
        Strore2BD()
    End Sub

    Public Function ParseReceiptJson() As ReceiptDto

        If String.IsNullOrWhiteSpace(json) Then
            Throw New Exception("JSON vide")
        End If

        Try
            Dim obj = JsonConvert.DeserializeObject(Of ReceiptDto)(json)

            If obj Is Nothing Then
                Throw New Exception("JSON invalide")
            End If

            If obj.items Is Nothing Then obj.items = New List(Of ReceiptItemDto)
            If obj.taxes Is Nothing Then obj.taxes = New List(Of ReceiptTaxDto)
            MyReceiptDto = obj

            odto = obj

            Return obj

        Catch ex As Exception
            Throw New Exception("Erreur parsing JSON reçu : " & ex.Message)
        End Try

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
