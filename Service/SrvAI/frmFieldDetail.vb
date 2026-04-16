Imports System.Data.SqlClient

Public Class frmFieldDetail

    Public MailId As Integer
    Public FieldName As String
    Public ConnectionString As String

    Private Sub frmFieldDetail_Load(sender As Object, e As EventArgs) Handles MyBase.Load

    End Sub

    Private Sub frmFieldDetail_Shown(sender As Object, e As EventArgs) Handles Me.Shown
        Dim cnn As New SqlClient.SqlConnection
        cnn.ConnectionString = ConnectionString
        Dim comm As SqlCommand
        comm = cnn.CreateCommand()
        comm.CommandType = System.Data.CommandType.Text
        comm.CommandText = "select * from T400Mails  where id =" & MailId.ToString

        Dim MyDA As New SqlDataAdapter
        Dim MyDS As New DataSet
        comm.Connection = cnn
        MyDA.SelectCommand = comm
        MyDA.Fill(MyDS)

        txtValue.Text = CheckNull(MyDS.Tables(0).Rows(0)(FieldName))
        Me.Text = "Field detail: " & FieldName
    End Sub
    Function CheckNull(str As Object) As String
        If IsDBNull(str) Then Return ""


        Return str.ToString

    End Function
    Private Sub Button1_Click(sender As Object, e As EventArgs) Handles Button1.Click
        Me.Close()

    End Sub
End Class