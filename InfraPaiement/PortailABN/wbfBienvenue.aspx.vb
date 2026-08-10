Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Ecran de prise en main (« Demarrage ») du portail des abonnes : check-list
''' de configuration initiale avec progression, calculee a partir de l'etat
''' reel du compte (s0073GetOnboardingStatus), scopee a l'AbonneId de la
''' session. Les etapes « developpeur » (cle d'API, webhook) sont optionnelles
''' et n'affichent leur bouton d'action qu'aux administrateurs de l'abonne.
''' </summary>
Public Class wbfBienvenue
    Inherits clsData

    Protected WithEvents litAbonne As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litPct As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents barFill As Global.System.Web.UI.HtmlControls.HtmlGenericControl
    Protected WithEvents pnlAllDone As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litSteps As Global.System.Web.UI.WebControls.Literal

    ' Petite structure d'etape (interne a la page).
    Private Class ObStep
        Public Title As String
        Public Descr As String
        Public Done As Boolean
        Public CtaText As String
        Public CtaUrl As String
        Public Optional_ As Boolean
        Public AdminOnly As Boolean
    End Class

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            litAbonne.Text = Server.HtmlEncode(AbonneName)
            BuildOnboarding()
        End If
    End Sub

    Private Sub BuildOnboarding()
        Dim r As DataRow = Nothing
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            Dim t As DataTable = ExecuteSQLds("s0073GetOnboardingStatus", p).Tables(0)
            If t.Rows.Count > 0 Then r = t.Rows(0)
        Catch ex As Exception
            pnlError.Visible = True
            litError.Text = Server.HtmlEncode("Impossible de charger l'état de configuration. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN Onboarding: " & ex.Message)
            Return
        End Try

        Dim clients As Integer = N(r, "ClientsCount")
        Dim fourn As Integer = N(r, "FournisseursCount")
        Dim eft As Integer = N(r, "EftReadyCount")
        Dim apiKeys As Integer = N(r, "ActiveApiKeys")
        Dim hasHook As Boolean = B(r, "HasWebhook")
        Dim txn As Integer = N(r, "TxnCount")

        Dim steps As New List(Of ObStep)
        steps.Add(New ObStep With {
            .Title = "Ajouter un premier client", .Descr = "Le payeur que vous encaisserez par EFT.",
            .Done = (clients > 0), .CtaText = "Ajouter un client", .CtaUrl = "wbfClient.aspx"})
        steps.Add(New ObStep With {
            .Title = "Ajouter un premier fournisseur", .Descr = "Le bénéficiaire que vous paierez par EFT.",
            .Done = (fourn > 0), .CtaText = "Ajouter un fournisseur", .CtaUrl = "wbfFournisseur.aspx"})
        steps.Add(New ObStep With {
            .Title = "Renseigner des coordonnées bancaires", .Descr = "Institution, transit et compte d'au moins une contrepartie (requis pour l'EFT).",
            .Done = (eft > 0), .CtaText = "Voir mes clients", .CtaUrl = "wbfClients.aspx"})
        steps.Add(New ObStep With {
            .Title = "Réaliser une première transaction", .Descr = "Initiez un encaissement ou un décaissement.",
            .Done = (txn > 0), .CtaText = "Nouvel encaissement", .CtaUrl = "wbfEncaissements.aspx"})
        steps.Add(New ObStep With {
            .Title = "Générer une clé d'API", .Descr = "Pour connecter votre application à l'API 60secPaiement.",
            .Done = (apiKeys > 0), .CtaText = "Gérer les clés d'API", .CtaUrl = "wbfApiKeys.aspx",
            .Optional_ = True, .AdminOnly = True})
        steps.Add(New ObStep With {
            .Title = "Configurer un webhook", .Descr = "Recevez les événements de paiement en temps réel.",
            .Done = hasHook, .CtaText = "Configurer un webhook", .CtaUrl = "wbfWebhooks.aspx",
            .Optional_ = True, .AdminOnly = True})

        ' Progression : uniquement sur les etapes requises (non optionnelles).
        Dim required = steps.FindAll(Function(s) Not s.Optional_)
        Dim doneReq As Integer = required.FindAll(Function(s) s.Done).Count
        Dim total As Integer = required.Count
        Dim pct As Integer = If(total = 0, 100, CInt(Math.Floor(doneReq * 100.0 / total)))

        litPct.Text = doneReq & " / " & total & " terminé" & If(doneReq > 1, "es", "e") & "  ·  " & pct & " %"
        barFill.Style("width") = pct & "%"
        pnlAllDone.Visible = (doneReq = total)

        ' Rendu des etapes.
        Dim sb As New StringBuilder()
        Dim i As Integer = 0
        For Each s As ObStep In steps
            i += 1
            RenderStep(sb, i, s)
        Next
        litSteps.Text = sb.ToString()
    End Sub

    Private Sub RenderStep(sb As StringBuilder, num As Integer, s As ObStep)
        Dim doneCls As String = If(s.Done, " done", "")
        sb.Append("<div class=""step").Append(doneCls).Append(""">")

        ' Pastille
        sb.Append("<div class=""mark"">").Append(If(s.Done, "✔", num.ToString())).Append("</div>")

        ' Corps
        sb.Append("<div class=""body""><h3>").Append(Server.HtmlEncode(s.Title))
        If s.Optional_ Then sb.Append("<span class=""opt"">optionnel</span>")
        sb.Append("</h3><p>").Append(Server.HtmlEncode(s.Descr)).Append("</p></div>")

        ' Action / etat
        sb.Append("<div class=""cta"">")
        If s.Done Then
            sb.Append("<span class=""done-lbl"">✔ Terminé</span>")
        ElseIf s.AdminOnly AndAlso Not IsAbonneAdmin Then
            sb.Append("<span class=""admin-note"">Réservé à un administrateur</span>")
        Else
            sb.Append("<a class=""btn btn-primary"" href=""").Append(s.CtaUrl).Append(""">") _
              .Append(Server.HtmlEncode(s.CtaText)).Append("</a>")
        End If
        sb.Append("</div></div>")
    End Sub

    Private Function N(r As DataRow, col As String) As Integer
        If r Is Nothing OrElse IsDBNull(r(col)) Then Return 0
        Return Convert.ToInt32(r(col))
    End Function

    Private Function B(r As DataRow, col As String) As Boolean
        If r Is Nothing OrElse IsDBNull(r(col)) Then Return False
        Return Convert.ToBoolean(r(col))
    End Function

End Class
