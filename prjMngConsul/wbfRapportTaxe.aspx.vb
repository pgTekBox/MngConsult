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
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            DateReference = Date.Today
            dpDatePaiement.SelectedDate = Date.Today
            LoadFrequence()
            ChargerRapport()
        End If
    End Sub

    Private Sub LoadFrequence()
        Dim freq = LireParametre("TAX_FREQ", "TRIMESTRIELLE")
        Frequence = freq

        Dim libelleFreq As String
        Select Case freq
            Case "MENSUELLE" : libelleFreq = "mensuelle"
            Case "ANNUELLE" : libelleFreq = "annuelle"
            Case Else : libelleFreq = "trimestrielle"
        End Select
        litFreqInfo.Text = "Fréquence configurée : <strong>" & libelleFreq & "</strong>."
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
        ShowStatus("success", "Rapport recalculé.")
    End Sub

    Protected Sub btnRemettre_Click(sender As Object, e As EventArgs)
        ' La modale s'ouvre via JavaScript, pas besoin d'action serveur ici
    End Sub

    Protected Sub btnConfirmerRemise_Click(sender As Object, e As EventArgs)
        If RapportId = 0 Then
            ShowStatus("warning", "Aucun rapport sélectionné.")
            Return
        End If

        Dim datePaie = If(dpDatePaiement.SelectedDate.HasValue, dpDatePaiement.SelectedDate.Value, Date.Today)
        Dim ref = If(String.IsNullOrWhiteSpace(txtReference.Text), Nothing, txtReference.Text.Trim())

        Try
            Dim res = MarquerCommeRemis(RapportId, datePaie, ref)
            ShowStatus("success",
                "Remise effectuée. TPS : " & FormatMontant(Convert.ToDecimal(res("TPS_Remise"))) &
                " — TVQ : " & FormatMontant(Convert.ToDecimal(res("TVQ_Remise"))) &
                " — Total : " & FormatMontant(Convert.ToDecimal(res("TotalRemis"))))
            ChargerRapport()
        Catch ex As Exception
            ShowStatus("danger", "Erreur lors de la remise : " & ex.Message)
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
        Dim ci = System.Globalization.CultureInfo.GetCultureInfo("fr-CA")
        Select Case Frequence
            Case "MENSUELLE"
                Return CapitalizeFirst(debut.ToString("MMMM yyyy", ci))
            Case "ANNUELLE"
                Return "Année " & debut.Year.ToString()
            Case Else  ' TRIMESTRIELLE
                Dim trim As Integer = ((debut.Month - 1) \ 3) + 1
                Return "T" & trim & " " & debut.Year.ToString() &
                    " (" & debut.ToString("dd MMM", ci) &
                    " — " & fin.ToString("dd MMM yyyy", ci) & ")"
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
            lblPeriode.Text = "Aucune donnée"
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
            Case "BROUILLON" : pillText = "Brouillon"
            Case "FINALISE" : pillText = "Finalisé"
            Case "PAYE" : pillText = "Remis"
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
