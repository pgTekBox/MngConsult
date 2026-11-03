Imports System.IO

Public Class SiteMaster
    Inherits MasterPage

    ''' <summary>Le lien vers la feuille de l'assistant (versionné par la date du fichier : le navigateur ne garde pas une vieille copie).</summary>
    Protected WithEvents lnkAssistantCss As HtmlLink
    ''' <summary>L'assistant flottant ; visible seulement pour une session ouverte avec une compagnie.</summary>
    Protected WithEvents divAssistant As HtmlGenericControl
    ''' <summary>Le bouton flottant « Demande à Claude » ; visible sur toute page authentifiée.</summary>
    Protected WithEvents divClaudePrompt As HtmlGenericControl

    ''' <summary>
    ''' Vrai quand la page pose elle-même ses boîtes sur le fond (le tableau de bord) :
    ''' le cadre blanc du corps s'efface, comme dans le gabarit « Doux bleu marine ».
    ''' </summary>
    Public Property FondDePage As Boolean

    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As EventArgs) Handles Me.PreRender
        If FondDePage AndAlso Not divMain.Attributes("class").Contains("mc-fond") Then
            divMain.Attributes("class") &= " mc-fond"
        End If
    End Sub

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

        ' Bouton flottant « Demande à Claude » : sur TOUTE page authentifiée
        ' (indépendant de la compagnie, contrairement à l'assistant). Posé avant le
        ' Return ci-dessous, sinon il manquerait sur les pages sans compagnie (portail).
        divClaudePrompt.Visible = userId <> 0
        If divClaudePrompt.Visible Then
            ' Nom du fichier .aspx ; FriendlyUrls retire l'extension du chemin d'exécution,
            ' on la remet pour afficher « wbfX.aspx » plutôt que « wbfX ».
            Dim pg As String = IO.Path.GetFileName(Request.AppRelativeCurrentExecutionFilePath)
            If pg <> "" AndAlso IO.Path.GetExtension(pg) = "" Then pg &= ".aspx"
            divClaudePrompt.Attributes("data-url") = ResolveUrl("~/ClaudePrompt.ashx")
            divClaudePrompt.Attributes("data-page") = pg
        End If

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
