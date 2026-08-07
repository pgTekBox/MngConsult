Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Gestion des clients (payeurs) de l'abonne connecte. Liste filtrable +
''' creation. Toutes les operations sont scopees a l'AbonneId de la session
''' (isolation multi-locataire) : un abonne ne voit jamais les clients d'un
''' autre.
''' </summary>
Public Class wbfClients
    Inherits clsData

    Protected WithEvents detAdd As Global.System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents pnlOk As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litOk As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents ddlType As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents tbRef As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbNom As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbEmail As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbTel As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbVille As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbProv As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnAdd As Global.System.Web.UI.WebControls.Button
    Protected WithEvents tbSearch As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnSearch As Global.System.Web.UI.WebControls.Button
    Protected WithEvents rpt As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlEmpty As Global.System.Web.UI.WebControls.Panel

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then Bind()
    End Sub

    Private Sub Bind()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Search", NzOrNull(tbSearch.Text)))
            p.Add(New SqlParameter("@Statut", DBNull.Value))
            Dim t As DataTable = ExecuteSQLds("s0011ListClients", p).Tables(0)
            rpt.DataSource = t
            rpt.DataBind()
            rpt.Visible = (t.Rows.Count > 0)
            pnlEmpty.Visible = (t.Rows.Count = 0)
        Catch ex As Exception
            ShowError("Impossible de charger les clients. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN Clients bind: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        Bind()
    End Sub

    Protected Sub btnAdd_Click(sender As Object, e As EventArgs)
        Dim nom As String = If(tbNom.Text, "").Trim()
        If nom.Length = 0 Then
            detAdd.Attributes("open") = "open"
            ShowError("Le nom du client est obligatoire.")
            Return
        End If
        Try
            Dim p As New Collection
            Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = 0}
            p.Add(outId)
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@TypeClient", ddlType.SelectedValue))
            p.Add(New SqlParameter("@Nom", nom))
            p.Add(New SqlParameter("@ReferenceExterne", NzOrNull(tbRef.Text)))
            p.Add(New SqlParameter("@CourrielContact", NzOrNull(tbEmail.Text)))
            p.Add(New SqlParameter("@Telephone", NzOrNull(tbTel.Text)))
            p.Add(New SqlParameter("@Ville", NzOrNull(tbVille.Text)))
            p.Add(New SqlParameter("@Province", NzOrNull(tbProv.Text)))
            ExecuteSQLds("s0013SaveClient", p)

            pnlOk.Visible = True
            litOk.Text = "Client « " & Server.HtmlEncode(nom) & " » créé."
            ClearForm()
            Bind()
        Catch sqlEx As SqlException
            detAdd.Attributes("open") = "open"
            If sqlEx.Number = 2601 OrElse sqlEx.Number = 2627 Then
                ShowError("Cette référence externe est déjà utilisée pour un autre client.")
            Else
                ShowError("Création impossible : " & sqlEx.Message)
            End If
        Catch ex As Exception
            detAdd.Attributes("open") = "open"
            ShowError("Création impossible.")
            System.Diagnostics.Debug.WriteLine("ABN Clients add: " & ex.Message)
        End Try
    End Sub

    Private Sub ClearForm()
        tbRef.Text = "" : tbNom.Text = "" : tbEmail.Text = ""
        tbTel.Text = "" : tbVille.Text = "" : tbProv.Text = ""
        ddlType.SelectedIndex = 0
    End Sub

    Protected Function BadgeStatut(s As Object) As String
        Select Case If(s, "").ToString()
            Case "Actif" : Return "badge-actif"
            Case "Bloque", "Bloqué" : Return "badge-rejete"
            Case Else : Return "badge-neutre"
        End Select
    End Function

    Private Function NzOrNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
