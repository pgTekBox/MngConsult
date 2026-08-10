Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization

''' <summary>
''' Decaissements de l'abonne : credits EFT inities vers ses fournisseurs.
''' Liste (T030 Direction=Sortant) + initiation (s0038InitiatePayout), qui
''' reserve le montant sur le solde de l'abonne. Scopees a l'AbonneId.
''' </summary>
Public Class wbfDecaissements
    Inherits clsData

    Protected WithEvents detAdd As Global.System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents pnlOk As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litOk As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlNoFourn As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents ddlFourn As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents tbAmount As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbFee As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbDays As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbDesc As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbRef As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnInit As Global.System.Web.UI.WebControls.Button
    Protected WithEvents rpt As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlEmpty As Global.System.Web.UI.WebControls.Panel

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            LoadFournisseurs()
            Bind()
        End If
    End Sub

    Private Sub LoadFournisseurs()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Search", DBNull.Value))
            p.Add(New SqlParameter("@Statut", "Actif"))
            p.Add(New SqlParameter("@Limit", 1000))
            p.Add(New SqlParameter("@Offset", 0))
            Dim t As DataTable = ExecuteSQLds("s0035ListFournisseurs", p).Tables(0)
            ddlFourn.DataSource = t
            ddlFourn.DataTextField = "Nom"
            ddlFourn.DataValueField = "Id"
            ddlFourn.DataBind()
            Dim has As Boolean = (t.Rows.Count > 0)
            pnlNoFourn.Visible = Not has
            btnInit.Enabled = has
            ddlFourn.Enabled = has
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ABN Dec fourn: " & ex.Message)
        End Try
    End Sub

    Private Sub Bind()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Status", DBNull.Value))
            p.Add(New SqlParameter("@Search", DBNull.Value))
            p.Add(New SqlParameter("@Direction", "Sortant"))
            p.Add(New SqlParameter("@Limit", 100))
            p.Add(New SqlParameter("@Offset", 0))
            Dim t As DataTable = ExecuteSQLds("s0023ListPayments", p).Tables(0)
            rpt.DataSource = t
            rpt.DataBind()
            rpt.Visible = (t.Rows.Count > 0)
            pnlEmpty.Visible = (t.Rows.Count = 0)
        Catch ex As Exception
            ShowError("Impossible de charger les décaissements. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN Dec bind: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnInit_Click(sender As Object, e As EventArgs)
        detAdd.Attributes("open") = "open"

        Dim fournId As Integer
        If Not Integer.TryParse(ddlFourn.SelectedValue, fournId) OrElse fournId <= 0 Then
            ShowError("Sélectionnez un fournisseur.") : Return
        End If

        Dim amountCents As Long
        If Not TryParseCents(tbAmount.Text, amountCents) OrElse amountCents <= 0 Then
            ShowError("Montant invalide.") : Return
        End If

        Dim feeCents As Long = 0
        If Not String.IsNullOrWhiteSpace(tbFee.Text) AndAlso Not TryParseCents(tbFee.Text, feeCents) Then
            ShowError("Frais invalides.") : Return
        End If
        If feeCents < 0 Then feeCents = 0

        Dim days As Integer = 2
        Integer.TryParse(tbDays.Text, days)
        If days < 0 Then days = 0

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@FournisseurId", fournId))
            p.Add(New SqlParameter("@AmountCents", amountCents))
            p.Add(New SqlParameter("@FeeCents", feeCents))
            p.Add(New SqlParameter("@Description", NzOrNull(tbDesc.Text)))
            p.Add(New SqlParameter("@Reference", NzOrNull(tbRef.Text)))
            p.Add(New SqlParameter("@SettlementDays", days))
            p.Add(New SqlParameter("@IdempotencyKey", DBNull.Value))
            p.Add(New SqlParameter("@AdminId", DBNull.Value))
            Dim outId As New SqlParameter("@PaymentId", SqlDbType.BigInt) With {.Direction = ParameterDirection.InputOutput, .Value = DBNull.Value}
            p.Add(outId)
            ExecuteSQLds("s0038InitiatePayout", p)

            pnlOk.Visible = True
            litOk.Text = "Décaissement de " & Money(amountCents) & " initié (montant réservé sur votre solde)."
            ClearForm()
            Bind()
        Catch sqlEx As SqlException
            ShowError("Initiation impossible : " & sqlEx.Message)
        Catch ex As Exception
            ShowError("Initiation impossible.")
            System.Diagnostics.Debug.WriteLine("ABN Dec init: " & ex.Message)
        End Try
    End Sub

    Private Sub ClearForm()
        tbAmount.Text = "" : tbFee.Text = "" : tbDesc.Text = "" : tbRef.Text = "" : tbDays.Text = "2"
    End Sub

    Private Function TryParseCents(s As String, ByRef cents As Long) As Boolean
        cents = 0
        Dim v As String = If(s, "").Trim().Replace(" ", "").Replace(ChrW(160), "").Replace("$", "").Replace(",", ".")
        If v.Length = 0 Then Return False
        Dim d As Decimal
        If Not Decimal.TryParse(v, NumberStyles.Number, CultureInfo.InvariantCulture, d) Then Return False
        cents = CLng(Math.Round(d * 100D, MidpointRounding.AwayFromZero))
        Return True
    End Function

    Protected Function BadgeStatut(s As Object) As String
        Select Case If(s, "").ToString()
            Case "Regle", "Réglé", "Settled" : Return "badge-actif"
            Case "Initie", "Initié" : Return "badge-encours"
            Case "Retourne", "Retourné", "Returned" : Return "badge-rejete"
            Case Else : Return "badge-neutre"
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

    Private Function NzOrNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
