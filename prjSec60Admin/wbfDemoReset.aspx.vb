Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.UI.WebControls

''' <summary>
''' Console d'administration : réinitialisation / recapture des compagnies de
''' démonstration (liste blanche dbo.fnDemoCompanies) à partir du cliché DEMO_*.
''' Un sélecteur choisit LA démo ciblée ; son GUID est passé aux procs
''' dbo.s0708ResetDemoCompany / dbo.s0709SnapshotDemoCompany, qui refusent toute
''' compagnie hors liste blanche.
''' </summary>
Public Class wbfDemoReset
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            SetDDL(ddlDemo, "Name", "CompanyGUID", "s0711GetDemoCompanies")
            RemplirCompagnies()
        End If
    End Sub

    ''' <summary>
    ''' Toutes les compagnies (s0653GetCompaniesList, sans filtre), sauf la
    ''' compagnie modèle : la remise à zéro s'adresse à une démo OU une vraie compagnie.
    ''' </summary>
    Private Sub RemplirCompagnies()
        Dim p As New Collection
        p.Add(New SqlParameter("@Search", ""))
        Dim ds As DataSet = ExecuteSQLds("s0653GetCompaniesList", p)
        ddlCie.Items.Clear()
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return
        For Each r As DataRow In ds.Tables(0).Rows
            Dim g As String = r("CompanyGUID").ToString().ToUpper()
            If g = "00000000-0000-0000-0000-000000000001" Then Continue For
            Dim nom As String = If(IsDBNull(r("Name")), "", r("Name").ToString())
            If nom.Length = 0 Then nom = If(IsDBNull(r("LegalName")), g, r("LegalName").ToString())
            ddlCie.Items.Add(New ListItem(nom, g))
        Next
    End Sub

    ''' <summary>
    ''' Remise à zéro de la comptabilité de la compagnie choisie : la proc
    ''' s0863ResetCompanyAccounting efface les données vivantes et garde la
    ''' configuration (plan comptable, journaux, exercices, taxes, paramètres,
    ''' utilisateurs, employés). Double confirmation : le confirm() du bouton et
    ''' le mot ZERO tapé dans la case.
    ''' </summary>
    Protected Sub btnZero_Click(sender As Object, e As EventArgs) Handles btnZero.Click
        If Not String.Equals(txtConfirmZero.Text.Trim(), "ZERO", StringComparison.OrdinalIgnoreCase) Then
            Show(pnlMsgZero, litMsgZero, "err", "✖ Tapez ZERO dans la case pour confirmer la remise à zéro.")
            Return
        End If
        If String.IsNullOrEmpty(ddlCie.SelectedValue) Then
            Show(pnlMsgZero, litMsgZero, "err", "✖ Choisissez une compagnie.")
            Return
        End If
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", New Guid(ddlCie.SelectedValue)))
            p.Add(New SqlParameter("@ModifiedBy", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0863ResetCompanyAccounting", p)

            ' La proc rend plusieurs jeux (dont ceux de s0790ViderStaging) : on cherche celui qui porte « Message ».
            Dim msg As String = "Comptabilité remise à zéro."
            If ds IsNot Nothing Then
                For Each t As DataTable In ds.Tables
                    If t.Columns.Contains("Message") AndAlso t.Rows.Count > 0 Then msg = t.Rows(0)("Message").ToString()
                Next
            End If
            txtConfirmZero.Text = ""
            Show(pnlMsgZero, litMsgZero, "ok", "✔ " & ddlCie.SelectedItem.Text & " : " & msg)
        Catch ex As Exception
            Show(pnlMsgZero, litMsgZero, "err", "✖ Échec de la remise à zéro : " & ex.Message)
        End Try
    End Sub

    ''' <summary>GUID de la démo sélectionnée dans la liste déroulante.</summary>
    Private Function SelectedDemoParams() As Collection
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", New Guid(ddlDemo.SelectedValue)))
        Return p
    End Function

    Protected Sub btnReset_Click(sender As Object, e As EventArgs) Handles btnReset.Click
        Try
            Dim ds As DataSet = ExecuteSQLds("s0708ResetDemoCompany", SelectedDemoParams())

            Dim msg As String = "Démo réinitialisée avec succès."
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 _
               AndAlso ds.Tables(0).Columns.Contains("Message") Then
                msg = ds.Tables(0).Rows(0)("Message").ToString()
            End If

            Show(pnlMsg, litMsg, "ok", "✔ " & ddlDemo.SelectedItem.Text & " : " & msg)
        Catch ex As Exception
            Show(pnlMsg, litMsg, "err", "✖ Échec de la réinitialisation : " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Recapture le cliché de référence de la démo sélectionnée : (re)crée sa
    ''' portion des tables DEMO_* à partir de son état actuel.
    ''' Appelle dbo.s0709SnapshotDemoCompany @CompanyGUID.
    ''' </summary>
    Protected Sub btnSnapshot_Click(sender As Object, e As EventArgs) Handles btnSnapshot.Click
        Try
            Dim ds As DataSet = ExecuteSQLds("s0709SnapshotDemoCompany", SelectedDemoParams())

            Dim msg As String = "Cliché de référence recapturé avec succès."
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 _
               AndAlso ds.Tables(0).Columns.Contains("Message") Then
                msg = ds.Tables(0).Rows(0)("Message").ToString()
            End If

            Show(pnlMsgSnap, litMsgSnap, "ok", "✔ " & ddlDemo.SelectedItem.Text & " : " & msg)
        Catch ex As Exception
            Show(pnlMsgSnap, litMsgSnap, "err", "✖ Échec de la recapture : " & ex.Message)
        End Try
    End Sub

    Private Sub Show(pnl As Panel, lit As Literal, kind As String, text As String)
        pnl.Visible = True
        lit.Text = "<div class=""demo-msg " & kind & """>" & Server.HtmlEncode(text) & "</div>"
    End Sub

End Class
