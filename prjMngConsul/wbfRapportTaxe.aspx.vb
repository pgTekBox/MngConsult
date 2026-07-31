Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Partial Public Class wbfRapportTaxe
    Inherits clsData

    ' =========================================================
    '  ÉTAT (ViewState)
    ' =========================================================

    ''' <summary>
    ''' Date de référence pour la période courante. Conservée en ViewState
    ''' pour la navigation Précédent / Suivant.
    ''' </summary>
    Private Property DateReference As Date
        Get
            If ViewState("DateRef") Is Nothing Then
                Return Date.Today
            End If
            Return DirectCast(ViewState("DateRef"), Date)
        End Get
        Set(value As Date)
            ViewState("DateRef") = value
        End Set
    End Property

    Private Property RapportId As Integer
        Get
            Return If(ViewState("RapportId"), 0)
        End Get
        Set(value As Integer)
            ViewState("RapportId") = value
        End Set
    End Property

    Private Property Frequence As String
        Get
            Return If(ViewState("Freq"), "TRIMESTRIELLE").ToString()
        End Get
        Set(value As String)
            ViewState("Freq") = value
        End Set
    End Property

    ' =========================================================
    '  PAGE LIFECYCLE
    ' =========================================================

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            DateReference = Date.Today
            dpDatePaiement.SelectedDate = Date.Today
            LoadFrequence()
            ChargerRapport()
        End If
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur et Literal de mise en page.</summary>
    Private Sub ApplyLocalization()
        ' Boutons / contrôles serveur
        btnPrev.Text = L("btnPrev")
        btnNext.Text = L("btnNext")
        btnRecalcul.Text = L("btnRecalcul")
        btnRemettre.Text = L("btnRemettre")
        winRemise.Title = L("winTitle")
        btnConfirmerRemise.Text = L("btnConfirmer")
        btnAnnulerRemise.Text = L("btnAnnuler")
        txtReference.EmptyMessage = L("refPlaceholder")

        ' Titre + sous-titre (Literal : pas de <%= %> dans la zone RadAjax)
        SetLiteral(Me, "litH2Title", L("h2Title"))
        SetLiteral(Me, "litSubtitle", L("subtitle"))

        ' Bloc TPS / TVQ (Literal de libellés statiques)
        SetLiteral(Me, "litDetailTitre", L("detailTitre"))
        SetLiteral(Me, "litTPSTitre", L("tpsTitre"))
        SetLiteral(Me, "litTPSPercueLbl", L("percueVentes"))
        SetLiteral(Me, "litTPSPayeeLbl", L("ctiAchats"))
        SetLiteral(Me, "litTPSNetteLbl", L("tpsNette"))
        SetLiteral(Me, "litTVQTitre", L("tvqTitre"))
        SetLiteral(Me, "litTVQPercueLbl", L("percueVentes"))
        SetLiteral(Me, "litTVQPayeeLbl", L("rtiAchats"))
        SetLiteral(Me, "litTVQNetteLbl", L("tvqNette"))
        SetLiteral(Me, "litTotalLbl", L("totalARemettre"))
        SetLiteral(Me, "litRemiseFaiteLbl", L("remiseFaite"))
        SetLiteral(Me, "litRefSepLbl", L("refSep"))

        ' Tableau de détail
        SetLiteral(Me, "litDetailEcrituresTitre", L("detailEcritures"))
        SetLiteral(Me, "litColDate", L("colDate"))
        SetLiteral(Me, "litColPiece", L("colPiece"))
        SetLiteral(Me, "litColLibelle", L("colLibelle"))
        SetLiteral(Me, "litColCompte", L("colCompte"))
        SetLiteral(Me, "litColCategorie", L("colCategorie"))
        SetLiteral(Me, "litColDebit", L("colDebit"))
        SetLiteral(Me, "litColCredit", L("colCredit"))

        ' Modale de confirmation de remise
        SetLiteral(Me, "litWinIntro", L("winIntro"))
        SetLiteral(Me, "litWinLi1", L("winLi1"))
        SetLiteral(Me, "litWinLi2", L("winLi2"))
        SetLiteral(Me, "litWinDateLbl", L("winDateLbl"))
        SetLiteral(Me, "litWinRefLbl", L("winRefLbl"))
    End Sub

    ''' <summary>Traductions de l'interface Rapport de remise de taxes (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Rapport de remise de taxes", "Tax remittance report", "Informe de remesa de impuestos")
            Case "h2Title" : Return Choose3(lang, "Rapport de remise de taxes (TPS / TVQ)", "Tax remittance report (GST / QST)", "Informe de remesa de impuestos (IVA / IVQ)")
            Case "subtitle" : Return Choose3(lang, "Calcul automatique des taxes perçues et payées sur la période, selon la fréquence de remise configurée.", "Automatic calculation of taxes collected and paid during the period, according to the configured remittance frequency.", "Cálculo automático de los impuestos recaudados y pagados en el período, según la frecuencia de remesa configurada.")
            Case "freqInfo" : Return Choose3(lang, "Fréquence configurée : <strong>{0}</strong>.", "Configured frequency: <strong>{0}</strong>.", "Frecuencia configurada: <strong>{0}</strong>.")
            Case "freqMensuelle" : Return Choose3(lang, "mensuelle", "monthly", "mensual")
            Case "freqTrimestrielle" : Return Choose3(lang, "trimestrielle", "quarterly", "trimestral")
            Case "freqAnnuelle" : Return Choose3(lang, "annuelle", "annual", "anual")
            Case "btnPrev" : Return Choose3(lang, "‹ Précédent", "‹ Previous", "‹ Anterior")
            Case "btnNext" : Return Choose3(lang, "Suivant ›", "Next ›", "Siguiente ›")
            Case "btnRecalcul" : Return Choose3(lang, "Recalculer", "Recalculate", "Recalcular")
            Case "btnRemettre" : Return Choose3(lang, "Marquer comme remis", "Mark as remitted", "Marcar como remitido")
            Case "periodeLabel" : Return Choose3(lang, "Période", "Period", "Período")
            Case "aucuneDonnee" : Return Choose3(lang, "Aucune donnée", "No data", "Sin datos")
            Case "detailTitre" : Return Choose3(lang, "Détail du rapport", "Report details", "Detalle del informe")
            Case "tpsTitre" : Return Choose3(lang, "TPS — 5 %", "GST — 5%", "IVA — 5 %")
            Case "tvqTitre" : Return Choose3(lang, "TVQ — 9,975 %", "QST — 9.975%", "IVQ — 9,975 %")
            Case "percueVentes" : Return Choose3(lang, "Perçue sur ventes", "Collected on sales", "Recaudado sobre ventas")
            Case "ctiAchats" : Return Choose3(lang, "CTI sur achats", "ITC on purchases", "CTI sobre compras")
            Case "rtiAchats" : Return Choose3(lang, "RTI sur achats", "ITR on purchases", "RTI sobre compras")
            Case "tpsNette" : Return Choose3(lang, "TPS nette à remettre", "Net GST to remit", "IVA neto a remitir")
            Case "tvqNette" : Return Choose3(lang, "TVQ nette à remettre", "Net QST to remit", "IVQ neto a remitir")
            Case "totalARemettre" : Return Choose3(lang, "TOTAL À REMETTRE À REVENU QUÉBEC", "TOTAL TO REMIT TO REVENU QUÉBEC", "TOTAL A REMITIR A REVENU QUÉBEC")
            Case "remiseFaite" : Return Choose3(lang, "Remise effectuée le", "Remittance made on", "Remesa efectuada el")
            Case "refSep" : Return Choose3(lang, "— Référence :", "— Reference:", "— Referencia:")
            Case "detailEcritures" : Return Choose3(lang, "Détail des écritures incluses dans le calcul", "Details of entries included in the calculation", "Detalle de los asientos incluidos en el cálculo")
            Case "colDate" : Return Choose3(lang, "Date", "Date", "Fecha")
            Case "colPiece" : Return Choose3(lang, "Pièce", "Voucher", "Comprobante")
            Case "colLibelle" : Return Choose3(lang, "Libellé", "Description", "Descripción")
            Case "colCompte" : Return Choose3(lang, "Compte", "Account", "Cuenta")
            Case "colCategorie" : Return Choose3(lang, "Catégorie", "Category", "Categoría")
            Case "colDebit" : Return Choose3(lang, "Débit", "Debit", "Débito")
            Case "colCredit" : Return Choose3(lang, "Crédit", "Credit", "Crédito")
            Case "winTitle" : Return Choose3(lang, "Confirmer la remise", "Confirm the remittance", "Confirmar la remesa")
            Case "winIntro" : Return Choose3(lang, "Vous allez marquer cette déclaration comme remise. Cette action :", "You are about to mark this declaration as remitted. This action:", "Va a marcar esta declaración como remitida. Esta acción:")
            Case "winLi1" : Return Choose3(lang, "créera l'écriture comptable de remise", "will create the remittance accounting entry", "creará el asiento contable de remesa")
            Case "winLi2" : Return Choose3(lang, "verrouillera la déclaration (statut PAYE)", "will lock the declaration (PAID status)", "bloqueará la declaración (estado PAGADO)")
            Case "winDateLbl" : Return Choose3(lang, "Date du paiement :", "Payment date:", "Fecha del pago:")
            Case "winRefLbl" : Return Choose3(lang, "Référence :", "Reference:", "Referencia:")
            Case "refPlaceholder" : Return Choose3(lang, "Numéro de chèque, confirmation, ...", "Cheque number, confirmation, ...", "Número de cheque, confirmación, ...")
            Case "btnConfirmer" : Return Choose3(lang, "Confirmer", "Confirm", "Confirmar")
            Case "btnAnnuler" : Return Choose3(lang, "Annuler", "Cancel", "Cancelar")
            Case "pillBrouillon" : Return Choose3(lang, "Brouillon", "Draft", "Borrador")
            Case "pillFinalise" : Return Choose3(lang, "Finalisé", "Finalized", "Finalizado")
            Case "pillRemis" : Return Choose3(lang, "Remis", "Remitted", "Remitido")
            Case "msgRecalcule" : Return Choose3(lang, "Rapport recalculé.", "Report recalculated.", "Informe recalculado.")
            Case "msgAucunRapport" : Return Choose3(lang, "Aucun rapport sélectionné.", "No report selected.", "Ningún informe seleccionado.")
            Case "msgRemiseOk" : Return Choose3(lang, "Remise effectuée.", "Remittance completed.", "Remesa completada.")
            Case "msgErreurRemise" : Return Choose3(lang, "Erreur lors de la remise : ", "Error during remittance: ", "Error durante la remesa: ")
            Case "lblTPS" : Return Choose3(lang, "TPS", "GST", "IVA")
            Case "lblTVQ" : Return Choose3(lang, "TVQ", "QST", "IVQ")
            Case "lblTotal" : Return Choose3(lang, "Total", "Total", "Total")
            Case "periodeAnnee" : Return Choose3(lang, "Année", "Year", "Año")
            Case "periodeTrim" : Return Choose3(lang, "T", "Q", "T")
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

    Private Shared Sub SetLiteral(root As Control, id As String, text As String)
        Dim lit = TryCast(FindDeep(root, id), Literal)
        If lit IsNot Nothing Then lit.Text = text
    End Sub

    Private Shared Function FindDeep(root As Control, id As String) As Control
        If root Is Nothing Then Return Nothing
        Dim direct As Control = root.FindControl(id)
        If direct IsNot Nothing Then Return direct
        For Each ch As Control In root.Controls
            Dim r As Control = FindDeep(ch, id)
            If r IsNot Nothing Then Return r
        Next
        Return Nothing
    End Function

    Private Sub LoadFrequence()
        Dim freq = LireParametre("TAX_FREQ", "TRIMESTRIELLE")
        Frequence = freq

        Dim libelleFreq As String
        Select Case freq
            Case "MENSUELLE" : libelleFreq = L("freqMensuelle")
            Case "ANNUELLE" : libelleFreq = L("freqAnnuelle")
            Case Else : libelleFreq = L("freqTrimestrielle")
        End Select
        litFreqInfo.Text = String.Format(L("freqInfo"), libelleFreq)
    End Sub

    ' =========================================================
    '  ÉVÉNEMENTS
    ' =========================================================

    Protected Sub btnPrev_Click(sender As Object, e As EventArgs)
        DateReference = DeplacerPeriode(DateReference, -1)
        ChargerRapport()
    End Sub

    Protected Sub btnNext_Click(sender As Object, e As EventArgs)
        DateReference = DeplacerPeriode(DateReference, 1)
        ChargerRapport()
    End Sub

    Protected Sub btnRecalcul_Click(sender As Object, e As EventArgs)
        ChargerRapport()
        ShowStatus("success", L("msgRecalcule"))
    End Sub

    Protected Sub btnRemettre_Click(sender As Object, e As EventArgs)
        ' La modale s'ouvre via JavaScript, pas besoin d'action serveur ici
    End Sub

    Protected Sub btnConfirmerRemise_Click(sender As Object, e As EventArgs)
        If RapportId = 0 Then
            ShowStatus("warning", L("msgAucunRapport"))
            Return
        End If

        Dim datePaie = If(dpDatePaiement.SelectedDate.HasValue, dpDatePaiement.SelectedDate.Value, Date.Today)
        Dim ref = If(String.IsNullOrWhiteSpace(txtReference.Text), Nothing, txtReference.Text.Trim())

        Try
            Dim res = MarquerCommeRemis(RapportId, datePaie, ref)
            ShowStatus("success",
                L("msgRemiseOk") & " " & L("lblTPS") & " : " & FormatMontant(Convert.ToDecimal(res("TPS_Remise"))) &
                " — " & L("lblTVQ") & " : " & FormatMontant(Convert.ToDecimal(res("TVQ_Remise"))) &
                " — " & L("lblTotal") & " : " & FormatMontant(Convert.ToDecimal(res("TotalRemis"))))
            ChargerRapport()
        Catch ex As Exception
            ShowStatus("danger", L("msgErreurRemise") & ex.Message)
        End Try
    End Sub

    ' =========================================================
    '  CALCUL DE LA PÉRIODE (selon fréquence)
    ' =========================================================

    Private Function DeplacerPeriode(d As Date, sens As Integer) As Date
        Select Case Frequence
            Case "MENSUELLE" : Return d.AddMonths(sens)
            Case "ANNUELLE" : Return d.AddYears(sens)
            Case Else : Return d.AddMonths(sens * 3) ' TRIMESTRIELLE
        End Select
    End Function

    Private Function FormaterLibellePeriode(debut As Date, fin As Date) As String
        Dim ci = System.Globalization.CultureInfo.GetCultureInfo(PeriodeCulture())
        Select Case Frequence
            Case "MENSUELLE"
                Return CapitalizeFirst(debut.ToString("MMMM yyyy", ci))
            Case "ANNUELLE"
                Return L("periodeAnnee") & " " & debut.Year.ToString()
            Case Else  ' TRIMESTRIELLE
                Dim trim As Integer = ((debut.Month - 1) \ 3) + 1
                Return L("periodeTrim") & trim & " " & debut.Year.ToString() &
                    " (" & debut.ToString("dd MMM", ci) &
                    " — " & fin.ToString("dd MMM yyyy", ci) & ")"
        End Select
    End Function

    ''' <summary>Culture d'affichage des dates/mois selon la langue courante.</summary>
    Private Function PeriodeCulture() As String
        Select Case CurrentLang
            Case "en" : Return "en-CA"
            Case "es" : Return "es-ES"
            Case Else : Return "fr-CA"
        End Select
    End Function

    Private Function CapitalizeFirst(s As String) As String
        If String.IsNullOrEmpty(s) Then Return s
        Return Char.ToUpper(s(0)) & s.Substring(1)
    End Function

    ' =========================================================
    '  APPELS SQL — UNIQUEMENT VIA PROCÉDURES STOCKÉES
    '  Aucun T-SQL inline dans ce code-behind.
    ' =========================================================

    ''' <summary>
    ''' Lit un paramètre T100/T101 via s0160GetParamValue.
    ''' Retourne la valeur défaut si le paramètre est inexistant ou non configuré.
    ''' </summary>
    Private Function LireParametre(shortName As String, defaut As String) As String
        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.s0160GetParamValue", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@ShortName", shortName)

                Using rdr = cmd.ExecuteReader()
                    If rdr.Read() Then
                        Dim v = rdr("sVal")
                        If v Is Nothing OrElse Convert.IsDBNull(v) Then Return defaut
                        Dim s = v.ToString()
                        Return If(String.IsNullOrEmpty(s), defaut, s)
                    End If
                End Using
            End Using
        End Using
        Return defaut
    End Function

    ''' <summary>
    ''' Charge le rapport courant via sp_GenererRapportTaxe.
    ''' </summary>
    Private Sub ChargerRapport()
        Dim ds As New DataSet()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.sp_GenererRapportTaxe", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@DateReference", DateReference)
                cmd.Parameters.AddWithValue("@UserId", UserId)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(ds)
                End Using
            End Using
        End Using

        If ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            lblPeriode.Text = L("aucuneDonnee")
            Return
        End If

        Dim r = ds.Tables(0).Rows(0)
        RapportId = Convert.ToInt32(r("Id"))
        Dim debut = Convert.ToDateTime(r("DebutPeriode"))
        Dim fin = Convert.ToDateTime(r("FinPeriode"))

        ' Libellé période
        lblPeriode.Text = FormaterLibellePeriode(debut, fin)

        ' Montants TPS
        litTPSPercue.Text = FormatMontant(Convert.ToDecimal(r("TPS_Percue")))
        litTPSPayee.Text = FormatMontant(Convert.ToDecimal(r("TPS_Payee")))
        litTPSNette.Text = FormatMontant(Convert.ToDecimal(r("TPS_Nette")) + Convert.ToDecimal(r("CTI_Ajustement")))

        ' Montants TVQ
        litTVQPercue.Text = FormatMontant(Convert.ToDecimal(r("TVQ_Percue")))
        litTVQPayee.Text = FormatMontant(Convert.ToDecimal(r("TVQ_Payee")))
        litTVQNette.Text = FormatMontant(Convert.ToDecimal(r("TVQ_Nette")) + Convert.ToDecimal(r("RTI_Ajustement")))

        ' Total à remettre
        litTotal.Text = FormatMontant(Convert.ToDecimal(r("TotalARemettre")))

        ' Statut & pill
        Dim statut = r("Statut").ToString()
        Dim pillClass = statut.ToLower()
        Dim pillText As String
        Select Case statut
            Case "BROUILLON" : pillText = L("pillBrouillon")
            Case "FINALISE" : pillText = L("pillFinalise")
            Case "PAYE" : pillText = L("pillRemis")
            Case Else : pillText = statut
        End Select
        litStatutPill.Text = "<span class='status-pill " & pillClass & "'>" & pillText & "</span>"

        ' Bloc paiement (si remis)
        If statut = "PAYE" AndAlso Not Convert.IsDBNull(r("PayerLe")) Then
            pnlPaye.Visible = True
            litDatePaiement.Text = Convert.ToDateTime(r("PayerLe")).ToString("yyyy-MM-dd")
            litReference.Text = If(Convert.IsDBNull(r("Reference")), "—", r("Reference").ToString())
            btnRemettre.Enabled = False
        Else
            pnlPaye.Visible = False
            btnRemettre.Enabled = (Convert.ToDecimal(r("TotalARemettre")) > 0)
        End If

        ' Détail
        If ds.Tables.Count >= 2 AndAlso ds.Tables(1).Rows.Count > 0 Then
            rpDetail.DataSource = ds.Tables(1)
            rpDetail.DataBind()
            phDetail.Visible = True
        Else
            phDetail.Visible = False
        End If
    End Sub

    ''' <summary>
    ''' Marque le rapport comme remis via sp_MarquerRapportTaxePaye.
    ''' Cette SP encapsule sp_PayerDeclarationTaxe + UPDATE Statut dans une transaction.
    ''' </summary>
    Private Function MarquerCommeRemis(rapportId As Integer, datePaiement As Date, reference As String) As Dictionary(Of String, Object)
        Dim out As New Dictionary(Of String, Object)

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.sp_MarquerRapportTaxePaye", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = 60
                cmd.Parameters.AddWithValue("@RapportId", rapportId)
                cmd.Parameters.AddWithValue("@DatePaiement", datePaiement)
                cmd.Parameters.AddWithValue("@Reference",
                    If(String.IsNullOrEmpty(reference), CObj(DBNull.Value), reference))
                cmd.Parameters.AddWithValue("@UserId", UserId)

                Using rdr = cmd.ExecuteReader()
                    If rdr.Read() Then
                        For i = 0 To rdr.FieldCount - 1
                            out(rdr.GetName(i)) = rdr.GetValue(i)
                        Next
                    End If
                End Using
            End Using
        End Using

        Return out
    End Function

    ' =========================================================
    '  HELPERS DE PRÉSENTATION
    ' =========================================================

    Private Function FormatMontant(m As Decimal) As String
        Return m.ToString("N2", System.Globalization.CultureInfo.GetCultureInfo("fr-CA")) & " $"
    End Function

    Private Sub ShowStatus(level As String, message As String)
        Dim bg As String, color As String, border As String
        Select Case level
            Case "success"
                bg = "#dcfce7" : color = "#166534" : border = "#16a34a"
            Case "warning"
                bg = "#fef3c7" : color = "#92400e" : border = "#f59e0b"
            Case "danger"
                bg = "#fee2e2" : color = "#991b1b" : border = "#dc2626"
            Case Else
                bg = "#dbeafe" : color = "#1e40af" : border = "#3b82f6"
        End Select

        divStatus.Style("background") = bg
        divStatus.Style("color") = color
        divStatus.Style("border-color") = border
        litStatus.Text = message
        phStatus.Visible = True
    End Sub

End Class
