Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Liste des fournisseurs (beneficiaires) de l'abonne connecte, avec
''' indicateur « prêt EFT ». Creation/edition via wbfFournisseur.aspx.
''' Scopee a l'AbonneId de la session.
''' </summary>
Public Class wbfFournisseurs
    Inherits clsData

    Protected WithEvents pnlOk As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litOk As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents tbSearch As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnSearch As Global.System.Web.UI.WebControls.Button
    Protected WithEvents rpt As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlEmpty As Global.System.Web.UI.WebControls.Panel

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            If Request.QueryString("saved") = "1" Then
                pnlOk.Visible = True
                litOk.Text = "Fournisseur enregistré."
            End If
            Bind()
        End If
    End Sub

    Private Sub Bind()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Search", NzOrNull(tbSearch.Text)))
            p.Add(New SqlParameter("@Statut", DBNull.Value))
            Dim t As DataTable = ExecuteSQLds("s0035ListFournisseurs", p).Tables(0)
            rpt.DataSource = t
            rpt.DataBind()
            rpt.Visible = (t.Rows.Count > 0)
            pnlEmpty.Visible = (t.Rows.Count = 0)
        Catch ex As Exception
            ShowError("Impossible de charger les fournisseurs. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN Fourn bind: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        Bind()
    End Sub

    Protected Function EftReady(v As Object) As String
        Dim ready As Boolean = Not (v Is Nothing OrElse IsDBNull(v)) AndAlso CBool(v)
        If ready Then Return "<span class=""eft-yes"">✔ Oui</span>"
        Return "<span class=""eft-no"">— Non</span>"
    End Function

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
