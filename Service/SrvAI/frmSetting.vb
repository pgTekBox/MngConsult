Imports System.Windows.Forms


Public Class frmSetting





    Private Sub frmSetting_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Dim oXMLconfig As New clsXmlConfig

        txtConnectionString.Text = oXMLconfig.ConnectionString
        txtPort.Text = oXMLconfig.SocketPort

        txtAddress.Text = oXMLconfig.IpAdresse

        If oXMLconfig.UseDatabase = "1" Then
            chkUseDatabase.Checked = True
        Else
            chkUseDatabase.Checked = False
        End If




        BinDomaine()


    End Sub

    Private Sub btnOk_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnOk.Click
        Dim oXMLconfig As New clsXmlConfig

        If chkUseDatabase.Checked = True Then
            oXMLconfig.UseDatabase = "1"
        Else
            oXMLconfig.UseDatabase = "0"
        End If

        oXMLconfig.ConnectionString = txtConnectionString.Text

        oXMLconfig.SocketPort = txtPort.Text
        oXMLconfig.IpAdresse = txtAddress.Text

        oXMLconfig.Domaines = tblDomaine
        oXMLconfig.saveAll()



        Me.Close()
    End Sub

    Private Sub btnCancel_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles btnCancel.Click
        Me.Close()
    End Sub

    Private Sub btnAddDomaine_Click(sender As Object, e As EventArgs) Handles btnAddDomaine.Click
        Dim ofrmdoamin As frmDomaine

        ofrmdoamin = New frmDomaine


        ofrmdoamin.ShowDialog()






        BinDomaine()
    End Sub
    Dim tblDomaine As DataTable
    Private Sub btnRemoveDomaine_Click(sender As Object, e As EventArgs) Handles btnRemoveDomaine.Click
        If dvListDomain.SelectedRows.Count = 0 Then Return

        Dim orow As System.Windows.Forms.DataGridViewRow = dvListDomain.SelectedRows(0)
        Dim sDomaineName As String = orow.Cells(0).Value

        Dim oXMLconfig As New clsXmlConfig
        oXMLconfig.RemoveDomaine(sDomaineName)
        oXMLconfig.saveAll()
        tblDomaine = oXMLconfig.Domaines

        dvListDomain.DataSource = tblDomaine
    End Sub

    Sub BinDomaine()
        Dim oXMLconfig As New clsXmlConfig

        If oXMLconfig.UseDatabase = "1" Then
            chkUseDatabase.Checked = True
        Else
            chkUseDatabase.Checked = False
        End If



        txtConnectionString.Text = oXMLconfig.ConnectionString
        txtPort.Text = oXMLconfig.SocketPort

        txtAddress.Text = oXMLconfig.IpAdresse
        tblDomaine = oXMLconfig.Domaines
        dvListDomain.DataSource = tblDomaine

    End Sub
End Class