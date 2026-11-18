Imports System.Globalization
Imports System.Web.Script.Serialization

''' <summary>
''' Importation 2 — nouvelle page de reprise d'une comptabilité tenue ailleurs,
''' en étapes (maquette « Importation des données » du 16 nov. 2026). La page
''' d'origine, Importations.aspx, reste intacte.
'''
''' Étape 1 : choisir le logiciel comptable source.
''' Étape 2 : relier la source — connexion Apideck (Vault) en lecture seule pour
'''           les logiciels en ligne, ou exports CSV à préparer ; date de bascule
'''           et fréquence des taxes. QuickBooks Desktop (Web Connector) et Odoo
'''           (clé d'API) n'ont pas encore de connecteur : la page le dit.
''' Les choix sont gardés en session, par compagnie, en attendant les étapes
''' suivantes (plan comptable, balance, tiers et catalogue, factures et taxes,
''' contrôle).
'''
''' Rendu côté client : les données et les libellés (fr/en/es) sont injectés en
''' JSON ; les actions passent par un POST léger op=… qui répond en JSON.
''' </summary>
Public Class Importation2
    Inherits clsData

    Protected WithEvents litData As System.Web.UI.WebControls.Literal
    Protected WithEvents litLabels As System.Web.UI.WebControls.Literal

    ' Logiciels acceptés (clés de la maquette) et leur façon de se relier
    Private Shared ReadOnly Logiciels As String() = {"qbo", "qbd", "xero", "sagebca", "fresh", "wave", "zoho", "odoo", "sage50", "acomba", "autre"}
    Private Shared ReadOnly ParFichierSeulement As String() = {"sage50", "acomba", "autre"}
    Private Shared ReadOnly Frequences As String() = {"trimestre", "mois", "annee"}

    ''' <summary>Le service Apideck (Vault) de chaque logiciel lu en direct par OAuth.</summary>
    Private Shared ReadOnly ServicesApideck As New Dictionary(Of String, String) From {
        {"qbo", "quickbooks"}, {"xero", "xero"}, {"sagebca", "sage-business-cloud-accounting"},
        {"fresh", "freshbooks"}, {"wave", "wave"}, {"zoho", "zoho-books"}}

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        DirectCast(Master, SiteMaster).FondDePage = True

        If String.Equals(Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase) Then
            Dim op As String = Convert.ToString(Request.Form("op"))
            If op <> "" Then
                Traiter(op) : Return
            End If
        End If

        litData.Text = Json(Etat())
        litLabels.Text = Json(Libelles())
    End Sub

#Region "État en session (par compagnie)"

    Private Function Cle(nom As String) As String
        Return "Imp2|" & nom & "|" & Company.ToString()
    End Function

    Private Property Logiciel As String
        Get
            Dim v As String = Convert.ToString(Session(Cle("logiciel")))
            Return If(Array.IndexOf(Logiciels, v) >= 0, v, Nothing)
        End Get
        Set(value As String)
            Session(Cle("logiciel")) = value
        End Set
    End Property

    ''' <summary>« direct » ou « fichier ».</summary>
    Private Property Mode As String
        Get
            If Logiciel IsNot Nothing AndAlso Array.IndexOf(ParFichierSeulement, Logiciel) >= 0 Then Return "fichier"
            Return If(Convert.ToString(Session(Cle("mode"))) = "fichier", "fichier", "direct")
        End Get
        Set(value As String)
            Session(Cle("mode")) = value
        End Set
    End Property

    Private Property Bascule As String
        Get
            Return Convert.ToString(Session(Cle("bascule")))
        End Get
        Set(value As String)
            Session(Cle("bascule")) = value
        End Set
    End Property

    Private Property Frequence As String
        Get
            Dim v As String = Convert.ToString(Session(Cle("freq")))
            Return If(Array.IndexOf(Frequences, v) >= 0, v, "trimestre")
        End Get
        Set(value As String)
            Session(Cle("freq")) = value
        End Set
    End Property

    ''' <summary>Étape 2 franchie : source reliée (direct) ou exports annoncés (fichier).</summary>
    Private Property Relie As Boolean
        Get
            Return Session(Cle("relie")) IsNot Nothing AndAlso CBool(Session(Cle("relie")))
        End Get
        Set(value As Boolean)
            Session(Cle("relie")) = value
        End Set
    End Property

    Private Sub ToutOublier()
        For Each n As String In {"logiciel", "mode", "bascule", "freq", "relie"}
            Session.Remove(Cle(n))
        Next
    End Sub

    Private Function Etat() As Object
        Return New With {.logiciel = Logiciel, .mode = Mode, .bascule = Bascule, .freq = Frequence, .relie = Relie}
    End Function

#End Region

#Region "Actions (POST op=…)"

    Private Sub Traiter(op As String)
        Dim res As Object
        Try
            Select Case op
                Case "source" : res = ChoisirLogiciel(Convert.ToString(Request.Form("logiciel")).Trim().ToLowerInvariant())
                Case "mode" : res = ChoisirMode(Convert.ToString(Request.Form("mode")))
                Case "reglages" : res = Reglages()
                Case "connexion" : res = Connecter()
                Case "etatConnexion" : res = EtatConnexion()
                Case "fichiers" : res = PasserAuxFichiers()
                Case "retour" : Relie = False : res = New With {.ok = True, .etat = Etat()}
                Case "vider" : ToutOublier() : res = New With {.ok = True}
                Case Else : res = New With {.ok = False, .erreur = T("Action inconnue.", "Unknown action.", "Acción desconocida.")}
            End Select
        Catch ex As Exception
            res = New With {.ok = False, .erreur = T("L'action n'a pas pu être faite : ", "The action could not be done: ", "No se pudo realizar la acción: ") & ex.Message}
        End Try
        Response.Clear()
        Response.ContentType = "application/json; charset=utf-8"
        Response.Write(Json(res))
        Context.ApplicationInstance.CompleteRequest()
        Response.End()
    End Sub

    Private Function SansLogiciel() As Object
        Return New With {.ok = False, .erreur = T("Choisissez d'abord le logiciel.", "Choose the software first.", "Elija primero el software.")}
    End Function

    Private Function ChoisirLogiciel(k As String) As Object
        If Array.IndexOf(Logiciels, k) < 0 Then Return New With {.ok = False, .erreur = T("Logiciel inconnu.", "Unknown software.", "Software desconocido.")}
        Logiciel = k
        Mode = If(Array.IndexOf(ParFichierSeulement, k) >= 0, "fichier", "direct")
        Relie = False
        Return New With {.ok = True, .etat = Etat()}
    End Function

    Private Function ChoisirMode(m As String) As Object
        If Logiciel Is Nothing Then Return SansLogiciel()
        Mode = If(m = "fichier", "fichier", "direct")
        Relie = False
        Return New With {.ok = True, .etat = Etat()}
    End Function

    ''' <summary>Date de bascule (AAAA-MM-JJ, obligatoire) et fréquence des taxes.</summary>
    Private Function LireReglages(ByRef erreur As String) As Boolean
        Dim d As String = Convert.ToString(Request.Form("bascule")).Trim()
        Dim f As String = Convert.ToString(Request.Form("freq")).Trim()
        Dim dt As Date
        If Not Date.TryParseExact(d, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, dt) Then
            erreur = T("Indiquez la date de bascule : la veille du premier jour tenu dans 60secondes.",
                       "Enter the switch-over date: the day before the first day kept in 60secondes.",
                       "Indique la fecha de cambio: el día anterior al primer día llevado en 60secondes.")
            Return False
        End If
        If dt > Date.Today.AddYears(1) OrElse dt < New Date(2000, 1, 1) Then
            erreur = T("La date de bascule semble incorrecte.", "The switch-over date looks wrong.", "La fecha de cambio parece incorrecta.")
            Return False
        End If
        Bascule = dt.ToString("yyyy-MM-dd")
        If Array.IndexOf(Frequences, f) >= 0 Then Frequence = f
        Return True
    End Function

    Private Function Reglages() As Object
        Dim err As String = ""
        If Not LireReglages(err) Then Return New With {.ok = False, .erreur = err}
        Return New With {.ok = True}
    End Function

    ''' <summary>
    ''' Relier la source en direct. Logiciels en ligne : session Vault d'Apideck
    ''' (la page où l'usager entre ses identifiants chez l'éditeur ; nous ne les
    ''' voyons jamais) — même consommateur que l'écran ImportApideck : le
    ''' CompanyGUID. QuickBooks Desktop et Odoo : pas encore de connecteur.
    ''' </summary>
    Private Function Connecter() As Object
        Dim err As String = ""
        If Logiciel Is Nothing Then Return SansLogiciel()
        If Not LireReglages(err) Then Return New With {.ok = False, .erreur = err}

        If Logiciel = "qbd" Then
            Return New With {.ok = False, .erreur = T("La liaison QuickBooks Desktop (Web Connector) n'est pas encore offerte. En attendant, choisissez « Je préfère déposer des fichiers ».",
                                                    "The QuickBooks Desktop link (Web Connector) is not available yet. In the meantime, choose ""I'd rather drop files"".",
                                                    "La conexión QuickBooks Desktop (Web Connector) aún no está disponible. Mientras tanto, elija «Prefiero depositar archivos».")}
        End If
        If Logiciel = "odoo" Then
            Return New With {.ok = False, .erreur = T("La liaison Odoo par clé d'API n'est pas encore offerte. En attendant, choisissez « Je préfère déposer des fichiers ». Votre clé n'a pas été conservée.",
                                                    "The Odoo API-key link is not available yet. In the meantime, choose ""I'd rather drop files"". Your key was not kept.",
                                                    "La conexión Odoo por clave de API aún no está disponible. Mientras tanto, elija «Prefiero depositar archivos». Su clave no se conservó.")}
        End If
        If Not ServicesApideck.ContainsKey(Logiciel) Then
            Return New With {.ok = False, .erreur = T("Ce logiciel se reprend par fichiers.", "This software is migrated by files.", "Este software se migra por archivos.")}
        End If
        If Not clsApideck.IsConfigured() Then
            Return New With {.ok = False, .erreur = T("La connexion en direct n'est pas configurée sur ce serveur. Choisissez « Je préfère déposer des fichiers ».",
                                                    "Live connection is not configured on this server. Choose ""I'd rather drop files"".",
                                                    "La conexión en directo no está configurada en este servidor. Elija «Prefiero depositar archivos».")}
        End If

        Dim api As New clsApideck(Company.ToString())
        Dim url As String
        Try
            url = api.CreateVaultSession(CompanyName)
        Catch ex As ApideckHttpException When ex.CodeHttp = 402 OrElse ex.CodeHttp = 401 OrElse ex.CodeHttp = 403
            ' Forfait Apideck expiré ou clé refusée : un message pour l'entrepreneur, pas le texte technique
            Return New With {.ok = False, .erreur = T("La connexion en direct est momentanément indisponible (abonnement du service de connexion à renouveler). Choisissez « Je préfère déposer des fichiers » pour continuer.",
                                                    "Live connection is temporarily unavailable (the connection service subscription must be renewed). Choose ""I'd rather drop files"" to continue.",
                                                    "La conexión en directo no está disponible por el momento (la suscripción del servicio de conexión debe renovarse). Elija «Prefiero depositar archivos» para continuar."),
                          .code = ex.CodeHttp}
        End Try
        If String.IsNullOrEmpty(url) Then
            Return New With {.ok = False, .erreur = T("Apideck n'a pas rendu d'adresse de connexion.", "Apideck returned no connection address.", "Apideck no devolvió una dirección de conexión.")}
        End If
        Return New With {.ok = True, .url = url}
    End Function

    ''' <summary>Sondé par la page pendant que l'usager autorise la lecture chez l'éditeur.</summary>
    Private Function EtatConnexion() As Object
        If Logiciel Is Nothing OrElse Not ServicesApideck.ContainsKey(Logiciel) Then Return New With {.ok = True, .statut = "attente"}
        Dim api As New clsApideck(Company.ToString())
        Dim relieChez As Boolean
        Try
            relieChez = api.IsConnected(ServicesApideck(Logiciel))
        Catch ex As ApideckHttpException When ex.CodeHttp = 402 OrElse ex.CodeHttp = 401 OrElse ex.CodeHttp = 403
            Return New With {.ok = False, .erreur = T("La connexion en direct est momentanément indisponible (abonnement du service de connexion à renouveler). Choisissez « Je préfère déposer des fichiers » pour continuer.",
                                                    "Live connection is temporarily unavailable (the connection service subscription must be renewed). Choose ""I'd rather drop files"" to continue.",
                                                    "La conexión en directo no está disponible por el momento (la suscripción del servicio de conexión debe renovarse). Elija «Prefiero depositar archivos» para continuar."),
                          .code = ex.CodeHttp}
        End Try
        If relieChez Then
            Relie = True
            Return New With {.ok = True, .statut = "connecte", .etat = Etat()}
        End If
        Return New With {.ok = True, .statut = "attente"}
    End Function

    ''' <summary>Mode fichier : les réglages sont retenus, on passe au dépôt des exports.</summary>
    Private Function PasserAuxFichiers() As Object
        Dim err As String = ""
        If Logiciel Is Nothing Then Return SansLogiciel()
        If Not LireReglages(err) Then Return New With {.ok = False, .erreur = err}
        Mode = "fichier"
        Relie = True
        Return New With {.ok = True, .etat = Etat()}
    End Function

#End Region

    Private Shared Function Json(o As Object) As String
        Return New JavaScriptSerializer().Serialize(o)
    End Function

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Function Libelles() As Object
        Return New With {
            .titre = T("Importation des données", "Data import", "Importación de datos"),
            .sousTitre = T("Reprendre une comptabilité tenue ailleurs, dans 60secondes", "Bring accounting kept elsewhere into 60secondes", "Traer a 60secondes una contabilidad llevada en otro lugar"),
            .demo = T("Démonstration · données fictives", "Demo · sample data", "Demostración · datos ficticios"),
            .demoTip = T("Les étapes 3 à 7 ne sont pas encore branchées : rien n'est écrit dans votre comptabilité.", "Steps 3 to 7 are not connected yet: nothing is written to your accounting.", "Los pasos 3 a 7 aún no están conectados: no se escribe nada en su contabilidad."),
            .vider = T("Vider la préparation", "Clear the preparation", "Vaciar la preparación"),
            .viderTip = T("Efface ce qui attend d'être validé ; rien de ce qui est déjà passé en comptabilité n'est retiré", "Clears what is waiting to be validated; nothing already in the accounting is removed", "Borra lo que espera validación; no se retira nada de lo que ya está en la contabilidad"),
            .viderConfirme = T("Tout ce qui attend d'être validé sera effacé, y compris le logiciel choisi et la date de bascule. Rien de ce qui est déjà passé en comptabilité n'est retiré.", "Everything waiting to be validated will be cleared, including the chosen software and the switch-over date. Nothing already in the accounting is removed.", "Se borrará todo lo que espera validación, incluidos el software elegido y la fecha de cambio. No se retira nada de lo que ya está en la contabilidad."),
            .changer = T("Changer", "Change", "Cambiar"),
            .origine = T("Origine", "Source", "Origen"),
            .aChoisir = T("À choisir", "To choose", "Por elegir"),
            .origineVia = T("Votre logiciel comptable actuel", "Your current accounting software", "Su software contable actual"),
            .viaDirect = T("En direct · non relié", "Live · not connected", "En directo · no conectado"),
            .viaRelie = T("En direct · relié", "Live · connected", "En directo · conectado"),
            .viaFichiers = T("Par fichiers CSV", "By CSV files", "Por archivos CSV"),
            .destination = T("Destination", "Destination", "Destino"),
            .destVia = T("Québec et Canada", "Québec and Canada", "Quebec y Canadá"),
            .enAttente = T("En attente", "Waiting", "En espera"),
            .fluxRelie = T("Source reliée", "Source connected", "Origen conectado"),
            .fluxFichiers = T("Fichiers à déposer", "Files to drop", "Archivos por depositar"),
            .stRes = T("ressources rapatriées", "resources brought back", "recursos recuperados"),
            .stImp = T("imports obligatoires", "required imports", "importaciones obligatorias"),
            .stEnr = T("enregistrements lus", "records read", "registros leídos"),
            .stSaisie = T("de saisie manuelle évitée*", "of manual entry avoided*", "de captura manual evitada*"),
            .e1 = T("Logiciel", "Software", "Software"),
            .e2 = T("Connexion", "Connection", "Conexión"),
            .e2Fichiers = T("Fichiers", "Files", "Archivos"),
            .e3 = T("Plan comptable", "Chart of accounts", "Plan contable"),
            .e4 = T("Balance", "Trial balance", "Balanza"),
            .e5 = T("Tiers et catalogue", "Parties and catalog", "Terceros y catálogo"),
            .e6 = T("Factures et taxes", "Invoices and taxes", "Facturas e impuestos"),
            .e7 = T("Contrôle", "Review", "Control"),
            .bonjour = T("Bonjour", "Hello", "Hola"),
            .bonjourTexte = T("Je vais reprendre votre comptabilité dans 60secondes. Pour commencer, dites-moi d'où elle vient.", "I will bring your accounting into 60secondes. To start, tell me where it comes from.", "Voy a traer su contabilidad a 60secondes. Para empezar, dígame de dónde viene."),
            .etapeNsur7 = T("Étape {0} sur 7", "Step {0} of 7", "Paso {0} de 7"),
            .question = T("Quel logiciel comptable quittez-vous ?", "Which accounting software are you leaving?", "¿Qué software contable deja?"),
            .lead = T("60 choisit la bonne connexion : lecture en direct quand le logiciel le permet, sinon les exports à déposer, écran par écran.", "60 picks the right connection: live reading when the software allows it, otherwise exports to drop, screen by screen.", "60 elige la conexión adecuada: lectura en directo cuando el software lo permite; si no, exportaciones para depositar, pantalla por pantalla."),
            .noteAutre = T("Vous ne savez pas ? Choisissez « Autre logiciel ou Excel » : 60 reconnaît les colonnes en français, en anglais et en espagnol.", "Not sure? Choose ""Other software or Excel"": 60 recognizes columns in French, English and Spanish.", "¿No lo sabe? Elija «Otro software o Excel»: 60 reconoce las columnas en francés, inglés y español."),
            .enDirect = T("En direct", "Live", "En directo"),
            .parFichier = T("Par fichier", "By file", "Por archivo"),
            .sageEnLigne = T("Sage Comptabilité (en ligne)", "Sage Accounting (online)", "Sage Contabilidad (en línea)"),
            .sage50 = T("Sage 50 (Canada)", "Sage 50 (Canada)", "Sage 50 (Canadá)"),
            .autre = T("Autre logiciel ou Excel", "Other software or Excel", "Otro software o Excel"),
            .ligne_qbo = T("Connexion Intuit, lecture seule", "Intuit connection, read-only", "Conexión Intuit, solo lectura"),
            .ligne_qbd = T("Web Connector sur le poste QuickBooks", "Web Connector on the QuickBooks computer", "Web Connector en el equipo de QuickBooks"),
            .ligne_xero = T("Connexion Xero, lecture seule", "Xero connection, read-only", "Conexión Xero, solo lectura"),
            .ligne_sagebca = T("Connexion Sage, lecture seule", "Sage connection, read-only", "Conexión Sage, solo lectura"),
            .ligne_fresh = T("Connexion FreshBooks, lecture seule", "FreshBooks connection, read-only", "Conexión FreshBooks, solo lectura"),
            .ligne_wave = T("Connexion Wave, lecture seule", "Wave connection, read-only", "Conexión Wave, solo lectura"),
            .ligne_zoho = T("Connexion Zoho, lecture seule", "Zoho connection, read-only", "Conexión Zoho, solo lectura"),
            .ligne_odoo = T("Adresse de l'instance et clé d'API", "Instance address and API key", "Dirección de la instancia y clave de API"),
            .ligne_sage50 = T("Exports CSV, un par écran", "CSV exports, one per screen", "Exportaciones CSV, una por pantalla"),
            .ligne_acomba = T("Exports CSV, un par écran", "CSV exports, one per screen", "Exportaciones CSV, una por pantalla"),
            .ligne_autre = T("Exports CSV, colonnes reconnues", "CSV exports, columns recognized", "Exportaciones CSV, columnas reconocidas"),
            .enregistrement = T("J'enregistre votre choix…", "Saving your choice…", "Guardo su elección…"),
            .erreur = T("Erreur", "Error", "Error"),
            .erreurTexte = T("L'action n'a pas pu être faite. Réessayez.", "The action could not be done. Try again.", "No se pudo realizar la acción. Inténtelo de nuevo."),
            .aCompleter = T("À compléter", "To complete", "Por completar"),
            .etape2Connexion = T("Étape 2 · Connexion", "Step 2 · Connection", "Paso 2 · Conexión"),
            .etape2Fichiers = T("Étape 2 · Fichiers", "Step 2 · Files", "Paso 2 · Archivos"),
            .relierTitre = T("Relier {n}", "Connect {n}", "Conectar {n}"),
            .relierLead = T("Lecture en direct : aucun fichier à exporter.", "Live reading: no file to export.", "Lectura en directo: ningún archivo que exportar."),
            .exportsTitre = T("Les exports à préparer depuis {n}", "The exports to prepare from {n}", "Las exportaciones que preparar desde {n}"),
            .exportsLead = T("Vous déposerez un export par écran, dans l'ordre. Le plan comptable d'abord.", "You will drop one export per screen, in order. The chart of accounts first.", "Depositará una exportación por pantalla, en orden. El plan contable primero."),
            .oa1 = T("Vous vous connectez chez {w}", "You sign in at {w}", "Usted se conecta en {w}"),
            .oa1d = T("Une fenêtre {w} s'ouvre ; vous y entrez vos identifiants, jamais dans 60secondes.", "A {w} window opens; you enter your credentials there, never in 60secondes.", "Se abre una ventana de {w}; allí ingresa sus credenciales, nunca en 60secondes."),
            .oa2 = T("Vous autorisez la lecture seule", "You allow read-only access", "Usted autoriza la solo lectura"),
            .oa2d = T("60secondes lit ; il n'écrit rien dans {n}. La liaison se fait une fois par compagnie.", "60secondes reads; it writes nothing in {n}. The link is made once per company.", "60secondes lee; no escribe nada en {n}. La conexión se hace una vez por compañía."),
            .oa3 = T("60 rapatrie tout en préparation", "60 brings everything into preparation", "60 trae todo a preparación"),
            .oa3d = T("Plan, balance, tiers, articles, factures, taxes. Rien n'entre dans vos livres sans votre accord.", "Chart, balance, parties, items, invoices, taxes. Nothing enters your books without your approval.", "Plan, balanza, terceros, artículos, facturas, impuestos. Nada entra en sus libros sin su acuerdo."),
            .qb1 = T("Téléchargez le fichier de liaison (.qwc)", "Download the link file (.qwc)", "Descargue el archivo de conexión (.qwc)"),
            .qb1d = T("Sur le poste où QuickBooks Desktop est installé.", "On the computer where QuickBooks Desktop is installed.", "En el equipo donde está instalado QuickBooks Desktop."),
            .qb2 = T("Ouvrez-le dans QuickBooks Web Connector", "Open it in QuickBooks Web Connector", "Ábralo en QuickBooks Web Connector"),
            .qb2d = T("Fichier ▸ Mise à jour des applications Web ▸ Ajouter une application, puis acceptez l'accès en lecture.", "File ▸ Update Web Services ▸ Add an application, then accept read access.", "Archivo ▸ Actualizar servicios web ▸ Agregar una aplicación y acepte el acceso de lectura."),
            .qb3 = T("Entrez le mot de passe de liaison", "Enter the link password", "Ingrese la contraseña de conexión"),
            .qb3d = T("Celui affiché ici. Il ne sert qu'à cette liaison.", "The one shown here. It is used only for this link.", "La que se muestra aquí. Solo sirve para esta conexión."),
            .qb4 = T("Cochez 60secondes et cliquez sur « Mettre à jour la sélection »", "Check 60secondes and click ""Update Selected""", "Marque 60secondes y haga clic en «Actualizar selección»"),
            .qb4d = T("QuickBooks doit rester ouvert sur la compagnie pendant la lecture.", "QuickBooks must stay open on the company during the reading.", "QuickBooks debe permanecer abierto en la compañía durante la lectura."),
            .od1 = T("Dans Odoo, créez une clé d'API", "In Odoo, create an API key", "En Odoo, cree una clave de API"),
            .od1d = T("Mon profil ▸ Sécurité du compte ▸ Nouvelle clé d'API. Nommez-la, par exemple « 60secondes ».", "My profile ▸ Account security ▸ New API key. Name it, for example ""60secondes"".", "Mi perfil ▸ Seguridad de la cuenta ▸ Nueva clave de API. Nómbrela, por ejemplo «60secondes»."),
            .od2 = T("Indiquez l'adresse de votre Odoo et la base", "Enter your Odoo address and database", "Indique la dirección de su Odoo y la base"),
            .od2d = T("L'adresse commence par https://.", "The address starts with https://.", "La dirección empieza por https://."),
            .od3 = T("60 vérifie la liaison et lit en préparation", "60 checks the link and reads into preparation", "60 verifica la conexión y lee en preparación"),
            .od3d = T("Plan, balance, partenaires, articles, factures et taxes.", "Chart, balance, partners, items, invoices and taxes.", "Plan, balanza, socios, artículos, facturas e impuestos."),
            .date = T("Date de bascule", "Switch-over date", "Fecha de cambio"),
            .dateAide = T("La veille du premier jour tenu dans 60secondes. La balance est arrêtée à cette date.", "The day before the first day kept in 60secondes. The trial balance is struck at this date.", "El día anterior al primer día llevado en 60secondes. La balanza se cierra en esta fecha."),
            .taxes = T("Taxes déclarées", "Taxes filed", "Impuestos declarados"),
            .trimestre = T("par trimestre", "quarterly", "por trimestre"),
            .mois = T("par mois", "monthly", "por mes"),
            .annee = T("par année", "yearly", "por año"),
            .seConnecter = T("Se connecter à {w}", "Sign in to {w}", "Conectarse a {w}"),
            .securiteOauth = T("Connexion chiffrée par Apideck. Vous pouvez retirer l'accès en tout temps chez {w}.", "Connection encrypted by Apideck. You can remove access at any time at {w}.", "Conexión cifrada por Apideck. Puede retirar el acceso en cualquier momento en {w}."),
            .preparerLiaison = T("Préparer la liaison", "Prepare the link", "Preparar la conexión"),
            .securiteQbd = T("Le Web Connector parle à Apideck en lecture seule ; rien n'est modifié dans QuickBooks.", "The Web Connector talks to Apideck read-only; nothing is changed in QuickBooks.", "El Web Connector habla con Apideck en solo lectura; no se modifica nada en QuickBooks."),
            .adresseOdoo = T("Adresse d'Odoo", "Odoo address", "Dirección de Odoo"),
            .base = T("Base de données", "Database", "Base de datos"),
            .utilisateur = T("Utilisateur", "User", "Usuario"),
            .cleApi = T("Clé d'API", "API key", "Clave de API"),
            .verifier = T("Vérifier et se connecter", "Check and connect", "Verificar y conectarse"),
            .securiteOdoo = T("La clé ne donne que les droits de l'utilisateur Odoo choisi ; révocable dans Odoo en tout temps.", "The key only grants the chosen Odoo user's rights; revocable in Odoo at any time.", "La clave solo da los derechos del usuario de Odoo elegido; revocable en Odoo en cualquier momento."),
            .odooManque = T("Il manque un renseignement : l'adresse doit commencer par https://, et la base, l'utilisateur et la clé sont requis.", "Something is missing: the address must start with https://, and the database, user and key are required.", "Falta un dato: la dirección debe empezar por https://, y la base, el usuario y la clave son obligatorios."),
            .accepte = T("Ce que 60 accepte", "What 60 accepts", "Lo que 60 acepta"),
            .accepteAide = T("Fichiers CSV ou texte, 10 Mo au plus. Séparateur et encodage (UTF-8 ou Windows-1252) détectés seuls. Les lignes de titre, de total et de pied de page sont écartées.", "CSV or text files, 10 MB max. Separator and encoding (UTF-8 or Windows-1252) detected automatically. Title, total and footer lines are set aside.", "Archivos CSV o de texto, 10 MB como máximo. Separador y codificación (UTF-8 o Windows-1252) detectados solos. Se descartan las líneas de título, total y pie de página."),
            .passerFichiers = T("Passer au dépôt des fichiers", "Go to file drop", "Pasar al depósito de archivos"),
            .securiteFichiers = T("Vos fichiers sont lus, contrôlés, puis déposés en préparation. Rien n'entre dans vos livres sans votre accord.", "Your files are read, checked, then placed in preparation. Nothing enters your books without your approval.", "Sus archivos se leen, se controlan y luego se depositan en preparación. Nada entra en sus libros sin su acuerdo."),
            .preferFichiers = T("Je préfère déposer des fichiers", "I'd rather drop files", "Prefiero depositar archivos"),
            .preferDirect = T("Revenir à la lecture en direct", "Back to live reading", "Volver a la lectura en directo"),
            .ditOauth = T("Je lis {n} en direct. Choisissez la date de bascule, puis connectez-vous chez {w}.", "I read {n} live. Choose the switch-over date, then sign in at {w}.", "Leo {n} en directo. Elija la fecha de cambio y luego conéctese en {w}."),
            .ditQbd = T("QuickBooks Desktop est installé sur un poste : on passe par son Web Connector.", "QuickBooks Desktop is installed on a computer: we go through its Web Connector.", "QuickBooks Desktop está instalado en un equipo: pasamos por su Web Connector."),
            .ditOdoo = T("Odoo se relie par une clé d'API.", "Odoo connects with an API key.", "Odoo se conecta con una clave de API."),
            .ditFichiers = T("{n} n'a pas de lecture en direct. Préparez les exports listés ; je les lirai un à un.", "{n} has no live reading. Prepare the listed exports; I will read them one by one.", "{n} no tiene lectura en directo. Prepare las exportaciones de la lista; las leeré una por una."),
            .ditFichiersChoix = T("D'accord, on passe par les fichiers : préparez les exports listés ; je les lirai un à un.", "All right, we go with files: prepare the listed exports; I will read them one by one.", "De acuerdo, pasamos por archivos: prepare las exportaciones de la lista; las leeré una por una."),
            .attenteAutorisation = T("En attente de votre autorisation dans la fenêtre {w}…", "Waiting for your authorization in the {w} window…", "Esperando su autorización en la ventana de {w}…"),
            .pasRecu = T("Je n'ai pas reçu l'autorisation. Recommencez quand vous serez prêt.", "I did not receive the authorization. Start again when you are ready.", "No recibí la autorización. Vuelva a empezar cuando esté listo."),
            .connexion = T("Connexion", "Connection", "Conexión"),
            .relieOk = T("Source reliée", "Source connected", "Origen conectado"),
            .relieTexte = T("{n} est relié en lecture seule. Prochaine étape : le plan comptable.", "{n} is connected read-only. Next step: the chart of accounts.", "{n} está conectado en solo lectura. Próximo paso: el plan contable."),
            .fichiersOk = T("Fichiers", "Files", "Archivos"),
            .fichiersTexte = T("Réglages retenus. Prochaine étape : déposer le plan comptable.", "Settings kept. Next step: drop the chart of accounts.", "Ajustes guardados. Próximo paso: depositar el plan contable."),
            .e3Titre = T("Étape 3 — Plan comptable", "Step 3 — Chart of accounts", "Paso 3 — Plan contable"),
            .e3LeadDirect = T("{n} est relié. 60 rapatriera le plan comptable, puis vous aidera à associer chaque compte.", "{n} is connected. 60 will bring back the chart of accounts, then help you match each account.", "{n} está conectado. 60 traerá el plan contable y luego le ayudará a asociar cada cuenta."),
            .e3LeadFichiers = T("Vous déposerez d'abord l'export du plan comptable de {n} ; 60 vous aidera ensuite à associer chaque compte.", "You will first drop the chart of accounts export from {n}; 60 will then help you match each account.", "Primero depositará la exportación del plan contable de {n}; luego 60 le ayudará a asociar cada cuenta."),
            .aVenir = T("Cette étape arrive bientôt. Vos réglages sont gardés.", "This step is coming soon. Your settings are kept.", "Este paso llegará pronto. Sus ajustes se conservan."),
            .modifierReglages = T("Revenir à l'étape 2", "Back to step 2", "Volver al paso 2"),
            .exp_plan = T("la liste des comptes (plan comptable)", "the list of accounts (chart of accounts)", "la lista de cuentas (plan contable)"),
            .exp_bal = T("la balance de vérification arrêtée à la date de bascule", "the trial balance struck at the switch-over date", "la balanza de comprobación cerrada en la fecha de cambio"),
            .exp_clients = T("la liste des clients", "the list of customers", "la lista de clientes"),
            .exp_fourn = T("la liste des fournisseurs", "the list of suppliers", "la lista de proveedores"),
            .exp_prod = T("la liste des produits et services", "the list of products and services", "la lista de productos y servicios"),
            .exp_fv = T("la liste des factures clients et fournisseurs, avec le solde dû", "the list of customer and supplier invoices, with the balance due", "la lista de facturas de clientes y proveedores, con el saldo pendiente"),
            .nom_plan = T("Plan comptable", "Chart of accounts", "Plan contable"),
            .nom_bal = T("Balance de vérification", "Trial balance", "Balanza de comprobación"),
            .nom_clients = T("Clients", "Customers", "Clientes"),
            .nom_fourn = T("Fournisseurs", "Suppliers", "Proveedores"),
            .nom_prod = T("Produits et services", "Products and services", "Productos y servicios"),
            .nom_fv = T("Factures clients et fournisseurs", "Customer and supplier invoices", "Facturas de clientes y proveedores"),
            .exporterGenerique = T("Dans {n}, exportez {r} en CSV (un .xlsx s'enregistre d'abord en CSV).", "In {n}, export {r} as CSV (save an .xlsx as CSV first).", "En {n}, exporte {r} en CSV (un .xlsx se guarda primero en CSV)."),
            .exporterChemin = T("Dans {n} : {c}, puis enregistrez en CSV UTF-8.", "In {n}: {c}, then save as CSV UTF-8.", "En {n}: {c}, luego guarde en CSV UTF-8."),
            .finTitre = T("Contrôle final en attente", "Final review pending", "Control final pendiente"),
            .finSous = T("Le bilan se remplit au fil des imports.", "The summary fills in as the imports go.", "El balance se completa con las importaciones."),
            .faComptes = T("comptes décidés", "accounts decided", "cuentas decididas"),
            .faFiches = T("fiches créées", "records created", "fichas creadas"),
            .faFactures = T("factures en brouillon", "draft invoices", "facturas en borrador"),
            .faBalance = T("balance au {0}", "balance at {0}", "balanza al {0}"),
            .fine = T("Rien n'entre au grand livre sans votre accord : tout attend en préparation, les comptes ne sont créés qu'à votre demande et les factures le sont en brouillon. Vos fichiers sont lus et contrôlés avant d'être déposés en préparation. * Saisie manuelle estimée à 45 s par enregistrement.",
                      "Nothing enters the general ledger without your approval: everything waits in preparation, accounts are created only when you ask and invoices are created as drafts. Your files are read and checked before being placed in preparation. * Manual entry estimated at 45 s per record.",
                      "Nada entra en el libro mayor sin su acuerdo: todo espera en preparación, las cuentas solo se crean cuando usted lo pide y las facturas se crean en borrador. Sus archivos se leen y controlan antes de depositarse en preparación. * Captura manual estimada en 45 s por registro."),
            .lang = CurrentLang
        }
    End Function
End Class
