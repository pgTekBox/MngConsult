Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Partial Public Class wbfFermetureAnnee
    Inherits clsData

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
            LoadExercices()
        End If
    End Sub

    ' =========================================================
    '  LOCALISATION (fr / en / es)
    ' =========================================================

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal statiques.</summary>
    Private Sub ApplyLocalization()
        ' Titres / textes statiques : siblings des zones mises à jour par RadAjaxManager
        ' → Literal obligatoire (pas de <%= %> sinon « Controls collection cannot be modified »).
        SetLiteral(Me, "litH2Title", L("pageTitle"))
        SetLiteral(Me, "litSubtitle", L("subtitle"))
        SetLiteral(Me, "litH3Step1", L("step1"))
        SetLiteral(Me, "litLblExercice", L("lblExercice"))
        SetLiteral(Me, "litH3Apercu", L("apercu"))
        SetLiteral(Me, "litLblRevenus", L("lblRevenus"))
        SetLiteral(Me, "litLblDepenses", L("lblDepenses"))
        SetLiteral(Me, "litLblBeneficeNet", L("lblBeneficeNet"))
        SetLiteral(Me, "litLblCompteBNR", L("lblCompteBNR"))
        SetLiteral(Me, "litLblBNRAvant", L("lblBNRAvant"))
        SetLiteral(Me, "litLblBNRApres", L("lblBNRApres"))
        SetLiteral(Me, "litLblCompteBNE", L("lblCompteBNE"))
        SetLiteral(Me, "litH3Problemes", L("problemes"))
        SetLiteral(Me, "litH3Ecritures", L("ecritures"))
        SetLiteral(Me, "litThCompte", L("thCompte"))
        SetLiteral(Me, "litThNom", L("thNom"))
        SetLiteral(Me, "litThType", L("thType"))
        SetLiteral(Me, "litThTotD", L("thTotD"))
        SetLiteral(Me, "litThTotC", L("thTotC"))
        SetLiteral(Me, "litThDebitClot", L("thDebitClot"))
        SetLiteral(Me, "litThCreditClot", L("thCreditClot"))

        ' Contrôles serveur
        btnVerifier.Text = L("verify")
        btnFermer.Text = L("btnFermer")
    End Sub

    ''' <summary>Traductions de l'interface Fermeture d'année (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Fermeture d'année fiscale", "Fiscal year-end close", "Cierre de ejercicio fiscal")
            Case "subtitle" : Return Choose3(lang,
                "Clôture des comptes de résultat, affectation du bénéfice net aux Bénéfices non répartis, verrouillage de l'exercice et création automatique de l'exercice suivant.",
                "Closing of income statement accounts, allocation of net income to Retained Earnings, locking of the fiscal year and automatic creation of the next fiscal year.",
                "Cierre de las cuentas de resultados, asignación del beneficio neto a los Beneficios no distribuidos, bloqueo del ejercicio y creación automática del ejercicio siguiente.")
            Case "step1" : Return Choose3(lang, "1. Sélection de l'exercice", "1. Fiscal year selection", "1. Selección del ejercicio")
            Case "lblExercice" : Return Choose3(lang, "Exercice à fermer :", "Fiscal year to close:", "Ejercicio a cerrar:")
            Case "verify" : Return Choose3(lang, "Vérifier", "Verify", "Verificar")
            Case "selectPlaceholder" : Return Choose3(lang, "-- Sélectionner --", "-- Select --", "-- Seleccionar --")
            Case "exercicePrefix" : Return Choose3(lang, "Exercice ", "Fiscal year ", "Ejercicio ")
            Case "apercu" : Return Choose3(lang, "2. Aperçu financier de l'exercice", "2. Financial overview of the fiscal year", "2. Resumen financiero del ejercicio")
            Case "lblRevenus" : Return Choose3(lang, "Total des revenus :", "Total revenue:", "Total de ingresos:")
            Case "lblDepenses" : Return Choose3(lang, "Total des dépenses :", "Total expenses:", "Total de gastos:")
            Case "lblBeneficeNet" : Return Choose3(lang, "Bénéfice net :", "Net income:", "Beneficio neto:")
            Case "lblCompteBNR" : Return Choose3(lang, "Compte BNR :", "Retained earnings account:", "Cuenta de beneficios no distribuidos:")
            Case "lblBNRAvant" : Return Choose3(lang, "Solde BNR avant clôture :", "Retained earnings balance before closing:", "Saldo de beneficios no distribuidos antes del cierre:")
            Case "lblBNRApres" : Return Choose3(lang, "Solde BNR après clôture :", "Retained earnings balance after closing:", "Saldo de beneficios no distribuidos después del cierre:")
            Case "lblCompteBNE" : Return Choose3(lang, "Compte BNE / Journal :", "Net income account / Journal:", "Cuenta de beneficio neto / Diario:")
            Case "problemes" : Return Choose3(lang, "3. Problèmes détectés", "3. Issues detected", "3. Problemas detectados")
            Case "ecritures" : Return Choose3(lang, "4. Écritures de clôture qui seront générées", "4. Closing entries that will be generated", "4. Asientos de cierre que se generarán")
            Case "thCompte" : Return Choose3(lang, "Compte", "Account", "Cuenta")
            Case "thNom" : Return Choose3(lang, "Nom", "Name", "Nombre")
            Case "thType" : Return Choose3(lang, "Type", "Type", "Tipo")
            Case "thTotD" : Return Choose3(lang, "Total D", "Total D", "Total D")
            Case "thTotC" : Return Choose3(lang, "Total C", "Total C", "Total C")
            Case "thDebitClot" : Return Choose3(lang, "Débit clôture", "Closing debit", "Débito cierre")
            Case "thCreditClot" : Return Choose3(lang, "Crédit clôture", "Closing credit", "Crédito cierre")
            Case "btnFermer" : Return Choose3(lang, "Confirmer la fermeture", "Confirm closing", "Confirmar el cierre")
            Case "pillOK" : Return Choose3(lang, "Prêt à fermer", "Ready to close", "Listo para cerrar")
            Case "pillWarning" : Return Choose3(lang, "Avec avertissements", "With warnings", "Con advertencias")
            Case "pillBloque" : Return Choose3(lang, "Fermeture bloquée", "Closing blocked", "Cierre bloqueado")
            Case "hintBloque" : Return Choose3(lang, "Corrigez les problèmes bloquants avant de pouvoir fermer l'exercice.", "Fix the blocking issues before you can close the fiscal year.", "Corrija los problemas bloqueantes antes de poder cerrar el ejercicio.")
            Case "hintWarning" : Return Choose3(lang, "Des avertissements existent. Vérifiez avant de continuer.", "Warnings exist. Review before continuing.", "Existen advertencias. Revise antes de continuar.")
            Case "msgSelectVerify" : Return Choose3(lang, "Veuillez sélectionner un exercice avant de vérifier.", "Please select a fiscal year before verifying.", "Seleccione un ejercicio antes de verificar.")
            Case "msgSelect" : Return Choose3(lang, "Veuillez sélectionner un exercice.", "Please select a fiscal year.", "Seleccione un ejercicio.")
            Case "errVerif" : Return Choose3(lang, "Erreur lors de la vérification : ", "Error during verification: ", "Error durante la verificación: ")
            Case "errFormat" : Return Choose3(lang, "Format de résultat inattendu de sp_VerifierPreCloture.", "Unexpected result format from sp_VerifierPreCloture.", "Formato de resultado inesperado de sp_VerifierPreCloture.")
            Case "errSql" : Return Choose3(lang, "Erreur SQL : ", "SQL error: ", "Error SQL: ")
            Case "errGeneric" : Return Choose3(lang, "Erreur : ", "Error: ", "Error: ")
            Case "successMsg" : Return Choose3(lang,
                "Exercice {0} fermé avec succès. Bénéfice net : {1}. Nouvel exercice {2} créé automatiquement.",
                "Fiscal year {0} closed successfully. Net income: {1}. New fiscal year {2} created automatically.",
                "Ejercicio {0} cerrado con éxito. Beneficio neto: {1}. Nuevo ejercicio {2} creado automáticamente.")
            Case "jsConfirm1" : Return Choose3(lang, "Cette opération est définitive et créera des écritures comptables.", "This operation is final and will create accounting entries.", "Esta operación es definitiva y creará asientos contables.")
            Case "jsConfirm2" : Return Choose3(lang, "L'exercice sélectionné sera FERMÉ et un nouvel exercice OUVERT sera créé automatiquement.", "The selected fiscal year will be CLOSED and a new OPEN fiscal year will be created automatically.", "El ejercicio seleccionado será CERRADO y se creará automáticamente un nuevo ejercicio ABIERTO.")
            Case "jsConfirm3" : Return Choose3(lang, "Voulez-vous continuer ?", "Do you want to continue?", "¿Desea continuar?")
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

    ''' <summary>
    ''' Charge la liste des exercices OUVERTS dans le combobox.
    ''' </summary>
    Private Sub LoadExercices()
        ddlExercice.Items.Clear()
        ddlExercice.Items.Add(New RadComboBoxItem(L("selectPlaceholder"), ""))

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand(
                "SELECT [id], [annee] FROM [dbo].[T111Exercices] " &
                "WHERE [statut] = 'OUVERT' " &
                "  AND ([CompanyGUID] = @cgid OR [CompanyGUID] IS NULL) " &
                "ORDER BY [annee]", cn)
                cmd.Parameters.AddWithValue("@cgid", Company)
                Using rdr = cmd.ExecuteReader()
                    While rdr.Read()
                        Dim it As New RadComboBoxItem(
                            L("exercicePrefix") & rdr("annee").ToString(),
                            rdr("id").ToString())
                        ddlExercice.Items.Add(it)
                    End While
                End Using
            End Using
        End Using

        phPreview.Visible = False
        phStatus.Visible = False
    End Sub

    ' =========================================================
    '  ÉVÉNEMENTS
    ' =========================================================

    Protected Sub ddlExercice_SelectedIndexChanged(sender As Object, e As RadComboBoxSelectedIndexChangedEventArgs)
        ' L'utilisateur change d'exercice → on cache l'aperçu
        phPreview.Visible = False
        phStatus.Visible = False
    End Sub

    Protected Sub btnVerifier_Click(sender As Object, e As EventArgs)
        Dim idStr = ddlExercice.SelectedValue
        If String.IsNullOrEmpty(idStr) Then
            ShowStatus("warning", L("msgSelectVerify"))
            Return
        End If

        Try
            VerifierExercice(Convert.ToInt32(idStr))
        Catch ex As Exception
            ShowStatus("danger", L("errVerif") & ex.Message)
        End Try
    End Sub

    Protected Sub btnFermer_Click(sender As Object, e As EventArgs)
        Dim idStr = ddlExercice.SelectedValue
        If String.IsNullOrEmpty(idStr) Then
            ShowStatus("warning", L("msgSelect"))
            Return
        End If

        Dim exerciceId = Convert.ToInt32(idStr)

        Try
            Dim result = FermerExercice(exerciceId)

            ShowStatus("success",
                String.Format(L("successMsg"),
                    result("AnneeFermee").ToString(),
                    FormatMontant(Convert.ToDecimal(result("BeneficeNet"))),
                    result("NouvelAnnee").ToString()))

            ' Recharger la liste pour enlever l'exercice fermé
            LoadExercices()

        Catch sqlex As SqlException
            ShowStatus("danger", L("errSql") & sqlex.Message)
        Catch ex As Exception
            ShowStatus("danger", L("errGeneric") & ex.Message)
        End Try
    End Sub

    ' =========================================================
    '  APPELS SQL
    ' =========================================================

    Private Sub VerifierExercice(exerciceId As Integer)
        Dim dsResult As New DataSet()

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.sp_VerifierPreCloture", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@ExerciceId", exerciceId)

                Using da As New SqlDataAdapter(cmd)
                    da.Fill(dsResult)
                End Using
            End Using
        End Using

        ' DataSet attendu : 3 tables
        '   [0] Problèmes
        '   [1] Aperçu (1 ligne)
        '   [2] Détail écritures
        If dsResult.Tables.Count < 2 Then
            ShowStatus("danger", L("errFormat"))
            Return
        End If

        Dim dtProb = dsResult.Tables(0)
        Dim dtPrev = dsResult.Tables(1)
        Dim dtEcr As DataTable = If(dsResult.Tables.Count >= 3, dsResult.Tables(2), Nothing)

        ' ─── Aperçu financier ───
        If dtPrev.Rows.Count > 0 Then
            Dim r = dtPrev.Rows(0)
            litRevenus.Text = FormatMontant(Convert.ToDecimal(r("TotalRevenus")))
            litDepenses.Text = FormatMontant(Convert.ToDecimal(r("TotalDepenses")))

            Dim ben = Convert.ToDecimal(r("BeneficeNet"))
            litBeneficeNet.Text = "<span class='" &
                If(ben >= 0, "positive", "negative") & "'>" &
                FormatMontant(ben) & "</span>"

            litCompteBNR.Text = If(Convert.IsDBNull(r("CompteBNR")), "—", r("CompteBNR").ToString())
            litCompteBNE.Text = If(Convert.IsDBNull(r("CompteBNE")), "—", r("CompteBNE").ToString())
            litJournal.Text = If(Convert.IsDBNull(r("CodeJournal")), "—", r("CodeJournal").ToString())
            litBNRAvant.Text = FormatMontant(Convert.ToDecimal(r("BNRAvant")))
            litBNRApres.Text = FormatMontant(Convert.ToDecimal(r("BNRApres")))

            Dim statut = r("StatutPreCloture").ToString()
            Dim pillClass = ""
            Dim pillText = ""
            Select Case statut
                Case "OK"
                    pillClass = "ok" : pillText = L("pillOK")
                Case "WARNING"
                    pillClass = "warning" : pillText = L("pillWarning")
                Case "BLOQUE"
                    pillClass = "bloque" : pillText = L("pillBloque")
            End Select
            litStatutPill.Text = "<span class='status-pill " & pillClass & "'>" & pillText & "</span>"

            ' Activer/désactiver le bouton de fermeture
            btnFermer.Enabled = (statut <> "BLOQUE")
            If statut = "BLOQUE" Then
                litFermeHint.Text = "<span style='color:#dc2626;font-size:13px;'>" &
                    L("hintBloque") & "</span>"
            ElseIf statut = "WARNING" Then
                litFermeHint.Text = "<span style='color:#92400e;font-size:13px;'>" &
                    L("hintWarning") & "</span>"
            Else
                litFermeHint.Text = ""
            End If
        End If

        ' ─── Problèmes ───
        If dtProb.Rows.Count > 0 Then
            rpProblemes.DataSource = dtProb
            rpProblemes.DataBind()
            phProblemes.Visible = True
        Else
            phProblemes.Visible = False
        End If

        ' ─── Détail écritures ───
        If dtEcr IsNot Nothing AndAlso dtEcr.Rows.Count > 0 Then
            rpEcritures.DataSource = dtEcr
            rpEcritures.DataBind()
            phEcritures.Visible = True
        Else
            phEcritures.Visible = False
        End If

        phPreview.Visible = True
    End Sub

    Private Function FermerExercice(exerciceId As Integer) As Dictionary(Of String, Object)
        Dim out As New Dictionary(Of String, Object)

        Using cn As New SqlConnection(ConnectionString)
            cn.Open()
            Using cmd As New SqlCommand("dbo.sp_FermerExerciceFiscal", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = 120 ' 2 min pour les gros exercices
                cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                cmd.Parameters.AddWithValue("@ExerciceId", exerciceId)
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
    '  HELPERS
    ' =========================================================

    Private Function FormatMontant(m As Decimal) As String
        Return m.ToString("N2", System.Globalization.CultureInfo.GetCultureInfo("fr-CA")) & " $"
    End Function

    Private Sub ShowStatus(level As String, message As String)
        ' level : success / warning / danger / info
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
