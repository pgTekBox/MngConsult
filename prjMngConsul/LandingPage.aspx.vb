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
    ''' Formate un montant en devise québécoise (séparateur virgule, espace milliers).
    ''' Exemple : 69.99 -> "69,99 $"
    ''' </summary>
    Public Function FormatPrice(amount As Object) As String
        If amount Is Nothing OrElse IsDBNull(amount) Then Return ""
        Dim val As Decimal = CDec(amount)
        Return val.ToString("N2", New Globalization.CultureInfo("fr-CA")) & " $"
    End Function

    ''' <summary>
    ''' Si BadgeText n'est pas vide, retourne le HTML du badge "Le plus populaire".
    ''' Sinon retourne une chaîne vide.
    ''' </summary>
    Public Function RenderBadge(badgeText As Object) As String
        If badgeText Is Nothing OrElse IsDBNull(badgeText) Then Return ""
        Dim text As String = badgeText.ToString().Trim()
        If String.IsNullOrEmpty(text) Then Return ""
        Return "<div class=""plan-badge-popular"">" & Server.HtmlEncode(text) & "</div>"
    End Function

    ''' <summary>
    ''' Convertit le texte multi-ligne de la colonne Features en HTML &lt;li&gt; avec
    ''' icône check SVG. Une ligne = une fonctionnalité.
    ''' </summary>
    Public Function RenderFeatures(featuresValue As Object) As String
        If featuresValue Is Nothing OrElse IsDBNull(featuresValue) Then Return ""
        Dim featuresText As String = featuresValue.ToString()
        If String.IsNullOrWhiteSpace(featuresText) Then Return ""

        Dim sb As New StringBuilder()
        Dim lines() As String = featuresText.Split(New String() {vbCrLf, vbLf, vbCr}, StringSplitOptions.RemoveEmptyEntries)
        For Each line As String In lines
            Dim cleanLine As String = line.Trim()
            If cleanLine.Length > 0 Then
                sb.Append("<li class=""plan-feature"">")
                sb.Append("<svg xmlns=""http://www.w3.org/2000/svg"" viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""2"" stroke-linecap=""round"" stroke-linejoin=""round""><path d=""M20 6 9 17l-5-5""></path></svg>")
                sb.Append("<span>")
                sb.Append(Server.HtmlEncode(cleanLine))
                sb.Append("</span>")
                sb.Append("</li>")
            End If
        Next
        Return sb.ToString()
    End Function

    Protected Sub lnkConnexion_Click(sender As Object, e As EventArgs) Handles lnkConnexion.Click
        ' Redirection vers la page de connexion
        Response.Redirect("wbfLogin.aspx")
    End Sub

    Protected Sub btnDemarrer_Click(sender As Object, e As EventArgs) Handles btnDemarrer.Click
        ' Redirection vers l'inscription depuis le CTA
        Response.Redirect("Inscription.aspx")
    End Sub

End Class
