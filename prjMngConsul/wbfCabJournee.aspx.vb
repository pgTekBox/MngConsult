Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web.Script.Serialization

''' <summary>
''' « Ma journée » du Portail comptable : l'écran d'accueil du cabinet, calqué sur
''' la maquette (persona « cabinet à plusieurs équipes »), mais la notion d'équipe
''' est remplacée par les employés — le portefeuille se regarde par employé.
'''
''' Source des « actions à faire » : les **tâches réelles** des dossiers
''' (T339DossierTache, proc s0956GetJourneeTaches), scopées au périmètre du
''' cabinet. Si le cabinet n'a aucune tâche, un **repli illustratif** génère des
''' actions de démonstration déterministes (un bandeau le signale).
'''
''' Le bouton « Marquer comme fait » agit réellement (s0944SetStatutTache) via un
''' POST léger traité en tête de Page_Load. Tout le rendu + le reste de
''' l'interactivité (filtres, regroupements, conseils) est côté client à partir
''' d'un jeu de données JSON injecté. Réservé aux comptables (IsAccountant).
''' </summary>
Public Class wbfCabJournee
    Inherits clsData

    Protected WithEvents litData As System.Web.UI.WebControls.Literal
    Protected WithEvents litLabels As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        ' Action réelle « Marquer comme fait » : POST léger (op=done&id=N), traité
        ' avant tout rendu, réponse JSON. Un vrai postback ASP.NET n'a pas « op ».
        If String.Equals(Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase) _
           AndAlso String.Equals(Request.Form("op"), "done", StringComparison.Ordinal) Then
            TraiterDone()
            Return
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

    ''' <summary>Marque une tâche « fait » via s0944 et répond en JSON.</summary>
    Private Sub TraiterDone()
        Dim id As Integer
        Dim ok As Boolean = False
        If Integer.TryParse(Request.Form("id"), id) Then
            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@UserId", UserEmail))
                p.Add(New SqlParameter("@Id", id))
                p.Add(New SqlParameter("@Statut", "fait"))
                Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
                p.Add(outErr)
                ExecuteSQL("s0944SetStatutTache", p)
                ok = (Not (outErr.Value Is Nothing OrElse IsDBNull(outErr.Value))) AndAlso CInt(outErr.Value) = 0
            Catch
            End Try
        End If
        Response.Clear()
        Response.ContentType = "application/json"
        Response.Write("{""ok"":" & If(ok, "true", "false") & "}")
        Response.End()
    End Sub

    ' ---- Hachage déterministe (FNV-1a 32 bits) pour le repli illustratif ----
    Private Shared Function H(s As String) As Integer
        Dim acc As ULong = 2166136261UL
        For Each ch As Char In s
            acc = acc Xor Convert.ToUInt64(AscW(ch))
            acc = (acc * 16777619UL) And &HFFFFFFFFUL
        Next
        Return CInt(acc And &H7FFFFFFFUL)
    End Function

    Private Shared Function Initiales(nom As String) As String
        Dim sb As New StringBuilder()
        For Each mot As String In If(nom, "").Split(New Char() {" "c, "-"c}, StringSplitOptions.RemoveEmptyEntries)
            If mot.Length > 0 AndAlso Char.IsLetter(mot(0)) Then sb.Append(Char.ToUpperInvariant(mot(0)))
            If sb.Length = 2 Then Exit For
        Next
        If sb.Length = 0 Then sb.Append("?"c)
        Return sb.ToString()
    End Function

    ' Catalogue d'activités (repli illustratif seulement) : nom, sujet, conseil, qui peut agir.
    Private Shared ReadOnly ACTS As String()() = New String()() {
        New String() {"Concilier le relevé bancaire", "Argent", "Importez le relevé : j'apparie la plupart des lignes, vous validez le reste.", "cabinet ou client"},
        New String() {"Produire la déclaration TPS/TVQ", "Taxes", "Vérifiez les taxes extraites avant de transmettre à Revenu Québec.", "cabinet seulement"},
        New String() {"Classer les factures d'achat", "Dépenses", "Glissez les PDF : j'extrais le fournisseur, la date et les taxes.", "cabinet ou client"},
        New String() {"Relancer une facture client impayée", "Ventes", "Un rappel courtois part en un clic ; je relance encore dans 7 jours.", "cabinet ou client"},
        New String() {"Préparer les acomptes provisionnels", "Impôts", "Je calcule l'acompte à partir des résultats courants.", "cabinet seulement"},
        New String() {"Réviser la paie du mois", "Paie", "Contrôlez les heures et les retenues avant l'émission.", "cabinet seulement"},
        New String() {"Fermer le mois comptable", "Argent", "Je bloque les écritures une fois la conciliation approuvée.", "cabinet seulement"},
        New String() {"Vérifier les dépenses par carte", "Dépenses", "Les dépenses sans pièce justificative sont surlignées pour suivi.", "cabinet ou client"},
        New String() {"Préparer les états financiers", "Argent", "Bilan et résultats sont prêts dès la clôture du mois.", "cabinet seulement"},
        New String() {"Transmettre un relevé d'emploi", "Paie", "Je pré-remplis le relevé à partir de la dernière paie.", "cabinet seulement"},
        New String() {"Obtenir les pièces manquantes du client", "Société", "J'envoie au client la liste des pièces manquantes.", "cabinet ou client"},
        New String() {"Approuver la conciliation mensuelle", "Argent", "Un coup d'œil, puis j'inscris l'approbation au journal.", "cabinet seulement"}
    }

    Private Shared ReadOnly SECTEURS As String() = {
        "Commerce de détail", "Restauration", "Construction", "Services professionnels",
        "Santé", "Technologie", "OBNL", "Immobilier"}

    Private Shared ReadOnly EMPS_DEMO As String() = {
        "Marie Tremblay", "Luc Bouchard", "Sophie Gagnon", "David Roy", "Émilie Côté"}

    Private Shared ReadOnly CLIENTS_DEMO As String() = {
        "Boulangerie Dupuis", "Clinique Zénith", "Construction Bélair", "Studio Pixel", "Café Mornel"}

    Private Class Emp
        Public Id As String
        Public Nom As String
        Public Demo As Boolean
    End Class

    Private Class Cli
        Public Guid As String
        Public Nom As String
        Public Code As String
        Public Secteur As String
        Public EmpId As String
        Public Demo As Boolean
    End Class

    Private Sub Charger()
        Dim prenom As String = ""
        Dim emps As New List(Of Emp)()
        ChargerMembres(emps, prenom)
        If prenom = "" Then prenom = T("comptable", "there", "contador")

        Dim actions As New List(Of Object)()
        Dim reel As Boolean = False

        Dim dt As DataTable = LireTaches()
        If dt IsNot Nothing AndAlso dt.Rows.Count > 0 Then
            reel = True
            actions = ActionsReelles(dt, emps)
        Else
            CompleterEmpsDemo(emps)
            actions = ActionsFictives(emps)
        End If

        Dim data As New Dictionary(Of String, Object) From {
            {"prenom", prenom},
            {"reel", reel},
            {"emps", emps.Select(Function(x) New With {.id = x.Id, .nom = x.Nom, .init = Initiales(x.Nom), .demo = x.Demo}).ToList()},
            {"actions", actions}
        }
        Dim js As New JavaScriptSerializer() With {.MaxJsonLength = 8 * 1024 * 1024}
        litData.Text = js.Serialize(data)
        litLabels.Text = New JavaScriptSerializer().Serialize(Libelles())
    End Sub

    ''' <summary>Membres réels du cabinet (s0922) + prénom de l'appelant.</summary>
    Private Sub ChargerMembres(emps As List(Of Emp), ByRef prenom As String)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0922ListCabinetMembres", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    Dim fn As String = Convert.ToString(r("FirstName")).Trim()
                    Dim ln As String = Convert.ToString(r("LastName")).Trim()
                    Dim nom As String = (fn & " " & ln).Trim()
                    If nom = "" Then nom = Convert.ToString(r("Email")).Split("@"c)(0)
                    emps.Add(New Emp With {.Id = Convert.ToString(r("UserGUID")), .Nom = nom, .Demo = False})
                    If Convert.ToBoolean(r("IsMe")) Then prenom = If(fn <> "", fn, nom.Split(" "c)(0))
                Next
            End If
        Catch
        End Try
    End Sub

    ''' <summary>Toutes les tâches du périmètre du cabinet (s0956), ou vide.</summary>
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

    ''' <summary>Tâches réelles → actions pour « Ma journée ».</summary>
    Private Function ActionsReelles(dt As DataTable, emps As List(Of Emp)) As List(Of Object)
        ' Les GUID de s0956 (CONVERT varchar → MAJUSCULES) et de s0922 (Guid.ToString → minuscules)
        ' doivent être comparés dans la même casse : on normalise tout en minuscules.
        Dim empIds As New HashSet(Of String)(emps.Select(Function(x) x.Id.ToLowerInvariant()))
        Dim besoinNone As Boolean = False
        Dim res As New List(Of Object)()
        For Each r As DataRow In dt.Rows
            Dim statut As String = Convert.ToString(r("Statut")).Trim().ToLowerInvariant()
            Dim fait As Boolean = (statut = "fait")
            Dim etat As String = If(statut = "bloque", "b", "a")
            Dim jours As Integer = 999
            If Not IsDBNull(r("Jours")) Then jours = Convert.ToInt32(r("Jours"))
            Dim empId As String = If(IsDBNull(r("AssignedUserGUID")), "", Convert.ToString(r("AssignedUserGUID")).ToLowerInvariant())
            If empId = "" OrElse Not empIds.Contains(empId) Then
                empId = "none" : besoinNone = True
            End If
            Dim titre As String = Convert.ToString(r("Titre"))
            Dim desc As String = If(IsDBNull(r("Description")), "", Convert.ToString(r("Description")))
            res.Add(New With {
                .id = "t" & Convert.ToString(r("Id")),
                .taskId = Convert.ToInt32(r("Id")),
                .cliNom = Convert.ToString(r("DossierNom")),
                .cliGuid = Convert.ToString(r("CompanyGUID")),
                .secteur = "",
                .actNom = titre,
                .sujet = titre,
                .conseil = desc,
                .peut = "",
                .ech = jours,
                .empId = empId,
                .etat = etat,
                .enCours = (statut = "encours"),
                .fait = fait})
        Next
        If besoinNone Then emps.Add(New Emp With {.Id = "none", .Nom = T("Non assigné", "Unassigned", "Sin asignar"), .Demo = False})
        Return res
    End Function

    ''' <summary>Complète les employés réels par quelques employés fictifs (repli).</summary>
    Private Sub CompleterEmpsDemo(emps As List(Of Emp))
        Dim di As Integer = 0
        While emps.Count < 4 AndAlso di < EMPS_DEMO.Length
            emps.Add(New Emp With {.Id = "demo-emp-" & di, .Nom = EMPS_DEMO(di), .Demo = True})
            di += 1
        End While
    End Sub

    ''' <summary>Repli illustratif : actions déterministes sur les vrais dossiers.</summary>
    Private Function ActionsFictives(emps As List(Of Emp)) As List(Of Object)
        Dim clients As New List(Of Cli)()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0920ListCabinetDossiers", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    If IsDBNull(r("CompanyGUID")) Then Continue For
                    Dim g As String = Convert.ToString(r("CompanyGUID"))
                    Dim nom As String = Convert.ToString(r("Name"))
                    Dim code As String = Convert.ToString(r("CompanyCode"))
                    Dim assigned As String = ""
                    If Not IsDBNull(r("AssignedUserGUID")) Then assigned = Convert.ToString(r("AssignedUserGUID"))
                    clients.Add(New Cli With {
                        .Guid = g, .Nom = nom, .Code = code,
                        .Secteur = SECTEURS(H(g & nom) Mod SECTEURS.Length),
                        .EmpId = assigned, .Demo = False})
                Next
            End If
        Catch
        End Try

        If clients.Count = 0 Then
            For i As Integer = 0 To CLIENTS_DEMO.Length - 1
                clients.Add(New Cli With {
                    .Guid = "", .Nom = CLIENTS_DEMO(i), .Code = "DÉMO",
                    .Secteur = SECTEURS(i Mod SECTEURS.Length), .EmpId = "", .Demo = True})
            Next
        End If

        Dim empIds As New HashSet(Of String)(emps.Select(Function(x) x.Id))
        For Each c As Cli In clients
            If c.EmpId = "" OrElse Not empIds.Contains(c.EmpId) Then
                c.EmpId = emps(H(c.Nom & "e") Mod emps.Count).Id
            End If
        Next

        Dim echPool As Integer() = {-3, -1, 0, 0, 1, 2, 4, 6, 9, 14, 21}
        Dim res As New List(Of Object)()
        Dim aid As Integer = 0
        For Each c As Cli In clients
            Dim cnt As Integer = 1 + (H(c.Nom & "#n") Mod 4)
            For k As Integer = 0 To cnt - 1
                Dim seed As Integer = H(c.Nom & ":" & k)
                Dim actIdx As Integer = seed Mod ACTS.Length
                Dim ech As Integer = echPool((seed \ 7) Mod echPool.Length)
                Dim roll As Integer = (seed \ 13) Mod 10
                Dim etat As String = If(roll < 6, "a", If(roll < 8, "w", "b"))
                Dim empId As String = If(k = 0, c.EmpId, emps((seed \ 17) Mod emps.Count).Id)
                Dim fait As Boolean = ((seed \ 23) Mod 11) = 0
                res.Add(New With {
                    .id = "a" & aid,
                    .cliNom = c.Nom,
                    .cliGuid = c.Guid,
                    .secteur = c.Secteur,
                    .actNom = ACTS(actIdx)(0),
                    .sujet = ACTS(actIdx)(1),
                    .conseil = ACTS(actIdx)(2),
                    .peut = ACTS(actIdx)(3),
                    .ech = ech,
                    .empId = empId,
                    .etat = etat,
                    .enCours = False,
                    .fait = fait})
                aid += 1
            Next
        Next
        Return res
    End Function

    ''' <summary>Libellés du chrome (trilingue).</summary>
    Private Function Libelles() As Dictionary(Of String, String)
        Return New Dictionary(Of String, String) From {
            {"bonjour", T("Bonjour", "Hello", "Hola")},
            {"sousTitre", T("Voici votre portefeuille, regroupé par employé.", "Here is your portfolio, grouped by employee.", "Aquí está su cartera, agrupada por empleado.")},
            {"echelleSolo", T("Cabinet solo", "Solo firm", "Despacho individual")},
            {"echelleN", T("Cabinet · {n} employés", "Firm · {n} employees", "Despacho · {n} empleados")},
            {"illustratif", T("Aucune tâche pour l'instant : les actions ci-dessous sont illustratives et montrent la page à l'œuvre sur vos vrais dossiers.", "No tasks yet: the actions below are illustrative and show the page in action on your real files.", "Sin tareas por ahora: las acciones siguientes son ilustrativas y muestran la página sobre sus expedientes reales.")},
            {"panTitre", T("Vos employés", "Your employees", "Sus empleados")},
            {"panSous", T("Les plus chargés en urgences d'abord. Touchez une personne pour voir ses actions.", "Those with the most urgencies first. Tap a person to see their actions.", "Los más cargados de urgencias primero. Toque a una persona para ver sus acciones.")},
            {"urgent", T("Urgent", "Urgent", "Urgente")},
            {"surveiller", T("À surveiller", "To watch", "A vigilar")},
            {"bien", T("Tout va bien", "All good", "Todo bien")},
            {"aFaire", T("à faire", "to do", "por hacer")},
            {"conseille", T("60 vous conseille", "60 advises you", "60 le aconseja")},
            {"commencez", T("Commencez par vos {n} urgences", "Start with your {n} urgencies", "Comience por sus {n} urgencias")},
            {"commencez1", T("Commencez par votre urgence", "Start with your urgency", "Comience por su urgencia")},
            {"ordre", T("Tout est en ordre. Bonne journée!", "All in order. Have a good day!", "Todo en orden. ¡Buen día!")},
            {"chercher", T("Chercher un client, une activité, un employé…", "Search a client, an activity, an employee…", "Buscar un cliente, una actividad, un empleado…")},
            {"regrouper", T("Regrouper par", "Group by", "Agrupar por")},
            {"gPrio", T("Priorité", "Priority", "Prioridad")},
            {"gClient", T("Client", "Client", "Cliente")},
            {"gActivite", T("Activité", "Activity", "Actividad")},
            {"gEch", T("Échéance", "Due date", "Vencimiento")},
            {"gEmp", T("Employé", "Employee", "Empleado")},
            {"etat", T("État", "State", "Estado")},
            {"employe", T("Employé", "Employee", "Empleado")},
            {"tous", T("Tous", "All", "Todos")},
            {"toutes", T("Toutes", "All", "Todas")},
            {"etatA", T("À faire", "To do", "Por hacer")},
            {"etatW", T("En attente du client", "Waiting on client", "Esperando al cliente")},
            {"etatB", T("Bloqué", "Blocked", "Bloqueado")},
            {"enCours", T("En cours", "In progress", "En curso")},
            {"effacer", T("Effacer les filtres", "Clear filters", "Borrar filtros")},
            {"toutesActions", T("Toutes les actions", "All actions", "Todas las acciones")},
            {"rienFiltres", T("Rien à afficher avec ces filtres.", "Nothing to show with these filters.", "Nada que mostrar con estos filtros.")},
            {"peutAgir", T("Peut agir", "Can act", "Puede actuar")},
            {"faitAuj", T("Fait aujourd'hui", "Done today", "Hecho hoy")},
            {"faitsN", T("{n} action(s) faite(s) aujourd'hui", "{n} action(s) done today", "{n} acción(es) hecha(s) hoy")},
            {"faitBtn", T("Marquer comme fait", "Mark as done", "Marcar como hecho")},
            {"faitOk", T("Tâche marquée comme faite.", "Task marked as done.", "Tarea marcada como hecha.")},
            {"erreur", T("Action impossible pour l'instant.", "Action not possible right now.", "Acción no posible por ahora.")},
            {"ouvrir", T("Ouvrir le dossier", "Open the file", "Abrir el expediente")},
            {"demoToast", T("Client de démonstration — pas de dossier réel à ouvrir.", "Demo client — no real file to open.", "Cliente de demostración — sin expediente real.")},
            {"demoAction", T("Action illustrative — le suivi réel des tâches arrive bientôt.", "Illustrative action — real task tracking is coming soon.", "Acción ilustrativa — el seguimiento real de tareas llegará pronto.")},
            {"enRetard", T("En retard", "Overdue", "Atrasado")},
            {"aujourdhui", T("Aujourd'hui", "Today", "Hoy")},
            {"demain", T("Demain", "Tomorrow", "Mañana")},
            {"cetteSemaine", T("Cette semaine", "This week", "Esta semana")},
            {"plusTard", T("Plus tard", "Later", "Más tarde")},
            {"sansEch", T("Sans échéance", "No due date", "Sin vencimiento")},
            {"dansJours", T("Dans {n} jours", "In {n} days", "En {n} días")},
            {"ilYaJours", T("Il y a {n} jours", "{n} days ago", "Hace {n} días")},
            {"sansUrg", T("Sans urgence", "No urgency", "Sin urgencia")},
            {"urgentN", T("{n} urgent", "{n} urgent", "{n} urgente")},
            {"surveillerN", T("{n} à surveiller", "{n} to watch", "{n} a vigilar")}
        }
    End Function

End Class
