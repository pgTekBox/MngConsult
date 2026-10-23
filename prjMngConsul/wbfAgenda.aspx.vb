Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports Newtonsoft.Json
Imports Newtonsoft.Json.Linq

''' <summary>
''' L'agenda, au modèle de la fenêtre « Tout l'agenda » de la page d'accueil 60secondes
''' du 21 octobre : 5 jours ouvrables par colonne, heure par heure, navigation ‹ ›,
''' filtre par employé, « + RDV » ; toucher un RDV ouvre « Mettre à jour le RDV » à droite
''' (jour, heure, durée, employé, plages libres, échange avec un autre RDV, annulation).
''' Le serveur bâtit le modèle (rendez-vous s0100, employés s0106) ; la page le dessine.
''' Les changements reviennent par un postback (hfAction + hfData) puis la page se recharge.
''' </summary>
Public Class wbfAgenda
    Inherits clsData

    ''' <summary>Le modèle de la page, en JSON.</summary>
    Protected ModeleJson As String = "null"

    ''' <summary>Nombre de jours ouvrables chargés : la période affichée (5) et les deux suivantes, pour les plages libres.</summary>
    Private Const JOURS_CHARGES As Integer = 15

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        rwAppointment.Title = L("winRdv")
        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True

        If Not isAuthenticated Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        If Not IsPostBack Then
            Try
                ModeleJson = JsonConvert.SerializeObject(BatirModele(), New JsonSerializerSettings With {
                    .StringEscapeHandling = StringEscapeHandling.EscapeHtml
                })
            Catch ex As Exception
                System.Diagnostics.Debug.WriteLine("Agenda : " & ex.Message)
                ModeleJson = "null"
            End Try
        End If
    End Sub

    ' =====================================================================
    ' Les changements : déplacer / confier, échanger, annuler
    ' =====================================================================

    Protected Sub btnAction_Click(sender As Object, e As EventArgs) Handles btnAction.Click
        Try
            Dim d As JObject = JObject.Parse(If(hfData.Value, "{}"))
            Select Case hfAction.Value
                Case "maj"
                    Dim jour As Date = Date.ParseExact(CStr(d("jour")), "yyyy-MM-dd", CultureInfo.InvariantCulture)
                    Dim debut As Date = jour.AddMinutes(CInt(d("deb")))
                    Dim fin As Date = debut.AddMinutes(Math.Max(5, CInt(d("duree"))))
                    Dim emp As String = If(CStr(d("emp")), "")
                    Resauver(CInt(d("id")), debut, fin, emp, Nothing)
                Case "echanger"
                    Dim a As DataRow = LireRdv(CInt(d("id")))
                    Dim b As DataRow = LireRdv(CInt(d("autre")))
                    If a IsNot Nothing AndAlso b IsNot Nothing Then
                        Dim aDeb As Date = CDate(a("StartDateTime")), aFin As Date = CDate(a("EndDateTime"))
                        Dim bDeb As Date = CDate(b("StartDateTime")), bFin As Date = CDate(b("EndDateTime"))
                        ' Chacun prend la plage de l'autre en gardant sa durée.
                        Deplacer(CInt(a("Id")), bDeb, bDeb + (aFin - aDeb))
                        Deplacer(CInt(b("Id")), aDeb, aDeb + (bFin - bDeb))
                    End If
                Case "demande"
                    ' Accepter (avec la plage choisie, au besoin) ou refuser une demande de RDV (s0911).
                    Dim p As New Collection
                    p.Add(New SqlParameter("@CompanyGUID", Company))
                    p.Add(New SqlParameter("@Id", CInt(d("id"))))
                    p.Add(New SqlParameter("@Decision", CStr(d("decision"))))
                    If d("jour") IsNot Nothing AndAlso d("deb") IsNot Nothing Then
                        Dim debut As Date = Date.ParseExact(CStr(d("jour")), "yyyy-MM-dd", CultureInfo.InvariantCulture).AddMinutes(CInt(d("deb")))
                        p.Add(New SqlParameter("@Debut", debut))
                        p.Add(New SqlParameter("@Fin", debut.AddMinutes(Math.Max(5, CInt(d("duree"))))))
                    End If
                    p.Add(New SqlParameter("@UserName", If(User.Identity.Name, "")))
                    Dim ds As DataSet = ExecuteSQLds("s0911TraiterRdvDemande", p)
                    If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 AndAlso
                       Not CBool(ds.Tables(0).Rows(0)("Ok")) Then
                        Session("AgendaMsg") = Txt(ds.Tables(0).Rows(0)("Msg"))
                    End If
                Case "annuler"
                    Dim r As DataRow = LireRdv(CInt(d("id")))
                    If r IsNot Nothing Then
                        Resauver(CInt(r("Id")), CDate(r("StartDateTime")), CDate(r("EndDateTime")),
                                 If(IsDBNull(r("EmployeeId")), "", r("EmployeeId").ToString()), "Annulé")
                    End If
            End Select
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Agenda, changement : " & ex.Message)
        End Try
        Response.Redirect(Request.RawUrl, False)
        Context.ApplicationInstance.CompleteRequest()
    End Sub

    ''' <summary>Un RDV de la compagnie (s0101), ou Nothing.</summary>
    Private Function LireRdv(id As Integer) As DataRow
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Id", id))
        Dim ds As DataSet = ExecuteSQLds("s0101GetAppointmentById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return Nothing
        Return ds.Tables(0).Rows(0)
    End Function

    Private Sub Deplacer(id As Integer, debut As Date, fin As Date)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@StartDateTime", debut))
        p.Add(New SqlParameter("@EndDateTime", fin))
        p.Add(New SqlParameter("@UserName", If(User.Identity.Name, "")))
        ExecuteSQL("s0104MoveAppointment", p)
    End Sub

    ''' <summary>
    ''' Réenregistre un RDV (s0102) avec une nouvelle plage, un employé et, au besoin, un
    ''' nouvel état ; tout le reste est repris tel quel de s0101.
    ''' </summary>
    Private Sub Resauver(id As Integer, debut As Date, fin As Date, emp As String, statut As String)
        Dim r As DataRow = LireRdv(id)
        If r Is Nothing Then Return
        Dim empId As Integer
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Title", r("Title")))
        p.Add(New SqlParameter("@Description", r("Description")))
        p.Add(New SqlParameter("@StartDateTime", debut))
        p.Add(New SqlParameter("@EndDateTime", fin))
        p.Add(New SqlParameter("@IsAllDay", If(IsDBNull(r("IsAllDay")), False, r("IsAllDay"))))
        p.Add(New SqlParameter("@CustomerId", r("CustomerId")))
        p.Add(New SqlParameter("@EmployeeId", If(Integer.TryParse(emp, empId), CObj(empId), DBNull.Value)))
        p.Add(New SqlParameter("@AppointmentTypeId", r("AppointmentTypeId")))
        p.Add(New SqlParameter("@Status", If(statut, If(IsDBNull(r("Status")), "Planifié", r("Status")))))
        p.Add(New SqlParameter("@Location", r("Location")))
        p.Add(New SqlParameter("@RecurrenceRule", r("RecurrenceRule")))
        p.Add(New SqlParameter("@ReminderMinutes", r("ReminderMinutes")))
        p.Add(New SqlParameter("@UserName", If(User.Identity.Name, "")))
        Dim outNew As New SqlParameter("@NewId", SqlDbType.Int)
        outNew.Direction = ParameterDirection.Output
        p.Add(outNew)
        ExecuteSQL("s0102SaveAppointment", p)
    End Sub

    ' =====================================================================
    ' Le modèle
    ' =====================================================================

    Private Function BatirModele() As Object
        Dim aujourdhui As Date = Date.Today

        ' Premier jour affiché (?debut=aaaa-mm-jj), aujourd'hui par défaut ; un samedi ou un dimanche passe au lundi.
        Dim debut As Date = aujourdhui
        Dim q As Date
        If Date.TryParseExact(If(Request.QueryString("debut"), ""), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, q) Then debut = q
        While debut.DayOfWeek = DayOfWeek.Saturday OrElse debut.DayOfWeek = DayOfWeek.Sunday
            debut = debut.AddDays(1)
        End While

        Dim jours As New List(Of Date)
        Dim d As Date = debut
        While jours.Count < JOURS_CHARGES
            If d.DayOfWeek <> DayOfWeek.Saturday AndAlso d.DayOfWeek <> DayOfWeek.Sunday Then jours.Add(d)
            d = d.AddDays(1)
        End While

        ' Les employés
        Dim emps As New List(Of Object)
        Dim couleurs As New Dictionary(Of Integer, String)
        Dim pe As New Collection
        pe.Add(New SqlParameter("@CompanyGUID", Company))
        Dim dsE As DataSet = ExecuteSQLds("s0106GetEmployeesForAgenda", pe)
        If dsE IsNot Nothing AndAlso dsE.Tables.Count > 0 Then
            For Each r As DataRow In dsE.Tables(0).Rows
                Dim id As Integer = Convert.ToInt32(r("Id"))
                Dim coul As String = If(Txt(r("ColorHex")) = "", "#1B4F9C", Txt(r("ColorHex")))
                couleurs(id) = coul
                emps.Add(New With {.v = id.ToString(), .lab = Txt(r("FullName")), .ini = Initiales(Txt(r("FullName"))), .c = coul})
            Next
        End If

        ' Les rendez-vous des jours chargés
        Dim rdv As New List(Of Object)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@StartDate", jours(0)))
        p.Add(New SqlParameter("@EndDate", jours(jours.Count - 1).AddDays(1)))
        p.Add(New SqlParameter("@EmployeeId", DBNull.Value))
        Dim ds As DataSet = ExecuteSQLds("s0100GetAppointmentsByRange", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                Dim dDeb As Date = Convert.ToDateTime(r("StartDateTime"))
                Dim dFin As Date = Convert.ToDateTime(r("EndDateTime"))
                Dim statut As String = Txt(r("Status"))
                If statut = "Annulé" Then Continue For
                Dim empId As String = If(IsDBNull(r("EmployeeId")), "", Convert.ToInt32(r("EmployeeId")).ToString())
                Dim etat As String = "avenir"
                If statut = "Terminé" OrElse dFin < Date.Now Then
                    etat = "termine"
                ElseIf dDeb <= Date.Now Then
                    etat = "encours"
                End If
                Dim client As String = Txt(r("CustomerName"))
                Dim titre As String = Txt(r("Title"))
                rdv.Add(New With {
                    .id = Convert.ToInt32(r("Id")),
                    .jour = dDeb.ToString("yyyy-MM-dd"),
                    .deb = dDeb.Hour * 60 + dDeb.Minute,
                    .fin = If(dFin.Date > dDeb.Date, 24 * 60, dFin.Hour * 60 + dFin.Minute),
                    .client = If(client = "", titre, client),
                    .objet = If(client = "", Txt(r("TypeName")), titre),
                    .cli = If(IsDBNull(r("CustomerId")), "", Convert.ToString(r("CustomerId"))),
                    .lieu = Txt(r("Location")),
                    .typ = Txt(r("TypeName")),
                    .emp = empId,
                    .empNom = Txt(r("EmployeeName")),
                    .c = If(empId <> "" AndAlso couleurs.ContainsKey(CInt(empId)), couleurs(CInt(empId)), "#8D9CB3"),
                    .etat = etat,
                    .rappel = If(IsDBNull(r("ReminderMinutes")), -1, Convert.ToInt32(r("ReminderMinutes")))
                })
            Next
        End If

        ' Un message laissé par le dernier changement (une demande déjà traitée, par exemple)
        Dim msg As String = If(TryCast(Session("AgendaMsg"), String), "")
        Session.Remove("AgendaMsg")

        Return New With {
            .lang = CurrentLang,
            .msg = msg,
            .demandes = LireDemandes(),
            .jours = jours.Select(Function(j) j.ToString("yyyy-MM-dd")).ToList(),
            .prec = PasserJoursOuvrables(debut, -5).ToString("yyyy-MM-dd"),
            .suiv = jours(5).ToString("yyyy-MM-dd"),
            .aujourdhui = aujourdhui.ToString("yyyy-MM-dd"),
            .maintenant = Date.Now.Hour * 60 + Date.Now.Minute,
            .emps = emps,
            .rdv = rdv,
            .t = Textes()
        }
    End Function

    ''' <summary>
    ''' Les demandes de RDV en attente (s0910, T328) : nouveau RDV, déplacement ou annulation,
    ''' avec la plage souhaitée et le RDV visé.
    ''' </summary>
    Private Function LireDemandes() As List(Of Object)
        Dim liste As New List(Of Object)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0910GetRdvDemandes", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return liste
        For Each r As DataRow In ds.Tables(0).Rows
            Dim sDeb As Date? = If(IsDBNull(r("DebutSouhaite")), CType(Nothing, Date?), CDate(r("DebutSouhaite")))
            Dim sFin As Date? = If(IsDBNull(r("FinSouhaitee")), CType(Nothing, Date?), CDate(r("FinSouhaitee")))
            Dim rDeb As Date? = If(IsDBNull(r("RdvDebut")), CType(Nothing, Date?), CDate(r("RdvDebut")))
            Dim rFin As Date? = If(IsDBNull(r("RdvFin")), CType(Nothing, Date?), CDate(r("RdvFin")))
            liste.Add(New With {
                .id = CInt(r("Id")),
                .type = Txt(r("TypeDemande")),
                .canal = Txt(r("Canal")),
                .message = Txt(r("Message")),
                .depuis = CInt(r("MinutesDepuis")),
                .client = Txt(r("NomClient")),
                .souhJour = If(sDeb.HasValue, sDeb.Value.ToString("yyyy-MM-dd"), ""),
                .souhDeb = If(sDeb.HasValue, sDeb.Value.Hour * 60 + sDeb.Value.Minute, -1),
                .souhDuree = If(sDeb.HasValue AndAlso sFin.HasValue, CInt((sFin.Value - sDeb.Value).TotalMinutes), 60),
                .rdvId = If(IsDBNull(r("AppointmentId")), 0, CInt(r("AppointmentId"))),
                .rdvTitre = Txt(r("RdvTitre")),
                .rdvJour = If(rDeb.HasValue, rDeb.Value.ToString("yyyy-MM-dd"), ""),
                .rdvDeb = If(rDeb.HasValue, rDeb.Value.Hour * 60 + rDeb.Value.Minute, -1),
                .rdvDuree = If(rDeb.HasValue AndAlso rFin.HasValue, CInt((rFin.Value - rDeb.Value).TotalMinutes), 60),
                .rdvEmp = If(IsDBNull(r("RdvEmployeId")), "", r("RdvEmployeId").ToString())
            })
        Next
        Return liste
    End Function

    Private Shared Function PasserJoursOuvrables(d As Date, n As Integer) As Date
        Dim pas As Integer = Math.Sign(n), reste As Integer = Math.Abs(n)
        While reste > 0
            d = d.AddDays(pas)
            If d.DayOfWeek <> DayOfWeek.Saturday AndAlso d.DayOfWeek <> DayOfWeek.Sunday Then reste -= 1
        End While
        Return d
    End Function

    ' =====================================================================
    ' Petits outils
    ' =====================================================================

    Private Shared Function Txt(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return Convert.ToString(o).Trim()
    End Function

    Private Shared Function Initiales(nom As String) As String
        Dim parts = nom.Split(New Char() {" "c, "-"c}, StringSplitOptions.RemoveEmptyEntries)
        If parts.Length = 0 Then Return ""
        If parts.Length = 1 Then Return parts(0).Substring(0, Math.Min(2, parts(0).Length)).ToUpperInvariant()
        Return (parts(0).Substring(0, 1) & parts(parts.Length - 1).Substring(0, 1)).ToUpperInvariant()
    End Function

    ''' <summary>Les textes dont la page a besoin côté navigateur.</summary>
    Private Function Textes() As Object
        Dim cles As String() = {
            "toutAgenda", "resume", "toutEquipe", "periodeDuAu", "prec5", "suiv5", "aujourdhui", "employeAffiche", "equipeN",
            "plusRdv", "aide", "lTermine", "lAFacturer", "chipAFacturer", "lEnCours", "lAVenir", "auj", "rdvH", "nouveauIci",
            "majTitre", "majAide", "plagesLibres", "aucunePlage", "jour", "heure", "duree", "employe", "aucunEmploye",
            "plageLibre", "echanger", "aucunEchange", "conflit", "changement", "enregistrer", "ficheComplete",
            "annulerRdv", "confirmAnnuler", "fermer", "winRdv", "facturable", "rappelA",
            "rdvDemande", "tNouveau", "tModification", "tAnnulation", "ilyaMin", "ilyaH", "ilyaJ", "parCanal",
            "cTexto", "cCourriel", "cTelephone", "cWeb", "souhaite", "rdvDu", "accepter", "refuser", "confirmRefus",
            "confirmerAnnul"
        }
        Dim t As New Dictionary(Of String, String)
        For Each k As String In cles : t(k) = L(k) : Next
        Return t
    End Function

    ''' <summary>Traductions de l'agenda (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Agenda — 60secondes", "Calendar — 60secondes", "Agenda — 60secondes")
            Case "winRdv" : Return Choose3(lang, "Rendez-vous", "Appointment", "Cita")
            Case "toutAgenda" : Return Choose3(lang, "Tout l'agenda", "Full calendar", "Toda la agenda")
            Case "resume" : Return Choose3(lang, "{0} RDV · {1} h planifiées", "{0} appt · {1} h scheduled", "{0} citas · {1} h planificadas")
            Case "toutEquipe" : Return Choose3(lang, " · toute l'équipe", " · whole team", " · todo el equipo")
            Case "periodeDuAu" : Return Choose3(lang, "{0} au {1}", "{0} to {1}", "{0} al {1}")
            Case "prec5" : Return Choose3(lang, "5 jours précédents", "Previous 5 days", "5 días anteriores")
            Case "suiv5" : Return Choose3(lang, "5 jours suivants", "Next 5 days", "5 días siguientes")
            Case "aujourdhui" : Return Choose3(lang, "Aujourd'hui", "Today", "Hoy")
            Case "employeAffiche" : Return Choose3(lang, "Employé affiché", "Employee shown", "Empleado mostrado")
            Case "equipeN" : Return Choose3(lang, "Toute l'équipe ({0})", "Whole team ({0})", "Todo el equipo ({0})")
            Case "plusRdv" : Return Choose3(lang, "+ RDV", "+ Appt", "+ Cita")
            Case "aide" : Return Choose3(lang, "Touchez un rendez-vous pour le déplacer, l'échanger avec un autre, le confier à un autre employé ou l'annuler. Touchez une heure libre pour ajouter un RDV.", "Tap an appointment to move it, swap it with another, hand it to another employee or cancel it. Tap a free hour to add an appointment.", "Toque una cita para moverla, intercambiarla con otra, asignarla a otro empleado o cancelarla. Toque una hora libre para añadir una cita.")
            Case "lTermine" : Return Choose3(lang, "Terminé", "Completed", "Terminado")
            Case "lAFacturer" : Return Choose3(lang, "Terminé : facturer", "Completed: invoice", "Terminado: facturar")
            Case "chipAFacturer" : Return Choose3(lang, "Terminé · facturer", "Completed · invoice", "Terminado · facturar")
            Case "lEnCours" : Return Choose3(lang, "En cours", "In progress", "En curso")
            Case "lAVenir" : Return Choose3(lang, "À venir", "Upcoming", "Próximo")
            Case "auj" : Return Choose3(lang, "aujourd'hui", "today", "hoy")
            Case "rdvH" : Return Choose3(lang, "{0} RDV · {1} h", "{0} appt · {1} h", "{0} citas · {1} h")
            Case "nouveauIci" : Return Choose3(lang, "Nouveau RDV le {0} à {1}", "New appointment on {0} at {1}", "Nueva cita el {0} a las {1}")
            Case "majTitre" : Return Choose3(lang, "Mettre à jour le RDV", "Update the appointment", "Actualizar la cita")
            Case "majAide" : Return Choose3(lang, "Mettre à jour", "Update", "Actualizar")
            Case "plagesLibres" : Return Choose3(lang, "Prochaines plages libres", "Next free slots", "Próximos huecos libres")
            Case "aucunePlage" : Return Choose3(lang, "Aucune plage libre dans les trois prochaines semaines.", "No free slot in the next three weeks.", "Ningún hueco libre en las próximas tres semanas.")
            Case "jour" : Return Choose3(lang, "Jour", "Day", "Día")
            Case "heure" : Return Choose3(lang, "Heure", "Time", "Hora")
            Case "duree" : Return Choose3(lang, "Durée", "Duration", "Duración")
            Case "employe" : Return Choose3(lang, "Employé", "Employee", "Empleado")
            Case "aucunEmploye" : Return Choose3(lang, "Aucun employé", "No employee", "Ningún empleado")
            Case "plageLibre" : Return Choose3(lang, "Changer pour une plage libre", "Switch to a free slot", "Cambiar a un hueco libre")
            Case "echanger" : Return Choose3(lang, "Échanger sa plage avec un autre RDV", "Swap its slot with another appointment", "Intercambiar su hueco con otra cita")
            Case "aucunEchange" : Return Choose3(lang, "Aucun échange", "No swap", "Ningún intercambio")
            Case "conflit" : Return Choose3(lang, "Conflit : {0} a déjà {1} à cette heure.", "Conflict: {0} already has {1} at this time.", "Conflicto: {0} ya tiene {1} a esta hora.")
            Case "changement" : Return Choose3(lang, "Nouveau : {0}", "New: {0}", "Nuevo: {0}")
            Case "enregistrer" : Return Choose3(lang, "Enregistrer le changement", "Save the change", "Guardar el cambio")
            Case "ficheComplete" : Return Choose3(lang, "Ouvrir la fiche complète", "Open the full record", "Abrir la ficha completa")
            Case "annulerRdv" : Return Choose3(lang, "Annuler le RDV", "Cancel the appointment", "Cancelar la cita")
            Case "confirmAnnuler" : Return Choose3(lang, "Annuler ce rendez-vous ?", "Cancel this appointment?", "¿Cancelar esta cita?")
            Case "fermer" : Return Choose3(lang, "Fermer", "Close", "Cerrar")
            Case "facturable" : Return Choose3(lang, "Terminé : il peut être facturé depuis la fiche.", "Completed: it can be invoiced from the record.", "Terminada: puede facturarse desde la ficha.")
            Case "rdvDemande" : Return Choose3(lang, "RDV demandé", "Requested appointments", "Citas solicitadas")
            Case "tNouveau" : Return Choose3(lang, "Nouveau RDV demandé", "New appointment request", "Nueva cita solicitada")
            Case "tModification" : Return Choose3(lang, "Demande de déplacement", "Request to move", "Solicitud de cambio")
            Case "tAnnulation" : Return Choose3(lang, "Demande d'annulation", "Cancellation request", "Solicitud de cancelación")
            Case "ilyaMin" : Return Choose3(lang, "il y a {0} min", "{0} min ago", "hace {0} min")
            Case "ilyaH" : Return Choose3(lang, "il y a {0} h", "{0} h ago", "hace {0} h")
            Case "ilyaJ" : Return Choose3(lang, "il y a {0} j", "{0} d ago", "hace {0} d")
            Case "parCanal" : Return Choose3(lang, "par {0}", "by {0}", "por {0}")
            Case "cTexto" : Return Choose3(lang, "texto", "text", "SMS")
            Case "cCourriel" : Return Choose3(lang, "courriel", "email", "correo")
            Case "cTelephone" : Return Choose3(lang, "téléphone", "phone", "teléfono")
            Case "cWeb" : Return Choose3(lang, "le web", "the web", "la web")
            Case "souhaite" : Return Choose3(lang, "Souhaité : {0} à {1}", "Wanted: {0} at {1}", "Deseado: {0} a las {1}")
            Case "rdvDu" : Return Choose3(lang, "RDV du {0} à {1}", "Appointment on {0} at {1}", "Cita del {0} a las {1}")
            Case "accepter" : Return Choose3(lang, "Accepter : {0}", "Accept: {0}", "Aceptar: {0}")
            Case "refuser" : Return Choose3(lang, "Refuser", "Decline", "Rechazar")
            Case "confirmRefus" : Return Choose3(lang, "Refuser cette demande ?", "Decline this request?", "¿Rechazar esta solicitud?")
            Case "confirmerAnnul" : Return Choose3(lang, "Confirmer l'annulation", "Confirm the cancellation", "Confirmar la cancelación")
            Case "rappelA" : Return Choose3(lang, "Rappel : à {0}", "Reminder: at {0}", "Recordatorio: a las {0}")
            Case Else : Return ""
        End Select
    End Function

    Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
        Select Case lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

End Class
