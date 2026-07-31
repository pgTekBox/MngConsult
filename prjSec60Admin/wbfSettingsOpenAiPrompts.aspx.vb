Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI


''' <summary>
''' Édition des prompts OpenAI (console d'administration).
''' Déplacée depuis prjMngConsul. Accès réservé aux administrateurs de la console :
''' la garde d'authentification globale de clsData (OnLoad) redirige vers wbfLogin.aspx.
''' Procédures partagées : s0031GetOpenAPISetting, s0029GetOpenAIPrompt, s0030SaveOpenAIPrompt.
''' </summary>
Partial Public Class wbfSettingsOpenAiPrompts
    Inherits clsData



    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            SetDDL(ddPromptKey, "ParamName", "Id", "s0031GetOpenAPISetting")
            LoadFirstPrompt()
        End If
    End Sub



    Private Sub LoadFirstPrompt()
        If ddPromptKey.Items.Count = 0 Then
            ClearEditor()
            ShowErr("Aucun prompt. Clique Nouveau.")
            Return
        End If
        LoadPrompt(ddPromptKey.SelectedValue)
    End Sub



    Private Sub LoadPrompt(promptKey As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", promptKey))
        Dim ds As DataSet = ExecuteSQLds("s0029GetOpenAIPrompt", p)
        tbPromptText.Text = ds.Tables(0).Rows(0)("PromptText").ToString()
        tbKey.Text = ds.Tables(0).Rows(0)("Name").ToString()
    End Sub

    Private Sub ClearEditor()
        tbKey.Text = ""
        tbPromptText.Text = ""
        tbModel.Text = "gpt-4.1-mini"
    End Sub



    Protected Sub btnLoadDefault_Click(sender As Object, e As EventArgs)
        ShowOk("Prompt défaut chargé.")
    End Sub

    Protected Sub btnReload_Click(sender As Object, e As EventArgs)
        LoadFirstPrompt()
        ShowOk("Rechargé.")
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Dim key = tbKey.Text.Trim()
        Dim text = tbPromptText.Text
        Dim model = tbModel.Text.Trim()

        If String.IsNullOrWhiteSpace(text) Then
            ShowErr("Le texte du prompt est requis.")
            Return
        End If

        Dim p As New Collection
        p.Add(New SqlParameter("@PromptKey", key))
        p.Add(New SqlParameter("@PromptText", text))
        Dim ds As DataSet = ExecuteSQLds("s0030SaveOpenAIPrompt", p)

        ShowOk("Enregistré.")
    End Sub



    Private Sub ShowOk(msg As String)
        phStatus.Visible = True
        litStatus.Text = "<span class=""status-ok"">✔ " & Server.HtmlEncode(msg) & "</span>"
    End Sub

    Private Sub ShowErr(msg As String)
        phStatus.Visible = True
        litStatus.Text = "<span class=""status-err"">✖ " & Server.HtmlEncode(msg) & "</span>"
    End Sub

    Private Sub ddPromptKey_SelectedIndexChanged(sender As Object, e As DropDownListEventArgs) Handles ddPromptKey.SelectedIndexChanged
        LoadPrompt(ddPromptKey.SelectedValue)
    End Sub
End Class
