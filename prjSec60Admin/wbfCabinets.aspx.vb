Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports Telerik.Web.UI

''' <summary>
''' Abonnements › Cabinets certifiés : l'annuaire des cabinets comptables
''' certifiés 60secondes (T319), celui que l'ERP montre à ses utilisateurs par
''' le bouton « Cabinets certifiés » de son en-tête. Liste avec recherche
''' (s0901, actifs et inactifs), fiche en fenêtre (wbfCabinetEdit.aspx),
''' suppression (s0904).
''' </summary>
Public Class wbfCabinets
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            rlvCabinets.Rebind()
        End If
    End Sub

    Private Sub rlvCabinets_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvCabinets.NeedDataSource
        rlvCabinets.DataSource = GetData()
    End Sub

    Private Sub rlvCabinets_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvCabinets.ItemCommand
        Select Case e.CommandName
            Case "DeleteCabinet"
                Dim id As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), id)
                If id > 0 Then
                    DeleteCabinet(id)
                    rlvCabinets.Rebind()
                End If
        End Select
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvCabinets.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvCabinets.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rlvCabinets.Rebind()
        End If
    End Sub

    Private Function GetData() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@Search", tbSearch.Text.Trim()))
        Dim ds As DataSet = ExecuteSQLds("s0901GetCabinetsAdminList", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub DeleteCabinet(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        ExecuteSQL("s0904DeleteCabinet", p)
    End Sub

    ' ---------------------------------------------------------------------
    ' Rendu des colonnes
    ' ---------------------------------------------------------------------
    Public Function S(o As Object) As String
        If o Is Nothing OrElse o Is DBNull.Value Then Return ""
        Return o.ToString()
    End Function

    ''' <summary>Les initiales du cabinet (deux lettres au plus), pour l'icône.</summary>
    Public Function GetInitials(nom As Object) As String
        Dim sb As New Text.StringBuilder()
        For Each mot As String In S(nom).Split(New Char() {" "c, "-"c}, StringSplitOptions.RemoveEmptyEntries)
            If Char.IsLetter(mot(0)) Then sb.Append(Char.ToUpperInvariant(mot(0)))
            If sb.Length = 2 Then Exit For
        Next
        Return If(sb.Length = 0, "?", sb.ToString())
    End Function

    ''' <summary>Sous le nom : le responsable, le courriel (lien), le téléphone, l'année de certification.</summary>
    Public Function GetMeta(resp As Object, courriel As Object, tel As Object, depuis As Object) As String
        Dim parts As New List(Of String)
        If S(resp) <> "" Then parts.Add(Server.HtmlEncode(S(resp)))
        If S(courriel) <> "" Then parts.Add("<a href=""mailto:" & Server.HtmlEncode(S(courriel)) & """>" & Server.HtmlEncode(S(courriel)) & "</a>")
        If S(tel) <> "" Then parts.Add(Server.HtmlEncode(S(tel)))
        If depuis IsNot Nothing AndAlso Not depuis Is DBNull.Value Then parts.Add("Certifié depuis " & Convert.ToDateTime(depuis).Year.ToString(CultureInfo.InvariantCulture))
        Return String.Join(" · ", parts)
    End Function

    Public Function GetLieu(ville As Object, province As Object) As String
        Dim v As String = S(ville), p As String = S(province)
        If v = "" Then Return "—"
        If p = "" Then Return Server.HtmlEncode(v)
        Return Server.HtmlEncode(v & " (" & p & ")")
    End Function

    ''' <summary>Les codes de langues en badges.</summary>
    Public Function GetLangues(langues As Object) As String
        Dim sb As New Text.StringBuilder()
        For Each l As String In S(langues).Split(New Char() {","c}, StringSplitOptions.RemoveEmptyEntries)
            sb.Append("<span class=""badge lang"">").Append(Server.HtmlEncode(l.Trim().ToUpperInvariant())).Append("</span>")
        Next
        Return sb.ToString()
    End Function

    ''' <summary>Les codes de spécialités, traduits, en badges.</summary>
    Public Function GetSpecialites(specs As Object) As String
        Dim sb As New Text.StringBuilder()
        For Each code As String In S(specs).Split(New Char() {","c}, StringSplitOptions.RemoveEmptyEntries)
            sb.Append("<span class=""badge spec"">").Append(Server.HtmlEncode(wbfCabinetEdit.LibelleSpecialite(code))).Append("</span>")
        Next
        Return sb.ToString()
    End Function

End Class
