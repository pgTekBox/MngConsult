Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Console d'admin → « Journal Apideck » : chaque appel de l'ERP à Apideck,
''' inscrit par clsApideck (ERP) dans T027ApideckLog (script T399).
''' Résumé de la période (s1022), liste filtrée (s1021 : période, erreurs
''' seulement, recherche), détail repliable par appel (erreur, extraits de la
''' requête et de la réponse), purge des entrées de plus de 90 jours (s1023).
''' </summary>
Public Class wbfApideckLog
    Inherits clsData

    Protected WithEvents litMessage As System.Web.UI.WebControls.Literal
    Protected WithEvents lnkJ1 As System.Web.UI.WebControls.HyperLink
    Protected WithEvents lnkJ7 As System.Web.UI.WebControls.HyperLink
    Protected WithEvents lnkJ30 As System.Web.UI.WebControls.HyperLink
    Protected WithEvents lnkJ90 As System.Web.UI.WebControls.HyperLink
    Protected WithEvents lnkTous As System.Web.UI.WebControls.HyperLink
    Protected WithEvents lnkErreurs As System.Web.UI.WebControls.HyperLink
    Protected WithEvents txtRecherche As System.Web.UI.WebControls.TextBox
    Protected WithEvents btnChercher As System.Web.UI.WebControls.Button
    Protected WithEvents litAppels As System.Web.UI.WebControls.Literal
    Protected WithEvents litErreurs As System.Web.UI.WebControls.Literal
    Protected WithEvents litTaux As System.Web.UI.WebControls.Literal
    Protected WithEvents litDuree As System.Web.UI.WebControls.Literal
    Protected WithEvents litCies As System.Web.UI.WebControls.Literal
    Protected WithEvents litDernier As System.Web.UI.WebControls.Literal
    Protected WithEvents litDerniereErreur As System.Web.UI.WebControls.Literal
    Protected WithEvents litCodes As System.Web.UI.WebControls.Literal
    Protected WithEvents rptLog As System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlVide As System.Web.UI.WebControls.Panel
    Protected WithEvents litPied As System.Web.UI.WebControls.Literal
    Protected WithEvents btnPurger As System.Web.UI.WebControls.Button

    Private Const LIMITE As Integer = 300

#Region "Filtres (lus dans l'adresse)"

    Private Function Q(nom As String) As String
        Try
            Dim ctx As System.Web.HttpContext = System.Web.HttpContext.Current
            If ctx IsNot Nothing AndAlso ctx.Request IsNot Nothing Then Return If(ctx.Request.QueryString(nom), "").Trim()
        Catch
        End Try
        Return ""
    End Function

    Private ReadOnly Property Jours As Integer
        Get
            Dim j As Integer
            If Integer.TryParse(Q("j"), j) AndAlso (j = 1 OrElse j = 7 OrElse j = 30 OrElse j = 90) Then Return j
            Return 7
        End Get
    End Property

    Private ReadOnly Property Filtre As String
        Get
            Return If(Q("f").ToLowerInvariant() = "erreurs", "erreurs", "tous")
        End Get
    End Property

    Private ReadOnly Property Recherche As String
        Get
            Return Q("q")
        End Get
    End Property

    Private Function Adresse(j As Integer, f As String, q As String) As String
        Dim u As String = "wbfApideckLog.aspx?j=" & j & "&f=" & f
        If q <> "" Then u &= "&q=" & Server.UrlEncode(q)
        Return u
    End Function

#End Region

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        lnkJ1.NavigateUrl = Adresse(1, Filtre, Recherche) : lnkJ1.CssClass = If(Jours = 1, "on", "")
        lnkJ7.NavigateUrl = Adresse(7, Filtre, Recherche) : lnkJ7.CssClass = If(Jours = 7, "on", "")
        lnkJ30.NavigateUrl = Adresse(30, Filtre, Recherche) : lnkJ30.CssClass = If(Jours = 30, "on", "")
        lnkJ90.NavigateUrl = Adresse(90, Filtre, Recherche) : lnkJ90.CssClass = If(Jours = 90, "on", "")
        lnkTous.NavigateUrl = Adresse(Jours, "tous", Recherche) : lnkTous.CssClass = If(Filtre = "tous", "on", "")
        lnkErreurs.NavigateUrl = Adresse(Jours, "erreurs", Recherche) : lnkErreurs.CssClass = If(Filtre = "erreurs", "on", "")
        txtRecherche.Text = Recherche

        If Q("purge") <> "" Then
            litMessage.Text = "<div class=""al-msg"">" & Server.HtmlEncode(Q("purge")) & " entrée(s) de plus de 90 jours effacée(s).</div>"
        End If

        ChargerResume()
        ChargerListe()
    End Sub

    Private Sub ChargerResume()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Jours", Jours))
            Dim ds As DataSet = ExecuteSQLds("s1022GetApideckLogResume", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return
            Dim r As DataRow = ds.Tables(0).Rows(0)
            Dim appels As Integer = Entier(r("Appels"))
            Dim erreurs As Integer = Entier(r("Erreurs"))
            litAppels.Text = appels.ToString("N0")
            litErreurs.Text = erreurs.ToString("N0")
            litTaux.Text = If(appels > 0, (erreurs * 100.0 / appels).ToString("0.#") & " % des appels", "")
            litDuree.Text = If(IsDBNull(r("DureeMoyenneMs")), "—", Duree(r("DureeMoyenneMs")))
            litCies.Text = Entier(r("Compagnies")).ToString()
            litDernier.Text = If(IsDBNull(r("DernierAppel")), "—", FormatDate(r("DernierAppel")))
            litDerniereErreur.Text = If(IsDBNull(r("DerniereErreur")), "aucune", FormatDate(r("DerniereErreur")))
            litPied.Text = Entier(r("TotalJournal")).ToString("N0") & " entrée(s) au journal, toutes périodes. "

            If ds.Tables.Count > 1 AndAlso ds.Tables(1).Rows.Count > 0 Then
                Dim sb As New Text.StringBuilder("Par statut :")
                For Each c As DataRow In ds.Tables(1).Rows
                    sb.Append(" ").Append(Statut(c("StatutHttp"), Entier(c("StatutHttp")) >= 200 AndAlso Entier(c("StatutHttp")) < 300)).Append(" ").Append(Entier(c("Appels")))
                Next
                litCodes.Text = sb.ToString()
            End If
        Catch ex As Exception
            litMessage.Text = "<div class=""al-msg"" style=""background:#FDE8E8;color:#A3261C"">Journal illisible : " & Server.HtmlEncode(ex.Message) & "</div>"
        End Try
    End Sub

    Private Sub ChargerListe()
        Dim dt As New DataTable()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Filtre", Filtre))
            p.Add(New SqlParameter("@Jours", Jours))
            p.Add(New SqlParameter("@Recherche", If(Recherche = "", CObj(DBNull.Value), Recherche)))
            p.Add(New SqlParameter("@Top", LIMITE))
            Dim ds As DataSet = ExecuteSQLds("s1021ListApideckLog", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then dt = ds.Tables(0)
        Catch
        End Try
        rptLog.DataSource = dt
        rptLog.DataBind()
        rptLog.Visible = dt.Rows.Count > 0
        pnlVide.Visible = dt.Rows.Count = 0
        If dt.Rows.Count >= LIMITE Then litPied.Text &= "Seuls les " & LIMITE & " appels les plus récents sont affichés : précisez la recherche. "
    End Sub

    Protected Sub btnChercher_Click(sender As Object, e As EventArgs) Handles btnChercher.Click
        Response.Redirect(Adresse(Jours, Filtre, txtRecherche.Text.Trim()))
    End Sub

    Protected Sub btnPurger_Click(sender As Object, e As EventArgs) Handles btnPurger.Click
        Dim n As Integer = 0
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Jours", 90))
            Dim ds As DataSet = ExecuteSQLds("s1023PurgerApideckLog", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then n = Entier(ds.Tables(0).Rows(0)("Effacees"))
        Catch
        End Try
        Response.Redirect(Adresse(Jours, Filtre, Recherche) & "&purge=" & n)
    End Sub

    ' ---- Aides d'affichage (appelées depuis le balisage) ----

    Private Shared Function Entier(o As Object) As Integer
        If o Is Nothing OrElse IsDBNull(o) Then Return 0
        Dim i As Integer
        Integer.TryParse(Convert.ToString(o), i)
        Return i
    End Function

    Protected Function FormatDate(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Try
            Return DateTime.SpecifyKind(Convert.ToDateTime(o), DateTimeKind.Utc).ToLocalTime().ToString("dd/MM/yyyy HH:mm:ss")
        Catch
            Return ""
        End Try
    End Function

    Protected Function Statut(code As Object, succes As Object) As String
        Dim c As Integer = Entier(code)
        Dim ok As Boolean = False
        If succes IsNot Nothing AndAlso Not IsDBNull(succes) Then ok = Convert.ToBoolean(succes)
        Dim cls As String = If(c = 0, "zero", If(ok, "ok", "err"))
        Return "<span class=""st " & cls & """ title=""" & If(c = 0, "Pas de réponse (délai, réseau ou configuration)", "HTTP " & c) & """>" & If(c = 0, "—", c.ToString()) & "</span>"
    End Function

    Protected Function Duree(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Dim ms As Long
        Long.TryParse(Convert.ToString(o), ms)
        Return If(ms >= 1000, (ms / 1000.0).ToString("0.0") & " s", ms & " ms")
    End Function

    Protected Function Taille(o As Object) As String
        Dim t As Integer = Entier(o)
        If t <= 0 Then Return "vide"
        Return If(t >= 1024, (t \ 1024) & " Ko", t & " o")
    End Function

    Protected Function Texte(o As Object, defaut As String) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return defaut
        Dim s As String = Convert.ToString(o).Trim()
        Return If(s = "", defaut, s)
    End Function

    Protected Function Qui(email As Object, page As Object) As String
        Dim e As String = Texte(email, "")
        Dim p As String = Texte(page, "")
        If e = "" AndAlso p = "" Then Return "—"
        If e = "" Then Return p
        If p = "" Then Return e
        Return e & " · " & p
    End Function

    ''' <summary>Un bloc du détail (titre + texte préformaté), absent si le texte est vide.</summary>
    Protected Function Bloc(titre As String, o As Object, estErreur As Boolean) As String
        Dim s As String = Texte(o, "")
        If s = "" Then Return ""
        Return "<div><h4>" & Server.HtmlEncode(titre) & "</h4><pre" & If(estErreur, " class=""erreur""", "") & ">" & Server.HtmlEncode(s) & "</pre></div>"
    End Function

End Class
