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
        End If
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
