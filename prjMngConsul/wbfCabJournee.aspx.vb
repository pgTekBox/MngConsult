Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web.Script.Serialization

''' <summary>
''' « Ma journée » du Portail comptable : l'écran d'accueil du cabinet, calqué sur
''' la maquette (persona « cabinet à plusieurs équipes »), mais la notion d'équipe
''' est remplacée par les employés — le portefeuille se regarde par employé.
'''
''' Les membres (s0922) et les dossiers (s0920) sont réels ; les « actions à faire »
''' (échéancier, urgences, charge) n'ont pas encore de modèle en base, elles sont
''' donc générées de façon illustrative et déterministe (stable d'une visite à
''' l'autre) sur les vrais dossiers et employés. Un bandeau le signale.
'''
''' Toute l'interactivité (filtres, regroupements, conseils de 60) est rendue côté
''' client à partir d'un jeu de données JSON injecté ; aucune requête par clic.
''' Réservé aux comptables (IsAccountant) ; sinon redirection vers Default.aspx.
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

        If Not IsPostBack Then Charger()
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    ' ---- Hachage déterministe (FNV-1a 32 bits) : même graine => mêmes données ----
    Private Shared Function H(s As String) As Integer
        ' FNV-1a 32 bits en arithmétique ULong pour éviter le dépassement
        ' (VB vérifie les débordements d'entier) ; on masque à 32 bits à chaque tour.
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

    ' Catalogue d'activités illustratif : nom, sujet, conseil de 60, qui peut agir.
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

        ' ---- Employés réels (membres du cabinet) ----
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

        If prenom = "" Then prenom = T("comptable", "there", "contador")

        ' On complète avec des employés fictifs pour illustrer la vue « par employé ».
        Dim di As Integer = 0
        While emps.Count < 4 AndAlso di < EMPS_DEMO.Length
            emps.Add(New Emp With {.Id = "demo-emp-" & di, .Nom = EMPS_DEMO(di), .Demo = True})
            di += 1
        End While

        ' ---- Dossiers réels ----
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

        ' Aucun dossier ? on en met quelques-uns en démonstration.
        If clients.Count = 0 Then
            For i As Integer = 0 To CLIENTS_DEMO.Length - 1
                clients.Add(New Cli With {
                    .Guid = "", .Nom = CLIENTS_DEMO(i), .Code = "DÉMO",
                    .Secteur = SECTEURS(i Mod SECTEURS.Length),
                    .EmpId = "", .Demo = True})
            Next
        End If

        ' Chaque dossier doit pointer vers un employé connu (sinon réparti).
        Dim empIds As New HashSet(Of String)(emps.Select(Function(x) x.Id))
        For Each c As Cli In clients
            If c.EmpId = "" OrElse Not empIds.Contains(c.EmpId) Then
                c.EmpId = emps(H(c.Nom & "e") Mod emps.Count).Id
            End If
        Next

        ' ---- Actions illustratives, déterministes ----
        Dim echPool As Integer() = {-3, -1, 0, 0, 1, 2, 4, 6, 9, 14, 21}
        Dim actions As New List(Of Object)()
        Dim aid As Integer = 0
        For Each c As Cli In clients
            Dim cnt As Integer = 1 + (H(c.Nom & "#n") Mod 4)   ' 1..4
            For k As Integer = 0 To cnt - 1
                Dim seed As Integer = H(c.Nom & ":" & k)
                Dim actIdx As Integer = seed Mod ACTS.Length
                Dim ech As Integer = echPool((seed \ 7) Mod echPool.Length)
                Dim roll As Integer = (seed \ 13) Mod 10
                Dim etat As String = If(roll < 6, "a", If(roll < 8, "w", "b"))
                Dim empId As String = If(k = 0, c.EmpId, emps((seed \ 17) Mod emps.Count).Id)
                Dim fait As Boolean = ((seed \ 23) Mod 11) = 0
                actions.Add(New With {
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
                    .fait = fait})
                aid += 1
            Next
        Next

        ' ---- Sérialisation ----
        Dim data As New Dictionary(Of String, Object) From {
            {"prenom", prenom},
            {"emps", emps.Select(Function(x) New With {.id = x.Id, .nom = x.Nom, .init = Initiales(x.Nom), .demo = x.Demo}).ToList()},
            {"actions", actions}
        }
        Dim js As New JavaScriptSerializer() With {.MaxJsonLength = 8 * 1024 * 1024}
        litData.Text = js.Serialize(data)

        ' ---- Libellés (chrome trilingue) ----
        Dim lbl As New Dictionary(Of String, String) From {
            {"bonjour", T("Bonjour", "Hello", "Hola")},
            {"sousTitre", T("Voici votre portefeuille, regroupé par employé.", "Here is your portfolio, grouped by employee.", "Aquí está su cartera, agrupada por empleado.")},
            {"echelleSolo", T("Cabinet solo", "Solo firm", "Despacho individual")},
            {"echelleN", T("Cabinet · {n} employés", "Firm · {n} employees", "Despacho · {n} empleados")},
            {"illustratif", T("Les actions ci-dessous sont illustratives : elles montrent la page à l'œuvre sur vos vrais dossiers, en attendant le suivi réel des tâches.", "The actions below are illustrative: they show the page in action on your real files, pending real task tracking.", "Las acciones siguientes son ilustrativas: muestran la página en funcionamiento sobre sus expedientes reales, a la espera del seguimiento real de tareas.")},
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
            {"effacer", T("Effacer les filtres", "Clear filters", "Borrar filtros")},
            {"toutesActions", T("Toutes les actions", "All actions", "Todas las acciones")},
            {"rienFiltres", T("Rien à afficher avec ces filtres.", "Nothing to show with these filters.", "Nada que mostrar con estos filtros.")},
            {"peutAgir", T("Peut agir", "Can act", "Puede actuar")},
            {"faitAuj", T("Fait aujourd'hui", "Done today", "Hecho hoy")},
            {"faitsN", T("{n} action(s) faite(s) aujourd'hui", "{n} action(s) done today", "{n} acción(es) hecha(s) hoy")},
            {"faireAvec", T("Faire avec 60", "Do with 60", "Hacer con 60")},
            {"suivreClient", T("Suivre le client", "Follow up client", "Seguir al cliente")},
            {"demanderAcces", T("Demander l'accès au client", "Request client access", "Solicitar acceso al cliente")},
            {"ouvrir", T("Ouvrir le dossier", "Open the file", "Abrir el expediente")},
            {"demoToast", T("Client de démonstration — pas de dossier réel à ouvrir.", "Demo client — no real file to open.", "Cliente de demostración — sin expediente real.")},
            {"demoAction", T("Action illustrative — le suivi réel des tâches arrive bientôt.", "Illustrative action — real task tracking is coming soon.", "Acción ilustrativa — el seguimiento real de tareas llegará pronto.")},
            {"enRetard", T("En retard", "Overdue", "Atrasado")},
            {"aujourdhui", T("Aujourd'hui", "Today", "Hoy")},
            {"demain", T("Demain", "Tomorrow", "Mañana")},
            {"cetteSemaine", T("Cette semaine", "This week", "Esta semana")},
            {"plusTard", T("Plus tard", "Later", "Más tarde")},
            {"dansJours", T("Dans {n} jours", "In {n} days", "En {n} días")},
            {"ilYaJours", T("Il y a {n} jours", "{n} days ago", "Hace {n} días")},
            {"sansUrg", T("Sans urgence", "No urgency", "Sin urgencia")},
            {"urgentN", T("{n} urgent", "{n} urgent", "{n} urgente")},
            {"surveillerN", T("{n} à surveiller", "{n} to watch", "{n} a vigilar")}
        }
        litLabels.Text = New JavaScriptSerializer().Serialize(lbl)
    End Sub

End Class
