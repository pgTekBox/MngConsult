Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

''' <summary>
''' « Tous les dossiers » du Portail comptable — calqué sur l'écran « Tous les
''' clients » de la maquette : les dossiers (compagnies clientes) regroupés par
''' priorité (sections Urgent / À surveiller / Sans urgence), avec recherche et
''' filtres (priorité, secteur, employé), et une carte par dossier montrant la
''' prochaine action et le nombre d'actions à faire.
'''
''' Données réelles : dossiers du périmètre (s0957, avec secteur + employé
''' assigné) et tâches (s0956), agrégées ici par dossier (priorité, nombre à
''' faire, prochaine action). Rendu + filtres côté client. Cliquer une carte
''' ouvre la fiche du dossier (wbfCabFiche). Réservé aux comptables.
''' </summary>
Public Class wbfCabDossiers
    Inherits clsData

    Protected WithEvents litData As System.Web.UI.WebControls.Literal
    Protected WithEvents litLabels As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        ' Entrer directement dans un dossier (ancien lien ?enter=GUID) : on garde
        ' la compatibilité — pose la compagnie et sort du portail.
        Dim ent As String = Request.QueryString("enter")
        If Not IsPostBack AndAlso Not String.IsNullOrEmpty(ent) Then
            EntrerDossier(ent) : Return
        End If

        If Not IsPostBack Then Charger()
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Sub EntrerDossier(guidStr As String)
        Dim g As Guid
        If Guid.TryParse(guidStr, g) Then
            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@UserId", UserEmail))
                p.Add(New SqlParameter("@CompanyGUID", g))
                ExecuteSQLds("s0211ValidateCompanyAccess", p)
            Catch
            End Try
            EnPortailComptable = False
            Company = g
            Response.Redirect("~/Default.aspx")
        Else
            Response.Redirect("~/wbfCabDossiers.aspx")
        End If
    End Sub

    ' Priorité d'une tâche ouverte : 0=urgent(r), 1=à surveiller(y), 2=ok(g).
    Private Shared Function PrioO(statut As String, jours As Integer) As Integer
        If statut = "bloque" Then Return 1
        If jours <= 1 Then Return 0
        If jours <= 7 Then Return 1
        Return 2
    End Function

    Private Class Doss
        Public Guid As String
        Public Nom As String
        Public Code As String
        Public Secteur As String
        Public Nouveau As Boolean
        Public EmpNom As String
    End Class

    Private Sub Charger()
        Dim role As String = LireRole()
        Dim admin As Boolean = (role = "admin" OrElse role = "solo")

        ' --- Dossiers (s0957) ---
        Dim dossiers As New List(Of Doss)()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0957GetJourneeClients", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    Dim sect As String = If(IsDBNull(r("Secteur")), "", Convert.ToString(r("Secteur")).Trim())
                    If sect = "" Then sect = T("Autres", "Other", "Otros")
                    dossiers.Add(New Doss With {
                        .Guid = Convert.ToString(r("CompanyGUID")).ToLowerInvariant(),
                        .Nom = Convert.ToString(r("Nom")),
                        .Code = If(IsDBNull(r("CompanyCode")), "", Convert.ToString(r("CompanyCode"))),
                        .Secteur = sect,
                        .Nouveau = (Not IsDBNull(r("EstNouveau"))) AndAlso Convert.ToInt32(r("EstNouveau")) = 1,
                        .EmpNom = If(IsDBNull(r("AssignedNom")), "", Convert.ToString(r("AssignedNom")).Trim())})
                Next
            End If
        Catch
        End Try

        ' --- Tâches (s0956) agrégées par dossier ---
        Dim nbByGuid As New Dictionary(Of String, Integer)()
        Dim pireByGuid As New Dictionary(Of String, Integer)()
        Dim nextTitreByGuid As New Dictionary(Of String, String)()
        Dim nextPoidsByGuid As New Dictionary(Of String, Integer)()
        Dim nextEchByGuid As New Dictionary(Of String, Integer)()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0956GetJourneeTaches", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    Dim statut As String = Convert.ToString(r("Statut")).Trim().ToLowerInvariant()
                    If statut = "fait" Then Continue For   ' seules les tâches ouvertes comptent
                    Dim g As String = Convert.ToString(r("CompanyGUID")).ToLowerInvariant()
                    Dim jours As Integer = 999
                    If Not IsDBNull(r("Jours")) Then jours = Convert.ToInt32(r("Jours"))
                    Dim o As Integer = PrioO(statut, jours)
                    Dim poids As Integer = o * 1000 + (jours + 100)

                    nbByGuid(g) = If(nbByGuid.ContainsKey(g), nbByGuid(g), 0) + 1
                    If Not pireByGuid.ContainsKey(g) OrElse o < pireByGuid(g) Then pireByGuid(g) = o
                    If Not nextPoidsByGuid.ContainsKey(g) OrElse poids < nextPoidsByGuid(g) Then
                        nextPoidsByGuid(g) = poids
                        nextTitreByGuid(g) = Convert.ToString(r("Titre"))
                        nextEchByGuid(g) = jours
                    End If
                Next
            End If
        Catch
        End Try

        ' --- Objets clients pour le rendu ---
        Dim clients As New List(Of Object)()
        For Each d As Doss In dossiers
            Dim nb As Integer = If(nbByGuid.ContainsKey(d.Guid), nbByGuid(d.Guid), 0)
            Dim o As Integer = If(pireByGuid.ContainsKey(d.Guid), pireByGuid(d.Guid), 2)
            Dim pk As String = If(o = 0, "r", If(o = 1, "y", "g"))
            clients.Add(New With {
                .guid = d.Guid,
                .nom = d.Nom,
                .code = d.Code,
                .secteur = d.Secteur,
                .nouveau = d.Nouveau,
                .empNom = d.EmpNom,
                .pk = pk,
                .nb = nb,
                .prochaine = If(nextTitreByGuid.ContainsKey(d.Guid), nextTitreByGuid(d.Guid), ""),
                .ech = If(nextEchByGuid.ContainsKey(d.Guid), nextEchByGuid(d.Guid), 9999)})
        Next

        Dim data As New Dictionary(Of String, Object) From {
            {"clients", clients},
            {"admin", admin}
        }
        Dim js As New JavaScriptSerializer() With {.MaxJsonLength = 8 * 1024 * 1024}
        litData.Text = js.Serialize(data)
        litLabels.Text = New JavaScriptSerializer().Serialize(Libelles(admin))
    End Sub

    Private Function LireRole() As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0919GetUserCabinet", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return Convert.ToString(ds.Tables(0).Rows(0)("Role")).Trim().ToLowerInvariant()
            End If
        Catch
        End Try
        Return ""
    End Function

    Private Function Libelles(admin As Boolean) As Dictionary(Of String, String)
        Return New Dictionary(Of String, String) From {
            {"titre", If(admin, T("Tous les dossiers", "All files", "Todos los expedientes"), T("Mes dossiers", "My files", "Mis expedientes"))},
            {"sousTitre", T("Vos dossiers, du plus urgent au plus calme. Touchez un dossier pour l'ouvrir.", "Your files, from the most urgent to the calmest. Tap a file to open it.", "Sus expedientes, del más urgente al más tranquilo. Toque uno para abrirlo.")},
            {"chercher", T("Chercher un dossier…", "Search a file…", "Buscar un expediente…")},
            {"tous", T("Tous", "All", "Todos")},
            {"urgent", T("Urgent", "Urgent", "Urgente")},
            {"surveiller", T("À surveiller", "To watch", "A vigilar")},
            {"bien", T("Tout va bien", "All good", "Todo bien")},
            {"sansUrg", T("Sans urgence", "No urgency", "Sin urgencia")},
            {"secteur", T("Secteur", "Sector", "Sector")},
            {"employe", T("Employé", "Employee", "Empleado")},
            {"suiviPar", T("suivi par", "handled by", "a cargo de")},
            {"nouveau", T("Nouveau", "New", "Nuevo")},
            {"aFaire", T("à faire", "to do", "por hacer")},
            {"rienAFaire", T("Rien à faire", "Nothing to do", "Nada por hacer")},
            {"aucuneAction", T("Aucune action en attente", "No pending action", "Sin acción pendiente")},
            {"dossierN", T("{n} dossier", "{n} file", "{n} expediente")},
            {"dossiersN", T("{n} dossiers", "{n} files", "{n} expedientes")},
            {"rienFiltres", T("Aucun dossier ne correspond.", "No file matches.", "Ningún expediente coincide.")},
            {"enRetard", T("En retard", "Overdue", "Atrasado")},
            {"aujourdhui", T("Aujourd'hui", "Today", "Hoy")},
            {"demain", T("Demain", "Tomorrow", "Mañana")},
            {"cetteSemaine", T("Cette semaine", "This week", "Esta semana")},
            {"dansJours", T("Dans {n} jours", "In {n} days", "En {n} días")},
            {"ilYaJours", T("Il y a {n} jours", "{n} days ago", "Hace {n} días")}
        }
    End Function

End Class
