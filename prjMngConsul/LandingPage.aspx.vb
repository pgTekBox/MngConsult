Imports System
Imports System.Data
Imports System.Text
Imports System.Web.UI

Partial Public Class LandingPage
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            BindPlans()
        End If
    End Sub

    ''' <summary>
    ''' Charge les forfaits actifs depuis T021Plan et les bind au Repeater.
    ''' </summary>
    Private Sub BindPlans()
        Try
            Dim ds As DataSet = ExecuteSQLds("s0630GetPlansForLanding")
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                rptPlans.DataSource = ds.Tables(0)
                rptPlans.DataBind()
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("LandingPage BindPlans error: " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Rend la cartouche complète d'un forfait dans le style de la nouvelle
    ''' LandingPage (Tailwind). Le thème (slate / sky recommandé / emerald) est
    ''' déterminé à partir des colonnes IsRecommended et PlanIconCssClass.
    ''' Le bouton pointe vers l'inscription : wbfRegister.aspx?ab=&lt;Code&gt;.
    ''' </summary>
    Public Function RenderPlanCard(item As Object) As String
        Dim row As DataRowView = TryCast(item, DataRowView)
        If row Is Nothing Then Return ""

        Dim code As String = GetStr(row, "Code")
        Dim name As String = GetStr(row, "Name")
        Dim tagline As String = GetStr(row, "Tagline")
        Dim empRange As String = GetStr(row, "EmployeeRange")
        Dim descr As String = GetStr(row, "Description")
        Dim badge As String = GetStr(row, "BadgeText")
        Dim iconClass As String = GetStr(row, "PlanIconCssClass")
        Dim recommended As Boolean = GetBool(row, "IsRecommended")
        Dim price As String = FormatPrice(row("Amount"))

        Dim cardCls, iconWrap, iconName, nameCls, tagCls, pillCls As String
        Dim descCls, priceCls, permoCls, featCheck, featText, btnCls As String

        If recommended Then
            cardCls = "relative flex flex-col rounded-2xl border-2 bg-slate-950 border-sky-500/40 p-7 transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-slate-900/40"
            iconWrap = "bg-sky-500/20 text-sky-300"
            iconName = "user-check"
            nameCls = "text-white"
            tagCls = "text-sky-300"
            pillCls = "bg-sky-500/20 text-sky-300"
            descCls = "text-slate-300"
            priceCls = "text-white"
            permoCls = "text-slate-400"
            featCheck = "text-sky-400"
            featText = "text-slate-300"
            btnCls = "w-full text-center font-semibold py-3 px-5 rounded-xl text-sm transition-all duration-200 bg-sky-500 hover:bg-sky-400 text-white hover:shadow-lg hover:shadow-sky-500/30"
        ElseIf iconClass.IndexOf("emerald", StringComparison.OrdinalIgnoreCase) >= 0 Then
            cardCls = "relative flex flex-col rounded-2xl border-2 bg-slate-50 border-emerald-200 p-7 transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-slate-200/80"
            iconWrap = "bg-emerald-100 text-emerald-700"
            iconName = "users"
            nameCls = "text-slate-950"
            tagCls = "text-slate-500"
            pillCls = "bg-emerald-100 text-emerald-700"
            descCls = "text-slate-500"
            priceCls = "text-slate-950"
            permoCls = "text-slate-500"
            featCheck = "text-emerald-600"
            featText = "text-slate-600"
            btnCls = "w-full text-center font-semibold py-3 px-5 rounded-xl text-sm transition-all duration-200 bg-slate-950 hover:bg-slate-800 text-white"
        Else
            cardCls = "relative flex flex-col rounded-2xl border-2 bg-slate-50 border-slate-200 p-7 transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-slate-200/80"
            iconWrap = "bg-slate-200 text-slate-700"
            iconName = "user"
            nameCls = "text-slate-950"
            tagCls = "text-slate-500"
            pillCls = "bg-slate-100 text-slate-600"
            descCls = "text-slate-500"
            priceCls = "text-slate-950"
            permoCls = "text-slate-500"
            featCheck = "text-slate-600"
            featText = "text-slate-600"
            btnCls = "w-full text-center font-semibold py-3 px-5 rounded-xl text-sm transition-all duration-200 bg-slate-950 hover:bg-slate-800 text-white"
        End If

        Dim sb As New StringBuilder()
        sb.Append("<div class=""" & cardCls & """>")

        If badge.Length > 0 Then
            sb.Append("<div class=""absolute -top-3.5 left-1/2 -translate-x-1/2""><span class=""bg-sky-500 text-white text-xs font-bold px-4 py-1.5 rounded-full shadow-lg shadow-sky-500/30 whitespace-nowrap"">")
            sb.Append(Server.HtmlEncode(badge))
            sb.Append("</span></div>")
        End If

        sb.Append("<div class=""mb-6"">")
        sb.Append("<div class=""w-12 h-12 rounded-xl flex items-center justify-center mb-5 " & iconWrap & """><i data-lucide=""" & iconName & """ class=""w-6 h-6""></i></div>")
        sb.Append("<h3 class=""text-xl font-bold mb-1 " & nameCls & """>" & Server.HtmlEncode(name) & "</h3>")
        If tagline.Length > 0 Then
            sb.Append("<p class=""text-sm font-semibold mb-1 " & tagCls & """>" & Server.HtmlEncode(tagline) & "</p>")
        End If
        If empRange.Length > 0 Then
            sb.Append("<span class=""inline-block text-xs font-medium px-2.5 py-1 rounded-full mb-4 " & pillCls & """>" & Server.HtmlEncode(empRange) & "</span>")
        End If
        If descr.Length > 0 Then
            sb.Append("<p class=""text-sm leading-relaxed " & descCls & """>" & Server.HtmlEncode(descr) & "</p>")
        End If
        sb.Append("</div>")

        sb.Append("<div class=""mb-6""><div class=""flex items-baseline gap-1""><span class=""text-3xl font-bold " & priceCls & """>" & Server.HtmlEncode(price) & "</span><span class=""text-sm font-medium " & permoCls & """>/ mois</span></div></div>")

        sb.Append("<ul class=""space-y-3 mb-8 flex-1"">")
        sb.Append(BuildFeatures(row("Features"), featCheck, featText))
        sb.Append("</ul>")

        Dim url As String = "wbfRegister.aspx?ab=" & Server.UrlEncode(code)
        sb.Append("<a href=""" & url & """ class=""" & btnCls & """>Commencer gratuitement</a>")

        sb.Append("</div>")
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Convertit le texte multi-ligne de la colonne Features en HTML &lt;li&gt; avec
    ''' icône check (lucide). Une ligne = une fonctionnalité.
    ''' </summary>
    Private Function BuildFeatures(featuresValue As Object, checkCls As String, textCls As String) As String
        If featuresValue Is Nothing OrElse IsDBNull(featuresValue) Then Return ""
        Dim featuresText As String = featuresValue.ToString()
        If String.IsNullOrWhiteSpace(featuresText) Then Return ""

        Dim sb As New StringBuilder()
        Dim lines() As String = featuresText.Split(New String() {vbCrLf, vbLf, vbCr}, StringSplitOptions.RemoveEmptyEntries)
        For Each line As String In lines
            Dim cleanLine As String = line.Trim()
            If cleanLine.Length > 0 Then
                sb.Append("<li class=""flex items-start gap-3""><i data-lucide=""check"" class=""w-4 h-4 mt-0.5 flex-shrink-0 " & checkCls & """></i><span class=""text-sm " & textCls & """>" & Server.HtmlEncode(cleanLine) & "</span></li>")
            End If
        Next
        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Formate un montant en devise québécoise (séparateur virgule, espace milliers).
    ''' Exemple : 69.99 -> "69,99 $"
    ''' </summary>
    Public Function FormatPrice(amount As Object) As String
        If amount Is Nothing OrElse IsDBNull(amount) Then Return ""
        Dim val As Decimal = CDec(amount)
        Return val.ToString("N2", New Globalization.CultureInfo("fr-CA")) & " $"
    End Function

    Private Shared Function GetStr(row As DataRowView, col As String) As String
        Dim v As Object = row(col)
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Return v.ToString().Trim()
    End Function

    Private Shared Function GetBool(row As DataRowView, col As String) As Boolean
        Dim v As Object = row(col)
        If v Is Nothing OrElse IsDBNull(v) Then Return False
        Return Convert.ToBoolean(v)
    End Function

End Class
