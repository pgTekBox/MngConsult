Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization

''' <summary>
''' Console Interac e-Transfer (staff), scopée par ?abonneId=N. Permet
''' d'initier un encaissement (demande à un client) ou un décaissement
''' (virement à un fournisseur) par Interac, puis de simuler le dépôt
''' (règlement) ou le refus (contre-passation). Journal des évènements.
''' </summary>
Public Class wbfInterac
    Inherits clsData

    Private Shared ReadOnly Cult As CultureInfo = New CultureInfo("fr-CA")

    Private ReadOnly Property AbonneId() As Integer
        Get
            Dim v As Integer
            Integer.TryParse(Request.QueryString("abonneId"), v)
            Return v
        End Get
    End Property
    ''' <summary>Exposé au markup pour le lien retour.</summary>
    Protected ReadOnly Property AbonneIdPublic() As Integer
        Get
            Return AbonneId
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If AbonneId <= 0 Then
            Response.Redirect("~/wbfAbonnes.aspx") : Return
        End If
        If Not IsPostBack Then
            If Not LoadAbonneName() Then Return
            BindContreparties()
            BindList()
            BindEvents()
            ShowMsgFromQuery()
        End If
    End Sub

    Private Function LoadAbonneName() As Boolean
        Try
            Dim p As New Collection : p.Add(New SqlParameter("@Id", AbonneId))
            Dim t As DataTable = ExecuteSQLds("s0005GetAbonne", p).Tables(0)
            If t.Rows.Count = 0 Then Response.Redirect("~/wbfAbonnes.aspx") : Return False
            litAbonne.Text = Server.HtmlEncode(t.Rows(0)("RaisonSociale").ToString())
            Return True
        Catch ex As Exception
            ShowError("Impossible de charger l'abonné. Vérifiez que les scripts de base de données ont été exécutés.")
            Return False
        End Try
    End Function

    Private Sub BindContreparties()
        Try
            Dim entrant As Boolean = (ddlDirection.SelectedValue = "Entrant")
            litContrepartieLbl.Text = If(entrant, "Client (payeur)", "Fournisseur (bénéficiaire)")
            Dim proc As String = If(entrant, "s0011ListClients", "s0035ListFournisseurs")
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Search", DBNull.Value))
            p.Add(New SqlParameter("@Statut", "Actif"))
            p.Add(New SqlParameter("@Limit", 1000))
            p.Add(New SqlParameter("@Offset", 0))
            Dim t As DataTable = ExecuteSQLds(proc, p).Tables(0)
            ddlContrepartie.DataSource = t
            ddlContrepartie.DataTextField = "Nom"
            ddlContrepartie.DataValueField = "Id"
            ddlContrepartie.DataBind()
            Dim has As Boolean = (t.Rows.Count > 0)
            pnlNoContrepartie.Visible = Not has
            ddlContrepartie.Enabled = has
            btnInitiate.Enabled = has
        Catch ex As Exception
            ShowError("Impossible de charger les contreparties.")
            System.Diagnostics.Debug.WriteLine("Interac BindContreparties: " & ex.Message)
        End Try
    End Sub

    Protected Sub ddlDirection_SelectedIndexChanged(sender As Object, e As EventArgs)
        BindContreparties()
    End Sub

    Private Sub BindList()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Top", 100))
            Dim t As DataTable = ExecuteSQLds("s0100ListInteracPayments", p).Tables(0)
            rptInterac.DataSource = t : rptInterac.DataBind()
            rptInterac.Visible = (t.Rows.Count > 0) : pnlEmpty.Visible = (t.Rows.Count = 0)
        Catch ex As Exception
            ShowError("Impossible de charger les transferts. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Interac BindList: " & ex.Message)
        End Try
    End Sub

    Private Sub BindEvents()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Top", 50))
            Dim t As DataTable = ExecuteSQLds("s0099ListInteracEvents", p).Tables(0)
            rptEvents.DataSource = t : rptEvents.DataBind()
            rptEvents.Visible = (t.Rows.Count > 0) : pnlNoEvents.Visible = (t.Rows.Count = 0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Interac BindEvents: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnInitiate_Click(sender As Object, e As EventArgs)
        Dim cpId As Integer
        If Not Integer.TryParse(ddlContrepartie.SelectedValue, cpId) OrElse cpId <= 0 Then
            ShowError("Sélectionnez une contrepartie.") : Return
        End If
        Dim email As String = If(tbEmail.Text, "").Trim()
        If email.Length = 0 OrElse Not email.Contains("@") Then
            ShowError("Un courriel Interac valide est requis.") : Return
        End If
        Dim amountCents As Long
        If Not TryParseCents(tbAmount.Text, amountCents) OrElse amountCents <= 0 Then
            ShowError("Montant invalide.") : Return
        End If
        Dim feeCents As Long = 0
        If Not String.IsNullOrWhiteSpace(tbFee.Text) AndAlso Not TryParseCents(tbFee.Text, feeCents) Then
            ShowError("Frais invalides.") : Return
        End If
        Dim desc As String = If(tbDesc.Text, "").Trim()

        Try
            If ddlDirection.SelectedValue = "Entrant" Then
                clsInterac.CreateEncaissement(AbonneId, cpId, amountCents, feeCents, email, desc, "", AdminId)
            Else
                clsInterac.CreatePayout(AbonneId, cpId, amountCents, feeCents, email, desc, "", AdminId)
            End If
            Response.Redirect("wbfInterac.aspx?abonneId=" & AbonneId & "&msg=init")
        Catch sqlEx As SqlException
            ShowError(sqlEx.Message) : BindContreparties() : BindList() : BindEvents()
        Catch ex As Exception
            ShowError("Initiation impossible : " & ex.Message)
            BindContreparties() : BindList() : BindEvents()
        End Try
    End Sub

    Protected Sub rptInterac_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        Dim id As Long
        If Not Long.TryParse(TryCast(e.CommandArgument, String), id) Then Return
        Try
            If e.CommandName = "deposit" Then
                clsInterac.Deposit(id, AdminId)
                Response.Redirect("wbfInterac.aspx?abonneId=" & AbonneId & "&msg=dep")
            ElseIf e.CommandName = "decline" Then
                clsInterac.Decline(id, "Refus / expiration du transfert Interac (simulation)")
                Response.Redirect("wbfInterac.aspx?abonneId=" & AbonneId & "&msg=dec")
            End If
        Catch sqlEx As SqlException
            ShowError(sqlEx.Message) : BindList() : BindEvents()
        Catch ex As Exception
            ShowError("Action impossible : " & ex.Message)
            BindList() : BindEvents()
        End Try
    End Sub

    Private Sub ShowMsgFromQuery()
        Select Case Request.QueryString("msg")
            Case "init" : pnlOk.Visible = True : litOk.Text = "Transfert Interac initié (notification envoyée)."
            Case "dep" : pnlOk.Visible = True : litOk.Text = "Transfert déposé/encaissé : réglé au grand livre."
            Case "dec" : pnlOk.Visible = True : litOk.Text = "Transfert refusé/expiré : contre-passé au grand livre."
        End Select
    End Sub

    ' --- Helpers ---
    Private Function TryParseCents(s As String, ByRef cents As Long) As Boolean
        cents = 0
        Dim v As String = If(s, "").Trim().Replace(" ", "").Replace(ChrW(160), "").Replace("$", "").Replace(",", ".")
        If v.Length = 0 Then Return False
        Dim d As Decimal
        If Not Decimal.TryParse(v, NumberStyles.Number, CultureInfo.InvariantCulture, d) Then Return False
        cents = CLng(Math.Round(d * 100D, MidpointRounding.AwayFromZero))
        Return True
    End Function
    Protected Function Money(cents As Object) As String
        Dim c As Long = If(cents Is Nothing OrElse IsDBNull(cents), 0L, Convert.ToInt64(cents))
        Return (c / 100D).ToString("N2", Cult) & " $"
    End Function
    Protected Function FormatDt(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return "—"
        Return CDate(d).ToString("yyyy-MM-dd HH:mm")
    End Function
    Protected Function Enc(o As Object) As String
        Return Server.HtmlEncode(If(o, "").ToString())
    End Function
    Protected Function BadgeStatut(s As Object) As String
        Select Case If(s, "").ToString()
            Case "Regle" : Return "badge-actif"
            Case "Initie" : Return "badge-encours"
            Case "Retourne" : Return "badge-rejete"
            Case Else : Return "badge-open"
        End Select
    End Function
    Protected Function LabelStatut(s As Object) As String
        Select Case If(s, "").ToString()
            Case "Initie" : Return "Envoyé"
            Case "Regle" : Return "Déposé"
            Case "Retourne" : Return "Refusé"
            Case Else : Return If(s, "").ToString()
        End Select
    End Function
    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
