Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Tableau de bord de l'abonne : soldes (disponible / reserve / EFT en cours)
''' et activite recente (grand livre scope a l'AbonneId de la session).
''' </summary>
Public Class Default_aspx
    Inherits clsData

    Protected WithEvents litHello As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litSolde As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litReserve As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litEftIn As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litEftOut As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents rptJournal As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlNoJournal As Global.System.Web.UI.WebControls.Panel

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            litHello.Text = Server.HtmlEncode(If(String.IsNullOrEmpty(UserName), UserEmail, UserName))
            LoadBalances()
            BindJournal()
        End If
    End Sub

    Private Sub LoadBalances()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            Dim t As DataTable = ExecuteSQLds("s0015GetAbonneBalances", p).Tables(0)
            If t.Rows.Count = 0 Then
                litSolde.Text = Money(0) : litReserve.Text = Money(0)
                litEftIn.Text = Money(0) : litEftOut.Text = Money(0)
                Return
            End If
            Dim r As DataRow = t.Rows(0)
            litSolde.Text = Money(r("SoldeCents"))
            litReserve.Text = Money(r("ReserveCents"))
            litEftIn.Text = Money(r("EftInCents"))
            litEftOut.Text = Money(r("EftOutCents"))
        Catch ex As Exception
            ShowError("Impossible de charger les soldes. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN Dash balances: " & ex.Message)
        End Try
    End Sub

    Private Sub BindJournal()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Top", 15))
            Dim t As DataTable = ExecuteSQLds("s0016ListAbonneJournal", p).Tables(0)
            rptJournal.DataSource = t
            rptJournal.DataBind()
            rptJournal.Visible = (t.Rows.Count > 0)
            pnlNoJournal.Visible = (t.Rows.Count = 0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ABN Dash journal: " & ex.Message)
        End Try
    End Sub

    ''' <summary>Formate un delta signe (en cents) avec couleur.</summary>
    Protected Function DeltaHtml(cents As Object) As String
        Dim c As Long = If(cents Is Nothing OrElse IsDBNull(cents), 0L, Convert.ToInt64(cents))
        If c = 0 Then Return "<span class=""muted"">—</span>"
        Dim cls As String = If(c > 0, "delta-pos", "delta-neg")
        Dim sign As String = If(c > 0, "+", "")
        Return "<span class=""" & cls & """>" & sign & Money(c) & "</span>"
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
