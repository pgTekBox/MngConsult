Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web.Script.Serialization

''' <summary>
''' « Activités de l'Avatar 60 » du Portail comptable : le journal de ce qui a été
''' fait pour les clients du cabinet, selon les droits convenus. Calqué sur la
''' maquette d'Yves (tuiles, filtres, liste groupée par jour, fenêtre de détail).
'''
''' Source réelle : le **journal des dossiers** du périmètre du cabinet
''' (T340DossierJournal, proc s0961GetCabinetJournal), rassemblé pour tous les
''' dossiers. Chaque ligne de journal devient une activité (dossier, horodatage,
''' texte, auteur). Les familles / résultats sont déduits du type d'entrée.
'''
''' Si le journal est vide, un **repli illustratif** riche s'affiche (un bandeau
''' le signale). Tout le rendu + l'interactivité vivent côté client à partir du
''' JSON injecté. Réservé aux comptables (IsAccountant).
''' </summary>
Public Class wbfCabAvatar60
    Inherits clsData

    Protected WithEvents litData As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        If Not IsPostBack Then Charger()
    End Sub

    ''' <summary>Famille + résultat + libellé déduits du type d'entrée de journal.</summary>
    Private Shared Function Mapper(typ As String, texte As String, ByRef fam As String, ByRef res As String) As String
        Dim t As String = If(texte, "").ToLowerInvariant()
        Select Case If(typ, "").Trim().ToLowerInvariant()
            Case "statut"
                fam = "livres"
                If t.Contains("bloque") Then
                    res = "arrete"
                ElseIf t.Contains("encours") OrElse t.Contains("afaire") Then
                    res = "avalider"
                Else
                    res = "fait"
                End If
                Return "Mise à jour d'une tâche"
            Case "echange"
                fam = "echanges" : res = "fait"
                Return "Échange avec le client"
            Case "tache"
                fam = "echanges" : res = "fait"
                Return "Tâche du dossier"
            Case Else
                fam = "echanges" : res = "fait"
                Return "Note au dossier"
        End Select
    End Function

    Private Sub Charger()
        Dim dt As DataTable = LireJournal()
        If dt Is Nothing OrElse dt.Rows.Count = 0 Then
            ' Journal vide : le repli illustratif du script prend le relais.
            litData.Text = "null"
            Return
        End If

        Dim today As Date = Date.Today
        Dim clients As New List(Of Object)()
        Dim indexParNom As New Dictionary(Of String, Integer)(StringComparer.OrdinalIgnoreCase)
        Dim data As New List(Of Object)()

        For Each r As DataRow In dt.Rows
            Dim dossier As String = Convert.ToString(r("DossierNom")).Trim()
            If dossier = "" Then dossier = "Dossier"
            Dim c As Integer
            If Not indexParNom.TryGetValue(dossier, c) Then
                c = clients.Count
                indexParNom(dossier) = c
                clients.Add(New With {.nom = dossier, .metier = "", .profil = ""})
            End If

            Dim utc As Date = Convert.ToDateTime(r("Utc"))
            Dim loc As Date = utc.ToLocalTime()
            Dim jours As Integer = CInt((today - loc.Date).TotalDays)
            If jours < 0 Then jours = 0
            Dim h As String = loc.ToString("HH:mm")

            Dim typ As String = Convert.ToString(r("Type"))
            Dim texte As String = Convert.ToString(r("Texte")).Trim()
            Dim par As String = Convert.ToString(r("ParNom")).Trim()
            Dim fam As String = "echanges", res As String = "fait"
            Dim act As String = Mapper(typ, texte, fam, res)

            Dim etapes As New List(Of String())()
            etapes.Add(New String() {h, texte})

            Dim don As New List(Of String())()
            don.Add(New String() {"Dossier", dossier})
            don.Add(New String() {"Type", act})
            don.Add(New String() {"Par", If(par = "", "60", par)})

            data.Add(New With {
                .j = jours,
                .h = h,
                .c = c,
                .fam = fam,
                .act = act,
                .resume = texte,
                .res = res,
                .val = If(par = "", "60", "cabinet"),
                .mt = "",
                .etapes = etapes,
                .don = don,
                .pcs = New List(Of String)(),
                .regle = "Entrée réelle inscrite au journal du dossier, horodatée et conservée."})
        Next

        Dim payload As New Dictionary(Of String, Object) From {
            {"reel", True},
            {"auj", New Integer() {today.Year, today.Month - 1, today.Day}},
            {"clients", clients},
            {"data", data}}
        litData.Text = New JavaScriptSerializer() With {.MaxJsonLength = 8 * 1024 * 1024}.Serialize(payload)
    End Sub

    ''' <summary>Le journal de tout le périmètre du cabinet (s0961), ou Nothing.</summary>
    Private Function LireJournal() As DataTable
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0961GetCabinetJournal", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0)
        Catch
        End Try
        Return Nothing
    End Function

End Class
