Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports Telerik.Web.UI

Public Class wbfPlans
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            rlvPlans.Rebind()
        End If
    End Sub

    Private Sub rlvPlans_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvPlans.NeedDataSource
        rlvPlans.DataSource = GetData()
    End Sub

    Private Sub rlvPlans_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvPlans.ItemCommand
        Select Case e.CommandName
            Case "DeletePlan"
                Dim id As Integer = 0
                Integer.TryParse(e.CommandArgument.ToString(), id)
                If id > 0 Then
                    DeletePlan(id)
                    rlvPlans.Rebind()
                End If
        End Select
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvPlans.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvPlans.Rebind()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If e.Argument = "refreshgrid" Then
            rlvPlans.Rebind()
        End If
    End Sub

    ' =========================================================================
    ' Synchronisation avec Stripe
    ' Stripe est la référence de ce qui est facturé : pour chaque forfait qui a un
    ' Price Id, on relit le prix dans Stripe (GET /v1/prices/{id}) et on reporte
    ' ici le montant, la devise et le Product Id (s1039). On ne modifie jamais Stripe.
    ' Clé : appSettings « Stripe.SecretKey » du Web.config de Sec60Admin (la même
    ' que celle de l'ERP, sinon les Price Id ne seront pas trouvés).
    ' =========================================================================

    Private Sub btnSyncStripe_Click(sender As Object, e As EventArgs) Handles btnSyncStripe.Click
        Dim sb As New StringBuilder()
        Dim cle As String = If(System.Configuration.ConfigurationManager.AppSettings("Stripe.SecretKey"), "").Trim()

        If cle = "" Then
            sb.Append("<div class='sync-h'>Synchronisation impossible</div>")
            sb.Append("<div>La clé Stripe n'est pas configurée : ajoutez <code>&lt;add key=""Stripe.SecretKey"" value=""sk_…"" /&gt;</code> dans les appSettings du Web.config de Sec60Admin (la même clé que l'ERP).</div>")
            AfficherRapport(sb.ToString())
            Return
        End If

        Dim mode As String = If(cle.StartsWith("sk_live", StringComparison.OrdinalIgnoreCase), "LIVE", "TEST")
        Dim ds As DataSet = ExecuteSQLds("s1038GetPlansForStripeSync")
        Dim lignes As New StringBuilder()
        Dim nbMaj As Integer = 0, nbOk As Integer = 0, nbProb As Integer = 0

        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            Net.ServicePointManager.SecurityProtocol = Net.ServicePointManager.SecurityProtocol Or Net.SecurityProtocolType.Tls12
            For Each r As DataRow In ds.Tables(0).Rows
                Dim res As ResultatSync = SynchroniserForfait(r, cle)
                Select Case res.Statut
                    Case "maj" : nbMaj += 1
                    Case "ok" : nbOk += 1
                    Case "warn", "err" : nbProb += 1
                End Select
                lignes.Append("<li><span class='st ").Append(res.Statut).Append("'>").Append(LibelleStatut(res.Statut)).Append("</span>")
                lignes.Append("<span><b>").Append(Server.HtmlEncode(EnTexte(r("Name")))).Append("</b> <span class='plan-meta'>")
                lignes.Append(Server.HtmlEncode(EnTexte(r("Code")))).Append(" · ").Append(GetCycleLabel(r("BillingCycle"))).Append("</span></span>")
                lignes.Append("<span>").Append(res.Message).Append("</span></li>")
            Next
        End If

        sb.Append("<div class='sync-h'>Synchronisation avec Stripe (mode ").Append(mode).Append(") : ")
        sb.Append(nbMaj).Append(" mis à jour, ").Append(nbOk).Append(" déjà à jour, ").Append(nbProb).Append(" à vérifier</div>")
        sb.Append("<ul>").Append(lignes.ToString()).Append("</ul>")
        sb.Append("<div class='note'>Seuls le montant, la devise et le Product Id sont repris de Stripe. Le cycle, les jours d'essai et les textes restent ceux d'ici.</div>")
        AfficherRapport(sb.ToString())
        rlvPlans.Rebind()
    End Sub

    Private Class ResultatSync
        Public Statut As String   ' maj | ok | warn | err | skip
        Public Message As String  ' HTML
    End Class

    Private Function SynchroniserForfait(r As DataRow, cle As String) As ResultatSync
        Dim res As New ResultatSync()
        Dim priceId As String = EnTexte(r("StripePriceId")).Trim()
        If priceId = "" Then
            res.Statut = "skip" : res.Message = "Pas de Stripe Price Id : rien à synchroniser."
            Return res
        End If

        ' 1. Lire le prix dans Stripe
        Dim prix As Newtonsoft.Json.Linq.JObject
        Try
            prix = LirePrixStripe(priceId, cle)
        Catch ex As Exception
            res.Statut = "err" : res.Message = Server.HtmlEncode(ex.Message)
            Return res
        End Try

        Dim avert As New List(Of String)

        ' 2. Contrôles : le prix doit être un montant fixe, récurrent, du même cycle
        Dim unitAmount = prix("unit_amount")
        If unitAmount Is Nothing OrElse unitAmount.Type = Newtonsoft.Json.Linq.JTokenType.Null Then
            res.Statut = "err" : res.Message = "Ce prix Stripe n'a pas de montant fixe (paliers ou montant libre) : non repris."
            Return res
        End If
        Dim intervalle As String = ""
        Dim recurring = TryCast(prix("recurring"), Newtonsoft.Json.Linq.JObject)
        If recurring IsNot Nothing Then intervalle = CStr(recurring("interval")) & If(CInt(recurring("interval_count")) > 1, "×" & CStr(recurring("interval_count")), "")
        Dim cycleStripe As String = If(intervalle = "month", "monthly", If(intervalle = "year", "annual", ""))
        Dim cycleIci As String = EnTexte(r("BillingCycle")).ToLowerInvariant()
        If recurring Is Nothing Then
            res.Statut = "err" : res.Message = "Ce prix Stripe n'est pas récurrent (paiement unique) : un abonnement ne peut pas l'utiliser."
            Return res
        End If
        If cycleStripe <> cycleIci AndAlso Not (cycleIci = "yearly" AndAlso cycleStripe = "annual") Then
            res.Statut = "err"
            res.Message = "Cycle différent : Stripe facture par « " & Server.HtmlEncode(intervalle) & " », ce forfait est « " & GetCycleLabel(r("BillingCycle")) & " ». Montant non repris ; vérifiez le Price Id."
            Return res
        End If

        If prix("active") IsNot Nothing AndAlso Not CBool(prix("active")) Then avert.Add("prix <b>archivé</b> dans Stripe : le paiement le refusera, créez un nouveau prix")
        Dim taxe As String = If(CStr(prix("tax_behavior")), "")
        If taxe = "" OrElse taxe = "unspecified" Then avert.Add("comportement fiscal non précisé dans Stripe (taxes incluses / en sus) : Stripe Tax refusera le paiement")

        ' 3. Comparer et reporter
        Dim devise As String = CStr(prix("currency")).ToUpperInvariant()
        Dim montant As Decimal = CDec(CLng(unitAmount)) / 100D
        Dim productId As String = If(CStr(prix("product")), "")
        Dim montantIci As Decimal = If(r("Amount") Is DBNull.Value, 0D, CDec(r("Amount")))
        Dim deviseIci As String = EnTexte(r("Currency")).ToUpperInvariant()
        Dim productIci As String = EnTexte(r("StripeProductId")).Trim()

        Dim changements As New List(Of String)
        If montant <> montantIci Then changements.Add("montant " & FormatAmount(montantIci) & " → <b>" & FormatAmount(montant) & "</b>")
        If devise <> deviseIci Then changements.Add("devise " & Server.HtmlEncode(deviseIci) & " → <b>" & Server.HtmlEncode(devise) & "</b>")
        If productId <> "" AndAlso productId <> productIci Then changements.Add("Product Id " & If(productIci = "", "renseigné", "corrigé") & " (" & Server.HtmlEncode(productId) & ")")

        If changements.Count > 0 Then
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", CInt(r("Id"))))
            p.Add(New SqlParameter("@Amount", montant))
            p.Add(New SqlParameter("@Currency", devise))
            p.Add(New SqlParameter("@StripeProductId", productId))
            p.Add(New SqlParameter("@ModifiedBy", UserEmail))
            ExecuteSQL("s1039UpdatePlanFromStripe", p)
            res.Statut = "maj" : res.Message = String.Join(" ; ", changements)
        Else
            res.Statut = "ok" : res.Message = FormatAmount(montant) & " " & Server.HtmlEncode(devise) & " — identique à Stripe."
        End If

        If avert.Count > 0 Then
            If res.Statut = "ok" Then res.Statut = "warn"
            res.Message &= "<br />⚠ " & String.Join("<br />⚠ ", avert)
        End If
        Return res
    End Function

    ''' <summary>GET https://api.stripe.com/v1/prices/{id}. Lève une exception au message lisible.</summary>
    Private Function LirePrixStripe(priceId As String, cle As String) As Newtonsoft.Json.Linq.JObject
        Dim req As Net.HttpWebRequest = CType(Net.WebRequest.Create("https://api.stripe.com/v1/prices/" & Uri.EscapeDataString(priceId)), Net.HttpWebRequest)
        req.Method = "GET"
        req.Headers(Net.HttpRequestHeader.Authorization) = "Bearer " & cle
        req.Timeout = 20000
        Try
            Using resp As Net.WebResponse = req.GetResponse(), lecteur As New IO.StreamReader(resp.GetResponseStream())
                Return Newtonsoft.Json.Linq.JObject.Parse(lecteur.ReadToEnd())
            End Using
        Catch ex As Net.WebException
            Dim msg As String = ex.Message
            Dim code As Integer = 0
            If ex.Response IsNot Nothing Then
                code = CInt(CType(ex.Response, Net.HttpWebResponse).StatusCode)
                Try
                    Using lecteur As New IO.StreamReader(ex.Response.GetResponseStream())
                        Dim j = Newtonsoft.Json.Linq.JObject.Parse(lecteur.ReadToEnd())
                        If j("error") IsNot Nothing AndAlso j("error")("message") IsNot Nothing Then msg = CStr(j("error")("message"))
                    End Using
                Catch
                End Try
            End If
            If code = 404 Then Throw New Exception("Price Id introuvable dans Stripe (" & priceId & ") : il a peut-être été créé dans l'autre mode (test ou live) que la clé utilisée.")
            If code = 401 Then Throw New Exception("Clé Stripe refusée : vérifiez Stripe.SecretKey dans le Web.config de Sec60Admin.")
            Throw New Exception("Stripe : " & msg)
        End Try
    End Function

    Private Shared Function LibelleStatut(statut As String) As String
        Select Case statut
            Case "maj" : Return "Mis à jour"
            Case "ok" : Return "À jour"
            Case "warn" : Return "À vérifier"
            Case "err" : Return "Erreur"
            Case Else : Return "Ignoré"
        End Select
    End Function

    Private Shared Function EnTexte(v As Object) As String
        Return If(v Is Nothing OrElse v Is DBNull.Value, "", v.ToString())
    End Function

    Private Sub AfficherRapport(html As String)
        litSync.Text = html
        pnlSync.Visible = True
    End Sub

    Private Function GetData() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@Search", tbSearch.Text.Trim()))
        Dim ds As DataSet = ExecuteSQLds("s0632GetPlansList", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        Return ds.Tables(0)
    End Function

    Private Sub DeletePlan(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@ModifiedBy", UserEmail))
        ExecuteSQL("s0635DeletePlan", p)
    End Sub

    ''' <summary>
    ''' Initiales pour l'icône du forfait (nom, sinon code).
    ''' </summary>
    Public Function GetInitials(name As Object, code As Object) As String
        Dim nm As String = If(name Is Nothing OrElse name Is DBNull.Value, "", name.ToString().Trim())
        If nm.Length > 0 Then Return nm.Substring(0, 1).ToUpper()
        Dim cd As String = If(code Is Nothing OrElse code Is DBNull.Value, "?", code.ToString())
        If cd.Length > 0 Then Return cd.Substring(0, 1).ToUpper()
        Return "?"
    End Function

    ''' <summary>
    ''' Formate le montant avec 2 décimales.
    ''' </summary>
    Public Function FormatAmount(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return "0.00"
        Return CDec(value).ToString("N2", Globalization.CultureInfo.InvariantCulture)
    End Function

    ''' <summary>
    ''' Libellé lisible du cycle de facturation.
    ''' </summary>
    Public Function GetCycleLabel(value As Object) As String
        Dim s As String = If(value Is Nothing OrElse value Is DBNull.Value, "", value.ToString().ToLower())
        Select Case s
            Case "monthly" : Return "Mensuel"
            Case "annual", "yearly" : Return "Annuel"
            Case "weekly" : Return "Hebdo"
            Case Else : Return If(s = "", "—", value.ToString())
        End Select
    End Function

End Class
