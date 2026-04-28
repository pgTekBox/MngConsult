Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI

Partial Public Class wbfFermetureAnnee
    Inherits clsData

    ' =========================================================
    '  PAGE LIFECYCLE
    ' =========================================================

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            LoadExercices()
        End If
    End Sub

    ''' <summary>
    ''' Charge la liste des exercices OUVERTS dans le combobox.
    ''' </summary>
    Private Sub LoadExercices()
        ddlExercice.Items.Clear()
        ddlExercice.Items.Add(New RadComboBoxItem("-- Sélectionner --", ""))

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
                            "Exercice " & rdr("annee").ToString(),
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
            ShowStatus("warning", "Veuillez sélectionner un exercice avant de vérifier.")
            Return
        End If

        Try
            VerifierExercice(Convert.ToInt32(idStr))
        Catch ex As Exception
            ShowStatus("danger", "Erreur lors de la vérification : " & ex.Message)
        End Try
    End Sub

    Protected Sub btnFermer_Click(sender As Object, e As EventArgs)
        Dim idStr = ddlExercice.SelectedValue
        If String.IsNullOrEmpty(idStr) Then
            ShowStatus("warning", "Veuillez sélectionner un exercice.")
            Return
        End If

        Dim exerciceId = Convert.ToInt32(idStr)

        Try
            Dim result = FermerExercice(exerciceId)

            ShowStatus("success",
                "Exercice " & result("AnneeFermee").ToString() & " fermé avec succès." &
                " Bénéfice net : " & FormatMontant(Convert.ToDecimal(result("BeneficeNet"))) & "." &
                " Nouvel exercice " & result("NouvelAnnee").ToString() & " créé automatiquement.")

            ' Recharger la liste pour enlever l'exercice fermé
            LoadExercices()

        Catch sqlex As SqlException
            ShowStatus("danger", "Erreur SQL : " & sqlex.Message)
        Catch ex As Exception
            ShowStatus("danger", "Erreur : " & ex.Message)
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
            ShowStatus("danger", "Format de résultat inattendu de sp_VerifierPreCloture.")
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
                    pillClass = "ok" : pillText = "Prêt à fermer"
                Case "WARNING"
                    pillClass = "warning" : pillText = "Avec avertissements"
                Case "BLOQUE"
                    pillClass = "bloque" : pillText = "Fermeture bloquée"
            End Select
            litStatutPill.Text = "<span class='status-pill " & pillClass & "'>" & pillText & "</span>"

            ' Activer/désactiver le bouton de fermeture
            btnFermer.Enabled = (statut <> "BLOQUE")
            If statut = "BLOQUE" Then
                litFermeHint.Text = "<span style='color:#dc2626;font-size:13px;'>" &
                    "Corrigez les problèmes bloquants avant de pouvoir fermer l'exercice.</span>"
            ElseIf statut = "WARNING" Then
                litFermeHint.Text = "<span style='color:#92400e;font-size:13px;'>" &
                    "Des avertissements existent. Vérifiez avant de continuer.</span>"
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
