Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

''' <summary>
''' Abonnements › Familles de métiers : les familles (T332FamilleMetier) parmi lesquelles
''' la fiche d'un métier (wbfMetierEdit.aspx) choisit la sienne. Liste avec recherche
''' (s0926, nombre de métiers de la famille), fiche en fenêtre (wbfFamilleMetierEdit.aspx),
''' suppression (s0929, refusée si des métiers portent encore la famille).
''' </summary>
Public Class wbfFamillesMetier
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            rlvFamilles.Rebind()
        End If
    End Sub

    Private Sub rlvFamilles_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvFamilles.NeedDataSource
        rlvFamilles.DataSource = GetData()
    End Sub

    Private Sub rlvFamilles_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvFamilles.ItemCommand
        Select Case e.CommandName
            Case "DeleteFamille"
                Dim id As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), id)
                If id > 0 Then
                    DeleteFamille(id)
                    rlvFamilles.Rebind()
                End If
        End Select
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvFamilles.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvFamilles.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rlvFamilles.Rebind()
        End If
    End Sub

    Private Function GetData() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@Search", tbSearch.Text.Trim()))
        Dim ds As DataSet = ExecuteSQLds("s0926GetFamillesMetierAdminList", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    ''' <summary>s0929 refuse une famille encore portée par des métiers : son message s'affiche au-dessus de la liste.</summary>
    Private Sub DeleteFamille(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            ExecuteSQL("s0929DeleteFamilleMetier", p)
            pnlMsg.Visible = False
        Catch ex As SqlException
            litMsg.Text = ex.Message
            pnlMsg.Visible = True
        End Try
    End Sub

    ' ---------------------------------------------------------------------
    ' Rendu des colonnes
    ' ---------------------------------------------------------------------
    Public Function S(o As Object) As String
        If o Is Nothing OrElse o Is DBNull.Value Then Return ""
        Return o.ToString()
    End Function

    ''' <summary>Les initiales de la famille (deux lettres au plus), pour l'icône.</summary>
    Public Function GetInitials(nom As Object) As String
        Dim sb As New Text.StringBuilder()
        For Each mot As String In S(nom).Split(New Char() {" "c, "-"c, "("c}, StringSplitOptions.RemoveEmptyEntries)
            If Char.IsLetter(mot(0)) Then sb.Append(Char.ToUpperInvariant(mot(0)))
            If sb.Length = 2 Then Exit For
        Next
        Return If(sb.Length = 0, "?", sb.ToString())
    End Function

    ''' <summary>« 12 métiers (10 actifs) », ou « — » pour une famille sans métier.</summary>
    Public Function GetMetiers(n As Object, actifs As Object) As String
        Dim nb As Integer = If(n Is Nothing OrElse n Is DBNull.Value, 0, Convert.ToInt32(n))
        Dim nbActifs As Integer = If(actifs Is Nothing OrElse actifs Is DBNull.Value, 0, Convert.ToInt32(actifs))
        If nb = 0 Then Return "—"
        Dim texte As String = If(nb = 1, "1 métier", nb & " métiers")
        If nbActifs <> nb Then texte &= " (" & nbActifs & If(nbActifs > 1, " actifs)", " actif)")
        Return texte
    End Function

End Class
