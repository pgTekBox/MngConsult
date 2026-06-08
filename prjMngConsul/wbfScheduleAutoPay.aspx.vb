Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization

''' <summary>
''' Modal pour programmer un paiement automatique sur une facture donnee.
''' Recoit en QueryString : DocumentId, PartyId, Total
'''
''' Flow :
'''   1. Charge les infos facture
'''   2. Liste les autorisations T144 actives pour le fournisseur (1 ligne par MethodType)
'''   3. Pre-rempli date par defaut = DueDate
'''   4. Au clic Confirmer : appelle s0087ScheduleAutoPay
''' </summary>
Public Class wbfScheduleAutoPay
    Inherits clsData

    Private Property DocumentId As Integer
        Get
            Return CInt(If(ViewState("DocumentId"), 0))
        End Get
        Set(value As Integer)
            ViewState("DocumentId") = value
        End Set
    End Property

    Private Property PartyId As Integer
        Get
            Return CInt(If(ViewState("PartyId"), 0))
        End Get
        Set(value As Integer)
            ViewState("PartyId") = value
        End Set
    End Property

    Private Property TotalDue As Decimal
        Get
            Return CDec(If(ViewState("Total"), 0D))
        End Get
        Set(value As Decimal)
            ViewState("Total") = value
        End Set
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If UserId = 0 Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        If Not IsPostBack Then
            ParseQueryString()
            LoadInvoiceInfo()
            LoadAuthorizations()
        End If
    End Sub

    Private Sub ParseQueryString()
        Dim docId As Integer = 0
        Dim partyId As Integer = 0
        Integer.TryParse(Request.QueryString("DocumentId"), docId)
        Integer.TryParse(Request.QueryString("PartyId"), partyId)
        DocumentId = docId
        PartyId = partyId

        Dim totalStr As String = If(Request.QueryString("Total"), "0").Trim().Replace(",", ".")
        Dim total As Decimal = 0D
        Decimal.TryParse(totalStr, NumberStyles.Any, CultureInfo.InvariantCulture, total)
        TotalDue = total
    End Sub

    Private Sub LoadInvoiceInfo()
        Try
            ' Recuperer infos facture (DocumentNumber, DueDate, PartyName)
            Dim sql As String =
                "SELECT D.DocumentNumber, D.DueDate, D.Total, " &
                "  P.DisplayName AS PartyName " &
                "FROM dbo.T060Document D " &
                "  LEFT JOIN dbo.T050Party P ON P.PartyGUID = D.PartyGUID AND P.CompanyGUID = D.CompanyGUID " &
                "WHERE D.Id = @DocId AND D.CompanyGUID = @Company"

            Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@DocId", DocumentId)
                    cmd.Parameters.AddWithValue("@Company", Company)
                    conn.Open()
                    Using rdr = cmd.ExecuteReader()
                        If Not rdr.Read() Then
                            ShowError("Facture introuvable.")
                            pnlForm.Visible = False
                            Return
                        End If

                        Dim docNumber As String = If(rdr("DocumentNumber") Is DBNull.Value, DocumentId.ToString(), rdr("DocumentNumber").ToString())
                        Dim partyName As String = If(rdr("PartyName") Is DBNull.Value, "Fournisseur", rdr("PartyName").ToString())

                        litInvoiceInfo.Text = Server.HtmlEncode("Facture #" & docNumber & " · " & partyName)

                        Dim culture As New CultureInfo("fr-CA")
                        litRestant.Text = TotalDue.ToString("N2", culture) & " $"

                        ' Pre-rempli la date avec DueDate (ou aujourd'hui si dans le passe)
                        If Not (rdr("DueDate") Is DBNull.Value) Then
                            Dim dueDate As Date = CDate(rdr("DueDate"))
                            If dueDate < Date.Today Then dueDate = Date.Today
                            tbAutoPayDate.Text = dueDate.ToString("yyyy-MM-dd")
                        Else
                            tbAutoPayDate.Text = Date.Today.ToString("yyyy-MM-dd")
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            ShowError("Erreur chargement facture : " & ex.Message)
        End Try
    End Sub

    Private Sub LoadAuthorizations()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@PartyId", PartyId))
            p.Add(New SqlParameter("@UserGUID", DBNull.Value))
            p.Add(New SqlParameter("@PaymentMethodType", DBNull.Value))

            Dim ds As DataSet = ExecuteSQLds("s0086GetActiveAuthorization", p)

            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ShowError("Aucune autorisation auto-paiement active pour ce fournisseur. " &
                          "Effectuez d'abord un paiement manuel en cochant 'Autoriser l'auto-paiement'.")
                pnlForm.Visible = False
                Return
            End If

            rblAuth.Items.Clear()
            For Each row As DataRow In ds.Tables(0).Rows
                Dim authId As Integer = CInt(row("Id"))
                Dim mtype As String = row("PaymentMethodType").ToString()
                Dim label As String

                If mtype = "card" Then
                    Dim brand As String = If(row("CardBrand") Is DBNull.Value, "Carte", row("CardBrand").ToString()).ToUpper()
                    Dim last4 As String = If(row("CardLast4") Is DBNull.Value, "????", row("CardLast4").ToString())
                    label = "💳 " & brand & " ****" & last4
                ElseIf mtype = "acss_debit" Then
                    Dim last4 As String = If(row("BankAccountLast4") Is DBNull.Value, "????", row("BankAccountLast4").ToString())
                    label = "🏦 PAD bancaire ****" & last4 & " (frais bas)"
                Else
                    label = mtype
                End If

                ' Annoter avec plafond si defini
                If Not (row("MaxAmountPerMonth") Is DBNull.Value) Then
                    Dim maxM As Decimal = CDec(row("MaxAmountPerMonth"))
                    Dim culture As New CultureInfo("fr-CA")
                    label &= " · plafond " & maxM.ToString("N0", culture) & " $/mois"
                End If

                rblAuth.Items.Add(New ListItem(label, authId.ToString()))
            Next

            ' Pre-selectionne le premier
            If rblAuth.Items.Count > 0 Then rblAuth.SelectedIndex = 0

        Catch ex As Exception
            ShowError("Erreur chargement autorisations : " & ex.Message)
            pnlForm.Visible = False
        End Try
    End Sub

    Private Sub btnConfirm_Click(sender As Object, e As EventArgs) Handles btnConfirm.Click
        Try
            ' Validation
            If rblAuth.SelectedValue Is Nothing OrElse rblAuth.SelectedValue = "" Then
                ShowError("Veuillez choisir un moyen de paiement.")
                Return
            End If

            Dim authId As Integer = 0
            Integer.TryParse(rblAuth.SelectedValue, authId)
            If authId = 0 Then
                ShowError("Autorisation invalide.")
                Return
            End If

            Dim autoPayDate As Date
            If Not Date.TryParse(tbAutoPayDate.Text, autoPayDate) Then
                ShowError("Date invalide.")
                Return
            End If

            If autoPayDate < Date.Today Then
                ShowError("La date doit être aujourd'hui ou ultérieure.")
                Return
            End If

            ' Appeler s0087ScheduleAutoPay
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@DocumentId", DocumentId))
            p.Add(New SqlParameter("@AutoPayDate", autoPayDate))
            p.Add(New SqlParameter("@AuthorizationId", authId))
            p.Add(New SqlParameter("@ScheduledByUserGUID", DBNull.Value))

            Dim ds As DataSet = ExecuteSQLds("s0087ScheduleAutoPay", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ShowError("Aucun retour de s0087.")
                Return
            End If

            Dim row As DataRow = ds.Tables(0).Rows(0)
            Dim retCode As Integer = CInt(row("RetCode"))

            If retCode <> 0 Then
                ShowError("Echec programmation : " & row("ErrorMessage").ToString())
                Return
            End If

            Dim culture As New CultureInfo("fr-CA")
            ShowSuccess(
                "✅ Paiement automatique programmé pour le <strong>" & autoPayDate.ToString("yyyy-MM-dd") & "</strong>." &
                "<br/>Montant : <strong>" & TotalDue.ToString("N2", culture) & " $</strong>" &
                "<br/><br/><small>Vous pouvez fermer cette fenêtre.</small>"
            )
            pnlForm.Visible = False

        Catch ex As Exception
            ShowError("Erreur programmation : " & ex.Message)
        End Try
    End Sub

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
        pnlSuccess.Visible = False
    End Sub

    Private Sub ShowSuccess(msg As String)
        pnlSuccess.Visible = True
        litSuccess.Text = msg
        pnlError.Visible = False
    End Sub

End Class
