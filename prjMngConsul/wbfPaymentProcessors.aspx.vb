Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Connexion / déconnexion des processeurs de paiement (Square, et à venir).
''' Le flux OAuth Square vit dans SquareOAuth.aspx ; cette page démarre la
''' connexion, affiche le statut et permet la déconnexion (effacement des jetons).
''' </summary>
Public Class wbfPaymentProcessors
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            ShowReturnMessage()
            LoadStatus()
            LoadPlaidStatus()
        End If
    End Sub

    ''' <summary>Charge l'état de connexion Plaid (banques connectées) et alimente la carte.</summary>
    Private Sub LoadPlaidStatus()
        Dim bankCount As Integer = 0, accountCount As Integer = 0
        Dim banks As String = ""

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0698GetCompanyPlaidStatus", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                bankCount = If(IsDBNull(r("BankCount")), 0, CInt(r("BankCount")))
                accountCount = If(IsDBNull(r("AccountCount")), 0, CInt(r("AccountCount")))
                banks = If(IsDBNull(r("Banks")), "", r("Banks").ToString())
            End If
        Catch
        End Try

        Dim connected As Boolean = bankCount > 0
        pnlPlaidConnected.Visible = connected
        pnlPlaidDisconnected.Visible = Not connected

        If connected Then
            litPlaidBadge.Text = "<span class=""pp-badge on""><span class=""dot""></span>" & L("connected") & "</span>"
            litPlaidBanks.Text = If(banks = "", "—", Server.HtmlEncode(banks))
            litPlaidAccounts.Text = accountCount.ToString()
            chkAutoImport.Checked = GetAutoImport()
        Else
            litPlaidBadge.Text = "<span class=""pp-badge off""><span class=""dot""></span>" & L("notConnected") & "</span>"
        End If
    End Sub

    ''' <summary>Lit l'état de l'import automatique Plaid de la compagnie (défaut activé).</summary>
    Private Function GetAutoImport() As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0705GetPlaidAutoImport", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim v As Object = ds.Tables(0).Rows(0)("PlaidAutoImport")
                Return IsDBNull(v) OrElse CBool(v)
            End If
        Catch
        End Try
        Return True
    End Function

    ''' <summary>Active / désactive l'import automatique Plaid pour la compagnie.</summary>
    Private Sub chkAutoImport_CheckedChanged(sender As Object, e As EventArgs) Handles chkAutoImport.CheckedChanged
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Enabled", chkAutoImport.Checked))
            ExecuteSQL("s0706SetPlaidAutoImport", p)

            pnlMsg.Visible = True
            pnlMsg.CssClass = "pp-msg ok"
            litMsg.Text = If(chkAutoImport.Checked, L("autoImportOn"), L("autoImportOff"))
        Catch
            pnlMsg.Visible = True
            pnlMsg.CssClass = "pp-msg err"
            litMsg.Text = L("autoImportErr")
        End Try
    End Sub

    ' Connexion / ajout d'une banque : vers la page du relevé bancaire, où le flux
    ' Plaid Link (avec reprise OAuth) est en place.
    Private Sub btnPlaidConnect_Click(sender As Object, e As EventArgs) _
        Handles btnPlaidConnect.Click, btnPlaidAdd.Click
        Response.Redirect("~/wbfReleve.aspx")
    End Sub

    ' Gestion des comptes déjà connectés.
    Private Sub btnPlaidManage_Click(sender As Object, e As EventArgs) Handles btnPlaidManage.Click
        Response.Redirect("~/PlaidAccounts.aspx")
    End Sub

    ''' <summary>Charge l'état de connexion Square et alimente la carte.</summary>
    Private Sub LoadStatus()
        Dim connected As Boolean = False
        Dim merchant As String = "", location As String = "", since As String = ""

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0663GetCompanySquareAuth", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                connected = Not IsDBNull(r("SquareAccessTokenEnc"))
                If connected Then
                    merchant = If(IsDBNull(r("SquareMerchantId")), "", r("SquareMerchantId").ToString())
                    location = If(IsDBNull(r("SquareLocationId")), "", r("SquareLocationId").ToString())
                    If Not IsDBNull(r("SquareConnectedDate")) Then since = CDate(r("SquareConnectedDate")).ToString("yyyy-MM-dd")
                End If
            End If
        Catch
        End Try

        pnlConnected.Visible = connected
        pnlDisconnected.Visible = Not connected

        If connected Then
            litSquareBadge.Text = "<span class=""pp-badge on""><span class=""dot""></span>" & L("connected") & "</span>"
            litMerchant.Text = If(merchant = "", "—", Server.HtmlEncode(merchant))
            litLocation.Text = If(location = "", "—", Server.HtmlEncode(location))
            litSince.Text = If(since = "", "—", since)
        Else
            litSquareBadge.Text = "<span class=""pp-badge off""><span class=""dot""></span>" & L("notConnected") & "</span>"
        End If
    End Sub

    ''' <summary>Message de retour du flux OAuth (?square=connected/denied/error) ou déconnexion.</summary>
    Private Sub ShowReturnMessage()
        Dim s As String = Request.QueryString("square")
        If String.IsNullOrEmpty(s) Then Return

        Dim ok As Boolean = True
        Dim msg As String
        Select Case s.ToLowerInvariant()
            Case "connected" : msg = L("msgConnected")
            Case "disconnected" : msg = L("msgDisconnected")
            Case "denied" : msg = L("msgDenied") : ok = False
            Case "badstate", "error" : msg = L("msgError") : ok = False
            Case Else : Return
        End Select

        pnlMsg.Visible = True
        pnlMsg.CssClass = "pp-msg " & If(ok, "ok", "err")
        litMsg.Text = msg
    End Sub

    ' Connexion / reconnexion : démarre le flux OAuth Square.
    Private Sub btnConnect_Click(sender As Object, e As EventArgs) Handles btnConnect.Click, btnReconnect.Click
        Response.Redirect("~/SquareOAuth.aspx")
    End Sub

    ' Déconnexion : efface les jetons Square de la compagnie.
    Private Sub btnDisconnect_Click(sender As Object, e As EventArgs) Handles btnDisconnect.Click
        Try
            SaveCompanySquareTokens(Nothing, Nothing, Nothing)
            Response.Redirect("~/wbfPaymentProcessors.aspx?square=disconnected")
        Catch ex As Threading.ThreadAbortException
            ' redirection normale
        Catch ex As Exception
            Response.Redirect("~/wbfPaymentProcessors.aspx?square=error")
        End Try
    End Sub

    ''' <summary>Applique les libellés localisés aux contrôles serveur.</summary>
    Private Sub ApplyLocalization()
        litTitle.Text = L("pageTitle")
        litHead.Text = L("head")
        litSub.Text = L("sub")
        litLblMerchant.Text = L("lblMerchant")
        litLblLocation.Text = L("lblLocation")
        litLblSince.Text = L("lblSince")
        litSquareIntro.Text = L("squareIntro")
        btnConnect.Text = L("connect")
        btnReconnect.Text = L("reconnect")
        btnDisconnect.Text = L("disconnect")
        litSoon.Text = L("soon")
        litStripeNote.Text = L("stripeNote")

        ' Plaid
        litLblPlaidBanks.Text = L("lblPlaidBanks")
        litLblPlaidAccounts.Text = L("lblPlaidAccounts")
        litPlaidIntro.Text = L("plaidIntro")
        btnPlaidConnect.Text = L("plaidConnect")
        btnPlaidAdd.Text = L("plaidAdd")
        btnPlaidManage.Text = L("plaidManage")
        chkAutoImport.Text = L("autoImport")
        litAutoImportHint.Text = L("autoImportHint")
    End Sub

    ''' <summary>Traductions (fr/en/es).</summary>
    Private Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Processeurs de paiement — 60Sec-AI", "Payment processors — 60Sec-AI", "Procesadores de pago — 60Sec-AI")
            Case "head" : Return Choose3(lang, "Processeurs de paiement", "Payment processors", "Procesadores de pago")
            Case "sub" : Return Choose3(lang, "Connectez vos comptes de traitement des paiements.", "Connect your payment processing accounts.", "Conecte sus cuentas de procesamiento de pagos.")
            Case "connected" : Return Choose3(lang, "Connecté", "Connected", "Conectado")
            Case "notConnected" : Return Choose3(lang, "Non connecté", "Not connected", "No conectado")
            Case "lblMerchant" : Return Choose3(lang, "Identifiant marchand", "Merchant ID", "ID de comercio")
            Case "lblLocation" : Return Choose3(lang, "Emplacement", "Location", "Ubicación")
            Case "lblSince" : Return Choose3(lang, "Connecté depuis", "Connected since", "Conectado desde")
            Case "squareIntro" : Return Choose3(lang, "Connectez votre compte Square pour encaisser les clients (carte / Interac) et synchroniser factures et paiements.", "Connect your Square account to collect from customers (card / Interac) and sync invoices and payments.", "Conecte su cuenta Square para cobrar a los clientes (tarjeta / Interac) y sincronizar facturas y pagos.")
            Case "connect" : Return Choose3(lang, "Connecter Square", "Connect Square", "Conectar Square")
            Case "reconnect" : Return Choose3(lang, "Reconnecter", "Reconnect", "Reconectar")
            Case "disconnect" : Return Choose3(lang, "Déconnecter", "Disconnect", "Desconectar")
            Case "soon" : Return Choose3(lang, "Bientôt", "Coming soon", "Próximamente")
            Case "stripeNote" : Return Choose3(lang, "Le paiement de votre abonnement 60Sec-AI est déjà géré par Stripe. La connexion Stripe pour encaisser vos propres clients arrivera bientôt.", "Your 60Sec-AI subscription billing is already handled by Stripe. Stripe connection to collect your own customers is coming soon.", "La facturación de su suscripción 60Sec-AI ya la gestiona Stripe. La conexión de Stripe para cobrar a sus propios clientes llegará pronto.")
            Case "msgConnected" : Return Choose3(lang, "✔ Compte Square connecté avec succès.", "✔ Square account connected successfully.", "✔ Cuenta Square conectada con éxito.")
            Case "msgDisconnected" : Return Choose3(lang, "✔ Compte Square déconnecté.", "✔ Square account disconnected.", "✔ Cuenta Square desconectada.")
            Case "msgDenied" : Return Choose3(lang, "✖ Connexion Square annulée.", "✖ Square connection cancelled.", "✖ Conexión Square cancelada.")
            Case "msgError" : Return Choose3(lang, "✖ Erreur lors de la connexion Square.", "✖ Error during Square connection.", "✖ Error durante la conexión Square.")

            ' === Plaid ===
            Case "lblPlaidBanks" : Return Choose3(lang, "Banques", "Banks", "Bancos")
            Case "lblPlaidAccounts" : Return Choose3(lang, "Comptes reliés", "Linked accounts", "Cuentas vinculadas")
            Case "plaidIntro" : Return Choose3(lang, "Connectez votre compte bancaire via Plaid pour importer automatiquement vos transactions et faire le rapprochement bancaire.", "Connect your bank account through Plaid to automatically import your transactions and reconcile your statements.", "Conecte su cuenta bancaria mediante Plaid para importar automáticamente sus transacciones y conciliar sus extractos.")
            Case "plaidConnect" : Return Choose3(lang, "Connecter une banque", "Connect a bank", "Conectar un banco")
            Case "plaidAdd" : Return Choose3(lang, "Connecter une autre banque", "Connect another bank", "Conectar otro banco")
            Case "plaidManage" : Return Choose3(lang, "Gérer les comptes", "Manage accounts", "Gestionar cuentas")
            Case "autoImport" : Return Choose3(lang, "Import automatique des transactions", "Automatic transaction import", "Importación automática de transacciones")
            Case "autoImportHint" : Return Choose3(lang, "Lorsque activé, les nouvelles transactions signalées par votre banque sont importées automatiquement (webhook Plaid), sans cliquer « Importer ».", "When enabled, new transactions reported by your bank are imported automatically (Plaid webhook), without clicking « Import ».", "Cuando está activado, las nuevas transacciones informadas por su banco se importan automáticamente (webhook de Plaid), sin hacer clic en « Importar ».")
            Case "autoImportOn" : Return Choose3(lang, "✔ Import automatique activé.", "✔ Automatic import enabled.", "✔ Importación automática activada.")
            Case "autoImportOff" : Return Choose3(lang, "✔ Import automatique désactivé.", "✔ Automatic import disabled.", "✔ Importación automática desactivada.")
            Case "autoImportErr" : Return Choose3(lang, "✖ Erreur lors de l'enregistrement du réglage.", "✖ Error saving the setting.", "✖ Error al guardar la configuración.")

            Case Else : Return ""
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

End Class
