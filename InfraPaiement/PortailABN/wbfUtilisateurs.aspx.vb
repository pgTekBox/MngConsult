Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Liste des utilisateurs de l'abonne connecte (gestion multi-utilisateurs).
''' Reservee aux administrateurs de l'abonne (IsAbonneAdmin). Scopee a
''' l'AbonneId de la session.
''' </summary>
Public Class wbfUtilisateurs
    Inherits clsData

    Protected WithEvents pnlOk As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litOk As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents tbSearch As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnSearch As Global.System.Web.UI.WebControls.Button
    Protected WithEvents rpt As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlEmpty As Global.System.Web.UI.WebControls.Panel

    ''' <summary>Expose l'Id de l'utilisateur courant au data-binding (badge « vous »).</summary>
    Protected ReadOnly Property MonId() As Integer
        Get
            Return UserId
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsAbonneAdmin Then
            Response.Redirect("~/Default.aspx")
            Return
        End If
        If Not IsPostBack Then
            If Request.QueryString("saved") = "1" Then
                pnlOk.Visible = True
                litOk.Text = "Utilisateur enregistré."
            End If
            Bind()
        End If
    End Sub

    Private Sub Bind()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Search", NzOrNull(tbSearch.Text)))
            Dim t As DataTable = ExecuteSQLds("s0071ListAbonneUsers", p).Tables(0)
            rpt.DataSource = t
            rpt.DataBind()
            rpt.Visible = (t.Rows.Count > 0)
            pnlEmpty.Visible = (t.Rows.Count = 0)
        Catch ex As Exception
            ShowError("Impossible de charger les utilisateurs. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN Users bind: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        Bind()
    End Sub

    Protected Function NomAffiche(item As Object) As String
        Dim r As DataRowView = TryCast(item, DataRowView)
        If r Is Nothing Then Return ""
        Dim nom As String = ((If(IsDBNull(r("FirstName")), "", r("FirstName").ToString())) & " " &
                             (If(IsDBNull(r("LastName")), "", r("LastName").ToString()))).Trim()
        If nom.Length = 0 Then nom = r("Email").ToString()
        Return Server.HtmlEncode(nom)
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
