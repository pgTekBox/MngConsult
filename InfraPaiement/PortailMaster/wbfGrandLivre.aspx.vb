Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization

''' <summary>
''' Grand livre / solde d'un abonné : soldes, saisie d'écritures (partie
''' double via s0017) et journal. Toujours scopé par ?abonneId=N.
''' </summary>
Public Class wbfGrandLivre
    Inherits clsData

    Private Shared ReadOnly Cult As CultureInfo = New CultureInfo("fr-CA")

    Private ReadOnly Property AbonneId() As Integer
        Get
            Dim v As Integer
            Integer.TryParse(Request.QueryString("abonneId"), v)
            Return v
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return

        If AbonneId <= 0 Then
            Response.Redirect("~/wbfAbonnes.aspx")
            Return
        End If

        lnkAbonne.HRef = "wbfAbonne.aspx?id=" & AbonneId
        lnkClients.HRef = "wbfClients.aspx?abonneId=" & AbonneId
        lnkPaiements.HRef = "wbfPaiements.aspx?abonneId=" & AbonneId

        If Not IsPostBack Then
            If Not LoadAbonneName() Then Return
            hfIdem.Value = Guid.NewGuid().ToString("N")
            UpdateFraisVisibility()
            LoadBalances()
            LoadJournal()
            If Request.QueryString("saved") = "1" Then
                pnlOk.Visible = True
                litOk.Text = "Écriture comptabilisée."
            End If
        End If
    End Sub

    Protected Sub ddlOperation_Changed(sender As Object, e As EventArgs)
        UpdateFraisVisibility()
    End Sub

    ''' <summary>Le champ « frais » n'a de sens que pour un encaissement.</summary>
    Private Sub UpdateFraisVisibility()
        rowFrais.Visible = (ddlOperation.SelectedValue = "Encaissement")
    End Sub

    Private Function LoadAbonneName() As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", AbonneId))
            Dim tbl As DataTable = ExecuteSQLds("s0005GetAbonne", p).Tables(0)
            If tbl.Rows.Count = 0 Then
                Response.Redirect("~/wbfAbonnes.aspx")
                Return False
            End If
            Dim nom As String = tbl.Rows(0)("RaisonSociale").ToString()
            litAbonne.Text = Server.HtmlEncode(nom)
            lnkAbonne.InnerText = nom
            Return True
        Catch ex As Exception
            ShowError("Impossible de charger l'abonné. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("GL LoadAbonneName: " & ex.Message)
            Return False
        End Try
    End Function

    Private Sub LoadBalances()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            Dim r As DataRow = ExecuteSQLds("s0015GetAbonneBalances", p).Tables(0).Rows(0)
            litSolde.Text = Money(r("SoldeCents"))
            litReserve.Text = Money(r("ReserveCents"))
            litEftIn.Text = Money(r("EftInCents"))
            litEftOut.Text = Money(r("EftOutCents"))
        Catch ex As Exception
            ShowError("Impossible de charger les soldes. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("GL LoadBalances: " & ex.Message)
        End Try
    End Sub

    Private Sub LoadJournal()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Top", 50))
            Dim tbl As DataTable = ExecuteSQLds("s0016ListAbonneJournal", p).Tables(0)
            rptJournal.DataSource = tbl
            rptJournal.DataBind()
            rptJournal.Visible = (tbl.Rows.Count > 0)
            pnlEmpty.Visible = (tbl.Rows.Count = 0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("GL LoadJournal: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnPost_Click(sender As Object, e As EventArgs)

        Dim op As String = ddlOperation.SelectedValue
        Dim amountCents As Long = ParseMoneyToCents(tbMontant.Text)
        Dim feeCents As Long = 0
        If op = "Encaissement" Then feeCents = ParseMoneyToCents(tbFrais.Text)

        If amountCents <= 0 Then
            ShowError("Le montant doit être supérieur à zéro.")
            LoadBalances() : LoadJournal()
            Return
        End If
        If op = "Encaissement" AndAlso (feeCents < 0 OrElse feeCents > amountCents) Then
            ShowError("Les frais doivent être compris entre 0 et le montant.")
            LoadBalances() : LoadJournal()
            Return
        End If

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Operation", op))
            p.Add(New SqlParameter("@AmountCents", amountCents))
            p.Add(New SqlParameter("@FeeCents", feeCents))
            p.Add(New SqlParameter("@Description", ParamOrNull(tbDescription.Text)))
            p.Add(New SqlParameter("@IdempotencyKey", If(String.IsNullOrEmpty(hfIdem.Value), CObj(DBNull.Value), hfIdem.Value)))
            p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))

            ExecuteSQLds("s0017RecordAbonneMovement", p)

            Response.Redirect("wbfGrandLivre.aspx?abonneId=" & AbonneId & "&saved=1")

        Catch sqlEx As SqlException
            ' Les règles métier (solde insuffisant, etc.) remontent en RAISERROR lisible.
            ShowError(sqlEx.Message)
            LoadBalances() : LoadJournal()
        Catch ex As Exception
            ShowError("Comptabilisation impossible. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("GL Post: " & ex.Message)
            LoadBalances() : LoadJournal()
        End Try
    End Sub

    ' ------------------------------------------------------------------
    ' Helpers monétaires (cents entiers <-> affichage CAD)
    ' ------------------------------------------------------------------

    Protected Function Money(cents As Object) As String
        Dim c As Long = ToLong(cents)
        Return (c / 100D).ToString("N2", Cult) & " $"
    End Function

    ''' <summary>Delta signé et coloré pour le journal.</summary>
    Protected Function MoneyDelta(cents As Object) As String
        Dim c As Long = ToLong(cents)
        If c = 0 Then Return "<span class=""muted"">—</span>"
        Dim txt As String = (c / 100D).ToString("N2", Cult) & " $"
        If c > 0 Then Return "<span class=""pos"">+" & txt & "</span>"
        Return "<span class=""neg"">" & txt & "</span>"
    End Function

    Private Function ToLong(o As Object) As Long
        If o Is Nothing OrElse IsDBNull(o) Then Return 0
        Return Convert.ToInt64(o)
    End Function

    ''' <summary>Convertit une saisie « 10 », « 10.50 » ou « 10,50 » en cents.</summary>
    Private Function ParseMoneyToCents(s As String) As Long
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return 0
        v = v.Replace(" ", "").Replace("$", "").Replace(",", ".")
        Dim d As Double
        If Double.TryParse(v, NumberStyles.Any, CultureInfo.InvariantCulture, d) Then
            Return CLng(Math.Round(d * 100D, MidpointRounding.AwayFromZero))
        End If
        Return 0
    End Function

    Protected Function FormatDate(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd")
    End Function

    Protected Function LabelType(t As Object) As String
        Select Case If(t, "").ToString()
            Case "Encaissement" : Return "Encaissement"
            Case "Paiement" : Return "Paiement"
            Case "MiseEnReserve" : Return "Mise en réserve"
            Case "LiberationReserve" : Return "Libération réserve"
            Case Else : Return If(t, "").ToString()
        End Select
    End Function

    Private Function ParamOrNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
