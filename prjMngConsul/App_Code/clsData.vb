Imports System.Data




Public Class clsData
    Inherits System.Web.UI.Page


    Public Property Company() As Guid
        Get
            Try


                Return Session("Company")
            Catch ex As Exception
                Return Guid.Empty
            End Try

        End Get
        Set(ByVal Value As Guid)
            Session("Company") = Value
        End Set
    End Property



    Private m_ConnectionString As String = ""
    Public Property ConnectionString() As String
        Get
            Try

                If m_ConnectionString.Length = 0 Then
                    Dim sConnect As String = System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
                    m_ConnectionString = sConnect
                End If
                Return m_ConnectionString
            Catch ex As Exception
                Return ""
            End Try

        End Get
        Set(ByVal Value As String)
            m_ConnectionString = Value
        End Set
    End Property


    Public Function ExecuteSQLds(ByVal SQLStatement As String) As DataSet
        Dim oDa As New SqlClient.SqlDataAdapter(SQLStatement, ConnectionString)
        Dim oDs As New DataSet
        oDa.Fill(oDs)
        Return oDs
    End Function

    Public Function ExecuteSQLds(ByVal SQLStatement As String, AllParameters As Collection) As DataSet



        Dim DRconn As SqlClient.SqlConnection
        DRconn = New SqlClient.SqlConnection(ConnectionString)
        Dim MyDA As New SqlClient.SqlDataAdapter

        Dim oCom As New SqlClient.SqlCommand
        oCom.CommandText = SQLStatement
        oCom.Connection = DRconn
        oCom.CommandType = CommandType.StoredProcedure
        MyDA.SelectCommand = oCom

        For Each oParam As Data.SqlClient.SqlParameter In AllParameters
            oCom.Parameters.Add(oParam)
        Next

        Dim oDs As New DataSet
        MyDA.Fill(oDs)
        Return oDs

    End Function

    Sub SetDDL(ByVal oDDL As System.Web.UI.WebControls.DropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String)

        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand("exec " & SQLStatement, oCon)
        Dim oDr As SqlClient.SqlDataReader
        oDr = oCom.ExecuteReader
        oDDL.Items.Clear()
        Do While oDr.Read()

            Dim MyItem As New ListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))
            oDDL.Items.Add(MyItem)

        Loop
        oDr.Close()
        oCom.Connection.Close()
        oCon.Close()

    End Sub

    Sub SetDDL(ByVal oDDL As System.Web.UI.WebControls.DropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String, ByVal SetSelectedValue As Integer)

        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand("exec " & SQLStatement, oCon)
        Dim oDr As SqlClient.SqlDataReader
        oDr = oCom.ExecuteReader
        oDDL.Items.Clear()
        Do While oDr.Read()

            Dim MyItem As New ListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))
            If SetSelectedValue = oDr(KeyField) Then MyItem.Selected = True
            oDDL.Items.Add(MyItem)

        Loop
        oDr.Close()
        oCom.Connection.Close()
        oCon.Close()


        For Each oItem As ListItem In oDDL.Items
            oItem.Selected = False

        Next
        For Each oItem As ListItem In oDDL.Items
            If SetSelectedValue = oItem.Value Then
                oItem.Selected = True
                Exit For
            End If

        Next





    End Sub
    Private Function CheckStringNull(ByVal oObj As Object) As Object
        If IsDBNull(oObj) Then
            Return ""
        Else
            Return oObj
        End If
    End Function
End Class
