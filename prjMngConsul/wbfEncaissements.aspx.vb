Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Linq
Imports System.Text
Imports Telerik.Web.UI

''' <summary>
''' Ventes › Encaissements : les paiements reçus des clients (T140Reglement,
''' Sens = ENCAISSEMENT), à la signature du gabarit « Portail du client ».
''' Trois indicateurs (reçu ce mois, rapprochés avec la banque, encore à
''' recevoir), une recherche, une ligne par paiement : client, date · type
''' · référence, factures imputées, montant, et d'où il vient (rapproché par
''' la banque ou saisi ici). « + Enregistrer un paiement reçu » ouvre la
''' fenêtre d'encaissement habituelle (wbfReceiptEditPopup, usercontrol
''' ucReceiptEdit) ; la liste se recharge à sa fermeture.
''' </summary>
Public Class wbfEncaissements
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If
        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        litRubrique.Text = L("rubrique")
        litTitre.Text = L("titre")
        litSousTitre.Text = L("sousTitre")
        litTitreListe.Text = L("titreListe")
        btnNouveau.Text = L("nouveau")
        tbSearch.Attributes("placeholder") = L("searchPh")
        btnClear.ToolTip = L("clear")
        rwEncaissement.Title = L("winNouveau")
        If Not IsPostBack Then Charger()
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        Charger()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        Charger()
    End Sub

    Private Sub Ram1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles Ram1.AjaxRequest
        If e.Argument = "refresh" Then Charger()
    End Sub

    ' ---------------------------------------------------------------------
    ' Données
    ' ---------------------------------------------------------------------
    Private Function Lire(recherche As String) As List(Of DataRow)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Search", recherche))
        Dim ds As DataSet = ExecuteSQLds("s0905GetEncaissements", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return New List(Of DataRow)
        Return ds.Tables(0).Rows.Cast(Of DataRow)().ToList()
    End Function

    Private Shared Function Montant(r As DataRow, col As String) As Decimal
        If IsDBNull(r(col)) Then Return 0D
        Return Convert.ToDecimal(r(col))
    End Function

    Private Sub Charger()
        ' Les indicateurs comptent tout, quelle que soit la recherche.
        Dim tous As List(Of DataRow) = Lire("")
        Dim debutMois As Date = New Date(Date.Today.Year, Date.Today.Month, 1)
        Dim duMois = tous.Where(Function(r) Not IsDBNull(r("DateReglement")) AndAlso CDate(r("DateReglement")) >= debutMois).ToList()
        Dim rapproches As Integer = tous.Where(Function(r) Convert.ToInt32(r("Rapproche")) = 1).Count()

        ' Encore à recevoir : les factures comptabilisées non soldées (même source que les factures clients).
        Dim aRecevoir As Decimal = 0D, nOuvertes As Integer = 0
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Search", ""))
            p.Add(New SqlParameter("@Etats", ""))
            p.Add(New SqlParameter("@StatutsPaiement", "EN_RETARD,OUVERTE,PARTIELLE"))
            Dim ds As DataSet = ExecuteSQLds("s0026GetCustomersInvoices", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    aRecevoir += Montant(r, "ResteAPayer") : nOuvertes += 1
                Next
            End If
        Catch
        End Try

        Dim mois As String = CultureInfo.GetCultureInfo(If(CurrentLang = "en", "en-CA", If(CurrentLang = "es", "es-ES", "fr-CA"))).DateTimeFormat.GetMonthName(Date.Today.Month)
        Dim sb As New StringBuilder()
        sb.Append(Kpi(String.Format(L("kpiRecuMois"), mois), duMois.Sum(Function(r) Montant(r, "Montant")).ToString("C0"), String.Format(L("kpiPaiements"), duMois.Count)))
        sb.Append(Kpi(L("kpiRapproches"), rapproches.ToString(), L("kpiRapprochesSub")))
        sb.Append(Kpi(L("kpiARecevoir"), aRecevoir.ToString("C0"), String.Format(L("kpiFactures"), nOuvertes)))
        litKpis.Text = sb.ToString()

        ' La liste, avec la recherche.
        Dim lignes As List(Of DataRow) = If(tbSearch.Text.Trim() = "", tous, Lire(tbSearch.Text.Trim()))
        sb.Clear()
        For Each r As DataRow In lignes
            sb.Append(Ligne(r))
        Next
        If lignes.Count = 0 Then sb.Append("<p class=""en-vide"">").Append(Server.HtmlEncode(L("vide"))).Append("</p>")
        litLignes.Text = sb.ToString()
        litPied.Text = Server.HtmlEncode(String.Format(L("pied"), lignes.Count, tous.Count))
    End Sub

    Private Function Kpi(lab As String, val As String, sub_ As String) As String
        Return "<div class=""fc-kpi""><span class=""lab"">" & Server.HtmlEncode(lab) & "</span><span class=""val"">" &
               Server.HtmlEncode(val) & "</span><span class=""sub"">" & Server.HtmlEncode(sub_) & "</span></div>"
    End Function

    ''' <summary>Une ligne : l'icône, le client et « date · type no référence », les factures, le montant, la provenance.</summary>
    Private Function Ligne(r As DataRow) As String
        Dim ci As New CultureInfo(If(CurrentLang = "en", "en-CA", If(CurrentLang = "es", "es-ES", "fr-CA")))
        Dim det As String = If(IsDBNull(r("DateReglement")), "", CDate(r("DateReglement")).ToString("d MMM yyyy", ci))
        det &= " · " & TypeLibelle(Convert.ToString(r("TypeReglement")))
        Dim ref As String = Convert.ToString(r("Reference")).Trim()
        If ref <> "" Then det &= " " & L("no") & " " & ref
        Dim rapproche As Boolean = Convert.ToInt32(r("Rapproche")) = 1
        Dim client As String = Convert.ToString(r("PartyName"))
        If client = "" Then client = L("sansClient")

        Dim sb As New StringBuilder()
        sb.Append("<div class=""en-ligne"">")
        sb.Append("<span class=""en-ico"" aria-hidden=""true""><svg viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""2.2"" stroke-linecap=""round"" stroke-linejoin=""round""><path d=""M12 3v18M7 8a4 3 0 0 1 4-3h2a4 3 0 0 1 0 6h-2a4 3 0 0 0 0 6h2a4 3 0 0 0 4-3""></path></svg></span>")
        sb.Append("<span class=""en-qui""><b>").Append(Server.HtmlEncode(client)).Append("</b><span>").Append(Server.HtmlEncode(det)).Append("</span></span>")
        sb.Append("<span class=""en-fact"">").Append(Server.HtmlEncode(Convert.ToString(r("Factures")))).Append("</span>")
        sb.Append("<span class=""en-montant"">").Append(Server.HtmlEncode(Montant(r, "Montant").ToString("C2"))).Append("</span>")
        sb.Append("<span class=""en-par ").Append(If(rapproche, "banque", "vous")).Append(""">").Append(Server.HtmlEncode(If(rapproche, L("parBanque"), L("parVous")))).Append("</span>")
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    ''' <summary>Le type de règlement (code de T140) dans la langue de la session.</summary>
    Private Function TypeLibelle(code As String) As String
        Select Case code.Trim().ToUpperInvariant()
            Case "CHEQUE" : Return L("tChq")
            Case "COMPTANT", "CASH" : Return L("tCash")
            Case "VIREMENT" : Return L("tVir")
            Case "INTERAC" : Return L("tInterac")
            Case "CARTE", "CARD" : Return L("tCarte")
            Case "STRIPE" : Return "Stripe"
            Case "SQUARE" : Return "Square"
            Case "" : Return L("tAutre")
            Case Else : Return code
        End Select
    End Function

    ' ---------------------------------------------------------------------
    ' Traductions (fr/en/es)
    ' ---------------------------------------------------------------------
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "rubrique" : Return Choose3(lang, "Ventes", "Sales", "Ventas")
            Case "titre" : Return Choose3(lang, "Encaissements", "Cash receipts", "Cobros")
            Case "sousTitre" : Return Choose3(lang, "Les paiements reçus de vos clients : virements, dépôts, chèques et comptant.", "The payments received from your customers: transfers, deposits, cheques and cash.", "Los pagos recibidos de sus clientes: transferencias, depósitos, cheques y efectivo.")
            Case "nouveau" : Return Choose3(lang, "+ Enregistrer un paiement reçu", "+ Record a received payment", "+ Registrar un pago recibido")
            Case "winNouveau" : Return Choose3(lang, "Enregistrer un paiement reçu", "Record a received payment", "Registrar un pago recibido")
            Case "titreListe" : Return Choose3(lang, "Paiements reçus", "Payments received", "Pagos recibidos")
            Case "searchPh" : Return Choose3(lang, "Chercher un client, une référence ou une facture", "Search a customer, a reference or an invoice", "Buscar un cliente, una referencia o una factura")
            Case "clear" : Return Choose3(lang, "Effacer", "Clear", "Borrar")
            Case "kpiRecuMois" : Return Choose3(lang, "Reçu en {0}", "Received in {0}", "Recibido en {0}")
            Case "kpiPaiements" : Return Choose3(lang, "{0} paiement(s)", "{0} payment(s)", "{0} pago(s)")
            Case "kpiRapproches" : Return Choose3(lang, "Rapprochés avec la banque", "Matched with the bank", "Conciliados con el banco")
            Case "kpiRapprochesSub" : Return Choose3(lang, "virements et dépôts", "transfers and deposits", "transferencias y depósitos")
            Case "kpiARecevoir" : Return Choose3(lang, "Encore à recevoir", "Still to receive", "Aún por cobrar")
            Case "kpiFactures" : Return Choose3(lang, "{0} facture(s)", "{0} invoice(s)", "{0} factura(s)")
            Case "no" : Return Choose3(lang, "no", "no.", "n.º")
            Case "sansClient" : Return Choose3(lang, "(sans client)", "(no customer)", "(sin cliente)")
            Case "parBanque" : Return Choose3(lang, "Rapproché avec la banque", "Matched with the bank", "Conciliado con el banco")
            Case "parVous" : Return Choose3(lang, "Saisi par vous", "Entered by you", "Registrado por usted")
            Case "vide" : Return Choose3(lang, "Aucun paiement reçu ne correspond.", "No received payment matches.", "Ningún pago recibido coincide.")
            Case "pied" : Return Choose3(lang, "{0} sur {1} paiements reçus", "{0} of {1} payments received", "{0} de {1} pagos recibidos")
            Case "tChq" : Return Choose3(lang, "Chèque", "Cheque", "Cheque")
            Case "tCash" : Return Choose3(lang, "Comptant", "Cash", "Efectivo")
            Case "tVir" : Return Choose3(lang, "Virement", "Transfer", "Transferencia")
            Case "tInterac" : Return Choose3(lang, "Virement Interac", "Interac transfer", "Transferencia Interac")
            Case "tCarte" : Return Choose3(lang, "Carte", "Card", "Tarjeta")
            Case "tAutre" : Return Choose3(lang, "Paiement", "Payment", "Pago")
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
