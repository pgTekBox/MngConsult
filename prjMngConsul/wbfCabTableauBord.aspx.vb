Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Tableau de bord du « Portail comptable » : l'écran d'accueil du cabinet quand
''' le comptable choisit « Portail comptable » dans le sélecteur de l'en-tête.
''' Montre l'échelle du cabinet, des compteurs (dossiers, membres, équipes) via
''' s0921, et un aperçu des dossiers (compagnies clientes) via s0920. Réservé aux
''' comptables (IsAccountant) ; sinon redirection vers Default.aspx.
''' </summary>
Public Class wbfCabTableauBord
    Inherits clsData

    Protected WithEvents litTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litEchelle As System.Web.UI.WebControls.Literal
    Protected WithEvents litKpis As System.Web.UI.WebControls.Literal
    Protected WithEvents litDossiersTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litDossiers As System.Web.UI.WebControls.Literal
    Protected WithEvents litPlus As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        ' On est dans l'espace du cabinet : le menu de gauche doit être celui du portail,
        ' même si la page est atteinte par une URL directe.
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        If Not IsPostBack Then Charger()
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Sub Charger()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))

        ' --- KPIs + rôle ---
        Dim role As String = ""
        Dim nbDossiers As Integer = 0, nbAMoi As Integer = 0, nbMembres As Integer = 0
        Try
            Dim ds As DataSet = ExecuteSQLds("s0921GetCabinetKpis", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                role = Convert.ToString(r("Role")).Trim().ToLowerInvariant()
                nbDossiers = Convert.ToInt32(r("NbDossiers"))
                nbAMoi = Convert.ToInt32(r("NbDossiersAMoi"))
                nbMembres = Convert.ToInt32(r("NbMembres"))
            End If
        Catch
        End Try

        litTitre.Text = Server.HtmlEncode(T("Tableau de bord du cabinet", "Firm dashboard", "Panel del despacho"))
        litSous.Text = Server.HtmlEncode(T("Votre espace de cabinet : vos dossiers et votre organisation.",
                                           "Your firm workspace: your files and your organization.",
                                           "Su espacio de despacho: sus expedientes y su organización."))
        litEchelle.Text = "<span class=""cab-echelle"">" & Server.HtmlEncode(EchelleLab(role)) & "</span>"

        ' --- Tuiles ---
        Dim sbK As New StringBuilder()
        sbK.Append(Tuile(nbDossiers, T("Dossiers", "Files", "Expedientes")))
        sbK.Append(Tuile(nbAMoi, T("Dossiers suivis par moi", "Files I handle", "Expedientes a mi cargo")))
        sbK.Append(Tuile(nbMembres, T("Membres du cabinet", "Firm members", "Miembros del despacho")))
        litKpis.Text = sbK.ToString()

        ' --- Aperçu des dossiers ---
        litDossiersTitre.Text = Server.HtmlEncode(T("Vos dossiers", "Your files", "Sus expedientes"))
        RendreDossiers()
    End Sub

    Private Function Tuile(n As Integer, libelle As String) As String
        Return "<div class=""kpi""><div class=""n"">" & n.ToString() & "</div><div class=""l"">" & Server.HtmlEncode(libelle) & "</div></div>"
    End Function

    Private Function EchelleLab(role As String) As String
        If role = "solo" Then Return T("Cabinet solo", "Solo firm", "Despacho individual")
        Return T("Cabinet", "Firm", "Despacho")
    End Function

    Private Sub RendreDossiers()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))

        Dim sb As New StringBuilder()
        Dim total As Integer = 0
        Try
            Dim ds As DataSet = ExecuteSQLds("s0920ListCabinetDossiers", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                total = ds.Tables(0).Rows.Count
                Dim n As Integer = 0
                For Each r As DataRow In ds.Tables(0).Rows
                    If n >= 8 Then Exit For   ' aperçu : les 8 premiers
                    sb.Append(LigneDossier(r))
                    n += 1
                Next
            End If
        Catch
        End Try

        If total = 0 Then
            litDossiers.Text = "<div class=""doss-vide"">" &
                Server.HtmlEncode(T("Aucun dossier pour l'instant.", "No files yet.", "Aún no hay expedientes.")) & "</div>"
            litPlus.Text = ""
        Else
            litDossiers.Text = sb.ToString()
            litPlus.Text = "<a class=""doss-plus"" href=""" & ResolveUrl("~/wbfCabDossiers.aspx") & """>" &
                Server.HtmlEncode(T("Voir tous les dossiers", "See all files", "Ver todos los expedientes")) & " →</a>"
        End If
    End Sub

    Private Function LigneDossier(r As DataRow) As String
        Dim guid As String = Convert.ToString(r("CompanyGUID"))
        Dim nom As String = Convert.ToString(r("Name"))
        Dim code As String = Convert.ToString(r("CompanyCode"))
        Dim href As String = ResolveUrl("~/wbfCabDossiers.aspx?enter=" & Server.UrlEncode(guid))
        Return "<a class=""doss-row"" href=""" & href & """>" &
               "<span class=""doss-av"">" & Server.HtmlEncode(Initiales(nom)) & "</span>" &
               "<span class=""nom"">" & Server.HtmlEncode(nom) & "</span>" &
               "<span class=""code"">" & Server.HtmlEncode(code) & "</span></a>"
    End Function

    Private Shared Function Initiales(nom As String) As String
        Dim sb As New StringBuilder()
        For Each mot As String In If(nom, "").Split(New Char() {" "c, "-"c}, StringSplitOptions.RemoveEmptyEntries)
            If Char.IsLetter(mot(0)) Then sb.Append(Char.ToUpperInvariant(mot(0)))
            If sb.Length = 2 Then Exit For
        Next
        Return sb.ToString()
    End Function

End Class
