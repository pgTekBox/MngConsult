Imports System.Data.SqlClient
Imports System.Net.NetworkInformation
Imports System.Runtime.InteropServices
Imports Telerik.Licensing
Imports Telerik.Web.UI



Partial Public Class wbfSettingsOpenAiPrompts
    Inherits clsData



    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
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
        p.Add(New SqlClient.SqlParameter("@Id", promptKey))
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
        p.Add(New SqlClient.SqlParameter("@PromptKey", key))
        p.Add(New SqlClient.SqlParameter("@PromptText", text))
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

    'Private Function GetDefaultStrictInvoicePrompt() As String
    '    Return ""
    '"Tu es un extracteur de données pour factures (fr-CA). Analyse le PDF fourni.

    'OBJECTIF
    'Retourner uniquement un JSON valide (sans markdown, sans commentaire).

    'RÈGLES
    '- JSON uniquement, un seul objet.
    '- Ne pas inventer.
    '- Champs absents: null.
    '- Dates: YYYY-MM-DD.
    '- Montants: nombre décimal sans symbole.
    '- Taxes: [{code,label,rate_percent,amount}]
    '- Pourboire (tip) n’est pas une taxe.
    '- Vérifie cohérence: subtotal + taxes = total (tolérance 0.02); sinon note dans notes[].

    'CHAMPS
    'document_type, language,
    'invoice {number, issue_date, due_date, status, currency},
    'seller {legal_name, trade_name, address{...}, phone, email, tax_numbers{gst_tps,qst_tvq}},
    'buyer {name, address{...}, phone, email},
    'service_location{text},
    'line_items[{description, service_date, quantity, unit_price, line_total}],
    'totals{subtotal, taxes[], total, paid, balance_due},
    'payment_terms{text},
    'notes[].

    'Retourne seulement le JSON final."
    'End Function

    Private Sub ddPromptKey_SelectedIndexChanged(sender As Object, e As DropDownListEventArgs) Handles ddPromptKey.SelectedIndexChanged
        LoadPrompt(ddPromptKey.SelectedValue)
    End Sub
End Class
