Imports System.IO

Public Class SiteMaster
    Inherits MasterPage

    ''' <summary>Le lien vers la feuille de l'assistant (versionné par la date du fichier : le navigateur ne garde pas une vieille copie).</summary>
    Protected WithEvents lnkAssistantCss As HtmlLink
    ''' <summary>L'assistant flottant ; visible seulement pour une session ouverte avec une compagnie.</summary>
    Protected WithEvents divAssistant As HtmlGenericControl

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        Dim css As String = Server.MapPath("~/css/assistant.css")
        Dim version As String = If(File.Exists(css), File.GetLastWriteTimeUtc(css).Ticks.ToString(), "1")
        lnkAssistantCss.Href = ResolveUrl("~/css/assistant.css") & "?v=" & version

        ' L'assistant n'apparaît que pour une session ouverte avec une compagnie active.
        Dim userId As Integer = 0
        Dim company As Guid = Guid.Empty
        Try
            If Session("UserId") IsNot Nothing Then userId = Convert.ToInt32(Session("UserId"))
            If Session("Company") IsNot Nothing Then company = CType(Session("Company"), Guid)
        Catch
        End Try
        divAssistant.Visible = userId <> 0 AndAlso company <> Guid.Empty
        If Not divAssistant.Visible Then Return

        Dim lang As String = If(Request.QueryString("lang"), "").Trim().ToLowerInvariant()
        If lang <> "fr" AndAlso lang <> "en" AndAlso lang <> "es" Then lang = TryCast(Session("Lang"), String)
        If lang <> "en" AndAlso lang <> "es" Then lang = "fr"

        divAssistant.Attributes("data-url") = ResolveUrl("~/AssistantIA.ashx")
        divAssistant.Attributes("data-page") = ResolveUrl("~/wbfAssistant.aspx")
        divAssistant.Attributes("data-lang") = lang
        divAssistant.Attributes("data-section") = clsAide.SectionPourPage(Page.AppRelativeVirtualPath)
    End Sub
End Class
