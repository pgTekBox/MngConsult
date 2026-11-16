Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web.Script.Serialization
Imports BCrypt.Net

''' <summary>
''' Comptables et techniciens du cabinet (Portail comptable, scripts T379/T380).
''' Les comptables sont les membres au rôle admin / employé (solo) ; un technicien
''' (rôle « technicien ») ne voit que les dossiers qui lui sont confiés et travaille
''' sous un superviseur (comptable ou administrateur).
'''   - admin / solo : tous les membres ; inviter (rôle au choix), changer le rôle,
'''     changer le superviseur d'un technicien, confier ou retirer des dossiers,
'''     retirer un membre du cabinet ;
'''   - employé : lui-même et les techniciens qu'il supervise, en lecture.
''' Données : s1000 (membres + superviseurs possibles), s1001 (dossiers cochés),
''' écritures : s0923 (invitation), s0924 (rôle / retrait), s0998 (superviseur),
''' s0930 (dossier). Actions par POST léger op=… (réponse JSON), rendu côté client.
''' </summary>
Public Class wbfCabTechniciens
    Inherits clsData

    Protected WithEvents litData As System.Web.UI.WebControls.Literal
    Protected WithEvents litLabels As System.Web.UI.WebControls.Literal

    Private _role As String = ""
    Private _cabinetId As Integer = 0

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
            If PeutGerer Then CreerBoitesManquantes()
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
                _cabinetId = CInt(Val(Convert.ToString(ds.Tables(0).Rows(0)("CabinetId"))))
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

    ''' <summary>Rôle affiché / modifiable : admin, solo, employe (comptable), technicien.</summary>
    Private Shared Function RoleNormal(r As String) As String
        r = r.Trim().ToLowerInvariant()
        If r = "responsable" Then Return "employe"
        If r = "admin" OrElse r = "solo" OrElse r = "technicien" Then Return r
        Return "employe"
    End Function

    ' ---------------------------------------------------------------------
    ' Lecture
    ' ---------------------------------------------------------------------
    Private Function LireEquipe() As DataSet
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Return ExecuteSQLds("s1000ListEquipeCabinet", p)
    End Function

    Private Function Charger() As Object
        Dim membres As New List(Of Object)
        Dim sups As New List(Of Object)
        Try
            Dim ds As DataSet = LireEquipe()
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                Dim ci = Globalization.CultureInfo.GetCultureInfo(If(CurrentLang = "en", "en-CA", If(CurrentLang = "es", "es-ES", "fr-CA")))
                For Each r As DataRow In ds.Tables(0).Rows
                    Dim nom As String = (Txt(r("FirstName")) & " " & Txt(r("LastName"))).Trim()
                    membres.Add(New With {
                        .id = CInt(r("MembreId")),
                        .role = RoleNormal(Txt(r("Role"))),
                        .roleId = If(IsDBNull(r("RoleId")), 0, CInt(r("RoleId"))),
                        .roleNom = Txt(r("RoleNom")),
                        .moi = CBool(r("IsMe")),
                        .nom = If(nom = "", Txt(r("Email")), nom),
                        .email = Txt(r("Email")),
                        .attente = CBool(r("Pending")),
                        .inactif = CBool(r("Inactif")),
                        .prenom = Txt(r("FirstName")),
                        .nomFam = Txt(r("LastName")),
                        .recup = Txt(r("RecoveryEmail")),
                        .connexion = If(IsDBNull(r("LastLoginOn")), "", CDate(r("LastLoginOn")).ToString("d MMM yyyy", ci)),
                        .sup = Txt(r("SuperviseurUserGUID")).ToLowerInvariant(),
                        .supNom = Txt(r("SuperviseurNom")),
                        .nbDossiers = CInt(r("NbDossiers")),
                        .dossiers = Txt(r("Dossiers")),
                        .taches = CInt(r("NbTaches")),
                        .retard = CInt(r("NbRetard")),
                        .nbTechs = CInt(r("NbTechniciens"))})
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
        Dim roles As New List(Of Object)
        Try
            For Each r As DataRow In LireRoles().Rows
                roles.Add(New With {.id = CInt(r("Id")), .nom = Txt(r("Nom")), .acces = Txt(r("Acces"))})
            Next
        Catch
        End Try
        Return New With {.gerer = PeutGerer, .membres = membres, .sups = sups, .roles = roles}
    End Function

    ''' <summary>Les rôles du cabinet (s1003, T382) : Id, Nom, Acces.</summary>
    Private Function LireRoles() As DataTable
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s1003ListRolesCabinet", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0)
        Return New DataTable()
    End Function

    ''' <summary>Le niveau d'accès d'un rôle du cabinet ("" s'il est introuvable).</summary>
    Private Function AccesDuRole(roleId As Integer) As String
        For Each r As DataRow In LireRoles().Rows
            If CInt(r("Id")) = roleId Then Return Txt(r("Acces")).ToLowerInvariant()
        Next
        Return ""
    End Function

    ''' <summary>Donne un rôle du cabinet à un membre (s1006 : niveau d'accès recopié, dernier admin protégé).</summary>
    Private Function AttribuerRole(membreId As Integer, roleId As Integer) As Integer
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@MembreId", membreId))
        p.Add(New SqlParameter("@RoleId", roleId))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s1006SetRoleMembre", p)
        Return If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
    End Function

    ''' <summary>Le membre (GUID, rôle, en attente) lu dans s1000 ; Nothing s'il n'est pas du cabinet.</summary>
    Private Function LireMembre(membreId As Integer) As DataRow
        Dim ds As DataSet = LireEquipe()
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                If CInt(r("MembreId")) = membreId Then Return r
            Next
        End If
        Return Nothing
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
                    Case "suggerer" : res = SuggererCourriel(Txt(Request.Form("prenom")), Txt(Request.Form("nom")))
                    Case "role" : res = ChangerRole(CInt(Val(Request.Form("id"))), Txt(Request.Form("role")))
                    Case "modifier" : res = Modifier(CInt(Val(Request.Form("id"))))
                    Case "motdepasse" : res = EnvoyerMotDePasse(CInt(Val(Request.Form("id"))))
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

    ''' <summary>Adresse @60sec.ca libre proposée pour un prénom / nom (s1008, T383).</summary>
    Private Function SuggererCourriel(prenom As String, nom As String) As Object
        Dim p As New Collection
        p.Add(New SqlParameter("@Prenom", prenom))
        p.Add(New SqlParameter("@Nom", nom))
        Dim ds As DataSet = ExecuteSQLds("s1008SuggererCourriel60Sec", p)
        Dim email As String = ""
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then email = Txt(ds.Tables(0).Rows(0)("Email"))
        Return New With {.ok = (email <> ""), .email = email}
    End Function

    Private Shared Function Est60Sec(email As String) As Boolean
        Return email.EndsWith("@60sec.ca", StringComparison.OrdinalIgnoreCase)
    End Function

    ''' <summary>Crée la boîte @60sec.ca dans MailService (s1009) ; renvoie le code d'erreur.</summary>
    Private Function CreerBoite(email As String) As Integer
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@Email", email))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s1009CreerBoite60Sec", p)
        Return If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
    End Function

    ''' <summary>
    ''' Fenêtre « Nouveau membre » : crée le compte (s0923) avec son courriel de
    ''' connexion — par défaut prenom.nom@60sec.ca — et, si demandé, la boîte
    ''' @60sec.ca (s1009). Le courriel de récupération (obligatoire, T389) est
    ''' enregistré et reçoit l'invitation : la nouvelle boîte n'est pas encore accessible.
    ''' </summary>
    Private Function Inviter() As Object
        Dim email As String = Txt(Request.Form("email")).ToLowerInvariant()
        If email = "" OrElse Not email.Contains("@") OrElse email.Contains(" ") Then Return New With {.ok = False, .erreur = T("Courriel invalide.", "Invalid email.", "Correo no válido.")}
        ' Courriel de récupération obligatoire (T389) ; l'invitation y est envoyée
        Dim perso As String = Txt(Request.Form("emailPerso")).ToLowerInvariant()
        Dim errRecup As String = ValiderRecuperation(perso, email)
        If errRecup <> "" Then Return New With {.ok = False, .erreur = errRecup}
        Dim boite As Boolean = Est60Sec(email) AndAlso Txt(Request.Form("boite")) = "1"
        If boite Then
            ' Vérifier avant de créer le compte que l'adresse est libre
            Dim pchk As New Collection
            pchk.Add(New SqlParameter("@Email", email))
            Dim dsChk As DataSet = ExecuteSQLds("s1010Courriel60SecPris", pchk)
            If dsChk IsNot Nothing AndAlso dsChk.Tables.Count > 0 AndAlso dsChk.Tables(0).Rows.Count > 0 AndAlso CBool(dsChk.Tables(0).Rows(0)("Pris")) Then
                Return New With {.ok = False, .erreur = T("Cette adresse @60sec.ca est déjà utilisée.", "This @60sec.ca address is already in use.", "Esta dirección @60sec.ca ya está en uso.")}
            End If
        End If
        ' Le rôle choisi (T382) ; son niveau d'accès est le rôle technique du membre
        Dim roleId As Integer = CInt(Val(Request.Form("roleId")))
        Dim role As String = AccesDuRole(roleId)
        If role = "" Then role = "employe" : roleId = 0

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@Email", email))
        p.Add(New SqlParameter("@FirstName", Nz(Txt(Request.Form("prenom")))))
        p.Add(New SqlParameter("@LastName", Nz(Txt(Request.Form("nom")))))
        p.Add(New SqlParameter("@Role", role))
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

        ' Le rôle choisi et, pour un technicien, le superviseur, posés sur le nouveau membre
        Dim membreId As Integer = TrouverMembre(email)
        If membreId > 0 Then
            If roleId > 0 Then AttribuerRole(membreId, roleId)
            PoserRecuperation(membreId, perso)
            Dim sup As String = Txt(Request.Form("sup"))
            If role = "technicien" AndAlso sup <> "" Then ChangerSuperviseur(membreId, sup)
        End If

        ' La boîte @60sec.ca (son mot de passe sera celui choisi à l'activation)
        Dim boiteOk As Boolean = False
        If boite Then boiteOk = (CreerBoite(email) = 0)

        Dim lien As String = Request.Url.GetLeftPart(UriPartial.Authority) & ResolveUrl("~/wbfCabInvitation.aspx?token=" & CType(outTok.Value, Guid).ToString())
        Dim dest As String = perso
        EnvoyerCourrielInvitation(dest, lien, role)
        Return New With {.ok = True, .lien = lien, .dest = dest, .boite = If(boiteOk, email, "")}
    End Function

    ''' <summary>
    ''' Courriel de récupération (T389) : obligatoire, valide, externe (pas @60sec.ca,
    ''' dont la boîte partage le mot de passe) et différent du courriel de connexion.
    ''' Renvoie "" s'il est correct, sinon le message d'erreur.
    ''' </summary>
    Private Function ValiderRecuperation(recup As String, connexion As String) As String
        recup = recup.Trim().ToLowerInvariant()
        If recup = "" Then Return T("Le courriel de récupération est obligatoire.", "The recovery email is required.", "El correo de recuperación es obligatorio.")
        Dim at As Integer = recup.IndexOf("@"c)
        If at < 1 OrElse recup.IndexOf("."c, at) < 0 OrElse recup.Contains(" ") Then
            Return T("Courriel de récupération invalide.", "Invalid recovery email.", "Correo de recuperación no válido.")
        End If
        If Est60Sec(recup) Then
            Return T("Le courriel de récupération doit être une adresse externe (pas @60sec.ca).", "The recovery email must be an external address (not @60sec.ca).", "El correo de recuperación debe ser una dirección externa (no @60sec.ca).")
        End If
        If String.Equals(recup, connexion.Trim(), StringComparison.OrdinalIgnoreCase) Then
            Return T("Le courriel de récupération doit être différent du courriel de connexion.", "The recovery email must differ from the sign-in email.", "El correo de recuperación debe ser distinto del correo de conexión.")
        End If
        Return ""
    End Function

    ''' <summary>Enregistre le courriel de récupération d'un membre (s1013) ; renvoie le code d'erreur.</summary>
    Private Function PoserRecuperation(membreId As Integer, recup As String) As Integer
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@MembreId", membreId))
        p.Add(New SqlParameter("@Email", recup))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s1013SetCourrielRecuperation", p)
        Return If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
    End Function

    Private Function TrouverMembre(email As String) As Integer
        Dim ds As DataSet = LireEquipe()
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return 0
        For Each r As DataRow In ds.Tables(0).Rows
            If String.Equals(Txt(r("Email")), email, StringComparison.OrdinalIgnoreCase) Then Return CInt(r("MembreId"))
        Next
        Return 0
    End Function

    ''' <summary>Appelle s0924 en gardant l'état du compte (un membre en attente reste en attente).</summary>
    Private Function MajMembre(membreId As Integer, role As String, actif As Boolean) As Integer
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@MembreId", membreId))
        p.Add(New SqlParameter("@Role", role))
        p.Add(New SqlParameter("@EquipeId", DBNull.Value))
        p.Add(New SqlParameter("@IsActive", actif))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s0924UpdateCabinetMembre", p)
        Return If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
    End Function

    Private Function MessageErreur(err As Integer) As String
        Select Case err
            Case 3 : Return T("Le cabinet doit garder au moins un administrateur.", "The firm must keep at least one administrator.", "El despacho debe conservar al menos un administrador.")
            Case 4 : Return T("Vous ne pouvez pas vous retirer vous-même.", "You cannot remove yourself.", "No puede retirarse a sí mismo.")
            Case 5 : Return T("Membre introuvable.", "Member not found.", "Miembro no encontrado.")
            Case Else : Return T("La modification n'a pas pu être faite.", "The change could not be made.", "No se pudo realizar el cambio.")
        End Select
    End Function

    Private Function ChangerRole(membreId As Integer, role As String) As Object
        Dim m As DataRow = LireMembre(membreId)
        If m Is Nothing Then Return New With {.ok = False, .erreur = MessageErreur(5)}
        role = RoleNormal(role)
        If role = "solo" Then role = "employe"
        Dim err As Integer = MajMembre(membreId, role, Not (CBool(m("Pending")) OrElse CBool(m("Inactif"))))
        Return New With {.ok = (err = 0), .erreur = If(err = 0, "", MessageErreur(err))}
    End Function

    ''' <summary>
    ''' Fenêtre « Modifier » : identité (s1002), rôle + actif (s0924), superviseur
    ''' d'un technicien (s0998). Un compte en attente d'activation reste en attente.
    ''' </summary>
    Private Function Modifier(membreId As Integer) As Object
        Dim m As DataRow = LireMembre(membreId)
        If m Is Nothing Then Return New With {.ok = False, .erreur = MessageErreur(5)}

        ' 0. Courriel de récupération, obligatoire (T389) — vérifié avant toute écriture
        Dim recup As String = Txt(Request.Form("recup")).ToLowerInvariant()
        Dim connexion As String = If(Txt(Request.Form("email")) <> "", Txt(Request.Form("email")), Txt(m("Email")))
        Dim errRecup As String = ValiderRecuperation(recup, connexion)
        If errRecup <> "" Then Return New With {.ok = False, .erreur = errRecup}

        ' 1. Identité
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@MembreId", membreId))
        p.Add(New SqlParameter("@FirstName", Txt(Request.Form("prenom"))))
        p.Add(New SqlParameter("@LastName", Txt(Request.Form("nom"))))
        p.Add(New SqlParameter("@Email", Txt(Request.Form("email"))))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s1002UpdateMembreIdentite", p)
        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        Select Case err
            Case 0
            Case 1 : Return New With {.ok = False, .erreur = T("Ce courriel est déjà utilisé.", "This email is already in use.", "Este correo ya está en uso.")}
            Case 6 : Return New With {.ok = False, .erreur = T("Courriel invalide.", "Invalid email.", "Correo no válido.")}
            Case 7 : Return New With {.ok = False, .erreur = T("Vous ne pouvez pas changer votre propre courriel ici.", "You cannot change your own email here.", "No puede cambiar su propio correo aquí.")}
            Case Else : Return New With {.ok = False, .erreur = MessageErreur(err)}
        End Select
        If PoserRecuperation(membreId, recup) <> 0 Then
            Return New With {.ok = False, .erreur = T("Le courriel de récupération n'a pas pu être enregistré.", "The recovery email could not be saved.", "No se pudo guardar el correo de recuperación.")}
        End If

        ' 2. Rôle et état actif (le solo garde son rôle ; un compte en attente reste en attente)
        Dim role As String = RoleNormal(Txt(m("Role")))
        If role <> "solo" Then
            ' Le rôle du cabinet (T382) : s1006 recopie son niveau d'accès et
            ' retire le superviseur d'un technicien qui change de niveau.
            Dim roleId As Integer = CInt(Val(Request.Form("roleId")))
            Dim acces As String = AccesDuRole(roleId)
            If acces = "" Then Return New With {.ok = False, .erreur = T("Rôle introuvable.", "Role not found.", "Rol no encontrado.")}
            err = AttribuerRole(membreId, roleId)
            If err <> 0 Then Return New With {.ok = False, .erreur = MessageErreur(err)}
            role = acces
        End If
        Dim actif As Boolean = (Txt(Request.Form("actif")) = "1")
        If CBool(m("Pending")) Then actif = False
        err = MajMembre(membreId, role, actif)
        If err <> 0 Then Return New With {.ok = False, .erreur = MessageErreur(err)}

        ' 3. Superviseur d'un technicien
        If role = "technicien" Then
            Dim r As Object = ChangerSuperviseur(membreId, Txt(Request.Form("sup")))
            If Not CBool(r.ok) Then Return r
        End If

        ' 4. Nouveau courriel @60sec.ca : sa boîte est créée si elle n'existe pas (T387)
        CreerBoitesManquantes()
        Return New With {.ok = True}
    End Function

    ''' <summary>
    ''' Crée les boîtes @60sec.ca manquantes des membres du cabinet (s1012, T387) :
    ''' mot de passe du compte pour un membre actif, aucun s'il est en attente.
    ''' Idempotent ; appelé à l'ouverture de la page (administrateur) et après une modification.
    ''' </summary>
    Private Sub CreerBoitesManquantes()
        If _cabinetId <= 0 Then Return
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CabinetId", _cabinetId))
            ExecuteSQL("s1012CreerBoitesCabinet", p)
        Catch
            ' Best-effort : la gestion des membres ne dépend pas du serveur de courriel.
        End Try
    End Sub

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

    Private Class DossierMembre
        Public id As String
        Public nom As String
        Public confie As Boolean
        Public autre As String
    End Class

    Private Function ListeDossiers(membreId As Integer) As List(Of DossierMembre)
        Dim lst As New List(Of DossierMembre)
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@MembreId", membreId))
        Dim ds As DataSet = ExecuteSQLds("s1001ListDossiersMembre", p)
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                lst.Add(New DossierMembre With {.id = Txt(r("CompanyGUID")).ToLowerInvariant(), .nom = Txt(r("Nom")),
                                                .confie = CBool(r("Confie")), .autre = If(CBool(r("Confie")), "", Txt(r("AssigneA")))})
            Next
        End If
        Return lst
    End Function

    Private Function LireDossiers(membreId As Integer) As Object
        Return New With {.ok = True, .dossiers = ListeDossiers(membreId)}
    End Function

    ''' <summary>Confie au membre les dossiers cochés, retire ceux décochés qui étaient à lui.</summary>
    Private Function Confier(membreId As Integer, guids As String) As Object
        Dim voulus As New HashSet(Of String)(guids.ToLowerInvariant().Split(New Char() {","c}, StringSplitOptions.RemoveEmptyEntries))
        Dim m As DataRow = LireMembre(membreId)
        If m Is Nothing Then Return New With {.ok = False, .erreur = MessageErreur(5)}
        Dim membreGuid As Guid = CType(m("UserGUID"), Guid)
        Dim n As Integer = 0
        For Each d As DossierMembre In ListeDossiers(membreId)
            Dim veut As Boolean = voulus.Contains(d.id)
            If veut = d.confie Then Continue For
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            p.Add(New SqlParameter("@CompanyGUID", New Guid(d.id)))
            p.Add(New SqlParameter("@AssignedUserGUID", If(veut, CObj(membreGuid), DBNull.Value)))
            p.Add(New SqlParameter("@EquipeId", DBNull.Value))
            Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
            p.Add(outErr)
            ExecuteSQL("s0930AssignDossier", p)
            If Not (outErr.Value Is Nothing OrElse IsDBNull(outErr.Value)) AndAlso CInt(outErr.Value) = 0 Then n += 1
        Next
        Return New With {.ok = True, .n = n}
    End Function

    Private Function Retirer(membreId As Integer) As Object
        Dim m As DataRow = LireMembre(membreId)
        If m Is Nothing Then Return New With {.ok = False, .erreur = MessageErreur(5)}
        Dim err As Integer = MajMembre(membreId, Txt(m("Role")).ToLowerInvariant(), False)
        Return New With {.ok = (err = 0), .erreur = If(err = 0, "", MessageErreur(err))}
    End Function

    ' Validité du lien de changement de mot de passe envoyé par l'administrateur (24 h).
    Private Const RESET_MINUTES As Integer = 1440

    ''' <summary>
    ''' Envoie au membre un courriel pour changer son mot de passe :
    '''   - compte actif : jeton de réinitialisation (s0679, 24 h) → wbfResetPassword ;
    '''   - en attente d'activation : nouvelle invitation (s0927) → wbfCabInvitation ;
    '''   - inactif : refusé (il faut d'abord réactiver le compte).
    ''' Le lien est aussi renvoyé à l'écran, à copier si le courriel tarde.
    ''' </summary>
    Private Function EnvoyerMotDePasse(membreId As Integer) As Object
        Dim m As DataRow = LireMembre(membreId)
        If m Is Nothing Then Return New With {.ok = False, .erreur = MessageErreur(5)}
        Dim email As String = Txt(m("Email"))
        ' T389 : les liens partent au courriel de récupération (la boîte @60sec.ca partage le mot de passe)
        Dim dest As String = Txt(m("RecoveryEmail"))
        If dest = "" Then dest = email

        If CBool(m("Inactif")) Then
            Return New With {.ok = False, .erreur = T("Ce compte est inactif : cochez « Compte actif » et enregistrez avant d'envoyer le courriel.",
                                                      "This account is inactive: check ""Active account"" and save before sending the email.",
                                                      "Esta cuenta está inactiva: marque «Cuenta activa» y guarde antes de enviar el correo.")}
        End If

        If CBool(m("Pending")) Then
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            p.Add(New SqlParameter("@MembreId", membreId))
            Dim outTok As New SqlParameter("@Token", SqlDbType.UniqueIdentifier) With {.Direction = ParameterDirection.Output}
            Dim outMail As New SqlParameter("@Email", SqlDbType.NVarChar, 200) With {.Direction = ParameterDirection.Output}
            Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
            p.Add(outTok) : p.Add(outMail) : p.Add(outErr)
            ExecuteSQL("s0927ResendInvite", p)
            Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
            If err <> 0 OrElse outTok.Value Is Nothing OrElse IsDBNull(outTok.Value) Then
                Return New With {.ok = False, .erreur = T("L'invitation n'a pas pu être renvoyée.", "The invitation could not be resent.", "No se pudo reenviar la invitación.")}
            End If
            Dim lienInv As String = Request.Url.GetLeftPart(UriPartial.Authority) & ResolveUrl("~/wbfCabInvitation.aspx?token=" & CType(outTok.Value, Guid).ToString())
            EnvoyerCourrielInvitation(dest, lienInv, RoleNormal(Txt(m("Role"))))
            Return New With {.ok = True, .lien = lienInv,
                             .message = T("Le compte est en attente d'activation : une nouvelle invitation a été envoyée à " & dest & " pour choisir son mot de passe.",
                                          "The account is awaiting activation: a new invitation was sent to " & dest & " to choose a password.",
                                          "La cuenta está pendiente de activación: se envió una nueva invitación a " & dest & " para elegir su contraseña.")}
        End If

        Dim pr As New Collection
        pr.Add(New SqlParameter("@Email", email))
        pr.Add(New SqlParameter("@ExpiresMinutes", RESET_MINUTES))
        Dim ds As DataSet = ExecuteSQLds("s0679CreateUserResetToken", pr)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return New With {.ok = False, .erreur = T("Le lien n'a pas pu être créé.", "The link could not be created.", "No se pudo crear el enlace.")}
        End If
        Dim token As Guid = CType(ds.Tables(0).Rows(0)("Token"), Guid)
        Dim lien As String = Request.Url.GetLeftPart(UriPartial.Authority) & ResolveUrl("~/wbfResetPassword.aspx") &
                             "?token=" & token.ToString("D") & "&lang=" & CurrentLang
        EnvoyerCourrielMotDePasse(dest, Txt(m("FirstName")), lien)
        Return New With {.ok = True, .lien = lien,
                         .message = T("Courriel de changement de mot de passe envoyé à " & dest & ". Le lien est valide 24 heures.",
                                      "Password change email sent to " & dest & ". The link is valid for 24 hours.",
                                      "Correo de cambio de contraseña enviado a " & dest & ". El enlace es válido 24 horas.")}
    End Function

    ''' <summary>Courriel « changer votre mot de passe » (MailService, best-effort), même gabarit que Mot de passe oublié.</summary>
    Private Sub EnvoyerCourrielMotDePasse(email As String, prenom As String, lien As String)
        Try
            Dim salut As String = If(prenom = "", T("Bonjour,", "Hello,", "Hola:"), T("Bonjour " & prenom & ",", "Hello " & prenom & ",", "Hola " & prenom & ":"))
            Dim intro As String = T("L'administrateur de votre cabinet vous invite à choisir un nouveau mot de passe pour votre compte 60Sec-AI.",
                                    "Your firm's administrator invites you to choose a new password for your 60Sec-AI account.",
                                    "El administrador de su despacho le invita a elegir una nueva contraseña para su cuenta 60Sec-AI.")
            Dim bouton As String = T("Changer mon mot de passe", "Change my password", "Cambiar mi contraseña")
            Dim validite As String = T("Le lien est valide pendant 24 heures. Votre mot de passe actuel reste valable tant que vous ne l'avez pas changé.",
                                       "The link is valid for 24 hours. Your current password still works until you change it.",
                                       "El enlace es válido durante 24 horas. Su contraseña actual sigue siendo válida hasta que la cambie.")
            Dim secours As String = T("Si le bouton ne fonctionne pas, copiez ce lien dans votre navigateur :", "If the button doesn't work, copy this link into your browser:", "Si el botón no funciona, copie este enlace en su navegador:")
            Dim sb As New StringBuilder()
            sb.Append("<!DOCTYPE html><html><body style=""font-family:Arial,sans-serif;background:#f6f7fb;margin:0;padding:20px;"">")
            sb.Append("<div style=""max-width:560px;margin:0 auto;background:#fff;border-radius:16px;overflow:hidden;"">")
            sb.Append("<div style=""background:linear-gradient(135deg,#2563eb,#06b6d4);padding:32px;text-align:center;""><h1 style=""color:#fff;margin:0;font-size:22px;"">60Sec-AI</h1></div>")
            sb.Append("<div style=""padding:32px;color:#0f172a;"">")
            sb.Append("<p style=""font-size:16px;"">").Append(Server.HtmlEncode(salut)).Append("</p>")
            sb.Append("<p>").Append(Server.HtmlEncode(intro)).Append("</p>")
            sb.Append("<div style=""text-align:center;margin:28px 0;""><a href=""").Append(lien).Append(""" target=""_blank"" style=""display:inline-block;background:linear-gradient(135deg,#2563eb,#06b6d4);color:#fff;padding:14px 32px;border-radius:12px;text-decoration:none;font-weight:800;font-size:15px;"">").Append(Server.HtmlEncode(bouton)).Append("</a></div>")
            sb.Append("<p style=""font-size:13px;color:#64748b;"">").Append(Server.HtmlEncode(validite)).Append("</p>")
            sb.Append("<p style=""font-size:13px;color:#64748b;"">").Append(Server.HtmlEncode(secours)).Append("<br/><span style=""word-break:break-all;color:#2563eb;"">").Append(Server.HtmlEncode(lien)).Append("</span></p>")
            sb.Append("</div></div></body></html>")

            Dim p As New Collection
            p.Add(New SqlParameter("@To", email))
            p.Add(New SqlParameter("@Subject", T("Changement de votre mot de passe 60Sec-AI", "Change your 60Sec-AI password", "Cambio de su contraseña 60Sec-AI")))
            p.Add(New SqlParameter("@HTMLBody", sb.ToString()))
            p.Add(New SqlParameter("@TextBody", salut & vbCrLf & intro & vbCrLf & lien))
            ExecuteSQLMail("s0610InsertOutboundMail", p)
        Catch
            ' Le lien copiable reste disponible si le courriel ne part pas.
        End Try
    End Sub

    ''' <summary>Dépose le courriel d'invitation dans MailService (best-effort), comme Membres.</summary>
    Private Sub EnvoyerCourrielInvitation(email As String, lien As String, role As String)
        Try
            Dim qui As String
            Select Case role
                Case "technicien" : qui = T("employé", "an employee", "empleado")
                Case "admin" : qui = T("administrateur", "an administrator", "administrador")
                Case Else : qui = T("employé", "an employee", "empleado")
            End Select
            Dim sujet As String = T("Invitation à rejoindre un cabinet sur 60Sec-AI", "Invitation to join a firm on 60Sec-AI", "Invitación para unirse a un despacho en 60Sec-AI")
            Dim corps As String = T("Vous avez été invité à rejoindre un cabinet comptable sur 60Sec-AI comme " & qui & ". Cliquez sur le lien pour activer votre compte :",
                                     "You have been invited to join an accounting firm on 60Sec-AI as " & qui & ". Click the link to activate your account:",
                                     "Se le ha invitado a unirse a un despacho contable en 60Sec-AI como " & qui & ". Haga clic en el enlace para activar su cuenta:")
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
            .titre = T("Employés", "Employees", "Empleados"),
            .sous = If(PeutGerer,
                       T("Les employés du cabinet. Le rôle de chacun décide des dossiers qu'il voit et de ce qu'il peut faire.",
                         "The firm's employees. Each person's role decides which files they see and what they can do.",
                         "Los empleados del despacho. El rol de cada uno decide qué expedientes ve y qué puede hacer."),
                       T("Votre charge et les employés que vous supervisez.", "Your workload and the employees you supervise.", "Su carga y los empleados que supervisa.")),
            .kEmployes = T("Employés", "Employees", "Empleados"),
            .secEmployes = T("Employés", "Employees", "Empleados"),
            .videEmployes = T("Aucun employé pour l'instant.", "No employee yet.", "Todavía no hay empleados."),
            .kComptables = T("Comptables", "Accountants", "Contadores"),
            .kTech = T("Techniciens", "Technicians", "Técnicos"),
            .kAttente = T("En attente d'activation", "Awaiting activation", "Pendientes de activación"),
            .kTaches = T("Tâches ouvertes", "Open tasks", "Tareas abiertas"),
            .kRetard = T("En retard", "Overdue", "Atrasadas"),
            .inviter = T("Ajouter un employé", "Add an employee", "Agregar un empleado"),
            .nouveau = T("Nouvel employé", "New employee", "Nuevo empleado"),
            .nouvSous = T("Créez un employé et choisissez son rôle ; son courriel @60sec.ca est proposé à partir de son nom.",
                          "Create an employee and choose their role; their @60sec.ca email is suggested from their name.",
                          "Cree un empleado y elija su rol; su correo @60sec.ca se propone a partir de su nombre."),
            .courriel60 = T("Courriel (identifiant de connexion)", "Email (sign-in identifier)", "Correo (identificador de conexión)"),
            .courriel60Aide = T("Proposé automatiquement : prenom.nom@60sec.ca. Vous pouvez le modifier.",
                                "Suggested automatically: firstname.lastname@60sec.ca. You can change it.",
                                "Propuesto automáticamente: nombre.apellido@60sec.ca. Puede modificarlo."),
            .creerBoite = T("Créer la boîte courriel @60sec.ca", "Create the @60sec.ca mailbox", "Crear el buzón @60sec.ca"),
            .creerBoiteAide = T("La boîte reçoit les courriels ; son mot de passe sera celui que le membre choisit en activant son compte.",
                                "The mailbox receives emails; its password will be the one the member chooses when activating their account.",
                                "El buzón recibe correos; su contraseña será la que el miembro elija al activar su cuenta."),
            .courrielPerso = T("Courriel de récupération", "Recovery email", "Correo de recuperación"),
            .courrielPersoAide = T("Obligatoire. Adresse externe (personnelle) du membre : elle reçoit l'invitation et les liens de mot de passe, puisque la boîte @60sec.ca partage son mot de passe.",
                                   "Required. The member's external (personal) address: it receives the invitation and password links, since the @60sec.ca mailbox shares their password.",
                                   "Obligatorio. Dirección externa (personal) del miembro: recibe la invitación y los enlaces de contraseña, ya que el buzón @60sec.ca comparte su contraseña."),
            .recupLab = T("Récupération", "Recovery", "Recuperación"),
            .sansRecup = T("sans courriel de récupération", "no recovery email", "sin correo de recuperación"),
            .kSansRecup = T("Sans courriel de récupération", "No recovery email", "Sin correo de recuperación"),
            .invEnvoyee = T("Invitation envoyée à {0}.", "Invitation sent to {0}.", "Invitación enviada a {0}."),
            .boiteCreee = T("Boîte {0} créée.", "Mailbox {0} created.", "Buzón {0} creado."),
            .prenom = T("Prénom", "First name", "Nombre"),
            .nom = T("Nom", "Last name", "Apellido"),
            .courriel = T("Courriel", "Email", "Correo"),
            .role = T("Rôle", "Role", "Rol"),
            .rAdmin = T("Administrateur", "Administrator", "Administrador"),
            .rEmploye = T("Employé", "Employee", "Empleado"),
            .rTech = T("Accès restreint", "Restricted access", "Acceso restringido"),
            .rSolo = T("Solo", "Solo", "Independiente"),
            .moi = T("vous", "you", "usted"),
            .superviseur = T("Superviseur", "Supervisor", "Supervisor"),
            .aucunSup = T("— Aucun superviseur —", "— No supervisor —", "— Sin supervisor —"),
            .supervise = T("Employés supervisés", "Supervised employees", "Empleados supervisados"),
            .envoyer = T("Envoyer l'invitation", "Send the invitation", "Enviar la invitación"),
            .invOk = T("Invitation envoyée. Lien d'activation :", "Invitation sent. Activation link:", "Invitación enviada. Enlace de activación:"),
            .copier = T("Copier le lien", "Copy link", "Copiar enlace"),
            .secComptables = T("Comptables", "Accountants", "Contadores"),
            .secTech = T("Techniciens", "Technicians", "Técnicos"),
            .videComptables = T("Aucun comptable.", "No accountant.", "Ningún contador."),
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
            .modifier = T("Modifier", "Edit", "Modificar"),
            .modifierTitre = T("Modifier {0}", "Edit {0}", "Modificar a {0}"),
            .actif = T("Compte actif", "Active account", "Cuenta activa"),
            .actifAide = T("Décoché : le membre ne peut plus se connecter ; ses dossiers restent confiés.",
                           "Unchecked: the member can no longer sign in; their files stay assigned.",
                           "Sin marcar: el miembro ya no puede conectarse; sus expedientes siguen confiados."),
            .dernierAdmin = T("Seul administrateur actif du cabinet : il garde un rôle de niveau Administrateur et reste actif. Nommez d'abord un autre administrateur.",
                              "Only active administrator of the firm: they keep an Administrator-level role and stay active. Appoint another administrator first.",
                              "Único administrador activo del despacho: conserva un rol de nivel Administrador y sigue activo. Nombre primero a otro administrador."),
            .mdp = T("Mot de passe", "Password", "Contraseña"),
            .mdpEnvoyer = T("Envoyer un courriel de changement de mot de passe", "Send a password change email", "Enviar un correo de cambio de contraseña"),
            .mdpAide = T("Le membre reçoit un lien valide 24 heures pour choisir un nouveau mot de passe ; l'actuel reste valable d'ici là.", "The member receives a link valid for 24 hours to choose a new password; the current one keeps working until then.", "El miembro recibe un enlace válido 24 horas para elegir una nueva contraseña; la actual sigue siendo válida hasta entonces."),
            .mdpAideAttente = T("Compte en attente d'activation : une nouvelle invitation sera envoyée pour choisir son mot de passe.", "Account awaiting activation: a new invitation will be sent to choose a password.", "Cuenta pendiente de activación: se enviará una nueva invitación para elegir su contraseña."),
            .mdpConf = T("Envoyer à {0} un courriel pour changer son mot de passe ?", "Send {0} an email to change their password?", "¿Enviar a {0} un correo para cambiar su contraseña?"),
            .actifAttente = T("En attente d'activation : le compte s'active quand le membre ouvre son lien d'invitation.",
                              "Awaiting activation: the account becomes active when the member opens their invitation link.",
                              "Pendiente de activación: la cuenta se activa cuando el miembro abre su enlace de invitación."),
            .emailMoi = T("Votre propre courriel ne se change pas ici.", "Your own email cannot be changed here.", "Su propio correo no se cambia aquí."),
            .inactif = T("inactif", "inactive", "inactivo"),
            .kInactifs = T("Inactifs", "Inactive", "Inactivos"),
            .confRole = T("Changer le rôle de {0} ?", "Change {0}'s role?", "¿Cambiar el rol de {0}?"),
            .dossiersDe = T("Dossiers confiés à {0}", "Files assigned to {0}", "Expedientes confiados a {0}"),
            .dejaA = T("actuellement suivi par {0}", "currently handled by {0}", "actualmente a cargo de {0}"),
            .enregistrer = T("Enregistrer", "Save", "Guardar"),
            .fermer = T("Fermer", "Close", "Cerrar"),
            .erreur = T("Une erreur est survenue.", "An error occurred.", "Se produjo un error."),
            .chargement = T("Chargement…", "Loading…", "Cargando…")
        }
    End Function
End Class
