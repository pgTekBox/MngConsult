Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Liste des abonnés (locataires) avec recherche et filtre par statut.
''' </summary>
Public Class wbfAbonnes
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Le master redirige les non-authentifiés ; on évite tout accès BD ici.
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            BindList()
        End If
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        BindList()
    End Sub

    Private Sub BindList()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Search", TextOrDbNull(tbSearch.Text)))
            p.Add(New SqlParameter("@Statut", TextOrDbNull(ddlStatut.SelectedValue)))

            Dim ds As DataSet = ExecuteSQLds("s0004ListAbonnes", p)
            Dim tbl As DataTable = ds.Tables(0)

            rptAbonnes.DataSource = tbl
            rptAbonnes.DataBind()

            Dim n As Integer = tbl.Rows.Count
            rptAbonnes.Visible = (n > 0)
            pnlEmpty.Visible = (n = 0)
            litCount.Text = n & If(n = 1, " abonné", " abonnés")
        Catch ex As Exception
            pnlError.Visible = True
            litError.Text = "Impossible de charger la liste des abonnés. Vérifiez que les scripts de base de données ont été exécutés."
            System.Diagnostics.Debug.WriteLine("BindList abonnés: " & ex.Message)
            rptAbonnes.Visible = False
            pnlEmpty.Visible = False
        End Try
    End Sub

    Private Function TextOrDbNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    ' --- Helpers d'affichage utilisés par le Repeater ---

    Protected Function DisplaySecondary(nom As Object) As String
        Dim s As String = If(nom Is Nothing OrElse IsDBNull(nom), "", nom.ToString())
        If s.Trim().Length = 0 Then Return ""
        Return "<div class=""muted"" style=""font-size:12px"">" & Server.HtmlEncode(s) & "</div>"
    End Function

    Protected Function VilleProvince(ville As Object, prov As Object) As String
        Dim v As String = If(ville Is Nothing OrElse IsDBNull(ville), "", ville.ToString())
        Dim p As String = If(prov Is Nothing OrElse IsDBNull(prov), "", prov.ToString())
        Dim parts As New List(Of String)
        If v.Trim().Length > 0 Then parts.Add(v)
        If p.Trim().Length > 0 Then parts.Add(p)
        Return String.Join(", ", parts)
    End Function

    Protected Function FormatDate(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd")
    End Function

    Protected Function BadgeStatut(statut As Object) As String
        Select Case If(statut, "").ToString()
            Case "Actif" : Return "badge-actif"
            Case "Suspendu" : Return "badge-suspendu"
            Case "Ferme" : Return "badge-ferme"
            Case Else : Return "badge-prospect"
        End Select
    End Function

    Protected Function LabelStatut(statut As Object) As String
        Select Case If(statut, "").ToString()
            Case "Ferme" : Return "Fermé"
            Case Else : Return If(statut, "").ToString()
        End Select
    End Function

    Protected Function BadgeKyb(kyb As Object) As String
        Select Case If(kyb, "").ToString()
            Case "Verifie" : Return "badge-verifie"
            Case "EnCours" : Return "badge-encours"
            Case "Rejete" : Return "badge-rejete"
            Case Else : Return "badge-nondebute"
        End Select
    End Function

    Protected Function LabelKyb(kyb As Object) As String
        Select Case If(kyb, "").ToString()
            Case "Verifie" : Return "Vérifié"
            Case "EnCours" : Return "En cours"
            Case "Rejete" : Return "Rejeté"
            Case "NonDebute" : Return "Non débuté"
            Case Else : Return If(kyb, "").ToString()
        End Select
    End Function

End Class
