Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

''' <summary>
''' Abonnements › Métiers : la liste des métiers (T330Metier, T330MetierProfil) que
''' 60Sec-AI propose dans Paramètres › Entreprise › Métier et dans « Qui fait quoi ».
''' Liste avec recherche (s0913, actifs et inactifs, nombre de compagnies qui ont
''' choisi le métier), fiche en fenêtre (wbfMetierEdit.aspx), suppression (s0916,
''' refusée si des compagnies l'ont choisi).
''' </summary>
Public Class wbfMetiers
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            rlvMetiers.Rebind()
        End If
    End Sub

    Private Sub rlvMetiers_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvMetiers.NeedDataSource
        rlvMetiers.DataSource = GetData()
    End Sub

    Private Sub rlvMetiers_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvMetiers.ItemCommand
        Select Case e.CommandName
            Case "DeleteMetier"
                Dim id As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), id)
                If id > 0 Then
                    DeleteMetier(id)
                    rlvMetiers.Rebind()
                End If
        End Select
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvMetiers.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvMetiers.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rlvMetiers.Rebind()
        End If
    End Sub

    Private Function GetData() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@Search", tbSearch.Text.Trim()))
        Dim ds As DataSet = ExecuteSQLds("s0913GetMetiersAdminList", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    ''' <summary>s0916 refuse un métier choisi par des compagnies : son message s'affiche au-dessus de la liste.</summary>
    Private Sub DeleteMetier(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            ExecuteSQL("s0916DeleteMetier", p)
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

    ''' <summary>Les initiales du métier (deux lettres au plus), pour l'icône.</summary>
    Public Function GetInitials(nom As Object) As String
        Dim sb As New Text.StringBuilder()
        For Each mot As String In S(nom).Split(New Char() {" "c, "-"c, "("c}, StringSplitOptions.RemoveEmptyEntries)
            If Char.IsLetter(mot(0)) Then sb.Append(Char.ToUpperInvariant(mot(0)))
            If sb.Length = 2 Then Exit For
        Next
        Return If(sb.Length = 0, "?", sb.ToString())
    End Function

    ''' <summary>Les profils (« TA, Cie 0, Cie 1-4 ») en badges.</summary>
    Public Function GetProfils(profils As Object) As String
        Dim sb As New Text.StringBuilder()
        For Each p As String In S(profils).Split(New Char() {","c}, StringSplitOptions.RemoveEmptyEntries)
            sb.Append("<span class=""badge profil"">").Append(Server.HtmlEncode(p.Trim())).Append("</span>")
        Next
        Return sb.ToString()
    End Function

    Public Function GetCompagnies(n As Object) As String
        Dim nb As Integer = If(n Is Nothing OrElse n Is DBNull.Value, 0, Convert.ToInt32(n))
        If nb = 0 Then Return "—"
        Return If(nb = 1, "1 compagnie", nb & " compagnies")
    End Function

End Class
