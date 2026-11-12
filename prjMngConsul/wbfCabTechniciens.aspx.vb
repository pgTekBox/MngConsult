Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web.Script.Serialization
Imports BCrypt.Net

''' <summary>
''' Techniciens du cabinet (Portail comptable, script T379). Un technicien est un
''' membre au rôle « technicien » : il ne voit que les dossiers qui lui sont
''' confiés et travaille sous un superviseur (employé ou administrateur).
'''   - admin / solo : tous les techniciens ; inviter, changer le superviseur,
'''     confier ou retirer des dossiers, retirer le technicien du cabinet ;
'''   - employé : les techniciens qu'il supervise, en lecture.
''' Données : s0997 (techniciens + superviseurs possibles), s0999 (dossiers cochés),
''' écritures : s0923 (invitation), s0998 (superviseur), s0930 (dossier), s0924 (retrait).
''' Actions par POST léger op=… (réponse JSON), rendu côté client (JSON injecté).
''' </summary>
Public Class wbfCabTechniciens
    Inherits clsData

    Protected WithEvents litData As System.Web.UI.WebControls.Literal
    Protected WithEvents litLabels As System.Web.UI.WebControls.Literal

    Private _role As String = ""

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        _role = RoleCabinet()
        If _role <> "admin" AndAlso _role <> "solo" AndAlso _role <> "employe" Then
            Response.Redirect("~/wbfCabJournee.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        If String.Equals(Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase) Then
            Dim op As String = Convert.ToString(Request.Form("op"))
            If op <> "" Then
                Traiter(op) : Return
            End If
        End If

        If Not IsPostBack Then
            litData.Text = Json(Charger())
            litLabels.Text = Json(Libelles())
        End If
    End Sub

    Private ReadOnly Property PeutGerer As Boolean
        Get
            Return _role = "admin" OrElse _role = "solo"
        End Get
    End Property

    Private Function RoleCabinet() As String
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

    Private Shared Function Json(o As Object) As String
        Return New JavaScriptSerializer() With {.MaxJsonLength = Integer.MaxValue}.Serialize(o)
    End Function

    Private Shared Function Txt(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return Convert.ToString(o).Trim()
    End Function

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    ' ---------------------------------------------------------------------
    ' Lecture
    ' ---------------------------------------------------------------------
    Private Function Charger() As Object
        Dim techs As New List(Of Object)
        Dim sups As New List(Of Object)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0997ListTechniciens", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                Dim ci = Globalization.CultureInfo.GetCultureInfo(If(CurrentLang = "en", "en-CA", If(CurrentLang = "es", "es-ES", "fr-CA")))
                For Each r As DataRow In ds.Tables(0).Rows
                    Dim nom As String = (Txt(r("FirstName")) & " " & Txt(r("LastName"))).Trim()
                    techs.Add(New With {
                        .id = CInt(r("MembreId")),
                        .nom = If(nom = "", Txt(r("Email")), nom),
                        .email = Txt(r("Email")),
                        .attente = CBool(r("Pending")),
                        .connexion = If(IsDBNull(r("LastLoginOn")), "", CDate(r("LastLoginOn")).ToString("d MMM yyyy", ci)),
                        .sup = Txt(r("SuperviseurUserGUID")).ToLowerInvariant(),
                        .supNom = Txt(r("SuperviseurNom")),
                        .nbDossiers = CInt(r("NbDossiers")),
                        .dossiers = Txt(r("Dossiers")),
                        .taches = CInt(r("NbTaches")),
                        .retard = CInt(r("NbRetard"))})
                Next
            End If
            If ds IsNot Nothing AndAlso ds.Tables.Count > 1 Then
                For Each r As DataRow In ds.Tables(1).Rows
                    Dim nom As String = Txt(r("Nom"))
                    sups.Add(New With {.id = Txt(r("UserGUID")).ToLowerInvariant(), .nom = If(nom = "", Txt(r("Email")), nom)})
                Next
            End If
        Catch
        End Try
        Return New With {.gerer = PeutGerer, .techs = techs, .sups = sups}
    End Function

    ' ---------------------------------------------------------------------
    ' Actions (POST op=…)
    ' ---------------------------------------------------------------------
    Private Sub Traiter(op As String)
        Dim res As Object
        Try
            If Not PeutGerer Then
                res = New With {.ok = False, .erreur = T("Réservé aux administrateurs du cabinet.", "Reserved to the firm's administrators.", "Reservado a los administradores del despacho.")}
            Else
                Select Case op
                    Case "invite" : res = Inviter()
                    Case "sup" : res = ChangerSuperviseur(CInt(Val(Request.Form("id"))), Txt(Request.Form("sup")))
                    Case "dossiers" : res = LireDossiers(CInt(Val(Request.Form("id"))))
                    Case "assign" : res = Confier(CInt(Val(Request.Form("id"))), Txt(Request.Form("guids")))
                    Case "retirer" : res = Retirer(CInt(Val(Request.Form("id"))))
                    Case Else : res = New With {.ok = False, .erreur = "op"}
                End Select
            End If
        Catch ex As Exception
            res = New With {.ok = False, .erreur = ex.Message}
        End Try
        Response.Clear()
        Response.ContentType = "application/json"
        Response.Write(Json(res))
        Response.End()
    End Sub

    Private Function Inviter() As Object
        Dim email As String = Txt(Request.Form("email"))
        If email = "" OrElse Not email.Contains("@") Then Return New With {.ok = False, .erreur = T("Courriel invalide.", "Invalid email.", "Correo no válido.")}

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@Email", email))
        p.Add(New SqlParameter("@FirstName", Nz(Txt(Request.Form("prenom")))))
        p.Add(New SqlParameter("@LastName", Nz(Txt(Request.Form("nom")))))
        p.Add(New SqlParameter("@Role", "technicien"))
        p.Add(New SqlParameter("@EquipeId", DBNull.Value))
        p.Add(New SqlParameter("@HomeCompanyGUID", Guid.Empty))
        p.Add(New SqlParameter("@PlaceholderHash", BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString(), 11)))
        Dim outTok As New SqlParameter("@Token", SqlDbType.UniqueIdentifier) With {.Direction = ParameterDirection.Output}
        Dim outUid As New SqlParameter("@NewUserId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outTok) : p.Add(outUid) : p.Add(outErr)
        ExecuteSQL("s0923InviteCabinetMembre", p)

        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        If err = 1 Then Return New With {.ok = False, .erreur = T("Ce courriel est déjà utilisé.", "This email is already in use.", "Este correo ya está en uso.")}
        If err <> 0 OrElse outTok.Value Is Nothing OrElse IsDBNull(outTok.Value) Then
            Return New With {.ok = False, .erreur = T("L'invitation n'a pas pu être créée.", "The invitation could not be created.", "No se pudo crear la invitación.")}
        End If

        ' Le superviseur choisi, posé sur le nouveau membre
        Dim sup As String = Txt(Request.Form("sup"))
        If sup <> "" Then
            Dim membreId As Integer = TrouverMembre(email)
            If membreId > 0 Then ChangerSuperviseur(membreId, sup)
        End If

        Dim lien As String = Request.Url.GetLeftPart(UriPartial.Authority) & ResolveUrl("~/wbfCabInvitation.aspx?token=" & CType(outTok.Value, Guid).ToString())
        EnvoyerCourrielInvitation(email, lien)
        Return New With {.ok = True, .lien = lien}
    End Function

    Private Function TrouverMembre(email As String) As Integer
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0922ListCabinetMembres", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return 0
        For Each r As DataRow In ds.Tables(0).Rows
            If String.Equals(Txt(r("Email")), email, StringComparison.OrdinalIgnoreCase) Then Return CInt(r("MembreId"))
        Next
        Return 0
    End Function

    Private Function ChangerSuperviseur(membreId As Integer, sup As String) As Object
        Dim g As Guid
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@MembreId", membreId))
        p.Add(New SqlParameter("@SuperviseurUserGUID", If(Guid.TryParse(sup, g), CObj(g), DBNull.Value)))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s0998SetSuperviseur", p)
        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        Return New With {.ok = (err = 0), .erreur = If(err = 0, "", T("Le superviseur n'a pas pu être changé.", "The supervisor could not be changed.", "No se pudo cambiar el supervisor."))}
    End Function

    Private Class DossierTech
        Public id As String
        Public nom As String
        Public confie As Boolean
        Public autre As String
    End Class

    Private Function ListeDossiers(membreId As Integer) As List(Of DossierTech)
        Dim lst As New List(Of DossierTech)
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@MembreId", membreId))
        Dim ds As DataSet = ExecuteSQLds("s0999ListDossiersTechnicien", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                lst.Add(New DossierTech With {.id = Txt(r("CompanyGUID")).ToLowerInvariant(), .nom = Txt(r("Nom")),
                                              .confie = CBool(r("Confie")), .autre = If(CBool(r("Confie")), "", Txt(r("AssigneA")))})
            Next
        End If
        Return lst
    End Function

    Private Function LireDossiers(membreId As Integer) As Object
        Return New With {.ok = True, .dossiers = ListeDossiers(membreId)}
    End Function

    ''' <summary>Confie au technicien les dossiers cochés, retire ceux décochés qui étaient à lui.</summary>
    Private Function Confier(membreId As Integer, guids As String) As Object
        Dim voulus As New HashSet(Of String)(guids.ToLowerInvariant().Split(New Char() {","c}, StringSplitOptions.RemoveEmptyEntries))
        Dim techGuid As Guid = TechnicienGuid(membreId)
        If techGuid = Guid.Empty Then Return New With {.ok = False, .erreur = T("Technicien introuvable.", "Technician not found.", "Técnico no encontrado.")}
        Dim n As Integer = 0
        For Each d As DossierTech In ListeDossiers(membreId)
            Dim id As String = d.id, confie As Boolean = d.confie
            Dim veut As Boolean = voulus.Contains(id)
            If veut = confie Then Continue For
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            p.Add(New SqlParameter("@CompanyGUID", New Guid(id)))
            p.Add(New SqlParameter("@AssignedUserGUID", If(veut, CObj(techGuid), DBNull.Value)))
            p.Add(New SqlParameter("@EquipeId", DBNull.Value))
            Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
            p.Add(outErr)
            ExecuteSQL("s0930AssignDossier", p)
            If Not (outErr.Value Is Nothing OrElse IsDBNull(outErr.Value)) AndAlso CInt(outErr.Value) = 0 Then n += 1
        Next
        Return New With {.ok = True, .n = n}
    End Function

    Private Function TechnicienGuid(membreId As Integer) As Guid
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0922ListCabinetMembres", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                If CInt(r("MembreId")) = membreId AndAlso Txt(r("Role")).ToLowerInvariant() = "technicien" Then Return CType(r("UserGUID"), Guid)
            Next
        End If
        Return Guid.Empty
    End Function

    Private Function Retirer(membreId As Integer) As Object
        If TechnicienGuid(membreId) = Guid.Empty Then Return New With {.ok = False, .erreur = T("Technicien introuvable.", "Technician not found.", "Técnico no encontrado.")}
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@MembreId", membreId))
        p.Add(New SqlParameter("@Role", "technicien"))
        p.Add(New SqlParameter("@EquipeId", DBNull.Value))
        p.Add(New SqlParameter("@IsActive", False))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s0924UpdateCabinetMembre", p)
        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        Return New With {.ok = (err = 0), .erreur = If(err = 0, "", T("Le technicien n'a pas pu être retiré.", "The technician could not be removed.", "No se pudo retirar al técnico."))}
    End Function

    ''' <summary>Dépose le courriel d'invitation dans MailService (best-effort), comme Membres.</summary>
    Private Sub EnvoyerCourrielInvitation(email As String, lien As String)
        Try
            Dim sujet As String = T("Invitation à rejoindre un cabinet sur 60Sec-AI", "Invitation to join a firm on 60Sec-AI", "Invitación para unirse a un despacho en 60Sec-AI")
            Dim corps As String = T("Vous avez été invité à rejoindre un cabinet comptable sur 60Sec-AI comme technicien. Cliquez sur le lien pour activer votre compte :",
                                     "You have been invited to join an accounting firm on 60Sec-AI as a technician. Click the link to activate your account:",
                                     "Se le ha invitado a unirse a un despacho contable en 60Sec-AI como técnico. Haga clic en el enlace para activar su cuenta:")
            Dim p As New Collection
            p.Add(New SqlParameter("@To", email))
            p.Add(New SqlParameter("@Subject", sujet))
            p.Add(New SqlParameter("@HTMLBody", "<p>" & Server.HtmlEncode(corps) & "</p><p><a href=""" & lien & """>" & Server.HtmlEncode(lien) & "</a></p>"))
            p.Add(New SqlParameter("@TextBody", corps & vbCrLf & lien))
            ExecuteSQLMail("s0610InsertOutboundMail", p)
        Catch
            ' Le lien copiable reste disponible si le courriel ne part pas.
        End Try
    End Sub

    Private Shared Function Nz(s As String) As Object
        Return If(String.IsNullOrEmpty(s), CType(DBNull.Value, Object), s)
    End Function

    ' ---------------------------------------------------------------------
    ' Libellés (fr/en/es)
    ' ---------------------------------------------------------------------
    Private Function Libelles() As Object
        Return New With {
            .titre = T("Techniciens", "Technicians", "Técnicos"),
            .sous = If(PeutGerer,
                       T("Les techniciens comptables du cabinet : ils ne voient que les dossiers qui leur sont confiés et travaillent sous un superviseur.",
                         "The firm's accounting technicians: they only see the files assigned to them and work under a supervisor.",
                         "Los técnicos contables del despacho: solo ven los expedientes que se les confían y trabajan bajo un supervisor."),
                       T("Les techniciens que vous supervisez et leurs dossiers.", "The technicians you supervise and their files.", "Los técnicos que supervisa y sus expedientes.")),
            .kTech = T("Techniciens", "Technicians", "Técnicos"),
            .kAttente = T("En attente d'activation", "Awaiting activation", "Pendientes de activación"),
            .kTaches = T("Tâches ouvertes", "Open tasks", "Tareas abiertas"),
            .kRetard = T("En retard", "Overdue", "Atrasadas"),
            .inviter = T("Inviter un technicien", "Invite a technician", "Invitar a un técnico"),
            .prenom = T("Prénom", "First name", "Nombre"),
            .nom = T("Nom", "Last name", "Apellido"),
            .courriel = T("Courriel", "Email", "Correo"),
            .superviseur = T("Superviseur", "Supervisor", "Supervisor"),
            .aucunSup = T("— Aucun superviseur —", "— No supervisor —", "— Sin supervisor —"),
            .envoyer = T("Envoyer l'invitation", "Send the invitation", "Enviar la invitación"),
            .invOk = T("Invitation envoyée. Lien d'activation :", "Invitation sent. Activation link:", "Invitación enviada. Enlace de activación:"),
            .copier = T("Copier le lien", "Copy link", "Copiar enlace"),
            .vide = T("Aucun technicien pour l'instant.", "No technician yet.", "Todavía no hay técnicos."),
            .attente = T("en attente d'activation", "awaiting activation", "pendiente de activación"),
            .dossiers = T("Dossiers", "Files", "Expedientes"),
            .aucunDossier = T("Aucun dossier confié", "No file assigned", "Ningún expediente confiado"),
            .taches = T("tâche(s) ouverte(s)", "open task(s)", "tarea(s) abierta(s)"),
            .retard = T("en retard", "overdue", "atrasada(s)"),
            .connexion = T("Dernière connexion", "Last sign-in", "Última conexión"),
            .jamais = T("jamais", "never", "nunca"),
            .gererDossiers = T("Gérer les dossiers", "Manage files", "Gestionar expedientes"),
            .retirer = T("Retirer", "Remove", "Retirar"),
            .confRetirer = T("Retirer {0} du cabinet ? Son compte sera désactivé ; ses dossiers restent confiés jusqu'à ce que vous les réattribuiez.",
                             "Remove {0} from the firm? Their account will be deactivated; their files stay assigned until you reassign them.",
                             "¿Retirar a {0} del despacho? Su cuenta se desactivará; sus expedientes siguen confiados hasta que los reasigne."),
            .dossiersDe = T("Dossiers confiés à {0}", "Files assigned to {0}", "Expedientes confiados a {0}"),
            .dejaA = T("actuellement suivi par {0}", "currently handled by {0}", "actualmente a cargo de {0}"),
            .enregistrer = T("Enregistrer", "Save", "Guardar"),
            .fermer = T("Fermer", "Close", "Cerrar"),
            .erreur = T("Une erreur est survenue.", "An error occurred.", "Se produjo un error."),
            .chargement = T("Chargement…", "Loading…", "Cargando…")
        }
    End Function
End Class
