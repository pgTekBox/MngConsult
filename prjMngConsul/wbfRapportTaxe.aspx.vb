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
            Response.Redirect("~/Default.aspx")
            Return
        End If

        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        ApplyLocalization()

        If Not IsPostBack Then
            DateReference = Date.Today
            ' Ouvert depuis l'activité « Déclaration de taxes à produire » (ACT_TAXES, T375) :
            ' ?date=aaaa-mm-jj = une date de la période à afficher.
            Dim qDate As Date
            If Date.TryParseExact(Request.QueryString("date"), "yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture, Globalization.DateTimeStyles.None, qDate) Then
                DateReference = qDate
            End If
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
        SetLiteral(Me, "litRubrique", L("rubrique"))
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
    ''' <summary>
    ''' Le numéro de pièce du détail : un lien qui ouvre la facture d'origine quand
    ''' l'écriture vient d'une facture (SourceType FACTURE_CLIENT / FACTURE_FOURN,
    ''' DocumentId renvoyé par sp_GenererRapportTaxe, T373) ; sinon le texte seul
    ''' (règlement, écriture manuelle).
    ''' </summary>
    Protected Function PieceCell(numero As Object, sourceType As Object, documentId As Object) As String
        Dim num As String = If(numero Is Nothing OrElse IsDBNull(numero), "", Convert.ToString(numero))
        Dim id As Integer = 0
        If documentId IsNot Nothing AndAlso Not IsDBNull(documentId) Then id = Convert.ToInt32(documentId)
        Dim src As String = If(sourceType Is Nothing OrElse IsDBNull(sourceType), "", Convert.ToString(sourceType).ToUpperInvariant())
        If id <= 0 OrElse (src <> "FACTURE_CLIENT" AndAlso src <> "FACTURE_FOURN") Then Return Server.HtmlEncode(num)
        Dim page As String = If(src = "FACTURE_CLIENT", "wbfInvoiceEdit.aspx", "wbfSupplierInvoinceEdit.aspx")
        Dim titre As String = String.Format(L(If(src = "FACTURE_CLIENT", "titreFactClient", "titreFactFourn")), num)
        Return "<button type=""button"" class=""lien-piece"" title=""" & Server.HtmlEncode(L("voirFacture")) & """ onclick=""ouvrirFacture(" & id & ", '" & page & "', " &
               Server.HtmlEncode(System.Web.HttpUtility.JavaScriptStringEncode(titre, True)) & ")"">" & Server.HtmlEncode(num) & "</button>"
    End Function

    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "rubrique" : Return Choose3(lang, "Comptabilité", "Accounting", "Contabilidad")
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
            Case "voirFacture" : Return Choose3(lang, "Afficher la facture", "Show the invoice", "Mostrar la factura")
            Case "echeance" : Return Choose3(lang, "Déclaration et paiement avant le {0}", "Return and payment due by {0}", "Declaración y pago antes del {0}")
            Case "echeanceRetard" : Return Choose3(lang, "en retard", "overdue", "atrasado")
            Case "btnProduite" : Return Choose3(lang, "Marquer comme produite", "Mark as filed", "Marcar como presentada")
            Case "confProduiteRemb" : Return Choose3(lang, "Marquer la déclaration comme produite ? Remboursement à recevoir : {0}. Le rapport sera finalisé et ne changera plus.", "Mark the return as filed? Refund to receive: {0}. The report will be finalized and will no longer change.", "¿Marcar la declaración como presentada? Reembolso por recibir: {0}. El informe quedará finalizado y no cambiará.")
            Case "confProduiteNul" : Return Choose3(lang, "Marquer la déclaration comme produite (solde nul) ? Le rapport sera finalisé et ne changera plus.", "Mark the return as filed (nil balance)? The report will be finalized and will no longer change.", "¿Marcar la declaración como presentada (saldo cero)? El informe quedará finalizado y no cambiará.")
            Case "noteRemb" : Return Choose3(lang, "Rien à remettre : un remboursement de {0} est à réclamer. Produisez quand même la déclaration auprès de Revenu Québec, puis marquez-la produite.", "Nothing to remit: a refund of {0} is to be claimed. File the return with Revenu Québec anyway, then mark it as filed.", "Nada que remitir: hay un reembolso de {0} por reclamar. Presente igualmente la declaración ante Revenu Québec y márquela como presentada.")
            Case "noteNul" : Return Choose3(lang, "Rien à remettre (solde nul). La déclaration doit quand même être produite, puis marquée produite.", "Nothing to remit (nil balance). The return must still be filed, then marked as filed.", "Nada que remitir (saldo cero). La declaración debe presentarse igualmente y marcarse como presentada.")
            Case "notePasFinie" : Return Choose3(lang, "La période n’est pas terminée : le montant peut encore changer.", "The period is not over: the amount may still change.", "El período no ha terminado: el importe aún puede cambiar.")
            Case "msgProduiteOk" : Return Choose3(lang, "Déclaration marquée produite : le rapport est finalisé.", "Return marked as filed: the report is finalized.", "Declaración marcada como presentada: el informe está finalizado.")
            Case "detailFige" : Return Choose3(lang, "Rapport finalisé : ses montants sont figés. Le détail montre les écritures de la période, qui concordent avec ces montants.", "Finalized report: its amounts are frozen. The detail shows the period’s entries, which agree with these amounts.", "Informe finalizado: sus importes están fijados. El detalle muestra los asientos del período, que coinciden con esos importes.")
            Case "detailEcart" : Return Choose3(lang, "Rapport finalisé : ses montants sont figés, mais les écritures de la période ont changé depuis (écart TPS {0}, TVQ {1}). Le détail montre les écritures actuelles.", "Finalized report: its amounts are frozen, but the period’s entries have changed since (GST difference {0}, QST {1}). The detail shows the current entries.", "Informe finalizado: sus importes están fijados, pero los asientos del período han cambiado desde entonces (diferencia TPS {0}, TVQ {1}). El detalle muestra los asientos actuales.")
            Case "titreFactClient" : Return Choose3(lang, "Facture client {0}", "Customer invoice {0}", "Factura de cliente {0}")
            Case "titreFactFourn" : Return Choose3(lang, "Facture fournisseur {0}", "Supplier invoice {0}", "Factura de proveedor {0}")
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

    ''' <summary>
    ''' Le nom de la période, dans l'EXERCICE de la compagnie (T375) : un exercice civil
    ''' s'appelle « 2026 », un exercice décalé « 2026-2027 » ; le trimestre est celui de
    ''' l'exercice (T1 = les trois premiers mois de l'exercice).
    ''' </summary>
    Private Function FormaterLibellePeriode(debut As Date, fin As Date, per As DataRow) As String
        Dim ci = System.Globalization.CultureInfo.GetCultureInfo(PeriodeCulture())
        Dim exDebut As Date = If(per Is Nothing, New Date(debut.Year, 1, 1), CDate(per("ExerciceDebut")))
        Dim exFin As Date = If(per Is Nothing, New Date(debut.Year, 12, 31), CDate(per("ExerciceFin")))
        Dim exercice As String = If(exDebut.Month = 1, exFin.Year.ToString(), exDebut.Year & "-" & exFin.Year)
        Select Case Frequence
            Case "MENSUELLE"
                Return CapitalizeFirst(debut.ToString("MMMM yyyy", ci))
            Case "ANNUELLE"
                Return L("periodeAnnee") & " " & exercice &
                    If(exDebut.Month = 1, "", " (" & exDebut.ToString("dd MMM yyyy", ci) & " — " & exFin.ToString("dd MMM yyyy", ci) & ")")
            Case Else  ' TRIMESTRIELLE
                Dim trim As Integer = If(per Is Nothing, ((debut.Month - 1) \ 3) + 1, Convert.ToInt32(per("NoPeriode")))
                Return L("periodeTrim") & trim & " " & exercice &
                    " (" & debut.ToString("dd MMM", ci) &
                    " — " & fin.ToString("dd MMM yyyy", ci) & ")"
        End Select
    End Function

    ''' <summary>La période de taxes d'une date (s0995 → fPeriodeTaxe) : exercice, n°, date limite.</summary>
    Private Function LirePeriode(d As Date) As DataRow
        Try
            Using cn As New SqlConnection(ConnectionString)
                Using cmd As New SqlCommand("dbo.s0995GetPeriodeTaxe", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                    cmd.Parameters.AddWithValue("@Date", d)
                    Dim dt As New DataTable()
                    Using da As New SqlDataAdapter(cmd)
                        da.Fill(dt)
                    End Using
                    If dt.Rows.Count > 0 Then Return dt.Rows(0)
                End Using
            End Using
        Catch
        End Try
        Return Nothing
    End Function

    ''' <summary>
    ''' « Déclaration et paiement avant le 31 janvier 2027 » sous le nom de la période :
    ''' rouge si la date est passée et que le rapport n'est ni finalisé ni remis.
    ''' </summary>
    Private Function LigneEcheance(per As DataRow, statut As String) As String
        If per Is Nothing OrElse IsDBNull(per("DateLimite")) Then Return ""
        Dim ci = System.Globalization.CultureInfo.GetCultureInfo(PeriodeCulture())
        Dim limite As Date = CDate(per("DateLimite"))
        Dim fait As Boolean = (statut = "PAYE" OrElse statut = "FINALISE")
        Dim retard As Boolean = Not fait AndAlso limite < Date.Today
        Dim txt As String = String.Format(L("echeance"), limite.ToString("d MMMM yyyy", ci)) & If(retard, " — " & L("echeanceRetard"), "")
        Return "<span class=""period-deadline" & If(retard, " retard", If(fait, " fait", "")) & """>" & Server.HtmlEncode(txt) & "</span>"
    End Function

    ''' <summary>Rien à remettre : marquer la déclaration produite (s0994, T375).</summary>
    Protected Sub btnProduite_Click(sender As Object, e As EventArgs)
        If RapportId = 0 Then
            ShowStatus("warning", L("msgAucunRapport"))
            Return
        End If
        Try
            Using cn As New SqlConnection(ConnectionString)
                Using cmd As New SqlCommand("dbo.s0994MarquerRapportTaxeProduit", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                    cmd.Parameters.AddWithValue("@RapportId", RapportId)
                    cmd.Parameters.AddWithValue("@UserId", UserId)
                    cn.Open()
                    cmd.ExecuteNonQuery()
                End Using
            End Using
            ShowStatus("success", L("msgProduiteOk"))
            ChargerRapport()
        Catch ex As Exception
            ShowStatus("danger", ex.Message)
        End Try
    End Sub

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

        ' Période de l'exercice et date limite (fPeriodeTaxe, T375), puis le geste possible
        ' quand il n'y a rien à remettre (remboursement ou solde nul).
        Dim per As DataRow = LirePeriode(DateReference)
        lblPeriode.Text = FormaterLibellePeriode(debut, fin, per) & LigneEcheance(per, statut)
        Dim total As Decimal = Convert.ToDecimal(r("TotalARemettre"))
        Dim terminee As Boolean = fin < Date.Today
        btnProduite.Visible = (statut = "BROUILLON" AndAlso total <= 0D AndAlso terminee)
        btnProduite.Text = L("btnProduite")
        btnProduite.CommandArgument = If(total < 0D, String.Format(L("confProduiteRemb"), FormatMontant(-total)), L("confProduiteNul"))
        Dim note As String = ""
        If statut = "BROUILLON" AndAlso total <= 0D Then
            note = If(total < 0D, String.Format(L("noteRemb"), FormatMontant(-total)), L("noteNul"))
            If Not terminee Then note &= " " & L("notePasFinie")
        End If
        litActionNote.Text = If(note = "", "", "<span class=""action-note"">" & Server.HtmlEncode(note) & "</span>")

        ' Détail : toujours lu par s0993 (T374), même quand le rapport est finalisé ou
        ' remis (sp_GenererRapportTaxe n'en renvoie plus dans ce cas).
        Dim detail As DataTable = LireDetail()
        If detail IsNot Nothing AndAlso detail.Rows.Count > 0 Then
            MarquerGroupes(detail)
            rpDetail.DataSource = detail
            rpDetail.DataBind()
            phDetail.Visible = True
            SetLiteral(Me, "litDetailNote", NoteDetail(statut, r, detail))
        Else
            phDetail.Visible = False
        End If
    End Sub

    ''' <summary>
    ''' Regroupe les lignes d'une même pièce (même date, même numéro, consécutives) :
    ''' colonne RangPiece = nombre de lignes de la pièce sur sa première ligne, 0 sur
    ''' les suivantes. La Date et la Pièce s'affichent une fois (rowspan), le reste
    ''' (libellé, compte, catégorie, débit, crédit) garde une ligne par compte de taxe.
    ''' </summary>
    Private Shared Sub MarquerGroupes(dt As DataTable)
        If Not dt.Columns.Contains("RangPiece") Then dt.Columns.Add("RangPiece", GetType(Integer))
        Dim cle = Function(r As DataRow) Convert.ToString(r("DateEcriture")) & "|" & Convert.ToString(r("NumeroPiece"))
        Dim i As Integer = 0
        While i < dt.Rows.Count
            Dim j As Integer = i + 1
            While j < dt.Rows.Count AndAlso cle(dt.Rows(j)) = cle(dt.Rows(i))
                dt.Rows(j)("RangPiece") = 0
                j += 1
            End While
            dt.Rows(i)("RangPiece") = j - i
            i = j
        End While
    End Sub

    ''' <summary>Les cellules Date et Pièce, seulement sur la première ligne de la pièce.</summary>
    Protected Function CellulesPiece(item As Object) As String
        Dim r As DataRowView = TryCast(item, DataRowView)
        If r Is Nothing Then Return ""
        Dim rang As Integer = If(IsDBNull(r("RangPiece")), 1, Convert.ToInt32(r("RangPiece")))
        If rang = 0 Then Return ""
        Dim span As String = If(rang > 1, " rowspan=""" & rang & """", "")
        Dim dateTxt As String = If(IsDBNull(r("DateEcriture")), "", Convert.ToDateTime(r("DateEcriture")).ToString("yyyy-MM-dd"))
        Return "<td class=""piece-groupe""" & span & ">" & dateTxt & "</td>" &
               "<td class=""piece-groupe""" & span & ">" & PieceCell(r("NumeroPiece"), r("SourceType"), r("DocumentId")) & "</td>"
    End Function

    ''' <summary>La première ligne d'une pièce porte un filet plus marqué.</summary>
    Protected Function ClassePiece(item As Object) As String
        Dim r As DataRowView = TryCast(item, DataRowView)
        If r Is Nothing OrElse IsDBNull(r("RangPiece")) Then Return ""
        Return If(Convert.ToInt32(r("RangPiece")) > 0, "piece-debut", "")
    End Function

    Private Function LireDetail() As DataTable
        Try
            Using cn As New SqlConnection(ConnectionString)
                Using cmd As New SqlCommand("dbo.s0993GetRapportTaxeDetail", cn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                    cmd.Parameters.AddWithValue("@RapportId", RapportId)
                    Dim dt As New DataTable()
                    Using da As New SqlDataAdapter(cmd)
                        da.Fill(dt)
                    End Using
                    Return dt
                End Using
            End Using
        Catch
            Return Nothing
        End Try
    End Function

    ''' <summary>
    ''' Rapport finalisé ou remis : ses montants sont figés. On le dit, et on signale
    ''' quand les écritures actuelles de la période ne donnent plus les mêmes taxes nettes.
    ''' </summary>
    Private Function NoteDetail(statut As String, r As DataRow, detail As DataTable) As String
        If statut <> "FINALISE" AndAlso statut <> "PAYE" Then Return ""
        Dim net = Function(vte As String, ach As String) As Decimal
                      Dim s As Decimal = 0D
                      For Each x As DataRow In detail.Rows
                          Dim d As Decimal = Convert.ToDecimal(x("MontantDebit")), c As Decimal = Convert.ToDecimal(x("MontantCredit"))
                          Select Case Convert.ToString(x("CodeCategorie"))
                              Case vte : s += c - d
                              Case ach : s -= d - c
                          End Select
                      Next
                      Return s
                  End Function
        Dim ecartTps As Decimal = net("TPS_VTE", "TPS_ACH") - Convert.ToDecimal(r("TPS_Nette"))
        Dim ecartTvq As Decimal = net("TVQ_VTE", "TVQ_ACH") - Convert.ToDecimal(r("TVQ_Nette"))
        If Math.Abs(ecartTps) < 0.005D AndAlso Math.Abs(ecartTvq) < 0.005D Then
            Return "<p class=""detail-note"">" & Server.HtmlEncode(L("detailFige")) & "</p>"
        End If
        Return "<p class=""detail-note ecart"">" & Server.HtmlEncode(String.Format(L("detailEcart"), FormatMontant(ecartTps), FormatMontant(ecartTvq))) & "</p>"
    End Function

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
