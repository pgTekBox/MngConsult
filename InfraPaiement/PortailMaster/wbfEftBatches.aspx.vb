Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text

''' <summary>
''' Gestion des lots EFT (CPA-005) au niveau plateforme : configuration
''' émetteur, génération de lots à partir des transactions initiées,
''' téléchargement du fichier .005 et marquage du règlement.
''' </summary>
Public Class wbfEftBatches
    Inherits clsData

    Private Shared ReadOnly Cult As CultureInfo = New CultureInfo("fr-CA")

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            LoadOriginator()
            BindBatches()
            BindReturns()
            BindExchange()
            ShowMsgFromQuery()
        End If
    End Sub

    Private Sub BindExchange()
        Try
            Dim p As New Collection : p.Add(New SqlParameter("@Top", 50))
            Dim tbl As DataTable = ExecuteSQLds("s0066ListExchangeLog", p).Tables(0)
            rptExchange.DataSource = tbl : rptExchange.DataBind()
            rptExchange.Visible = (tbl.Rows.Count > 0) : pnlNoExchange.Visible = (tbl.Rows.Count = 0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Eft BindExchange: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnExchange_Click(sender As Object, e As EventArgs)
        Try
            Dim push As clsBankExchange.ExchangeResult = clsBankExchange.PushOutbound()
            Dim pull As clsBankExchange.ExchangeResult = clsBankExchange.PullInbound()
            pnlOk.Visible = True
            litOk.Text = "Échange banque : " & push.Sent & " fichier(s) envoyé(s), " & pull.Processed & " reçu(s)/traité(s), " & (push.Errors + pull.Errors) & " erreur(s)."
            BindBatches() : BindReturns() : BindExchange()
        Catch ex As Exception
            ShowError("Échange impossible : " & ex.Message)
            System.Diagnostics.Debug.WriteLine("Eft Exchange: " & ex.Message)
        End Try
    End Sub

    Private Sub BindReturns()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Top", 50))
            Dim tbl As DataTable = ExecuteSQLds("s0051ListEftReturns", p).Tables(0)
            rptReturns.DataSource = tbl
            rptReturns.DataBind()
            rptReturns.Visible = (tbl.Rows.Count > 0)
            pnlNoReturns.Visible = (tbl.Rows.Count = 0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Eft BindReturns: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnImport_Click(sender As Object, e As EventArgs)
        If Not fuReturn.HasFile Then
            ShowError("Sélectionnez un fichier de retour.") : Return
        End If
        Try
            Dim text As String = Encoding.UTF8.GetString(fuReturn.FileBytes)
            Dim sum As clsEft005Returns.ImportSummary = clsEft005Returns.ImportReturnFile(text, fuReturn.FileName)
            pnlOk.Visible = True
            litOk.Text = "Import terminé : " & sum.Processed & " contre-passé(s), " & sum.Unmatched & " non rapproché(s), " & sum.Errors & " erreur(s)."
            BindBatches() : BindReturns()
        Catch ex As Exception
            ShowError("Import impossible : " & ex.Message)
            System.Diagnostics.Debug.WriteLine("Eft Import: " & ex.Message)
        End Try
    End Sub

    Private Sub ShowMsgFromQuery()
        Select Case Request.QueryString("msg")
            Case "gen"
                pnlOk.Visible = True
                litOk.Text = "Lot généré (fichier n° " & CInt(Val(Request.QueryString("fcn"))) & "). Téléchargez le fichier .005 puis soumettez-le à la banque."
            Case "settle"
                pnlOk.Visible = True : litOk.Text = "Lot réglé : transactions comptabilisées."
            Case "orig"
                pnlOk.Visible = True : litOk.Text = "Configuration émetteur enregistrée."
            Case "ret"
                pnlOk.Visible = True : litOk.Text = CInt(Val(Request.QueryString("n"))) & " retour(s) contre-passé(s) au grand livre."
        End Select
    End Sub

    Protected Function BadgeReturn(s As Object) As String
        Select Case If(s, "").ToString()
            Case "Processed" : Return "badge-actif"
            Case "Error" : Return "badge-rejete"
            Case Else : Return "badge-open"
        End Select
    End Function

    Private Sub LoadOriginator()
        Try
            Dim tbl As DataTable = ExecuteSQLds("s0042GetOriginator", New Collection).Tables(0)
            If tbl.Rows.Count = 0 Then Return
            Dim r As DataRow = tbl.Rows(0)
            tbClientNumber.Text = V(r, "ClientNumber")
            tbDataCentre.Text = V(r, "DataCentre")
            tbShortName.Text = V(r, "ShortName")
            tbLongName.Text = V(r, "LongName")
            tbRetInst.Text = V(r, "ReturnInstitution")
            tbRetTransit.Text = V(r, "ReturnTransit")
            tbRetAccount.Text = V(r, "ReturnAccount")
            tbCpaDebit.Text = V(r, "CpaCodeDebit")
            tbCpaCredit.Text = V(r, "CpaCodeCredit")
        Catch ex As Exception
            ShowError("Impossible de charger la configuration. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Eft LoadOrig: " & ex.Message)
        End Try
    End Sub

    Private Sub BindBatches()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Top", 50))
            Dim tbl As DataTable = ExecuteSQLds("s0045ListEftBatches", p).Tables(0)
            rptBatches.DataSource = tbl
            rptBatches.DataBind()
            rptBatches.Visible = (tbl.Rows.Count > 0)
            pnlEmpty.Visible = (tbl.Rows.Count = 0)
        Catch ex As Exception
            ShowError("Impossible de charger les lots. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("Eft BindBatches: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnSaveOrig_Click(sender As Object, e As EventArgs)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@ClientNumber", Nz(tbClientNumber.Text)))
            p.Add(New SqlParameter("@ShortName", Nz(tbShortName.Text)))
            p.Add(New SqlParameter("@LongName", Nz(tbLongName.Text)))
            p.Add(New SqlParameter("@DataCentre", Nz(tbDataCentre.Text)))
            p.Add(New SqlParameter("@ReturnInstitution", NzOrNull(tbRetInst.Text)))
            p.Add(New SqlParameter("@ReturnTransit", NzOrNull(tbRetTransit.Text)))
            p.Add(New SqlParameter("@ReturnAccount", NzOrNull(tbRetAccount.Text)))
            p.Add(New SqlParameter("@CpaCodeDebit", NzDef(tbCpaDebit.Text, "430")))
            p.Add(New SqlParameter("@CpaCodeCredit", NzDef(tbCpaCredit.Text, "230")))
            ExecuteSQL("s0043SaveOriginator", p)
            Response.Redirect("wbfEftBatches.aspx?msg=orig")
        Catch ex As Exception
            ShowError("Enregistrement impossible.")
            System.Diagnostics.Debug.WriteLine("Eft SaveOrig: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnGenerate_Click(sender As Object, e As EventArgs)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))
            Dim tbl As DataTable = ExecuteSQLds("s0044CreateEftBatch", p).Tables(0)
            Dim id As Integer = If(tbl.Rows.Count > 0, CInt(tbl.Rows(0)("BatchId")), 0)
            ' Récupérer le n° de fichier pour le message
            Dim fcn As Integer = 0
            Dim gp As New Collection : gp.Add(New SqlParameter("@BatchId", id))
            Dim g As DataTable = ExecuteSQLds("s0046GetEftBatch", gp).Tables(0)
            If g.Rows.Count > 0 Then fcn = CInt(g.Rows(0)("FileCreationNumber"))
            Response.Redirect("wbfEftBatches.aspx?msg=gen&fcn=" & fcn)
        Catch sqlEx As SqlException
            ShowError(sqlEx.Message)
            BindBatches()
        Catch ex As Exception
            ShowError("Génération impossible.")
            System.Diagnostics.Debug.WriteLine("Eft Generate: " & ex.Message)
            BindBatches()
        End Try
    End Sub

    Protected Sub rptBatches_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        Dim id As Integer
        If Not Integer.TryParse(TryCast(e.CommandArgument, String), id) Then Return
        Try
            If e.CommandName = "settle" Then
                Dim p As New Collection
                p.Add(New SqlParameter("@BatchId", id))
                p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))
                ExecuteSQL("s0048SettleEftBatch", p)
                Response.Redirect("wbfEftBatches.aspx?msg=settle")
            ElseIf e.CommandName = "simret" Then
                ' Simule un fichier de retour NSF pour le lot, puis l'importe (contre-passe).
                Dim text As String = clsEft005Returns.SimulateReturnFile(id, "901")
                Dim sum As clsEft005Returns.ImportSummary = clsEft005Returns.ImportReturnFile(text, "SIMULATION_RETOUR.005")
                Response.Redirect("wbfEftBatches.aspx?msg=ret&n=" & sum.Processed)
            End If
        Catch sqlEx As SqlException
            ShowError(sqlEx.Message) : BindBatches() : BindReturns()
        Catch ex As Exception
            ShowError("Action impossible : " & ex.Message)
            System.Diagnostics.Debug.WriteLine("Eft ItemCommand: " & ex.Message) : BindBatches() : BindReturns()
        End Try
    End Sub

    ' --- Helpers ---
    Protected Function Money(cents As Object) As String
        Dim c As Long = If(cents Is Nothing OrElse IsDBNull(cents), 0L, Convert.ToInt64(cents))
        Return (c / 100D).ToString("N2", Cult) & " $"
    End Function
    Protected Function FormatDt(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd HH:mm")
    End Function
    Protected Function BadgeStatut(s As Object) As String
        Select Case If(s, "").ToString()
            Case "Settled" : Return "badge-actif"
            Case "Generated" : Return "badge-gen"
            Case "Submitted" : Return "badge-sub"
            Case Else : Return "badge-open"
        End Select
    End Function
    Protected Function LabelStatut(s As Object) As String
        Select Case If(s, "").ToString()
            Case "Open" : Return "Ouvert"
            Case "Generated" : Return "Généré"
            Case "Submitted" : Return "Soumis"
            Case "Settled" : Return "Réglé"
            Case Else : Return If(s, "").ToString()
        End Select
    End Function

    Private Function V(r As DataRow, col As String) As String
        If IsDBNull(r(col)) Then Return ""
        Return r(col).ToString()
    End Function
    Private Function Nz(s As String) As String
        Return If(s, "").Trim()
    End Function
    Private Function NzOrNull(s As String) As Object
        Dim v2 As String = If(s, "").Trim()
        If v2.Length = 0 Then Return DBNull.Value
        Return v2
    End Function
    Private Function NzDef(s As String, dflt As String) As String
        Dim v2 As String = If(s, "").Trim()
        Return If(v2.Length = 0, dflt, v2)
    End Function
    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
