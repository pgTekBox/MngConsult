Imports Telerik.Web.UI
Imports System.Data
Imports System.Data.SqlClient

Public Class wbfReleve
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            rlvReleve.Rebind()
        End If
    End Sub

    Private Sub rlvReleve_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvReleve.NeedDataSource
        Dim dt As DataTable = GetData()
        rlvReleve.DataSource = dt
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvReleve.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvReleve.Rebind()
    End Sub

    Private Function GetData() As DataTable
        Dim dt As New DataTable()
        Dim q As String = tbSearch.Text.Trim()

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", q))
        dt = ExecuteSQLds("s0047GetReleveBancaire", p).Tables(0)

        'Using cn As New SqlConnection(GetConnectionString())
        '    Using cmd As New SqlCommand("
        '        SELECT
        '            Id,
        '            ReleveBancaireGUID,
        '            CompanyGUID,
        '            DateMouvement,
        '            Description,
        '            Reference,
        '            Montant,
        '            CompteBanque,
        '            Statut,
        '            ReglementId,
        '            Created,
        '            CreatedBy
        '        FROM dbo.T142ReleveBancaire
        '        WHERE CompanyGUID = @CompanyGUID
        '          AND (
        '                @Search = ''
        '                OR Description LIKE '%' + @Search + '%'
        '                OR Reference LIKE '%' + @Search + '%'
        '                OR CompteBanque LIKE '%' + @Search + '%'
        '                OR Statut LIKE '%' + @Search + '%'
        '              )
        '        ORDER BY DateMouvement DESC, Id DESC", cn)

        '        cmd.Parameters.AddWithValue("@CompanyGUID", Company)
        '        cmd.Parameters.AddWithValue("@Search", q)

        '        Using da As New SqlDataAdapter(cmd)
        '            da.Fill(dt)
        '        End Using
        '    End Using
        'End Using

        Return dt
    End Function

    Protected Function FormatDateOnly(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return ""
        Return Convert.ToDateTime(value).ToString("dd MMM yyyy").ToLower()
    End Function

    Protected Function FormatMontant(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return "0.00 $"
        Dim m As Decimal = Convert.ToDecimal(value)
        Return m.ToString("#,##0.00 $")
    End Function

    Protected Function GetMontantCss(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return ""
        Dim m As Decimal = Convert.ToDecimal(value)

        If m < 0D Then
            Return "montant-negatif"
        ElseIf m > 0D Then
            Return "montant-positif"
        End If

        Return ""
    End Function

    Protected Function GetStatutCss(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then
            Return "badge-statut"
        End If

        Dim s As String = value.ToString().Trim().ToLower()

        Select Case s
            Case "réglé", "reglé", "regle", "payé", "paye", "traité", "traite"
                Return "badge-statut regle"

            Case "en attente", "attente", "a traiter", "à traiter"
                Return "badge-statut enattente"

            Case "ignoré", "ignore"
                Return "badge-statut ignore"

            Case Else
                Return "badge-statut"
        End Select
    End Function

    Private Function GetConnectionString() As String
        Return ConnectionString
    End Function


End Class