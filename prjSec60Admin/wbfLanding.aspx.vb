Imports System.Data
Imports System.Data.SqlClient

Public Class wbfLanding
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            LoadPages()
            LoadSections()
            LoadContent()
        End If
    End Sub

    Protected Sub ddlPage_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlPage.SelectedIndexChanged
        LoadSections()
        LoadContent()
    End Sub

    Protected Sub ddlSection_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlSection.SelectedIndexChanged
        LoadContent()
    End Sub

    Protected Sub ddlLang_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlLang.SelectedIndexChanged
        LoadContent()
    End Sub

    ''' <summary>Remplit la liste des pages.</summary>
    Private Sub LoadPages()
        Dim ds As DataSet = ExecuteSQLds("s0675GetLandingPages")
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            ddlPage.DataSource = ds.Tables(0)
            ddlPage.DataBind()
        End If
    End Sub

    ''' <summary>Remplit la liste des sections de la page sélectionnée.</summary>
    Private Sub LoadSections()
        ddlSection.Items.Clear()
        If ddlPage.SelectedValue = "" Then Return

        Dim p As New Collection
        p.Add(New SqlParameter("@PageCode", ddlPage.SelectedValue))
        Dim ds As DataSet = ExecuteSQLds("s0676GetLandingSectionsForPage", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            ddlSection.DataSource = ds.Tables(0)
            ddlSection.DataBind()
        End If
    End Sub

    ''' <summary>Charge le HTML de la section/langue courante (vide si non traduit).</summary>
    Private Sub LoadContent()
        txtHtml.Text = ""
        If ddlPage.SelectedValue = "" OrElse ddlSection.SelectedValue = "" Then Return

        Dim p As New Collection
        p.Add(New SqlParameter("@PageCode", ddlPage.SelectedValue))
        p.Add(New SqlParameter("@SectionCode", ddlSection.SelectedValue))
        p.Add(New SqlParameter("@Lang", ddlLang.SelectedValue))
        Dim ds As DataSet = ExecuteSQLds("s0677GetLandingSectionContent", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
            Dim v As Object = ds.Tables(0).Rows(0)("HtmlContent")
            txtHtml.Text = If(v Is Nothing OrElse v Is DBNull.Value, "", v.ToString())
        End If
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        If ddlPage.SelectedValue = "" OrElse ddlSection.SelectedValue = "" Then
            ShowMsg("Sélectionnez une page et une section.", isError:=True)
            Return
        End If

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@PageCode", ddlPage.SelectedValue))
            p.Add(New SqlParameter("@SectionCode", ddlSection.SelectedValue))
            p.Add(New SqlParameter("@Lang", ddlLang.SelectedValue))
            p.Add(New SqlParameter("@HtmlContent", If(String.IsNullOrEmpty(txtHtml.Text), CObj(DBNull.Value), CObj(txtHtml.Text))))
            ExecuteSQL("s0678UpsertLandingSectionContent", p)
            ShowMsg("Contenu enregistré (" & ddlPage.SelectedValue & " / " & ddlSection.SelectedValue & " / " & ddlLang.SelectedValue & ").")
        Catch ex As Exception
            ShowMsg("Erreur : " & ex.Message, isError:=True)
        End Try
    End Sub

    Private Sub ShowMsg(text As String, Optional isError As Boolean = False)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "lp-msg " & If(isError, "bad", "ok")
    End Sub

End Class
