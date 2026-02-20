Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI.Editor.DialogControls
Imports Telerik.Web.UI



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

    Public Sub ExecuteSQL(ByVal SQLStatement As String)
        Dim oCom As New SqlClient.SqlCommand
        oCom.CommandText = SQLStatement
        oCom.Connection = New SqlClient.SqlConnection(ConnectionString)
        oCom.CommandType = CommandType.StoredProcedure
        oCom.Connection.Open()
        oCom.ExecuteNonQuery()
        oCom.Connection.Close()
    End Sub
    Public Sub ExecuteSQL(ByVal SQLStatement As String, AllParameters As Collection)
        Dim DRconn As SqlClient.SqlConnection
        DRconn = New SqlClient.SqlConnection(ConnectionString)


        Dim oCom As New SqlClient.SqlCommand
        oCom.CommandText = SQLStatement
        oCom.Connection = DRconn
        oCom.CommandType = CommandType.StoredProcedure


        For Each oParam As Data.SqlClient.SqlParameter In AllParameters
            oCom.Parameters.Add(oParam)
        Next

        oCom.Connection.Open()
        oCom.ExecuteNonQuery()
        oCom.Connection.Close()

    End Sub
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
        Dim oCom As New SqlClient.SqlCommand(SQLStatement, oCon)
        oCom.CommandType = CommandType.StoredProcedure
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

    Sub SetDDL(ByVal oDDL As RadDropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String)

        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand(SQLStatement, oCon)
        oCom.CommandType = CommandType.StoredProcedure
        Dim oDr As SqlClient.SqlDataReader
        oDr = oCom.ExecuteReader
        oDDL.Items.Clear()
        Do While oDr.Read()
            Dim MyItem As New DropDownListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))
            oDDL.Items.Add(MyItem)

        Loop
        oDr.Close()
        oCom.Connection.Close()
        oCon.Close()

        For Each oItem As DropDownListItem In oDDL.Items
            oItem.Selected = False
        Next

    End Sub


    Sub SetDDL(ByVal oDDL As RadDropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String, ByVal SetSelectedValue As Integer)

        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand(SQLStatement, oCon)
        oCom.CommandType = CommandType.StoredProcedure
        Dim oDr As SqlClient.SqlDataReader
        oDr = oCom.ExecuteReader
        oDDL.Items.Clear()
        Do While oDr.Read()
            Dim MyItem As New DropDownListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))
            If SetSelectedValue = oDr(KeyField) Then MyItem.Selected = True
            oDDL.Items.Add(MyItem)

        Loop
        oDr.Close()
        oCom.Connection.Close()
        oCon.Close()

        For Each oItem As DropDownListItem In oDDL.Items
            oItem.Selected = False

        Next
        For Each oItem As DropDownListItem In oDDL.Items
            If SetSelectedValue = oItem.Value Then
                oItem.Selected = True
                Exit For
            End If
        Next

    End Sub


    Sub SetDDL(ByVal oDDL As System.Web.UI.WebControls.DropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String, ByVal SetSelectedValue As Integer)

        Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
        oCon.Open()
        Dim oCom As New SqlClient.SqlCommand(SQLStatement, oCon)
        oCom.CommandType = CommandType.StoredProcedure
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


    'Sub SetDDL(ByVal oDDL As System.Web.UI.WebControls.DropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String, DefaultValue As Integer)



    '    Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
    '    oCon.Open()
    '    Dim oCom As New SqlClient.SqlCommand("exec " & SQLStatement, oCon)
    '    Dim oDr As SqlClient.SqlDataReader
    '    oDr = oCom.ExecuteReader
    '    oDDL.Items.Clear()
    '    Do While oDr.Read()

    '        Dim MyItem As New ListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))

    '        If oDr(KeyField) = DefaultValue Then
    '            MyItem.Selected = True
    '            oDDL.SelectedValue = DefaultValue.ToString
    '        End If
    '        oDDL.Items.Add(MyItem)

    '    Loop
    '    oDr.Close()
    '    oCom.Connection.Close()
    '    oCon.Close()

    'End Sub



    'Sub SetDDL(ByVal oDDL As System.Web.UI.WebControls.DropDownList, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String)



    '    Dim oCon As New SqlClient.SqlConnection(Me.ConnectionString)
    '    oCon.Open()
    '    Dim oCom As New SqlClient.SqlCommand("exec " & SQLStatement, oCon)
    '    Dim oDr As SqlClient.SqlDataReader
    '    oDr = oCom.ExecuteReader
    '    oDDL.Items.Clear()
    '    Do While oDr.Read()

    '        Dim MyItem As New ListItem(CheckStringNull(oDr(DisplayName)), CheckStringNull(oDr(KeyField).ToString))

    '        oDDL.Items.Add(MyItem)

    '    Loop
    '    oDr.Close()
    '    oCom.Connection.Close()
    '    oCon.Close()

    'End Sub




    Sub SetListBox(ByVal oDDL As System.Web.UI.WebControls.ListBox, ByVal DisplayName As String, ByVal KeyField As String, ByVal SQLStatement As String)

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

    'Private Function CheckStringNull(ByVal oObj As Object) As Object
    '    If IsDBNull(oObj) Then
    '        Return ""
    '    Else
    '        Return oObj
    '    End If
    'End Function
    Public Sub FillListBox(ByVal SQLstatement As String, ByVal SelectSQL As String, ByRef lstBox As System.Web.UI.WebControls.ListBox)

        Dim oDa As New SqlClient.SqlDataAdapter(SQLstatement & "," & SelectSQL, ConnectionString)
        Dim oDs As New DataSet

        Dim iSelectedIndex As Integer = -1

        lstBox.Items.Clear()
        oDa.Fill(oDs)
        lstBox.DataSource = oDs.Tables(0)
        lstBox.DataTextField = "Name"
        lstBox.DataValueField = "Id"
        lstBox.DataBind()
    End Sub
    Public Sub FillListBox(ByVal SQLstatement As String, ByRef lstBox As System.Web.UI.WebControls.ListBox)

        Dim oDa As New SqlClient.SqlDataAdapter(SQLstatement, ConnectionString)
        Dim oDs As New DataSet

        Dim iSelectedIndex As Integer = -1

        lstBox.Items.Clear()
        oDa.Fill(oDs)
        lstBox.DataSource = oDs.Tables(0)
        lstBox.DataTextField = "Name"
        lstBox.DataValueField = "Id"
        lstBox.DataBind()
    End Sub

    Public Sub SetRadComboCheckBox(oCombo As RadComboBox, sList As String)

        Dim arrItem As Array = sList.Split(",")



        For z As Integer = 0 To arrItem.Length - 1
            Dim sListitem As String = arrItem(z)
            For Each oItem As Telerik.Web.UI.RadComboBoxItem In oCombo.Items
                If sListitem = oItem.Value Then
                    oItem.Checked = True
                End If
            Next
        Next


    End Sub

    Public Sub SetRadComboCheckBox(oCombo As RadDropDownTree, sList As String)

        oCombo.EmbeddedTree.UncheckAllNodes()

        Dim arrItem As Array = sList.Split(",")



        For z As Integer = 0 To arrItem.Length - 1
            Dim sListitem As String = arrItem(z)
            Dim oItem As Telerik.Web.UI.RadTreeNode = oCombo.EmbeddedTree.FindNodeByValue(sListitem)
            If Not oItem Is Nothing Then
                If sListitem = oItem.Value Then
                    oItem.Checked = True
                End If
            End If
        Next
    End Sub





End Class
