Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

''' <summary>
''' Profil du cabinet (Portail comptable, admin/solo) — calqué sur la maquette, en
''' 8 onglets : Identification, Certification, Sécurité, Service, Clients et
''' visibilité, Offre de services, Organisation, Contacts.
'''
''' Données réelles : champs du cabinet (s0935/s0936 : nom, responsable,
''' coordonnées, langues, spécialités, accepter de nouveaux clients, fiche
''' publique→annuaire T319) ; MFA, étapes de certification et offre de services
''' (s0958/s0959, colonnes T331). Membres réels (s0922) pour l'organisation et
''' l'attribution. Le reste (garanties, remplaçants, contacts secondaires) est
''' illustratif. Rendu côté client ; sauvegarde par POST léger (op=save).
''' </summary>
Public Class wbfCabProfil
    Inherits clsData

    Protected WithEvents litData As System.Web.UI.WebControls.Literal
    Protected WithEvents litLabels As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        Dim role As String = RoleCabinet()
        If role <> "admin" AndAlso role <> "solo" Then
            Response.Redirect("~/wbfCabJournee.aspx") : Return
        End If

        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        If String.Equals(Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase) _
           AndAlso String.Equals(Request.Form("op"), "save", StringComparison.Ordinal) Then
            TraiterSave()
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

    Private Shared Function SVal(r As DataRow, col As String) As String
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return ""
        Return Convert.ToString(r(col))
    End Function

    Private Shared Function Initiales(nom As String) As String
        Dim sb As New Text.StringBuilder()
        For Each mot As String In If(nom, "").Split(New Char() {" "c, "-"c}, StringSplitOptions.RemoveEmptyEntries)
            If mot.Length > 0 AndAlso Char.IsLetter(mot(0)) Then sb.Append(Char.ToUpperInvariant(mot(0)))
            If sb.Length = 2 Then Exit For
        Next
        If sb.Length = 0 Then sb.Append("?"c)
        Return sb.ToString()
    End Function

    Private Sub Charger()
        ' --- Champs coeur (s0935) ---
        Dim nom = "", resp = "", desc = "", ville = "", prov = "", mail = "", tel = "", site = ""
        Dim langues = "", spec = ""
        Dim accepte As Boolean = False, publique As Boolean = False
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0935GetCabinetProfil", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                nom = SVal(r, "Nom") : resp = SVal(r, "Responsable") : desc = SVal(r, "Description")
                ville = SVal(r, "Ville") : prov = SVal(r, "Province") : mail = SVal(r, "Courriel")
                tel = SVal(r, "Telephone") : site = SVal(r, "SiteWeb")
                langues = SVal(r, "Langues") : spec = SVal(r, "Specialites")
                accepte = (Not IsDBNull(r("AccepteNouveauxClients"))) AndAlso Convert.ToBoolean(r("AccepteNouveauxClients"))
                publique = (Not IsDBNull(r("FichePublique"))) AndAlso Convert.ToBoolean(r("FichePublique"))
            End If
        Catch
        End Try

        ' --- Champs enrichis (s0958) ---
        Dim mfa As Boolean = False, certif As String = "", offre As String = ""
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0958GetCabinetProfilPlus", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                mfa = (Not IsDBNull(r("MfaObligatoire"))) AndAlso Convert.ToInt32(r("MfaObligatoire")) = 1
                certif = SVal(r, "CertifEtapes")
                offre = SVal(r, "OffreActivites")
            End If
        Catch
        End Try

        ' --- Membres réels (s0922) ---
        Dim membres As New List(Of Object)()
        Dim adminNom As String = resp
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0922ListCabinetMembres", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    Dim fn As String = Convert.ToString(r("FirstName")).Trim()
                    Dim ln As String = Convert.ToString(r("LastName")).Trim()
                    Dim mnom As String = (fn & " " & ln).Trim()
                    If mnom = "" Then mnom = Convert.ToString(r("Email")).Split("@"c)(0)
                    membres.Add(New With {.id = Convert.ToString(r("UserGUID")).ToLowerInvariant(), .ini = Initiales(mnom), .nom = mnom})
                    If Convert.ToBoolean(r("IsMe")) Then adminNom = mnom
                Next
            End If
        Catch
        End Try
        If adminNom = "" Then adminNom = If(nom <> "", nom, "Administrateur")

        Dim data As New Dictionary(Of String, Object) From {
            {"profil", New Dictionary(Of String, Object) From {
                {"nom", nom}, {"resp", resp}, {"desc", desc}, {"ville", ville}, {"prov", prov},
                {"mail", mail}, {"tel", tel}, {"site", site},
                {"langues", If(langues = "", New String() {}, langues.Split(","c))},
                {"spec", If(spec = "", New String() {}, spec.Split(","c))},
                {"accepte", accepte}, {"publique", publique}}},
            {"mfa", mfa},
            {"certif", certif},
            {"offre", offre},
            {"membres", membres},
            {"adminNom", adminNom},
            {"adminIni", Initiales(adminNom)}
        }
        Dim js As New JavaScriptSerializer() With {.MaxJsonLength = 16 * 1024 * 1024}
        litData.Text = js.Serialize(data)
        litLabels.Text = js.Serialize(Libelles())
    End Sub

    Private Sub TraiterSave()
        Dim ok As Boolean = False
        Try
            Dim js As New JavaScriptSerializer() With {.MaxJsonLength = 16 * 1024 * 1024}
            Dim data As Dictionary(Of String, Object) = js.Deserialize(Of Dictionary(Of String, Object))(Request.Form("data"))
            Dim core As Dictionary(Of String, Object) = CType(data("core"), Dictionary(Of String, Object))

            Dim nom As String = CStr(If(core("nom"), "")).Trim()
            If nom <> "" Then
                ' --- coeur (s0936) ---
                Dim p As New Collection
                p.Add(New SqlParameter("@UserId", UserEmail))
                p.Add(New SqlParameter("@Nom", nom))
                p.Add(New SqlParameter("@Responsable", Nz(core, "resp")))
                p.Add(New SqlParameter("@Description", Nz(core, "desc")))
                p.Add(New SqlParameter("@Ville", Nz(core, "ville")))
                p.Add(New SqlParameter("@Province", Nz(core, "prov")))
                p.Add(New SqlParameter("@Courriel", Nz(core, "mail")))
                p.Add(New SqlParameter("@Telephone", Nz(core, "tel")))
                p.Add(New SqlParameter("@SiteWeb", Nz(core, "site")))
                p.Add(New SqlParameter("@Langues", NzCsv(core, "langues")))
                p.Add(New SqlParameter("@Specialites", NzCsv(core, "spec")))
                p.Add(New SqlParameter("@AccepteNouveauxClients", CBool(core("accepte"))))
                p.Add(New SqlParameter("@FichePublique", CBool(core("publique"))))
                Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
                p.Add(outErr)
                ExecuteSQL("s0936SaveCabinetProfil", p)
                ok = (Not (outErr.Value Is Nothing OrElse IsDBNull(outErr.Value))) AndAlso CInt(outErr.Value) = 0

                ' --- enrichis (s0959) — isolé pour ne pas invalider la sauvegarde cœur ---
                Try
                    Dim p2 As New Collection
                    p2.Add(New SqlParameter("@UserId", UserEmail))
                    p2.Add(New SqlParameter("@Mfa", CBool(data("mfa"))))
                    p2.Add(New SqlParameter("@CertifEtapes", Nz2(CStr(If(data("certif"), "")))))
                    p2.Add(New SqlParameter("@OffreActivites", Nz2(CStr(If(data("offre"), "")))))
                    Dim outErr2 As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
                    p2.Add(outErr2)
                    ExecuteSQL("s0959SaveCabinetProfilPlus", p2)
                Catch
                End Try
            End If
        Catch
            ok = False
        End Try
        Response.Clear()
        Response.ContentType = "application/json"
        Response.Write("{""ok"":" & If(ok, "true", "false") & "}")
        Response.End()
    End Sub

    Private Shared Function Nz(d As Dictionary(Of String, Object), k As String) As Object
        Dim s As String = If(d.ContainsKey(k) AndAlso d(k) IsNot Nothing, Convert.ToString(d(k)).Trim(), "")
        Return If(s = "", CType(DBNull.Value, Object), s)
    End Function

    Private Shared Function Nz2(s As String) As Object
        Return If(String.IsNullOrEmpty(s), CType(DBNull.Value, Object), s)
    End Function

    ' Jointure d'un tableau JSON de codes en CSV (langues/spécialités).
    Private Shared Function NzCsv(d As Dictionary(Of String, Object), k As String) As Object
        If Not d.ContainsKey(k) OrElse d(k) Is Nothing Then Return CType(DBNull.Value, Object)
        Dim items As New List(Of String)()
        Dim seq = TryCast(d(k), System.Collections.IEnumerable)
        If seq IsNot Nothing Then
            For Each o As Object In seq
                Dim v As String = Convert.ToString(o).Trim()
                If v <> "" Then items.Add(v)
            Next
        End If
        Return If(items.Count = 0, CType(DBNull.Value, Object), String.Join(",", items))
    End Function

    Private Function Libelles() As Dictionary(Of String, String)
        Return New Dictionary(Of String, String) From {
            {"titre", T("Profil du cabinet", "Firm profile", "Perfil del despacho")},
            {"chapeau", T("Ce que vos clients et 60secondes savent de votre cabinet.", "What your clients and 60secondes know about your firm.", "Lo que sus clientes y 60secondes saben de su despacho.")},
            {"certifEnCours", T("Certification en cours", "Certification in progress", "Certificación en curso")},
            {"certifFait", T("Cabinet certifié", "Certified firm", "Despacho certificado")},
            {"tIdent", T("Identification", "Identification", "Identificación")},
            {"tCertif", T("Certification", "Certification", "Certificación")},
            {"tSecu", T("Sécurité", "Security", "Seguridad")},
            {"tService", T("Service", "Service", "Servicio")},
            {"tClients", T("Clients et visibilité", "Clients and visibility", "Clientes y visibilidad")},
            {"tOffre", T("Offre de services", "Service offering", "Oferta de servicios")},
            {"tOrga", T("Organisation", "Organization", "Organización")},
            {"tContacts", T("Contacts", "Contacts", "Contactos")},
            {"lNom", T("Nom du cabinet", "Firm name", "Nombre del despacho")},
            {"lResp", T("Responsable", "Lead", "Responsable")},
            {"lDesc", T("Description", "Description", "Descripción")},
            {"lVille", T("Ville", "City", "Ciudad")},
            {"lProv", T("Province", "Province", "Provincia")},
            {"lMail", T("Courriel", "Email", "Correo")},
            {"lTel", T("Téléphone", "Phone", "Teléfono")},
            {"lSite", T("Site web", "Website", "Sitio web")},
            {"enregistrer", T("Enregistrer", "Save", "Guardar")},
            {"enregistre", T("Profil enregistré.", "Profile saved.", "Perfil guardado.")},
            {"erreur", T("L'enregistrement a échoué.", "Save failed.", "El guardado falló.")},
            {"certifTitre", T("Certification 60secondes", "60secondes certification", "Certificación 60secondes")},
            {"certifEtapes", T("{n} sur {t} étapes", "{n} of {t} steps", "{n} de {t} pasos")},
            {"secuTitre", T("Sécurité et confidentialité", "Security and privacy", "Seguridad y confidencialidad")},
            {"mfaT", T("Double vérification obligatoire", "Mandatory two-factor", "Doble verificación obligatoria")},
            {"mfaS", T("Chaque membre confirme sa connexion avec son téléphone.", "Each member confirms sign-in with their phone.", "Cada miembro confirma su conexión con su teléfono.")},
            {"specTitre", T("Spécialités", "Specialties", "Especialidades")},
            {"specSous", T("les clientèles et secteurs que vous servez", "the clienteles and sectors you serve", "las clientelas y sectores que atiende")},
            {"langTitre", T("Langues de service", "Service languages", "Idiomas de servicio")},
            {"langSous", T("pour parler à vos clients", "to speak with your clients", "para hablar con sus clientes")},
            {"accepteT", T("Accepter de nouveaux clients", "Accept new clients", "Aceptar nuevos clientes")},
            {"accepteS", T("Les entreprises qui cherchent un comptable peuvent vous choisir.", "Businesses looking for an accountant can choose you.", "Las empresas que buscan un contador pueden elegirle.")},
            {"accepteOn", T("Ouvert aux nouveaux clients", "Open to new clients", "Abierto a nuevos clientes")},
            {"accepteOff", T("Fermé aux nouveaux clients", "Closed to new clients", "Cerrado a nuevos clientes")},
            {"publiqueT", T("Fiche visible dans l'annuaire", "Profile visible in the directory", "Ficha visible en el directorio")},
            {"publiqueS", T("Votre cabinet apparaît dans « Cabinets certifiés » des entreprises.", "Your firm appears in businesses' « Certified firms » directory.", "Su despacho aparece en « Despachos certificados ».")},
            {"publiqueOn", T("Visible", "Visible", "Visible")},
            {"publiqueOff", T("Masquée", "Hidden", "Oculta")},
            {"apercuTitre", T("CE QUE VOIENT LES ENTREPRISES", "WHAT BUSINESSES SEE", "LO QUE VEN LAS EMPRESAS")},
            {"offreTitre", T("Votre offre, activité par activité", "Your offering, activity by activity", "Su oferta, actividad por actividad")},
            {"offreIntro", T("60secondes isole chaque activité. Vous choisissez celles que vous offrez, puis vous décidez qui les fait.", "60secondes isolates each activity. You choose the ones you offer, then decide who does them.", "60secondes aísla cada actividad. Elige las que ofrece, luego decide quién las hace.")},
            {"etape1", T("Ce que nous offrons", "What we offer", "Lo que ofrecemos")},
            {"etape2", T("Qui le fait", "Who does it", "Quién lo hace")},
            {"etape2S", T("Équipes et personnes", "Teams and people", "Equipos y personas")},
            {"toutOffrir", T("Tout offrir", "Offer all", "Ofrecer todo")},
            {"offertesSur", T("offertes sur", "offered of", "ofrecidas de")},
            {"offreAide", T("Les activités faites par 60 ou réservées au client ne sont pas dans votre offre.", "Activities done by 60 or reserved to the client are not in your offering.", "Las actividades hechas por 60 o reservadas al cliente no están en su oferta.")},
            {"activitesAttribuer", T("Activités à attribuer", "Activities to assign", "Actividades por asignar")},
            {"couvertes", T("couvertes", "covered", "cubiertas")},
            {"nonAttribuees", T("non attribuées", "unassigned", "sin asignar")},
            {"aEquipe", T("à toute l'équipe", "to whole team", "a todo el equipo")},
            {"attribuerA", T("Attribuer à", "Assign to", "Asignar a")},
            {"touteEquipe", T("Toute l'équipe", "Whole team", "Todo el equipo")},
            {"membres", T("membres", "members", "miembros")},
            {"attribuees", T("attribuées", "assigned", "asignadas")},
            {"horsCabinet", T("Hors cabinet", "Outside firm", "Fuera del despacho")},
            {"nonAttribuee", T("Non attribuée", "Unassigned", "Sin asignar")},
            {"respClient", T("Client", "Client", "Cliente")},
            {"respCab", T("Cabinet", "Firm", "Despacho")},
            {"respCc", T("Cabinet et client", "Firm and client", "Despacho y cliente")},
            {"resp60", T("60", "60", "60")},
            {"orgaTitre", T("Votre cabinet", "Your firm", "Su despacho")},
            {"orgaSous", T("Les membres de votre cabinet.", "The members of your firm.", "Los miembros de su despacho.")},
            {"responsable", T("Responsable", "Lead", "Responsable")},
            {"sansRemplacant", T("sans remplaçant planifié", "without a planned backup", "sin reemplazo planificado")},
            {"contactsTitre", T("Personnes-ressources", "Key contacts", "Personas de contacto")},
            {"contactAdmin", T("ADMINISTRATEUR DU CABINET", "FIRM ADMINISTRATOR", "ADMINISTRADOR DEL DESPACHO")},
            {"contactAdminS", T("seul à pouvoir modifier ce profil", "only one who can edit this profile", "único que puede modificar este perfil")},
            {"contactLoi25", T("RESPONSABLE DE LA PROTECTION DES RENSEIGNEMENTS (LOI 25)", "PRIVACY OFFICER (LAW 25)", "RESPONSABLE DE PROTECCIÓN DE DATOS (LEY 25)")},
            {"contactLoi25S", T("désigné par défaut, modifiable", "designated by default, editable", "designado por defecto, modificable")},
            {"contact60", T("CONTACT POUR 60SECONDES", "CONTACT FOR 60SECONDES", "CONTACTO PARA 60SECONDES")},
            {"contact60S", T("reçoit les messages de certifies@60secondes.ca", "receives messages from certifies@60secondes.ca", "recibe los mensajes de certifies@60secondes.ca")},
            {"garantie1T", T("Données hébergées au Canada", "Data hosted in Canada", "Datos alojados en Canadá")},
            {"garantie1S", T("Elles ne quittent jamais le Canada.", "They never leave Canada.", "Nunca salen de Canadá.")},
            {"garantie2T", T("Journal de chaque action", "Log of every action", "Registro de cada acción")},
            {"garantie2S", T("Tout ce qui est fait au nom d'un client est conservé et consultable.", "Everything done on a client's behalf is kept and auditable.", "Todo lo hecho en nombre de un cliente se conserva y es consultable.")},
            {"garantie3T", T("Accès limité à ce que le client autorise", "Access limited to what the client allows", "Acceso limitado a lo que el cliente autoriza")},
            {"garantie3S", T("Chaque client choisit ce que votre cabinet peut voir et faire.", "Each client chooses what your firm can see and do.", "Cada cliente elige lo que su despacho puede ver y hacer.")},
            {"resume", T("responsable", "lead", "responsable")},
            {"ouvertAux", T("accepte de nouveaux clients", "accepts new clients", "acepta nuevos clientes")},
            {"fermeAux", T("n'accepte pas de nouveaux clients", "does not accept new clients", "no acepta nuevos clientes")},
            {"pasAnnuaire", T("n'apparaît pas dans l'annuaire des cabinets certifiés.", "does not appear in the certified firms directory.", "no aparece en el directorio de despachos certificados.")},
            {"specialites", T("spécialités", "specialties", "especialidades")},
            {"serviceEn", T("service en", "service in", "servicio en")},
            {"specTravailleurs", T("Travailleurs autonomes", "Self-employed", "Autónomos")},
            {"specSocietes", T("Sociétés", "Corporations", "Sociedades")},
            {"specPaie", T("Paie et employés", "Payroll", "Nómina")},
            {"specConstr", T("Construction", "Construction", "Construcción")},
            {"specSante", T("Santé et services", "Health and services", "Salud y servicios")},
            {"langFr", T("Français", "French", "Francés")},
            {"langEn", T("Anglais", "English", "Inglés")},
            {"langEs", T("Espagnol", "Spanish", "Español")}
        }
    End Function

End Class
