Imports System.Web.Script.Serialization

''' <summary>
''' Importation 2 — nouvelle page de reprise d'une comptabilité tenue ailleurs,
''' en étapes (maquette « Importation des données » du 16 nov. 2026). La page
''' d'origine, Importations.aspx, reste intacte.
'''
''' Étape 1 (livrée) : choisir le logiciel comptable source. Le choix est gardé
''' en session, par compagnie, en attendant les étapes suivantes (connexion,
''' plan comptable, balance, tiers et catalogue, factures et taxes, contrôle).
'''
''' Rendu côté client : les données et les libellés (fr/en/es) sont injectés en
''' JSON ; les actions passent par un POST léger op=… qui répond en JSON.
''' </summary>
Public Class Importation2
    Inherits clsData

    Protected WithEvents litData As System.Web.UI.WebControls.Literal
    Protected WithEvents litLabels As System.Web.UI.WebControls.Literal

    ' Logiciels acceptés (clés de la maquette)
    Private Shared ReadOnly Logiciels As String() = {"qbo", "qbd", "xero", "sagebca", "fresh", "wave", "zoho", "odoo", "sage50", "acomba", "autre"}

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

        litData.Text = Json(New With {.logiciel = LogicielChoisi()})
        litLabels.Text = Json(Libelles())
    End Sub

    ''' <summary>Clé de session du logiciel choisi, par compagnie.</summary>
    Private ReadOnly Property CleSession As String
        Get
            Return "Imp2Logiciel|" & Company.ToString()
        End Get
    End Property

    Private Function LogicielChoisi() As String
        Dim v As String = Convert.ToString(Session(CleSession))
        Return If(Array.IndexOf(Logiciels, v) >= 0, v, Nothing)
    End Function

    Private Sub Traiter(op As String)
        Dim res As Object
        Select Case op
            Case "source"
                Dim k As String = Convert.ToString(Request.Form("logiciel")).Trim().ToLowerInvariant()
                If Array.IndexOf(Logiciels, k) < 0 Then
                    res = New With {.ok = False, .erreur = T("Logiciel inconnu.", "Unknown software.", "Software desconocido.")}
                Else
                    Session(CleSession) = k
                    res = New With {.ok = True}
                End If
            Case "vider"
                Session.Remove(CleSession)
                res = New With {.ok = True}
            Case Else
                res = New With {.ok = False, .erreur = T("Action inconnue.", "Unknown action.", "Acción desconocida.")}
        End Select
        Response.Clear()
        Response.ContentType = "application/json; charset=utf-8"
        Response.Write(Json(res))
        Context.ApplicationInstance.CompleteRequest()
        Response.End()
    End Sub

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
            .demoTip = T("Les étapes suivantes ne sont pas encore branchées : rien n'est lu ni écrit dans votre comptabilité.", "The next steps are not connected yet: nothing is read from or written to your accounting.", "Los pasos siguientes aún no están conectados: no se lee ni se escribe nada en su contabilidad."),
            .vider = T("Vider la préparation", "Clear the preparation", "Vaciar la preparación"),
            .viderTip = T("Efface ce qui attend d'être validé ; rien de ce qui est déjà passé en comptabilité n'est retiré", "Clears what is waiting to be validated; nothing already in the accounting is removed", "Borra lo que espera validación; no se retira nada de lo que ya está en la contabilidad"),
            .viderConfirme = T("Tout ce qui attend d'être validé sera effacé, y compris le logiciel choisi. Rien de ce qui est déjà passé en comptabilité n'est retiré.", "Everything waiting to be validated will be cleared, including the chosen software. Nothing already in the accounting is removed.", "Se borrará todo lo que espera validación, incluido el software elegido. No se retira nada de lo que ya está en la contabilidad."),
            .changer = T("Changer", "Change", "Cambiar"),
            .changerLogiciel = T("Choisir un autre logiciel", "Choose another software", "Elegir otro software"),
            .origine = T("Origine", "Source", "Origen"),
            .aChoisir = T("À choisir", "To choose", "Por elegir"),
            .origineVia = T("Votre logiciel comptable actuel", "Your current accounting software", "Su software contable actual"),
            .viaDirect = T("En direct · non relié", "Live · not connected", "En directo · no conectado"),
            .viaFichiers = T("Par fichiers CSV", "By CSV files", "Por archivos CSV"),
            .destination = T("Destination", "Destination", "Destino"),
            .destVia = T("Québec et Canada", "Québec and Canada", "Quebec y Canadá"),
            .enAttente = T("En attente", "Waiting", "En espera"),
            .fluxConnexion = T("Connexion à faire", "Connection to make", "Conexión pendiente"),
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
            .etape1 = T("Étape 1 sur 7", "Step 1 of 7", "Paso 1 de 7"),
            .etape2 = T("Étape 2 sur 7", "Step 2 of 7", "Paso 2 de 7"),
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
            .choisi = T("Logiciel choisi", "Software chosen", "Software elegido"),
            .choisiTexte = T("Parfait : on part de {0}. Prochaine étape : relier 60 à vos données.", "Great: we start from {0}. Next step: connect 60 to your data.", "Perfecto: partimos de {0}. Próximo paso: conectar 60 a sus datos."),
            .e2Titre = T("Étape 2 — Connexion", "Step 2 — Connection", "Paso 2 — Conexión"),
            .e2TitreFichiers = T("Étape 2 — Fichiers", "Step 2 — Files", "Paso 2 — Archivos"),
            .e2Lead = T("60 lira {0} en direct, en lecture seule : rien n'y sera modifié.", "60 will read {0} live, read-only: nothing will be changed there.", "60 leerá {0} en directo, en solo lectura: no se modificará nada allí."),
            .e2LeadFichiers = T("Vous exporterez de {0} un fichier CSV par écran ; 60 les lira et les contrôlera.", "You will export one CSV file per screen from {0}; 60 will read and check them.", "Exportará desde {0} un archivo CSV por pantalla; 60 los leerá y los controlará."),
            .aVenir = T("Cette étape arrive bientôt. Votre choix est gardé.", "This step is coming soon. Your choice is kept.", "Este paso llegará pronto. Su elección se conserva."),
            .enregistrement = T("J'enregistre votre choix…", "Saving your choice…", "Guardo su elección…"),
            .erreur = T("Erreur", "Error", "Error"),
            .erreurTexte = T("L'action n'a pas pu être faite. Réessayez.", "The action could not be done. Try again.", "No se pudo realizar la acción. Inténtelo de nuevo."),
            .finTitre = T("Contrôle final en attente", "Final review pending", "Control final pendiente"),
            .finSous = T("Le bilan se remplit au fil des imports.", "The summary fills in as the imports go.", "El balance se completa con las importaciones."),
            .faComptes = T("comptes décidés", "accounts decided", "cuentas decididas"),
            .faFiches = T("fiches créées", "records created", "fichas creadas"),
            .faFactures = T("factures en brouillon", "draft invoices", "facturas en borrador"),
            .faBalance = T("balance de vérification", "trial balance", "balanza de comprobación"),
            .fine = T("Rien n'entre au grand livre sans votre accord : tout attend en préparation, les comptes ne sont créés qu'à votre demande et les factures le sont en brouillon. Vos fichiers sont lus et contrôlés avant d'être déposés en préparation. * Saisie manuelle estimée à 45 s par enregistrement.",
                      "Nothing enters the general ledger without your approval: everything waits in preparation, accounts are created only when you ask and invoices are created as drafts. Your files are read and checked before being placed in preparation. * Manual entry estimated at 45 s per record.",
                      "Nada entra en el libro mayor sin su acuerdo: todo espera en preparación, las cuentas solo se crean cuando usted lo pide y las facturas se crean en borrador. Sus archivos se leen y controlan antes de depositarse en preparación. * Captura manual estimada en 45 s por registro.")
        }
    End Function
End Class
