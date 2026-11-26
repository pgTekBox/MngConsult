''' <summary>
''' La page d'accueil publique de 60secondes (septembre 2026) : la page HTML
''' livrée par le marketing, découpée en balisage (ici), css/landing2.css et
''' js/landing2-1..7.js. Presque tout est côté client (trois langues, démonstrations,
''' calculateur). Le serveur versionne les fichiers liés pour que le navigateur
''' ne garde pas une vieille copie, et met les prix des forfaits à jour (voir
''' LirePrixForfaits). Deux autres branchements réels :
''' « Se connecter » ouvre wbfLogin.aspx en fenêtre par-dessus la page, et « Réserver ma place » enregistre
''' la demande par LandingReservation.ashx.
''' L'ancienne page (contenu en base, page Application mobile) reste servie par
''' LandingPageV1.aspx.
''' </summary>
Partial Public Class LandingPage
    Inherits clsData

    ''' <summary>
    ''' Prix écrits dans la page (profils ta, c0, c4), dans le dictionnaire de
    ''' traduction (landing2-6.js) et dans js/landing2-prix.js. Ils sont remplacés
    ''' au rendu par ceux de la base ; ne pas les changer ici sans changer le texte.
    ''' </summary>
    Private Shared ReadOnly PrixDansLaPage As Decimal() = {79.99D, 99.99D, 149.99D}

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' rien : la page est statique ; version des fichiers et prix se calculent au rendu.
    End Sub

    ''' <summary>Jeton de version des fichiers css/js (date du plus récent), remplacé dans le balisage.</summary>
    Protected ReadOnly Property VersionFichiers As String
        Get
            Dim plusRecent As Long = 1
            For Each f As String In New String() {"~/css/landing2.css", "~/js/landing2-prix.js", "~/js/landing2-1.js", "~/js/landing2-2.js", "~/js/landing2-3.js", "~/js/landing2-4.js", "~/js/landing2-5.js", "~/js/landing2-6.js", "~/js/landing2-7.js"}
                Dim p As String = Server.MapPath(f)
                If IO.File.Exists(p) Then plusRecent = Math.Max(plusRecent, IO.File.GetLastWriteTimeUtc(p).Ticks)
            Next
            Return plusRecent.ToString()
        End Get
    End Property

    ''' <summary>
    ''' Prix mensuels des trois profils, lus dans T021Plan (s0630 : forfaits actifs,
    ''' mensuels, triés par « Ordre d'affichage »). Le 1er forfait donne le prix du
    ''' profil 1 (travailleur autonome), le 2e celui du profil 2 (société sans
    ''' employé), le 3e celui du profil 3 (société avec employés). Un profil sans
    ''' forfait, ou une base injoignable, garde le prix écrit dans la page.
    ''' </summary>
    Private Function LirePrixForfaits() As Decimal()
        Dim prix As Decimal() = CType(PrixDansLaPage.Clone(), Decimal())
        Try
            Dim pp As New Collection
            pp.Add(New System.Data.SqlClient.SqlParameter("@Lang", "fr"))
            Dim ds As System.Data.DataSet = ExecuteSQLds("s0630GetPlansForLanding", pp)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                Dim i As Integer = 0
                For Each r As System.Data.DataRow In ds.Tables(0).Rows
                    If i >= prix.Length Then Exit For
                    If r("Amount") IsNot DBNull.Value AndAlso CDec(r("Amount")) > 0D Then prix(i) = Math.Round(CDec(r("Amount")), 2)
                    i += 1
                Next
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("LandingPage LirePrixForfaits : " & ex.Message)
        End Try
        Return prix
    End Function

    ''' <summary>79.99 → « 79,99 » (format de la page française).</summary>
    Private Shared Function FormaterPrixFr(montant As Decimal) As String
        Return montant.ToString("0.00", Globalization.CultureInfo.InvariantCulture).Replace(".", ",")
    End Function

    ''' <summary>
    ''' Remplace, en un seul passage, chaque prix écrit dans la page par le prix de
    ''' la base (« 79,99 » → « 69,99 »), puis pose les prix pour les scripts (%%PRIX%%).
    ''' </summary>
    Private Shared Function AppliquerPrix(html As String, prix As Decimal()) As String
        Dim remplacements As New Dictionary(Of String, String)
        For i As Integer = 0 To PrixDansLaPage.Length - 1
            remplacements(FormaterPrixFr(PrixDansLaPage(i))) = FormaterPrixFr(prix(i))
        Next
        Dim motif As String = "(?<![\d.,])(" & String.Join("|", remplacements.Keys.Select(Function(k) Regex.Escape(k))) & ")(?!\d)"
        html = Regex.Replace(html, motif, Function(m) remplacements(m.Value))
        Dim inv = Globalization.CultureInfo.InvariantCulture
        Dim json As String = String.Format(inv, "{{""ta"":{0},""c0"":{1},""c4"":{2}}}",
                                           prix(0).ToString("0.00", inv), prix(1).ToString("0.00", inv), prix(2).ToString("0.00", inv))
        Return html.Replace("%%PRIX%%", json)
    End Function

    Protected Overrides Sub Render(writer As HtmlTextWriter)
        Dim tampon As New IO.StringWriter()
        MyBase.Render(New HtmlTextWriter(tampon))
        Dim html As String = tampon.ToString().Replace("%%V%%", VersionFichiers)
        writer.Write(AppliquerPrix(html, LirePrixForfaits()))
    End Sub

End Class
