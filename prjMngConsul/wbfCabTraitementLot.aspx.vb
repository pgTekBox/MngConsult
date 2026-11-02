Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web.Script.Serialization

''' <summary>
''' « Traitement en lot » du Portail comptable : faire la même action pour
''' plusieurs clients d'un seul geste (ou une à la fois), regroupée par activité,
''' client, urgence ou échéance, avec exclusion ligne par ligne et confirmation.
''' Calqué sur la maquette d'Yves.
'''
''' Source réelle des actions : les **tâches réelles** des dossiers
''' (T339DossierTache, proc s0956GetJourneeTaches — la même que « Ma journée »),
''' scopées au périmètre du cabinet, en gardant celles qui ne sont pas « fait ».
''' Grouper « par activité » revient à grouper les dossiers qui ont la même tâche.
''' Lancer (le lot ou une ligne) marque les tâches « fait » via s0944SetStatutTache,
''' par un POST léger (op=done, ids=…) traité en tête de Page_Load, et inscrit au
''' journal du dossier. L'annulation (10 s) les remet « à faire » (op=undo).
'''
''' Si le cabinet n'a aucune tâche à faire, un **repli illustratif** affiche le jeu
''' de démonstration (un bandeau le signale). Réservé aux comptables (IsAccountant).
''' </summary>
Public Class wbfCabTraitementLot
    Inherits clsData

    Protected WithEvents litData As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        ' Actions réelles « Lancer » / « Annuler » : POST léger, traité avant tout
        ' rendu, réponse JSON. Un vrai postback ASP.NET n'a pas « op ».
        If String.Equals(Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase) Then
            Dim op As String = Convert.ToString(Request.Form("op"))
            If op = "done" OrElse op = "undo" Then
                TraiterLot(op)
                Return
            End If
        End If

        If Not IsPostBack Then Charger()
    End Sub

    ''' <summary>Marque les tâches « fait » (op=done) ou les remet « à faire » (op=undo).</summary>
    Private Sub TraiterLot(op As String)
        Dim statut As String = If(op = "undo", "afaire", "fait")
        Dim n As Integer = 0
        For Each raw As String In Convert.ToString(Request.Form("ids")).Split(","c)
            Dim id As Integer
            If Integer.TryParse(raw.Trim(), id) Then
                Try
                    Dim p As New Collection
                    p.Add(New SqlParameter("@UserId", UserEmail))
                    p.Add(New SqlParameter("@Id", id))
                    p.Add(New SqlParameter("@Statut", statut))
                    Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
                    p.Add(outErr)
                    ExecuteSQL("s0944SetStatutTache", p)
                    If Not (outErr.Value Is Nothing OrElse IsDBNull(outErr.Value)) AndAlso CInt(outErr.Value) = 0 Then n += 1
                Catch
                End Try
            End If
        Next
        Response.Clear()
        Response.ContentType = "application/json"
        Response.Write("{""ok"":true,""n"":" & n & "}")
        Response.End()
    End Sub

    ' ---- Hachage déterministe (FNV-1a) pour le secteur illustratif d'un dossier ----
    Private Shared Function H(s As String) As Integer
        Dim acc As ULong = 2166136261UL
        For Each ch As Char In If(s, "")
            acc = acc Xor Convert.ToUInt64(AscW(ch))
            acc = (acc * 16777619UL) And &HFFFFFFFFUL
        Next
        Return CInt(acc And &H7FFFFFFFUL)
    End Function

    Private Shared ReadOnly SECTEURS As String() = {
        "Commerce de détail", "Restauration", "Construction", "Services professionnels",
        "Santé", "Technologie", "OBNL", "Immobilier", "Arts et médias", "Services"}

    ''' <summary>Un identifiant JS simple et stable à partir d'un libellé de tâche.</summary>
    Private Shared Function Slug(s As String) As String
        Dim sb As New StringBuilder()
        For Each ch As Char In If(s, "").Normalize(NormalizationForm.FormD)
            Dim cat = Globalization.CharUnicodeInfo.GetUnicodeCategory(ch)
            If cat = Globalization.UnicodeCategory.NonSpacingMark Then Continue For
            If Char.IsLetterOrDigit(ch) Then sb.Append(Char.ToLowerInvariant(ch)) Else sb.Append("_"c)
        Next
        Dim r As String = sb.ToString().Trim("_"c)
        Return If(r = "", "act", r)
    End Function

    Private Sub Charger()
        Dim reel As Boolean = False
        Dim activites As New Dictionary(Of String, Object)()
        Dim tx As New List(Of Object)()

        Dim dt As DataTable = LireTaches()
        If dt IsNot Nothing Then
            For Each r As DataRow In dt.Rows
                Dim statut As String = Convert.ToString(r("Statut")).Trim().ToLowerInvariant()
                If statut = "fait" Then Continue For   ' on ne traite en lot que ce qui reste à faire
                Dim titre As String = Convert.ToString(r("Titre")).Trim()
                If titre = "" Then Continue For
                Dim cle As String = Slug(titre)
                If Not activites.ContainsKey(cle) Then
                    activites(cle) = New With {.nom = titre, .verbe = "Faire", .cat = "", .pourquoi = ""}
                End If
                Dim nom As String = Convert.ToString(r("DossierNom")).Trim()
                Dim jours As Object = Nothing
                If Not IsDBNull(r("Jours")) Then jours = Convert.ToInt32(r("Jours"))
                tx.Add(New With {
                    .id = Convert.ToInt32(r("Id")),
                    .act = cle,
                    .client = nom,
                    .secteur = SECTEURS(H(nom) Mod SECTEURS.Length),
                    .jours = jours})
            Next
            reel = (tx.Count > 0)
        End If

        If reel Then
            Dim data As New Dictionary(Of String, Object) From {
                {"reel", True},
                {"activites", activites},
                {"tx", tx}}
            litData.Text = New JavaScriptSerializer() With {.MaxJsonLength = 8 * 1024 * 1024}.Serialize(data)
        Else
            ' Aucune tâche réelle à faire : le repli illustratif du script prend le relais.
            litData.Text = "null"
        End If
    End Sub

    ''' <summary>Toutes les tâches du périmètre du cabinet (s0956), ou Nothing.</summary>
    Private Function LireTaches() As DataTable
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0956GetJourneeTaches", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0)
        Catch
        End Try
        Return Nothing
    End Function

End Class
