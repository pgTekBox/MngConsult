Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

''' <summary>
''' Abonnements › Secteurs d'activité : les secteurs (T333SecteurActivite) parmi lesquels
''' la fiche d'un métier (wbfMetierEdit.aspx) choisit le sien, facultatif. Liste avec recherche
''' (s0930, nombre de métiers du secteur), fiche en fenêtre (wbfSecteurActiviteEdit.aspx),
''' suppression (s0933, refusée si des métiers portent encore le secteur).
''' </summary>
Public Class wbfSecteursActivite
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            rlvSecteurs.Rebind()
        End If
    End Sub

    Private Sub rlvSecteurs_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvSecteurs.NeedDataSource
        rlvSecteurs.DataSource = GetData()
    End Sub

    Private Sub rlvSecteurs_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvSecteurs.ItemCommand
        Select Case e.CommandName
            Case "DeleteSecteur"
                Dim id As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), id)
                If id > 0 Then
                    DeleteSecteur(id)
                    rlvSecteurs.Rebind()
                End If
        End Select
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvSecteurs.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvSecteurs.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rlvSecteurs.Rebind()
        End If
    End Sub

    Private Function GetData() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@Search", tbSearch.Text.Trim()))
        Dim ds As DataSet = ExecuteSQLds("s0930GetSecteursActiviteAdminList", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    ''' <summary>s0933 refuse un secteur encore porté par des métiers : son message s'affiche au-dessus de la liste.</summary>
    Private Sub DeleteSecteur(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            ExecuteSQL("s0933DeleteSecteurActivite", p)
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

    ''' <summary>Les initiales du secteur (deux lettres au plus), pour l'icône.</summary>
    Public Function GetInitials(nom As Object) As String
        Dim sb As New Text.StringBuilder()
        For Each mot As String In S(nom).Split(New Char() {" "c, "-"c, "("c}, StringSplitOptions.RemoveEmptyEntries)
            If Char.IsLetter(mot(0)) Then sb.Append(Char.ToUpperInvariant(mot(0)))
            If sb.Length = 2 Then Exit For
        Next
        Return If(sb.Length = 0, "?", sb.ToString())
    End Function

    ''' <summary>« 12 métiers (10 actifs) », ou « — » pour un secteur sans métier.</summary>
    Public Function GetMetiers(n As Object, actifs As Object) As String
        Dim nb As Integer = If(n Is Nothing OrElse n Is DBNull.Value, 0, Convert.ToInt32(n))
        Dim nbActifs As Integer = If(actifs Is Nothing OrElse actifs Is DBNull.Value, 0, Convert.ToInt32(actifs))
        If nb = 0 Then Return "—"
        Dim texte As String = If(nb = 1, "1 métier", nb & " métiers")
        If nbActifs <> nb Then texte &= " (" & nbActifs & If(nbActifs > 1, " actifs)", " actif)")
        Return texte
    End Function

End Class
