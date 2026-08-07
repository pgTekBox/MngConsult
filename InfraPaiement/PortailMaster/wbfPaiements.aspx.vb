Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization

''' <summary>
''' Paiements EFT (encaissements clients) d'un abonné : initiation, règlement
''' simulé (individuel ou par lot) et retour NSF. Scopé par ?abonneId=N.
''' </summary>
Public Class wbfPaiements
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
        lnkGrandLivre.HRef = "wbfGrandLivre.aspx?abonneId=" & AbonneId

        If Not IsPostBack Then
            If Not LoadAbonneName() Then Return
            hfIdem.Value = Guid.NewGuid().ToString("N")
            LoadClients()
            BindList()
            ShowMsgFromQuery()
        End If
    End Sub

    ''' <summary>Affiche un message de succès après une action (PRG).</summary>
    Private Sub ShowMsgFromQuery()
        Dim msg As String = Request.QueryString("msg")
        If String.IsNullOrEmpty(msg) Then Return
        Dim txt As String
        Select Case msg
            Case "init" : txt = "Encaissement initié."
            Case "settle" : txt = "Paiement réglé."
            Case "ret" : txt = "Retour NSF enregistré."
            Case "batch" : txt = CInt(Val(Request.QueryString("n"))) & " paiement(s) réglé(s) par le lot."
            Case Else : Return
        End Select
        pnlOk.Visible = True
        litOk.Text = txt
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
            System.Diagnostics.Debug.WriteLine("Pay LoadAbonneName: " & ex.Message)
            Return False
        End Try
    End Function

    Private Sub LoadClients()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Statut", "Actif"))
            Dim tbl As DataTable = ExecuteSQLds("s0011ListClients", p).Tables(0)
            ddlClient.DataSource = tbl
            ddlClient.DataTextField = "Nom"
            ddlClient.DataValueField = "Id"
            ddlClient.DataBind()
            Dim none As Boolean = (tbl.Rows.Count = 0)
            hintNoClient.Visible = none
            btnCreate.Enabled = Not none
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Pay LoadClients: " & ex.Message)
        End Try
    End Sub

    Private Sub BindList()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Status", TextOrDbNull(ddlStatut.SelectedValue)))
            p.Add(New SqlParameter("@Search", TextOrDbNull(tbSearch.Text)))
            p.Add(New SqlParameter("@Direction", "Entrant"))
            Dim tbl As DataTable = ExecuteSQLds("s0023ListPayments", p).Tables(0)
            rptPay.DataSource = tbl
            rptPay.DataBind()
            Dim n As Integer = tbl.Rows.Count
            rptPay.Visible = (n > 0)
            pnlEmpty.Visible = (n = 0)
            litCount.Text = n & If(n = 1, " paiement", " paiements")
        Catch ex As Exception
            ShowError("Impossible de charger les paiements. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Pay BindList: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnFilter_Click(sender As Object, e As EventArgs)
        BindList()
    End Sub

    Protected Sub btnCreate_Click(sender As Object, e As EventArgs)
        Dim amount As Long = ParseMoneyToCents(tbMontant.Text)
        Dim fee As Long = ParseMoneyToCents(tbFrais.Text)

        If ddlClient.SelectedValue = "" Then
            ShowError("Sélectionnez un client.")
            BindList() : Return
        End If
        If amount <= 0 Then
            ShowError("Le montant doit être supérieur à zéro.")
            BindList() : Return
        End If
        If fee < 0 OrElse fee > amount Then
            ShowError("Les frais doivent être compris entre 0 et le montant.")
            BindList() : Return
        End If

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@ClientId", CInt(ddlClient.SelectedValue)))
            p.Add(New SqlParameter("@AmountCents", amount))
            p.Add(New SqlParameter("@FeeCents", fee))
            p.Add(New SqlParameter("@Description", ParamOrNull(tbDescription.Text)))
            p.Add(New SqlParameter("@Reference", ParamOrNull(tbReference.Text)))
            p.Add(New SqlParameter("@SettlementDays", 2))
            p.Add(New SqlParameter("@IdempotencyKey", If(String.IsNullOrEmpty(hfIdem.Value), CObj(DBNull.Value), hfIdem.Value)))
            p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))
            ExecuteSQLds("s0020InitiateClientPayment", p)
            Response.Redirect("wbfPaiements.aspx?abonneId=" & AbonneId & "&msg=init")
        Catch sqlEx As SqlException
            ShowError(sqlEx.Message)
            BindList()
        Catch ex As Exception
            ShowError("Initiation impossible. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Pay Create: " & ex.Message)
            BindList()
        End Try
    End Sub

    Protected Sub rptPay_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        Dim pid As Long
        If Not Long.TryParse(TryCast(e.CommandArgument, String), pid) Then Return
        Try
            If e.CommandName = "settle" Then
                Dim p As New Collection
                p.Add(New SqlParameter("@PaymentId", pid))
                p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))
                ExecuteSQL("s0021SettlePayment", p)
                Response.Redirect("wbfPaiements.aspx?abonneId=" & AbonneId & "&msg=settle")
            ElseIf e.CommandName = "ret" Then
                Dim p As New Collection
                p.Add(New SqlParameter("@PaymentId", pid))
                p.Add(New SqlParameter("@Reason", "NSF"))
                p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))
                ExecuteSQL("s0022ReturnPayment", p)
                Response.Redirect("wbfPaiements.aspx?abonneId=" & AbonneId & "&msg=ret")
            End If
        Catch sqlEx As SqlException
            ShowError(sqlEx.Message)
            BindList()
        Catch ex As Exception
            ShowError("Action impossible.")
            System.Diagnostics.Debug.WriteLine("Pay ItemCommand: " & ex.Message)
            BindList()
        End Try
    End Sub

    Protected Sub btnBatch_Click(sender As Object, e As EventArgs)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))
            Dim n As Integer = 0
            Dim tbl As DataTable = ExecuteSQLds("s0024RunSettlementBatch", p).Tables(0)
            If tbl.Rows.Count > 0 Then n = CInt(tbl.Rows(0)("NbRegles"))
            Response.Redirect("wbfPaiements.aspx?abonneId=" & AbonneId & "&msg=batch&n=" & n)
        Catch ex As Exception
            ShowError("Traitement du lot impossible.")
            System.Diagnostics.Debug.WriteLine("Pay Batch: " & ex.Message)
            BindList()
        End Try
    End Sub

    ' --- Helpers ---

    Protected Function Money(cents As Object) As String
        Dim c As Long = ToLong(cents)
        Return (c / 100D).ToString("N2", Cult) & " $"
    End Function

    Protected Function FormatDate(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd")
    End Function

    Protected Function BadgeStatut(s As Object) As String
        Select Case If(s, "").ToString()
            Case "Regle" : Return "badge-actif"
            Case "Retourne" : Return "badge-rejete"
            Case Else : Return "badge-encours"
        End Select
    End Function

    Protected Function LabelStatut(s As Object) As String
        Select Case If(s, "").ToString()
            Case "Initie" : Return "Initié"
            Case "Regle" : Return "Réglé"
            Case "Retourne" : Return "Retourné"
            Case Else : Return If(s, "").ToString()
        End Select
    End Function

    Protected Function SettlementText(item As Object) As String
        Dim r As DataRowView = TryCast(item, DataRowView)
        If r Is Nothing Then Return ""
        Dim st As String = r("Status").ToString()
        If st = "Regle" Then Return "Réglé le " & FormatDate(r("SettledUtc"))
        If st = "Retourne" Then Return "Retour " & Server.HtmlEncode(If(IsDBNull(r("ReturnReason")), "", r("ReturnReason").ToString()))
        If Not IsDBNull(r("ExpectedSettlementDate")) Then Return "Prévu " & FormatDate(r("ExpectedSettlementDate"))
        Return ""
    End Function

    Private Function ToLong(o As Object) As Long
        If o Is Nothing OrElse IsDBNull(o) Then Return 0
        Return Convert.ToInt64(o)
    End Function

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

    Private Function TextOrDbNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
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
