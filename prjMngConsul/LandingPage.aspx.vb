''' <summary>
''' La page d'accueil publique de 60secondes (septembre 2026) : la page HTML
''' livrée par le marketing, découpée en balisage (ici), css/landing2.css et
''' js/landing2-1..5.js. Tout est côté client (trois langues, démonstrations,
''' calculateur) ; le serveur ne fait que versionner les fichiers liés pour
''' que le navigateur ne garde pas une vieille copie. Deux branchements réels :
''' « Se connecter » mène à wbfLogin.aspx, et « Réserver ma place » enregistre
''' la demande par LandingReservation.ashx.
''' L'ancienne page (contenu en base, page Application mobile) reste servie par
''' LandingPageV1.aspx.
''' </summary>
Partial Public Class LandingPage
    Inherits clsData

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' rien : la page est statique ; la version des fichiers se calcule au rendu.
    End Sub

    ''' <summary>Jeton de version des fichiers css/js (date du plus récent), remplacé dans le balisage.</summary>
    Protected ReadOnly Property VersionFichiers As String
        Get
            Dim plusRecent As Long = 1
            For Each f As String In New String() {"~/css/landing2.css", "~/js/landing2-1.js", "~/js/landing2-2.js", "~/js/landing2-3.js", "~/js/landing2-4.js", "~/js/landing2-5.js"}
                Dim p As String = Server.MapPath(f)
                If IO.File.Exists(p) Then plusRecent = Math.Max(plusRecent, IO.File.GetLastWriteTimeUtc(p).Ticks)
            Next
            Return plusRecent.ToString()
        End Get
    End Property

    Protected Overrides Sub Render(writer As HtmlTextWriter)
        Dim tampon As New IO.StringWriter()
        MyBase.Render(New HtmlTextWriter(tampon))
        writer.Write(tampon.ToString().Replace("%%V%%", VersionFichiers))
    End Sub

End Class
