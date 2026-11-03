Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Console d'admin → « Demandes à Claude » : la liste des demandes de modification
''' composées dans l'ERP (bouton flottant, table T026ClaudePrompt). Filtre
''' Nouvelles / Toutes / Faites (s0964). Un bouton marque une demande « faite »
''' (ou la rouvre) via s0965.
''' </summary>
Public Class wbfClaudePrompts
    Inherits clsData

    Protected WithEvents lnkNouveau As System.Web.UI.WebControls.HyperLink
    Protected WithEvents lnkTous As System.Web.UI.WebControls.HyperLink
    Protected WithEvents lnkFait As System.Web.UI.WebControls.HyperLink
    Protected WithEvents rptDemandes As System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlVide As System.Web.UI.WebControls.Panel

    ''' <summary>Filtre courant (?f=nouveau|tous|fait), lu de façon robuste : on passe
    ''' par HttpContext.Current (Me.Request peut être Nothing selon le cycle de vie).</summary>
    Private ReadOnly Property Filtre As String
        Get
            Dim f As String = ""
            Try
                Dim ctx As System.Web.HttpContext = System.Web.HttpContext.Current
                If ctx IsNot Nothing AndAlso ctx.Request IsNot Nothing Then
                    ' ⚠ Request.QueryString(name) renvoie Nothing si absent, et
                    ' Convert.ToString(String) laisse passer Nothing → .Trim() planterait.
                    f = If(ctx.Request.QueryString("f"), "")
                End If
            Catch
            End Try
            f = f.Trim().ToLowerInvariant()
            If f <> "tous" AndAlso f <> "fait" Then f = "nouveau"
            Return f
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            MajFiltres()
            Charger()
        End If
    End Sub

    Private Sub MajFiltres()
        lnkNouveau.CssClass = If(Filtre = "nouveau", "on", "")
        lnkTous.CssClass = If(Filtre = "tous", "on", "")
        lnkFait.CssClass = If(Filtre = "fait", "on", "")
    End Sub

    Private Sub Charger()
        Dim p As New Collection
        p.Add(New SqlParameter("@Filtre", Filtre))
        Dim ds As DataSet = ExecuteSQLds("s0964ListClaudePrompts", p)
        Dim dt As DataTable = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
        rptDemandes.DataSource = dt
        rptDemandes.DataBind()
        pnlVide.Visible = (dt.Rows.Count = 0)
    End Sub

    Protected Sub rptDemandes_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName <> "Done" AndAlso e.CommandName <> "Reopen" Then Return
        Dim id As Integer
        If Not Integer.TryParse(Convert.ToString(e.CommandArgument), id) Then Return

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            p.Add(New SqlParameter("@DoneBy", If(AdminEmail = "", "sec60admin", AdminEmail)))
            p.Add(New SqlParameter("@Done", If(e.CommandName = "Done", 1, 0)))
            ExecuteSQLds("s0965SetClaudePromptDone", p)
        Catch
        End Try

        ' PRG : on recharge en conservant le filtre courant.
        Response.Redirect("wbfClaudePrompts.aspx?f=" & Filtre)
    End Sub

    ' ---- Aides d'affichage (appelées depuis le balisage) ----

    Protected Function FormatDate(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Try
            Return Convert.ToDateTime(o).ToLocalTime().ToString("dd/MM/yyyy HH:mm")
        Catch
            Return ""
        End Try
    End Function

    Protected Function Qui(email As Object, dossier As Object) As String
        Dim e As String = If(email Is Nothing OrElse IsDBNull(email), "", Convert.ToString(email))
        Dim d As String = If(dossier Is Nothing OrElse IsDBNull(dossier), "", Convert.ToString(dossier))
        Dim s As String = If(e = "", "Usager inconnu", e)
        If d <> "" Then s &= " · " & d
        Return s
    End Function

    Protected Function LienUrl(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Dim u As String = Convert.ToString(o).Trim()
        If u = "" Then Return ""
        Dim enc As String = Server.HtmlEncode(u)
        Return "<a href=""" & enc & """ target=""_blank"" rel=""noopener"">ouvrir la page</a>"
    End Function

    ''' <summary>Lien de téléchargement du fichier joint (si la demande en a un).</summary>
    Protected Function LienFichier(id As Object, nom As Object, taille As Object) As String
        If nom Is Nothing OrElse IsDBNull(nom) Then Return ""
        Dim n As String = Convert.ToString(nom).Trim()
        If n = "" Then Return ""
        Dim i As Integer = 0
        Integer.TryParse(Convert.ToString(id), i)
        If i <= 0 Then Return ""
        Dim libelle As String = Server.HtmlEncode(n)
        Dim ko As String = ""
        Dim t As Long = 0
        If taille IsNot Nothing AndAlso Not IsDBNull(taille) AndAlso Long.TryParse(Convert.ToString(taille), t) AndAlso t > 0 Then
            ko = If(t >= 1048576, " (" & (t \ 1048576) & " Mo)", " (" & Math.Max(1L, t \ 1024) & " Ko)")
        End If
        Return "&#128206; <a href=""ClaudePromptFichier.ashx?id=" & i & """ target=""_blank"" rel=""noopener"">" & libelle & "</a>" & Server.HtmlEncode(ko)
    End Function

    Protected Function InfoFait(statut As Object, doneBy As Object, doneUtc As Object) As String
        If Convert.ToString(statut) <> "fait" Then Return ""
        Dim who As String = If(doneBy Is Nothing OrElse IsDBNull(doneBy), "", Convert.ToString(doneBy))
        Dim quand As String = FormatDate(doneUtc)
        Dim s As String = "Fait"
        If who <> "" Then s &= " par " & Server.HtmlEncode(who)
        If quand <> "" Then s &= " le " & quand
        Return "<span>" & s & "</span>"
    End Function

End Class
