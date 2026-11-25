Imports System.Globalization
Imports System.Web.Script.Serialization

''' <summary>
''' Importation 2 — nouvelle page de reprise d'une comptabilité tenue ailleurs,
''' en étapes (maquette « Importation des données » du 16 nov. 2026). La page
''' d'origine, Importations.aspx, reste intacte.
'''
''' Étape 1 : choisir le logiciel comptable source.
''' Étape 2 : relier la source — connexion Apideck (Vault) en lecture seule pour
'''           les logiciels en ligne, ou exports CSV à préparer ; date de début de la comptabilité
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

    ''' <summary>Étape 2 franchie avec les données déjà en préparation, sans relier la source.</summary>
    Private Property ViaPreparation As Boolean
        Get
            Return Session(Cle("viaPrep")) IsNot Nothing AndAlso CBool(Session(Cle("viaPrep")))
        End Get
        Set(value As Boolean)
            Session(Cle("viaPrep")) = value
        End Set
    End Property

    Private Sub ToutOublier()
        For Each n As String In {"logiciel", "mode", "bascule", "freq", "relie", "viaPrep"}
            Session.Remove(Cle(n))
        Next
    End Sub

    Private Function Etat() As Object
        Return New With {.logiciel = Logiciel, .mode = Mode, .bascule = Bascule, .freq = Frequence, .relie = Relie,
                         .viaPrep = ViaPreparation, .prep = Preparation(),
                         .reinit = Reinitialisable(), .compagnie = CompanyName, .debutLivres = DebutLivres(), .dateProposee = DateProposee(),
                         .exercice = DebutExercice(), .exerciceProposee = DebutExerciceProposee()}
    End Function

    ''' <summary>
    ''' Le début des livres chez la source (dernière fiche en préparation, s1030) :
    ''' c'est la date de début de la comptabilité proposée à l'étape 2. "" si inconnu.
    ''' </summary>
    ''' <summary>
    ''' La date de début de la comptabilité PROPOSÉE (s1030) : la clôture des livres de
    ''' la source + 1 jour, sinon le début de l'exercice en cours, jamais avant le
    ''' début des livres. "" si la source n'a pas encore été lue.
    ''' </summary>
    Private Function DateProposee() As String
        Try
            Dim v As DataRow = Rang0(Table(Lire("s1030VerifierDateBascule", New SqlClient.SqlParameter("@Date", Date.Today)), 0))
            If v Is Nothing OrElse IsDBNull(v("DateProposee")) OrElse IsDBNull(v("DebutLivres")) Then Return ""
            Return Convert.ToDateTime(v("DateProposee")).ToString("yyyy-MM-dd")
        Catch
            Return ""
        End Try
    End Function
    ''' <summary>
    ''' La date d'arrêt du moteur (balance, grand livre, taxes, rapprochement…) :
    ''' la VEILLE de la date de début de la comptabilité. Les soldes d'ouverture sont
    ''' ceux de la fin de la veille ; les opérations du premier jour arrivent comme
    ''' opérations, pas dans la balance (sinon elles compteraient deux fois).
    ''' </summary>
    Private Shared Function Veille(dateDebut As String) As Date?
        Dim d As Date? = ApideckExtraction.LireDate(dateDebut)
        If Not d.HasValue Then Return Nothing
        Return d.Value.AddDays(-1)
    End Function

    ''' <summary>La date de début de l'exercice mémorisée pour la compagnie (T411) ; "" si jamais saisie.</summary>
    Private Function DebutExercice() As String
        Try
            Dim r As DataRow = Rang0(Table(Lire("s1033GetDebutExercice"), 0))
            If r Is Nothing OrElse IsDBNull(r("DebutExercice")) Then Return ""
            Return Convert.ToDateTime(r("DebutExercice")).ToString("yyyy-MM-dd")
        Catch
            Return ""
        End Try
    End Function

    ''' <summary>
    ''' Ce qu'on propose dans le champ quand rien n'est mémorisé : le 1er du mois de
    ''' début d'exercice lu dans QuickBooks (le dernier passé). QuickBooks n'a pas de
    ''' jour : la personne corrige au besoin.
    ''' </summary>
    Private Function DebutExerciceProposee() As String
        Dim memo As String = DebutExercice()
        If memo <> "" Then Return memo
        Try
            Dim v As DataRow = Rang0(Table(Lire("s1030VerifierDateBascule", New SqlClient.SqlParameter("@Date", Date.Today)), 0))
            If v Is Nothing OrElse IsDBNull(v("MoisExercice")) Then Return ""
            Dim m As Integer = Convert.ToInt32(v("MoisExercice"))
            If m < 1 OrElse m > 12 Then Return ""
            Dim d As New Date(Date.Today.Year, m, 1)
            If d > Date.Today Then d = d.AddYears(-1)
            Return d.ToString("yyyy-MM-dd")
        Catch
            Return ""
        End Try
    End Function

    Private Function DebutLivres() As String
        Try
            Dim v As DataRow = Rang0(Table(Lire("s1030VerifierDateBascule", New SqlClient.SqlParameter("@Date", Date.Today)), 0))
            If v Is Nothing OrElse IsDBNull(v("DebutLivres")) Then Return ""
            Return Convert.ToDateTime(v("DebutLivres")).ToString("yyyy-MM-dd")
        Catch
            Return ""
        End Try
    End Function

    ''' <summary>
    ''' OUTIL DE TEST. Le bouton « Réinitialiser » n'est offert qu'aux compagnies
    ''' listées dans Web.config : &lt;add key="Importation2.Reinitialisables"
    ''' value="GUID;GUID" /&gt;. Sans la clé, personne ne le voit.
    ''' </summary>
    Private Function Reinitialisable() As Boolean
        Dim liste As String = If(System.Configuration.ConfigurationManager.AppSettings("Importation2.Reinitialisables"), "")
        For Each g As String In liste.Split({";"c, ","c}, StringSplitOptions.RemoveEmptyEntries)
            Dim guid As Guid
            If System.Guid.TryParse(g.Trim(), guid) AndAlso guid = Company Then Return True
        Next
        Return False
    End Function

    ''' <summary>
    ''' Efface factures, écritures, tiers et produits, ramène le plan comptable au
    ''' plan par défaut et remet la préparation « à faire » (s1026, T402).
    ''' </summary>
    ''' <summary>
    ''' « Recommencer l'assistant » : défait ce que la reprise a créé (s1027 :
    ''' factures, écriture d'ouverture, tiers, produits, comptes créés, décisions),
    ''' sans toucher aux données importées de QuickBooks ni à ce qui a été validé
    ''' depuis, puis oublie les choix de l'assistant et revient à l'étape 1.
    ''' </summary>
    Private Function Recommencer() As Object
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Confirmation", "RECOMMENCER"))
        Dim ds As DataSet = ExecuteSQLds("s1027RecommencerReprise", p)

        ToutOublier()
        Session.Remove(Cle("lienSurs"))
        Session.Remove("AssocierCompte.Sautes")
        Session.Remove("CreerCompte.Sautes")

        Dim lignes As New List(Of Object)
        Dim bilan As DataTable = If(ds Is Nothing OrElse ds.Tables.Count = 0, Nothing, ds.Tables(ds.Tables.Count - 1))
        If bilan IsNot Nothing Then
            For Each r As DataRow In bilan.Rows
                Dim nb As Integer = Convert.ToInt32(r("Nb"))
                If nb > 0 Then lignes.Add(New With {.quoi = Convert.ToString(r("Quoi")), .nb = nb})
            Next
        End If
        Return New With {.ok = True, .lignes = lignes, .etat = Etat()}
    End Function

    Private Function Reinitialiser() As Object
        If Not Reinitialisable() Then
            Return New With {.ok = False, .erreur = T("La réinitialisation n'est pas permise pour cette compagnie.", "Reset is not allowed for this company.", "El reinicio no está permitido para esta compañía.")}
        End If
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Confirmation", "REINITIALISER"))
        Dim ds As DataSet = ExecuteSQLds("s1026ReinitialiserReprise", p)
        ' Départ neuf : les propositions sûres se relieront à la prochaine arrivée au tableau.
        Session.Remove(Cle("lienSurs"))

        Dim lignes As New List(Of Object)
        Dim bilanReinit As DataTable = If(ds Is Nothing OrElse ds.Tables.Count = 0, Nothing, ds.Tables(ds.Tables.Count - 1))
        If bilanReinit IsNot Nothing Then
            For Each r As DataRow In bilanReinit.Rows
                lignes.Add(New With {.quoi = Convert.ToString(r("Quoi")), .nb = Convert.ToInt32(r("Nb"))})
            Next
        End If
        Return New With {.ok = True, .lignes = lignes, .etat = Etat()}
    End Function

    ''' <summary>Ce qu'une extraction précédente a laissé en préparation (staging.ConnecteurDonnee).</summary>
    Public Class DonneesEnPreparation
        Public Property nb As Integer
        Public Property ressources As Integer
        Public Property derniere As String
        Public Property service As String
        ''' <summary>La clé du logiciel (« qbo »…), ou Nothing si le service n'est pas reconnu.</summary>
        Public Property logiciel As String
    End Class

    ''' <summary>Nothing quand rien n'attend. Une erreur de lecture ne bloque jamais la page.</summary>
    Private Function Preparation() As DonneesEnPreparation
        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s1024GetPreparationConnecteur", p)
            If ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return Nothing

            Dim r As DataRow = ds.Tables(0).Rows(0)
            Dim nb As Integer = If(IsDBNull(r("NbEnregistrements")), 0, CInt(r("NbEnregistrements")))
            If nb <= 0 Then Return Nothing

            Dim service As String = If(IsDBNull(r("Service")), "", CStr(r("Service")))
            Dim cle As String = Nothing
            For Each kv As KeyValuePair(Of String, String) In ServicesApideck
                If String.Equals(kv.Value, service, StringComparison.OrdinalIgnoreCase) Then cle = kv.Key : Exit For
            Next

            Return New DonneesEnPreparation With {
                .nb = nb,
                .ressources = If(IsDBNull(r("NbRessources")), 0, CInt(r("NbRessources"))),
                .derniere = If(IsDBNull(r("Derniere")), "", CDate(r("Derniere")).ToString("yyyy-MM-dd")),
                .service = service,
                .logiciel = cle}
        Catch
            Return Nothing
        End Try
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
                Case "extraire" : res = Extraire()
                Case "fichiers" : res = PasserAuxFichiers()
                Case "continuerPrep" : res = ContinuerAvecPreparation()
                Case "tableau" : res = New With {.ok = True, .tableau = Tableau()}
                Case "creerFiches" : res = CreerFiches(Convert.ToString(Request.Form("type")))
                Case "creerTiers" : CreerFiches("Client") : res = CreerFiches("Fournisseur")
                Case "creerFactures" : res = CreerFactures()
                Case "creerOuverture" : res = CreerOuverture()
                Case "reinitialiser" : res = Reinitialiser()
                Case "retour" : Relie = False : ViaPreparation = False : res = New With {.ok = True, .etat = Etat()}
                Case "vider" : ToutOublier() : res = New With {.ok = True}
                Case "recommencer" : res = Recommencer()
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
        ViaPreparation = False
        Return New With {.ok = True, .etat = Etat()}
    End Function

    Private Function ChoisirMode(m As String) As Object
        If Logiciel Is Nothing Then Return SansLogiciel()
        Mode = If(m = "fichier", "fichier", "direct")
        Relie = False
        ViaPreparation = False
        Return New With {.ok = True, .etat = Etat()}
    End Function

    ''' <summary>
    ''' Continuer avec les données déjà en préparation, sans relier la source :
    ''' l'extraction a déjà eu lieu. La date de début de la comptabilité, si elle est saisie
    ''' (étape 2), est retenue ; sinon elle se donne plus tard.
    ''' </summary>
    Private Function ContinuerAvecPreparation() As Object
        Dim prep As DonneesEnPreparation = Preparation()
        If prep Is Nothing Then
            Return New With {.ok = False, .erreur = T("Aucune donnée n'attend en préparation.", "No data is waiting in preparation.", "No hay datos esperando en preparación.")}
        End If

        ' Étape 1 : aucune date n'est envoyée — Request.Form rend Nothing.
        If If(Request.Form("exercice"), "").Trim() <> "" Then
            Dim err As String = ""
            If Not LireReglages(err) Then Return New With {.ok = False, .erreur = err}
        End If

        If prep.logiciel IsNot Nothing Then Logiciel = prep.logiciel
        If Logiciel Is Nothing Then Logiciel = "qbo"
        Mode = "direct"
        Relie = True
        ViaPreparation = True
        Return New With {.ok = True, .etat = Etat()}
    End Function

    ''' <summary>Date de début de la comptabilité (AAAA-MM-JJ, obligatoire) et fréquence des taxes.</summary>
    Private Function LireReglages(ByRef erreur As String, Optional permettreVide As Boolean = False) As Boolean
        Dim d As String = If(Request.Form("bascule"), "").Trim()
        Dim f As String = If(Request.Form("freq"), "").Trim()
        Dim dt As Date

        ' La date de début de l'exercice : QuickBooks n'en a pas (seulement un mois),
        ' on la demande et on la mémorise pour la compagnie (T411).
        Dim ex As String = If(Request.Form("exercice"), "").Trim()
        If ex = "" Then ex = DebutExercice()
        Dim dex As Date
        If Not Date.TryParseExact(ex, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, dex) Then
            erreur = T("Indiquez la date de début de l'exercice. QuickBooks n'a pas de date de début d'exercice, seulement le premier mois : précisez le jour exact.",
                       "Enter the fiscal year start date. QuickBooks has no fiscal year start date, only the first month: give the exact day.",
                       "Indique la fecha de inicio del ejercicio. QuickBooks no tiene fecha de inicio del ejercicio, solo el primer mes: precise el día exacto.")
            Return False
        End If
        If dex < New Date(1990, 1, 1) OrElse dex > Date.Today.AddYears(1) Then
            erreur = T("La date de début de l'exercice semble incorrecte.", "The fiscal year start date looks wrong.", "La fecha de inicio del ejercicio parece incorrecta.")
            Return False
        End If
        Try
            Lire("s1034SaveDebutExercice", New SqlClient.SqlParameter("@DebutExercice", dex), New SqlClient.SqlParameter("@UserId", UserId))
        Catch
        End Try
        ' La date de début de la comptabilité n'est plus demandée : c'est le début de
        ' l'exercice. La balance de vérification est arrêtée à la veille (Extraire).
        Bascule = dex.ToString("yyyy-MM-dd")
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
        If Not LireReglages(err, permettreVide:=True) Then Return New With {.ok = False, .erreur = err}

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
        Return New With {.ok = True, .url = url, .direct = False}
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

    ''' <summary>
    ''' La source reliée, on lit ses données : toutes les ressources du catalogue,
    ''' sur un fil de fond (le même moteur que l'écran Import Apideck), arrêtées à
    ''' la date de début de la comptabilité, taxes par mois / trimestre / année. La page suit
    ''' l'avancement par ApideckEtat.ashx?run=N. Les automatismes du tableau
    ''' (comptes sûrs, fiche, tiers…) repartent sur les données fraîches.
    ''' </summary>
    Private Function Extraire() As Object
        If Logiciel Is Nothing OrElse Not ServicesApideck.ContainsKey(Logiciel) Then
            Return New With {.ok = False, .erreur = T("Aucune source en direct n'est reliée.", "No live source is linked.", "Ninguna fuente en directo está vinculada.")}
        End If
        ' Chaque import repart d'une comptabilité vide : les données de la source
        ' prennent la place des anciennes (T412). Seulement avec l'accord donné à
        ' l'écran (reinit=1) ; sans lui, on n'extrait pas par-dessus l'existant.
        If Convert.ToString(Request.Form("reinit")) <> "1" Then
            Return New With {.ok = False, .erreur = T("L'import efface d'abord toute la comptabilité : confirmez-le pour continuer.", "The import first erases all the accounting: confirm it to continue.", "La importación borra primero toda la contabilidad: confírmelo para continuar.")}
        End If
        Dim pR As New Collection
        pR.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        pR.Add(New SqlClient.SqlParameter("@Confirmation", "IMPORTER"))
        ExecuteSQLds("s1035ReinitialiserAvantImport", pR)
        Session.Remove(Cle("lienSurs"))

        ' La date de début est celle de l'exercice, mémorisée (T411). La balance est
        ' arrêtée à sa veille. À défaut seulement (aucune date mémorisée), on lit la
        ' fiche de la société chez la source pour en proposer une.
        If String.IsNullOrEmpty(Bascule) Then Bascule = DebutExercice()
        If String.IsNullOrEmpty(Bascule) Then
            Try
                Dim fiche As New ApideckExtraction(Me)
                fiche.Importer(ApideckExtraction.Choisir("company-info"))
            Catch
            End Try
            Bascule = DateProposee()
        End If

        Dim mois As Integer = If(Frequence = "mois", 1, If(Frequence = "annee", 12, 3))
        Dim moteur As New ApideckExtraction(Me) With {
            .DateArret = Veille(Bascule),
            .DebutExercice = ApideckExtraction.LireDate(DebutExercice()),
            .MoisParPeriode = mois
        }
        Dim runId As Integer = moteur.LancerEnFond(ApideckExtraction.Catalogue)
        Session.Remove(Cle("lienSurs"))
        Return New With {.ok = True, .run = runId}
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

#Region "Étape 3 : le tableau des imports"

    ' Chaque carte lit les procédures des écrans d'import existants : rien n'est
    ' recalculé ici, et les boutons appellent les mêmes procédures de création.
    '   1 Plan comptable        s0758 + s0766       → AssocierCompte.aspx?popup=1 (décider), puis AppliquerPlanComptable.aspx (créer)
    '   2 Balance               s0770 + s0771       → s1025 (écriture d'ouverture validée)
    '   3-5 Clients, fournisseurs, produits  s0772 + s0773 → s0774
    '   6 Factures              s0782               → s0785 (brouillons)
    '   7 Taxes                 s0871               → ValiderTaxes.aspx

    Private Function Lire(proc As String, ParamArray extra As SqlClient.SqlParameter()) As DataSet
        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        For Each x As SqlClient.SqlParameter In extra
            p.Add(x)
        Next
        Return ExecuteSQLds(proc, p)
    End Function

    Private Shared Function Table(ds As DataSet, i As Integer) As DataTable
        If ds Is Nothing OrElse ds.Tables.Count <= i Then Return Nothing
        Return ds.Tables(i)
    End Function

    Private Shared Function Rang0(t As DataTable) As DataRow
        If t Is Nothing OrElse t.Rows.Count = 0 Then Return Nothing
        Return t.Rows(0)
    End Function

    Private Shared Function Ent(r As DataRow, col As String) As Integer
        If r Is Nothing OrElse Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return 0
        Return Convert.ToInt32(r(col))
    End Function

    Private Shared Function Dec(r As DataRow, col As String) As Decimal
        If r Is Nothing OrElse Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return 0D
        Return Convert.ToDecimal(r(col))
    End Function

    Private Shared Function Txt(r As DataRow, col As String) As String
        If r Is Nothing OrElse Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return ""
        Return Convert.ToString(r(col))
    End Function

    Private Function Montant(m As Decimal) As String
        Dim c As CultureInfo = If(CurrentLang = "en", CultureInfo.GetCultureInfo("en-CA"), CultureInfo.GetCultureInfo("fr-CA"))
        Return m.ToString("N2", c) & " $"
    End Function

    ''' <summary>Une ligne de la liste de contrôle d'une carte : ok, mid (en cours) ou todo.</summary>
    Private Shared Function Point(texte As String, etat As String) As Object
        Return New With {.t = texte, .e = etat}
    End Function

    Private Shared Function Puce(texte As String, cls As String) As Object
        Return New With {.t = texte, .c = cls}
    End Function

    Private Shared Function EtatDe(fait As Boolean, enCours As Boolean) As String
        Return If(fait, "ok", If(enCours, "mid", "todo"))
    End Function

    ''' <summary>Le fichier d'import le plus récent d'un type, et ses compteurs (s0772 → s0773).</summary>
    Private Function FichierImport(typeImport As String, ByRef fichierId As Integer) As DataRow
        fichierId = 0
        Dim f As DataRow = Rang0(Table(Lire("s0772GetImportFichiers", New SqlClient.SqlParameter("@TypeImport", typeImport)), 0))
        If f Is Nothing Then Return Nothing
        fichierId = Ent(f, "Id")
        Return Rang0(Table(Lire("s0773GetImportLignes", New SqlClient.SqlParameter("@ImportFileId", fichierId)), 0))
    End Function

    ''' <summary>
    ''' À l'arrivée au tableau, une fois par session (et de nouveau après
    ''' Réinitialiser ou Recommencer), tout ce qui ne demande aucune décision :
    '''   · lier les comptes dont la proposition est sûre — même numéro, même nom,
    '''     alias QuickBooks (s0760) ; il ne reste à décider un par un que les autres ;
    '''   · créer les nouveaux clients et fournisseurs (s0774) : ils ne dépendent
    '''     d'aucun compte, et les factures en ont besoin pour trouver leur tiers ;
    '''   · répartir TPS et TVQ des factures en préparation selon les codes et taux
    '''     de taxe rapatriés (s0794).
    ''' Les produits attendent : leurs comptes de vente et d'achat doivent d'abord
    ''' exister au plan. Une fois par session, pour qu'une liaison défaite à la main
    ''' ne revienne pas à chaque rechargement du tableau.
    ''' Chaque étape est indépendante : un échec n'empêche pas les autres.
    ''' </summary>
    ''' <summary>
    ''' Les taxes et les paramètres de la compagnie remplacés par ceux de la source
    ''' (s1036, T414). Sans effet quand rien n'a changé ; un échec n'arrête rien.
    ''' </summary>
    Private Sub AppliquerParametresSource()
        Try
            Lire("s1036AppliquerParametresSource", New SqlClient.SqlParameter("@Frequence", Frequence))
        Catch
        End Try
    End Sub

    Private Sub ArriveeAuTableau()
        ' La fiche de la compagnie : chaque champ que QuickBooks donne autrement
        ' remplace celui d'ici (s0791, la même procédure que l'écran de la fiche).
        Try
            Dim soc As DataTable = Table(Lire("s0789GetSocieteImport"), 0)
            Dim ids As New List(Of String)
            If soc IsNot Nothing Then
                For Each r As DataRow In soc.Rows
                    If Txt(r, "Statut") = "DIFFERENT" AndAlso IsDBNull(r("AppliqueLe")) AndAlso Txt(r, "Champ") <> "" Then ids.Add(Txt(r, "Id"))
                Next
            End If
            If ids.Count > 0 Then
                Lire("s0791AppliquerSocieteImport",
                     New SqlClient.SqlParameter("@Ids", "[" & String.Join(",", ids) & "]"),
                     New SqlClient.SqlParameter("@UserId", UserId))
            End If
        Catch
        End Try
        ' Les taxes et les paramètres viennent de la source (T414) : taux, numéros
        ' d'inscription, fin d'exercice, fréquence de déclaration.
        AppliquerParametresSource()
        Try
            Lire("s0760AccepterPropositions", New SqlClient.SqlParameter("@UserId", UserId))
        Catch
        End Try
        For Each typeImport As String In {"Client", "Fournisseur"}
            Try
                Dim fid As Integer = 0
                Dim r As DataRow = FichierImport(typeImport, fid)
                If fid > 0 AndAlso Ent(r, "Nouveaux") > 0 Then
                    Lire("s0774AppliquerImportFichier", New SqlClient.SqlParameter("@ImportFileId", fid))
                End If
            Catch
            End Try
        Next
        Try
            Lire("s1037ClasserTaxesSansTaux")
        Catch
        End Try
        Try
            Lire("s0794RepartirTaxesImport")
        Catch
        End Try
    End Sub

    Private Function Tableau() As Object
        Dim cartes As New List(Of Object)
        Dim nomSrc As String = NomSource()

        ' En arrivant au tableau, ce qui ne demande aucune décision se fait tout seul.
        If Session(Cle("lienSurs")) Is Nothing Then
            Session(Cle("lienSurs")) = True
            ArriveeAuTableau()
        End If
        ' À chaque affichage : une nouvelle extraction remet les tiers déjà créés
        ' « en attente » ; on les rattache aux fiches existantes, pour que leurs
        ' factures retrouvent leur tiers avant d'être créées (T408). Sans effet
        ' quand il n'y a rien à rattacher.
        Try
            Lire("s1031RattacherTiersExistants")
        Catch
        End Try

        ' ---- 1 : plan comptable et correspondance, une seule carte ---------------
        Dim st As DataRow = Nothing, resteACreer As Integer = 0, dejaCrees As Integer = 0
        Try
            st = Rang0(Table(Lire("s0758StatsCorrespondance"), 0))
            Dim app As DataSet = Lire("s0766GetAAppliquer")
            Dim t0 As DataTable = Table(app, 0)
            resteACreer = If(t0 Is Nothing, 0, t0.Rows.Count)
            dejaCrees = Ent(Rang0(Table(app, 1)), "DejaCrees")
        Catch
        End Try
        Dim total As Integer = Ent(st, "Total"), decides As Integer = Ent(st, "Decides"), aDecider As Integer = Ent(st, "ADecider")
        Dim lies As Integer = Ent(st, "Lies"), aCreer As Integer = Ent(st, "ACreer"), ignores As Integer = Ent(st, "Ignores")
        Dim planFait As Boolean = total > 0 AndAlso aDecider = 0 AndAlso resteACreer = 0

        ' Le plan terminé (tout décidé, tout créé), les comptes de vente et d'achat
        ' des produits existent : les nouveaux produits se créent d'eux-mêmes.
        ' Après la fenêtre « Créer un compte », le tableau se recharge et passe ici.
        If planFait Then
            ' Le plan décidé, le compte des bénéfices non répartis de la source est connu ici.
            AppliquerParametresSource()
            Try
                Dim fid As Integer = 0
                Dim rp As DataRow = FichierImport("Produit", fid)
                If fid > 0 AndAlso Ent(rp, "Nouveaux") > 0 Then
                    Lire("s0774AppliquerImportFichier", New SqlClient.SqlParameter("@ImportFileId", fid))
                End If
            Catch
            End Try
            ' Puis, les produits créés, les factures clients et fournisseurs se créent
            ' d'elles-mêmes en brouillon : chaque ligne trouve son compte et son produit.
            Try
                Dim fid2 As Integer = 0
                Dim rp2 As DataRow = FichierImport("Produit", fid2)
                If fid2 = 0 OrElse Ent(rp2, "Nouveaux") = 0 Then CreerFacturesPretes()
            Catch
            End Try
        End If

        ' Une seule carte : lire le plan, décider chaque compte un par un (60
        ' propose, vous décidez), puis créer au plan les comptes marqués « Créer ».
        ' Associés, importés et à décider ont leurs propres chiffres (.chiffres) :
        ' les pastilles ne gardent que le reste.
        Dim p1 As New List(Of Object)
        If resteACreer > 0 Then p1.Add(Puce(resteACreer & " " & T("à créer", "to create", "por crear"), "act"))
        If ignores > 0 Then p1.Add(Puce(ignores & " " & T("ignorés", "ignored", "ignoradas"), ""))

        ' Le bouton suit l'étape : décider tant qu'il reste des comptes à décider,
        ' puis créer ceux marqués « Créer » (leur classe se choisit à l'écran dédié).
        Dim bouton1 As Object
        If aDecider > 0 OrElse resteACreer = 0 Then
            bouton1 = New With {.t = T("Décider un par un", "Decide one by one", "Decidir una por una"), .op = "fenetre", .url = "AssocierCompte.aspx?popup=1", .actif = aDecider > 0}
        Else
            bouton1 = New With {.t = String.Format(T("Créer {0} comptes", "Create {0} accounts", "Crear {0} cuentas"), resteACreer), .op = "fenetre", .url = "CreerCompte.aspx?popup=1", .actif = True}
        End If

        cartes.Add(New With {
            .k = "plan", .no = 2, .ico = "plan", .titre = T("Plan comptable", "Chart of accounts", "Plan contable"),
            .src = nomSrc & " · " & T("60 propose, vous décidez", "60 suggests, you decide", "60 propone, usted decide"),
            .etat = If(total = 0, "vide", If(planFait, "fait", If(aDecider > 0, "decider", "afaire"))),
            .liste = New Object() {
                Point(T("Lire et contrôler : doublons, lignes invalides, déjà au plan", "Read and check: duplicates, invalid lines, already in the chart", "Leer y controlar: duplicados, líneas inválidas, ya en el plan"), EtatDe(total > 0, False)),
                Point(T("Correspondance par numéro, par nom en quatre langues et par IA", "Matching by number, by name in four languages and by AI", "Correspondencia por número, por nombre en cuatro idiomas y por IA"), EtatDe(total > 0, False)),
                Point(T("Décider un par un : la recommandation de 60, l'enjeu, puis Associer · Plus tard · Demander au cabinet", "Decide one by one: 60's recommendation, what's at stake, then Match · Later · Ask the firm", "Decidir una por una: la recomendación de 60, lo que está en juego, luego Asociar · Más tarde · Preguntar al despacho"), EtatDe(total > 0 AndAlso aDecider = 0, decides > 0)),
                Point(T("Créer au plan les comptes marqués « Créer »", "Create the accounts marked ""Create""", "Crear en el plan las cuentas marcadas «Crear»"), EtatDe(total > 0 AndAlso aDecider = 0 AndAlso resteACreer = 0, dejaCrees > 0))},
            .puces = p1, .n = decides, .unite = String.Format(T("sur {0} décidés", "of {0} decided", "de {0} decididas"), total), .extra = "",
            .chiffres = New Object() {
                New With {.n = lies, .t = T("déjà associés", "already matched", "ya asociadas"), .c = "ok"},
                New With {.n = total, .t = T("importés", "imported", "importadas"), .c = ""},
                New With {.n = aDecider, .t = T("à décider", "to decide", "por decidir"), .c = If(aDecider > 0, "dec", "ok")}},
            .bouton = bouton1,
            .voir = "CorrespondanceComptes.aspx",
            .pct = If(total = 0, 0, CInt(100 * Math.Max(0, decides - resteACreer) / Math.Max(1, total))),
            .dit = If(aDecider > 0,
                      String.Format(T("{0} comptes liés d'eux-mêmes. {1} comptes attendent votre décision : cliquez sur « Décider un par un ».", "{0} accounts linked by themselves. {1} accounts await your decision: click ""Decide one by one"".", "{0} cuentas vinculadas solas. {1} cuentas esperan su decisión: haga clic en «Decidir una por una»."), lies, aDecider),
                      String.Format(T("{0} comptes à créer : choisissez leur classe.", "{0} accounts to create: choose their class.", "{0} cuentas por crear: elija su clase."), resteACreer))})

        ' ---- 2 : balance de vérification ---------------------------------------
        Dim nbBal As Integer = 0, debit As Decimal = 0D, credit As Decimal = 0D, erreurs As Integer = 0, aVerifier As Integer = 0
        Dim balControle As Boolean = False, balFin As String = ""
        Try
            Dim bal As DataTable = Table(Lire("s0770GetBalanceVerification"), 0)
            If bal IsNot Nothing Then
                nbBal = bal.Rows.Count
                If nbBal > 0 Then balControle = Not BalanceDOuverture(bal, balFin)
                For Each r As DataRow In bal.Rows
                    debit += Dec(r, "Debit") : credit += Dec(r, "Credit")
                Next
            End If
            If nbBal > 0 Then
                Dim ctl As DataRow = Rang0(Table(Lire("s0771ControleBalancePlan"), 0))
                erreurs = Ent(ctl, "Erreurs") : aVerifier = Ent(ctl, "AVerifier")
            End If
        Catch
        End Try
        Dim equilibree As Boolean = nbBal > 0 AndAlso Math.Abs(debit - credit) < 0.005D

        ' Soldes d'ouverture (s1025, vérification seulement) : VIDE | BLOQUE | PRET | CREE | EXISTE
        Dim ouv As DataRow = Nothing, ouvStatut As String = "", ouvBloquees As Integer = 0
        If nbBal > 0 AndAlso Not balControle Then
            Try
                Dim dsO As DataSet = SoldesOuverture(False)
                ouv = Rang0(Table(dsO, dsO.Tables.Count - 1))
                ouvStatut = Txt(ouv, "Statut") : ouvBloquees = Ent(ouv, "NbBloquees")
            Catch
            End Try
        End If
        ' Tout balance (s1025 dit PRET) et le plan est terminé : l'écriture
        ' d'ouverture se crée d'elle-même, en brouillon, puis on relit son état.
        If ouvStatut = "PRET" AndAlso planFait Then
            Try
                SoldesOuverture(True)
                Dim dsO2 As DataSet = SoldesOuverture(False)
                ouv = Rang0(Table(dsO2, dsO2.Tables.Count - 1))
                ouvStatut = Txt(ouv, "Statut") : ouvBloquees = Ent(ouv, "NbBloquees")
            Catch
            End Try
        End If
        Dim ouvFaite As Boolean = ouvStatut = "EXISTE"
        ' Prête seulement une fois le plan comptable terminé : chaque solde doit
        ' tomber sur le compte DÉCIDÉ, pas sur une proposition en attente.
        Dim ouvPrete As Boolean = ouvStatut = "PRET" AndAlso planFait
        Dim msgPlan As String = T("Les soldes d'ouverture attendent la fin du plan comptable : chaque solde doit tomber sur le compte décidé.", "Opening balances wait for the chart of accounts to be finished: each balance must land on the decided account.", "Los saldos de apertura esperan a que termine el plan contable: cada saldo debe caer en la cuenta decidida.")

        Dim p3 As New List(Of Object)
        If nbBal > 0 Then p3.Add(If(equilibree, Puce(T("Équilibrée", "Balanced", "Equilibrada"), "ok"), Puce(T("Déséquilibrée", "Unbalanced", "Desequilibrada"), "bad")))
        If erreurs > 0 Then p3.Add(Puce(erreurs & " " & T("erreurs", "errors", "errores"), "bad"))
        If aVerifier > 0 Then p3.Add(Puce(aVerifier & " " & T("à vérifier", "to check", "por verificar"), "act"))
        If nbBal > 0 AndAlso erreurs = 0 Then p3.Add(Puce(T("Concorde avec le plan", "Matches the chart", "Concuerda con el plan"), "ok"))
        If ouvFaite Then p3.Add(Puce(String.Format(T("Ouverture {0}", "Opening {0}", "Apertura {0}"), Txt(ouv, "EcritureStatut").ToLowerInvariant()), "ok"))
        If ouvBloquees > 0 Then p3.Add(Puce(ouvBloquees & " " & T("sans compte", "without account", "sin cuenta"), "dec"))

        ' Ce que dit 60 et l'info-bulle du bouton : le message de s1025 quand il bloque.
        Dim dit3 As String
        If balControle Then
            p3.Add(Puce(T("Contrôle", "Control", "Control"), ""))
            dit3 = String.Format(T("La balance va du début de l'exercice au {0} : elle sert de contrôle. Les opérations de l'exercice sont reprises une à une (factures, dépenses…), pas en soldes d'ouverture, sinon elles compteraient deux fois.",
                                   "The trial balance runs from the start of the fiscal year to {0}: it serves as a control. The year's transactions are brought over one by one (invoices, expenses…), not as opening balances, otherwise they would count twice.",
                                   "La balanza va del inicio del ejercicio al {0}: sirve de control. Las operaciones del ejercicio se retoman una a una (facturas, gastos…), no como saldos de apertura, si no contarían dos veces."), balFin)
        ElseIf erreurs > 0 Then
            dit3 = String.Format(T("La balance a {0} erreurs à corriger face au plan comptable.", "The trial balance has {0} errors against the chart of accounts.", "La balanza tiene {0} errores frente al plan contable."), erreurs)
        ElseIf Not equilibree Then
            dit3 = T("La balance n'est pas équilibrée : vérifiez l'export.", "The trial balance does not balance: check the export.", "La balanza no está equilibrada: verifique la exportación.")
        ElseIf ouvPrete Then
            dit3 = T("La balance est prête : créez l'écriture d'ouverture, validée au Journal général.", "The trial balance is ready: create the opening entry, validated in the General journal.", "La balanza está lista: cree el asiento de apertura, validado en el Diario general.")
        ElseIf Not ouvFaite AndAlso Not planFait Then
            dit3 = msgPlan
        Else
            dit3 = Txt(ouv, "Message")
        End If

        cartes.Add(New With {
            .k = "balance", .no = 5, .ico = "balance", .titre = T("Balance de vérification", "Trial balance", "Balanza de comprobación"), .src = nomSrc,
            .etat = If(nbBal = 0, "vide", If(ouvFaite OrElse (balControle AndAlso equilibree), "fait", "afaire")),
            .liste = New Object() {
                Point(T("Lire l'export, écarter titres, total et pied de page", "Read the export, drop titles, total and footer", "Leer la exportación, descartar títulos, total y pie"), EtatDe(nbBal > 0, False)),
                Point(T("Contrôler l'équilibre et le total", "Check the balance and the total", "Controlar el equilibrio y el total"), EtatDe(equilibree, nbBal > 0)),
                Point(T("Confronter chaque ligne au plan comptable", "Compare each line with the chart of accounts", "Confrontar cada línea con el plan contable"), EtatDe(nbBal > 0 AndAlso erreurs = 0 AndAlso ouvBloquees = 0, nbBal > 0)),
                Point(T("Créer et valider les soldes d'ouverture au Journal général", "Create and validate the opening balances in the General journal", "Crear y validar los saldos de apertura en el Diario general"), EtatDe(ouvFaite, ouvPrete))},
            .puces = p3, .n = nbBal, .unite = T("lignes", "lines", "líneas"), .extra = If(nbBal > 0, " · " & Montant(debit), ""),
            .bouton = If(ouvFaite,
                New With {.t = T("Voir l'écriture", "See the entry", "Ver el asiento"), .op = "page", .url = "wbfJournalEntryEdit.aspx?Id=" & Ent(ouv, "EcritureId"), .actif = True, .info = Txt(ouv, "Message")},
                New With {.t = T("Créer les soldes d'ouverture", "Create opening balances", "Crear los saldos de apertura"), .op = "creerOuverture", .url = "", .actif = ouvPrete, .cache = balControle, .info = If(ouvPrete, "", If(planFait, Txt(ouv, "Message"), msgPlan))}),
            .voir = "ImportBalanceVerification.aspx",
            .pct = If(nbBal = 0, 0, If(ouvFaite, 100, If(ouvPrete, 75, 40))),
            .dit = dit3})

        ' ---- 3, 4, 5 : clients, fournisseurs, produits ------------------------
        Dim fichesCreees As Integer = 0, produitsAFaire As Integer = 0
        Dim cliLignes As Integer = 0, cliNouveaux As Integer = 0, cliCrees As Integer = 0, cliErr As Integer = 0
        Dim fouLignes As Integer = 0, fouNouveaux As Integer = 0, fouCrees As Integer = 0, fouErr As Integer = 0
        For Each def As String() In {
                New String() {"clients", "2", "Client", "client", T("Clients", "Customers", "Clientes"), "ImportClients.aspx"},
                New String() {"fournisseurs", "3", "Fournisseur", "fournisseur", T("Fournisseurs", "Suppliers", "Proveedores"), "ImportFournisseurs.aspx"},
                New String() {"produits", "3", "Produit", "produit", T("Produits et services", "Products and services", "Productos y servicios"), "ImportProduits.aspx"}}
            Dim fid As Integer = 0, r As DataRow = Nothing
            Try
                r = FichierImport(def(2), fid)
            Catch
            End Try
            Dim lignes As Integer = Ent(r, "Lignes"), nouveaux As Integer = Ent(r, "Nouveaux"), existants As Integer = Ent(r, "Existants")
            Dim doublons As Integer = Ent(r, "Doublons"), crees As Integer = Ent(r, "Crees"), errs As Integer = Ent(r, "Erreurs")
            fichesCreees += crees
            If def(0) = "produits" Then produitsAFaire = nouveaux
            ' Clients et fournisseurs n'ont plus leur propre carte : leurs chiffres
            ' vont dans la carte 1, avec la fiche de la compagnie.
            If def(0) = "clients" Then
                cliLignes = lignes : cliNouveaux = nouveaux : cliCrees = crees : cliErr = errs
                Continue For
            ElseIf def(0) = "fournisseurs" Then
                fouLignes = lignes : fouNouveaux = nouveaux : fouCrees = crees : fouErr = errs
                Continue For
            End If
            Dim fait As Boolean = lignes > 0 AndAlso nouveaux = 0
            Dim pp As New List(Of Object)
            If nouveaux > 0 Then pp.Add(Puce(nouveaux & " " & T("nouveaux", "new", "nuevos"), "ok"))
            If crees > 0 Then pp.Add(Puce(crees & " " & T("créés", "created", "creados"), "ok"))
            If existants > 0 Then pp.Add(Puce(existants & " " & T("déjà là", "already there", "ya existen"), ""))
            If doublons > 0 Then pp.Add(Puce(doublons & " " & T("répété", "repeated", "repetido") & If(doublons > 1, "s", ""), "act"))
            If errs > 0 Then pp.Add(Puce(errs & " " & T("erreurs", "errors", "errores"), "bad"))
            Dim nomBouton As String
            Select Case def(0)
                Case "clients" : nomBouton = T("Créer {0} clients", "Create {0} customers", "Crear {0} clientes")
                Case "fournisseurs" : nomBouton = T("Créer {0} fournisseurs", "Create {0} suppliers", "Crear {0} proveedores")
                Case Else : nomBouton = T("Créer {0} produits", "Create {0} products", "Crear {0} productos")
            End Select
            Dim liste As Object()
            If def(0) = "produits" Then
                liste = New Object() {
                    Point(T("Reprendre nom, description, prix de vente et taxabilité", "Bring name, description, sale price and taxability", "Retomar nombre, descripción, precio de venta e imponibilidad"), EtatDe(lignes > 0, False)),
                    Point(T("N'en créer aucun en double", "Create none twice", "No crear ninguno en duplicado"), EtatDe(lignes > 0, False)),
                    Point(T("Créer les nouveaux produits et services", "Create the new products and services", "Crear los nuevos productos y servicios"), EtatDe(fait, crees > 0))}
            Else
                liste = New Object() {
                    Point(T("Lire l'export et découper l'adresse", "Read the export and split the address", "Leer la exportación y separar la dirección"), EtatDe(lignes > 0, False)),
                    Point(T("Signaler ce qui existe déjà et ce qui se répète", "Flag what already exists and what repeats", "Señalar lo que ya existe y lo que se repite"), EtatDe(lignes > 0, False)),
                    Point(If(def(0) = "clients", T("Créer les nouveaux clients et leur adresse", "Create the new customers and their address", "Crear los nuevos clientes y su dirección"),
                                                 T("Créer les nouveaux fournisseurs et leur adresse", "Create the new suppliers and their address", "Crear los nuevos proveedores y su dirección")), EtatDe(fait, crees > 0))}
            End If
            cartes.Add(New With {
                .k = def(0), .no = CInt(def(1)), .ico = def(0), .titre = def(4), .src = nomSrc,
                .etat = If(lignes = 0, "vide", If(fait, "fait", "afaire")),
                .liste = liste, .puces = pp, .n = lignes, .unite = UniteFiches(def(0)), .extra = "",
                .bouton = New With {.t = String.Format(nomBouton, nouveaux), .op = "creerFiches", .type = def(2), .actif = nouveaux > 0 AndAlso (def(0) <> "produits" OrElse planFait), .cache = nouveaux = 0},
                .voir = def(5),
                .pct = If(lignes = 0, 0, CInt(100 * (lignes - nouveaux) / lignes)),
                .dit = If(def(0) = "produits" AndAlso nouveaux > 0 AndAlso Not planFait,
                          T("Les produits attendent la fin du plan comptable : leurs comptes de vente et d'achat doivent d'abord exister. Ils se créeront d'eux-mêmes.", "Products wait for the chart of accounts to be finished: their sales and purchase accounts must exist first. They will be created automatically.", "Los productos esperan a que termine el plan contable: sus cuentas de venta y compra deben existir primero. Se crearán solos."),
                          String.Format(T("{0} nouvelles fiches prêtes à créer.", "{0} new records ready to create.", "{0} fichas nuevas listas para crear."), nouveaux))})
        Next

        ' ---- 6 : factures ------------------------------------------------------
        Dim nbDoc As Integer = 0, prets As Integer = 0, sansTiers As Integer = 0, aCorriger As Integer = 0, docCrees As Integer = 0, ouvertes As Integer = 0, deja As Integer = 0
        ' Les pièces que la source donne sans aucun client ni fournisseur (dépenses
        ' payées directement, frais bancaires…) : aucun tiers à créer ne les
        ' débloquera. Elles ne retiennent pas la carte.
        Dim sansPayeur As Integer = 0
        Try
            Dim docs As DataTable = Table(Lire("s0782GetDocumentsImport"), 0)
            If docs IsNot Nothing Then
                nbDoc = docs.Rows.Count
                For Each r As DataRow In docs.Rows
                    Dim statut As String = Txt(r, "Statut")
                    Dim cree As Boolean = Not IsDBNull(r("DocumentId"))
                    If Dec(r, "Solde") > 0D Then ouvertes += 1
                    If cree Then
                        docCrees += 1
                    ElseIf statut = "OK" AndAlso Not IsDBNull(r("PartyGUID")) Then
                        prets += 1
                    ElseIf statut = "OK" AndAlso Txt(r, "TiersExterneId").Trim() = "" AndAlso Txt(r, "TiersNom").Trim() = "" Then
                        sansPayeur += 1
                    ElseIf statut = "OK" Then
                        sansTiers += 1
                    ElseIf statut = "EXISTE" OrElse statut = "DOUBLON_FICHIER" Then
                        deja += 1
                    Else
                        aCorriger += 1
                    End If
                Next
            End If
        Catch
        End Try
        Dim p7 As New List(Of Object)
        If prets > 0 Then p7.Add(Puce(prets & " " & T("prêtes", "ready", "listas"), "ok"))
        If docCrees > 0 Then p7.Add(Puce(docCrees & " " & T("en brouillon", "in draft", "en borrador"), "ok"))
        If ouvertes > 0 Then p7.Add(Puce(ouvertes & " " & T("ouvertes", "open", "abiertas"), ""))
        If aCorriger > 0 Then p7.Add(Puce(aCorriger & " " & T("à corriger", "to fix", "por corregir"), "act"))
        If sansTiers > 0 Then p7.Add(Puce(sansTiers & " " & T("sans tiers : créez les tiers d'abord", "no party: create parties first", "sin tercero: cree los terceros primero"), "act"))
        If sansPayeur > 0 Then p7.Add(Puce(sansPayeur & " " & T("dépenses sans fournisseur dans la source : non reprises en factures", "expenses with no supplier in the source: not brought over as invoices", "gastos sin proveedor en el origen: no se retoman como facturas"), ""))
        cartes.Add(New With {
            .k = "factures", .no = 4, .ico = "factures", .titre = T("Factures clients et fournisseurs", "Customer and supplier invoices", "Facturas de clientes y proveedores"), .src = nomSrc,
            .etat = If(nbDoc - sansPayeur = 0, "vide", If(prets = 0 AndAlso sansTiers = 0 AndAlso aCorriger = 0, "fait", "afaire")),
            .liste = New Object() {
                Point(T("Un verdict par facture : nouvelle ou à corriger", "One verdict per invoice: new or to fix", "Un veredicto por factura: nueva o por corregir"), EtatDe(nbDoc > 0, False)),
                Point(T("Trier ouvertes et fermées", "Sort open and closed", "Ordenar abiertas y cerradas"), EtatDe(nbDoc > 0, False)),
                Point(T("Rapprocher le tiers que la source n'a pas retrouvé", "Match the party the source didn't find", "Conciliar el tercero que el origen no encontró"), EtatDe(nbDoc > 0 AndAlso sansTiers = 0, sansTiers > 0)),
                Point(T("Répartir TPS et TVQ, puis créer en brouillon", "Split GST and QST, then create as draft", "Repartir TPS y TVQ, luego crear en borrador"), EtatDe(nbDoc > 0 AndAlso prets = 0 AndAlso sansTiers = 0 AndAlso aCorriger = 0, docCrees > 0))},
            .puces = p7, .n = nbDoc, .unite = T("factures lues", "invoices read", "facturas leídas"), .extra = "",
            .bouton = New With {.t = String.Format(T("Créer {0} en brouillon", "Create {0} as draft", "Crear {0} en borrador"), prets), .op = "creerFactures", .actif = prets > 0 AndAlso planFait AndAlso produitsAFaire = 0},
            .voir = "ValiderFactures.aspx",
            .pct = If(nbDoc - sansPayeur <= 0, 0, CInt(100 * (docCrees + deja) / (nbDoc - sansPayeur))),
            .dit = If(prets > 0 AndAlso Not (planFait AndAlso produitsAFaire = 0),
                      T("Les factures attendent la fin du plan comptable et la création des produits : chaque ligne doit trouver son compte et son produit. Elles se créeront ensuite d'elles-mêmes, en brouillon.", "Invoices wait for the chart of accounts to be finished and the products to be created: each line must find its account and product. They will then be created automatically, as drafts.", "Las facturas esperan a que termine el plan contable y se creen los productos: cada línea debe encontrar su cuenta y su producto. Luego se crearán solas, en borrador."),
                  If(prets > 0, String.Format(T("{0} factures sont prêtes à créer en brouillon.", "{0} invoices are ready to create as draft.", "{0} facturas están listas para crear en borrador."), prets),
                  If(sansTiers = 0, T("Les factures sont créées. Les dépenses que la source donne sans fournisseur ne deviennent pas des factures.", "Invoices are created. Expenses the source gives with no supplier do not become invoices.", "Las facturas están creadas. Los gastos que el origen da sin proveedor no se convierten en facturas."),
                      T("Créez d'abord les clients et les fournisseurs : certaines factures n'ont pas encore de tiers.", "Create customers and suppliers first: some invoices have no party yet.", "Cree primero los clientes y proveedores: algunas facturas aún no tienen tercero."))))})

        ' ---- 7 : taxes ---------------------------------------------------------
        Dim tx As DataRow = Nothing
        ' Les codes à 0 % (Détaxé, Exonéré, Hors champ, Redressement) se classent
        ' d'après leur nom (T416) : sans eux, la carte ne se terminait jamais.
        Try
            Lire("s1037ClasserTaxesSansTaux")
        Catch
        End Try
        Try
            tx = Rang0(Table(Lire("s0871GetTaxesImportEcran"), 0))
        Catch
        End Try
        Dim nbTaux As Integer = Ent(tx, "NbTaux"), reconnues As Integer = Ent(tx, "NbReconnues"), aVerif As Integer = Ent(tx, "NbAVerifier"), inconnus As Integer = Ent(tx, "NbCodesInconnus")
        Dim p8 As New List(Of Object)
        If reconnues > 0 Then p8.Add(Puce(reconnues & " " & T("reconnus", "recognized", "reconocidos"), "ok"))
        If aVerif > 0 Then p8.Add(Puce(aVerif & " " & T("à vérifier", "to check", "por verificar"), "act"))
        If inconnus > 0 Then p8.Add(Puce(inconnus & " " & T("codes inconnus", "unknown codes", "códigos desconocidos"), "bad"))
        cartes.Add(New With {
            .k = "taxes", .no = 9, .ico = "taxes", .titre = T("Codes et taux de taxe", "Tax codes and rates", "Códigos y tasas de impuesto"), .src = nomSrc,
            .etat = If(nbTaux = 0, "vide", If(aVerif = 0 AndAlso inconnus = 0, "fait", "afaire")),
            .liste = New Object() {
                Point(T("Lire chaque code et ses composantes", "Read each code and its components", "Leer cada código y sus componentes"), EtatDe(nbTaux > 0, False)),
                Point(T("Classer au québécois : 14,975 % → TPS 5 % + TVQ 9,975 %", "Classify Quebec-style: 14.975% → GST 5% + QST 9.975%", "Clasificar a la quebequense: 14,975 % → TPS 5 % + TVQ 9,975 %"), EtatDe(nbTaux > 0, False)),
                Point(T("Signaler les codes sans taux, avec leur motif", "Flag codes without a rate, with the reason", "Señalar los códigos sin tasa, con su motivo"), EtatDe(nbTaux > 0 AndAlso aVerif = 0, aVerif > 0)),
                Point(T("Ajouter ou corriger un taux à la main", "Add or fix a rate by hand", "Agregar o corregir una tasa a mano"), EtatDe(nbTaux > 0 AndAlso aVerif = 0 AndAlso inconnus = 0, False))},
            .puces = p8, .n = nbTaux, .unite = T("codes de taxe", "tax codes", "códigos de impuesto"), .extra = "",
            .bouton = New With {.t = T("Vérifier les taux", "Check the rates", "Verificar las tasas"), .op = "page", .url = "ValiderTaxes.aspx", .actif = aVerif > 0 OrElse inconnus > 0},
            .voir = "ValiderTaxes.aspx",
            .pct = If(nbTaux = 0, 0, CInt(100 * reconnues / nbTaux)),
            .dit = String.Format(T("{0} taux de taxe sont à vérifier.", "{0} tax rates need checking.", "{0} tasas de impuesto por verificar."), aVerif + inconnus)})

        ' ---- 8 : encaissements et décaissements (s0826, lecture) ---------------
        ' Les paiements de la source et leurs imputations aux factures : acomptes
        ' (argent qui ne règle encore rien), imputations vers une facture non reprise.
        Dim regl As DataTable = Nothing, imputations As DataTable = Nothing
        Try
            Dim dsR As DataSet = Lire("s0826GetReglementsImport")
            regl = Table(dsR, 0) : imputations = Table(dsR, 2)
        Catch
        End Try
        ' Une imputation vers un document qui n'est pas en préparation (total NULL) :
        ' le paiement règle une facture qu'on ne reprend pas.
        Dim nbSansFacture As Integer = 0
        If imputations IsNot Nothing AndAlso imputations.Columns.Contains("DocumentTotal") Then
            For Each r As DataRow In imputations.Rows
                If IsDBNull(r("DocumentTotal")) Then nbSansFacture += 1
            Next
        End If
        Dim nbEnc As Integer = 0, nbDec As Integer = 0, totEnc As Decimal = 0D, totDec As Decimal = 0D
        Dim nbAcomptes As Integer = 0, totAcomptes As Decimal = 0D, nbAnoRegl As Integer = 0, nbImput As Integer = 0
        If regl IsNot Nothing Then
            For Each r As DataRow In regl.Rows
                If Txt(r, "Sens") = "Encaissement" Then
                    nbEnc += Ent(r, "NbMouvements") : totEnc += Dec(r, "Total")
                Else
                    nbDec += Ent(r, "NbMouvements") : totDec += Dec(r, "Total")
                End If
                nbAcomptes += Ent(r, "NbAcomptes") : totAcomptes += Dec(r, "TotalAcomptes")
                nbAnoRegl += Ent(r, "NbAnomalies") : nbImput += Ent(r, "NbImputations")
            Next
        End If
        nbAnoRegl += nbSansFacture
        Dim nbRegl As Integer = nbEnc + nbDec
        Dim pR As New List(Of Object)
        If nbEnc > 0 Then pR.Add(Puce(nbEnc & " " & T("encaissements", "receipts", "cobros") & " · " & Montant(totEnc), "ok"))
        If nbDec > 0 Then pR.Add(Puce(nbDec & " " & T("décaissements", "disbursements", "pagos") & " · " & Montant(totDec), "ok"))
        If nbAcomptes > 0 Then pR.Add(Puce(nbAcomptes & " " & T("acomptes", "deposits", "anticipos") & " · " & Montant(totAcomptes), "act"))
        If nbAnoRegl > 0 Then pR.Add(Puce(nbAnoRegl & " " & T("anomalies", "issues", "anomalías"), "bad"))
        cartes.Add(New With {
            .k = "reglements", .no = 7, .ico = "reglements", .titre = T("Encaissements et décaissements", "Receipts and disbursements", "Cobros y pagos"), .src = nomSrc,
            .etat = If(nbRegl = 0, "vide", If(nbAnoRegl = 0, "fait", "afaire")),
            .liste = New Object() {
                Point(T("Lire les paiements reçus et les paiements faits", "Read the payments received and made", "Leer los pagos recibidos y hechos"), EtatDe(nbRegl > 0, False)),
                Point(T("Relier chaque paiement à ses factures", "Link each payment to its invoices", "Vincular cada pago a sus facturas"), EtatDe(nbRegl > 0, False)),
                Point(T("Repérer les acomptes : l'argent qui ne règle encore aucune facture", "Spot deposits: money that settles no invoice yet", "Detectar los anticipos: dinero que aún no salda ninguna factura"), EtatDe(nbRegl > 0, nbAcomptes > 0)),
                Point(T("Signaler les paiements vers une facture non reprise", "Flag payments to an invoice not brought in", "Señalar los pagos hacia una factura no importada"), EtatDe(nbRegl > 0 AndAlso nbAnoRegl = 0, nbAnoRegl > 0))},
            .puces = pR, .n = nbRegl, .unite = T("paiements", "payments", "pagos"), .extra = "",
            .bouton = New With {.t = T("Vérifier les paiements", "Check the payments", "Verificar los pagos"), .op = "page", .url = "ValiderReglements.aspx", .actif = nbRegl > 0},
            .voir = "ValiderReglements.aspx",
            .pct = If(nbRegl = 0, 0, If(nbAnoRegl = 0, 100, 60)),
            .dit = If(nbAnoRegl > 0,
                      String.Format(T("{0} paiements ont une anomalie à vérifier.", "{0} payments have an issue to check.", "{0} pagos tienen una anomalía por verificar."), nbAnoRegl),
                      String.Format(T("{0} paiements lus, {1} imputations aux factures.", "{0} payments read, {1} applications to invoices.", "{0} pagos leídos, {1} imputaciones a facturas."), nbRegl, nbImput))})

        ' ---- 9 : rapprochement bancaire (s0828, lecture) ----------------------
        ' Les opérations pas encore pointées à la bascule : chèques émis et dépôts
        ' faits avant, compensés après. Le premier rapprochement en dépend.
        Dim rap As DataRow = Nothing
        Try
            rap = Rang0(Table(Lire("s0828GetOperationsRapprochement"), 0))
        Catch
        End Try
        Dim nbOps As Integer = Ent(rap, "NbOperations"), nbNonPointees As Integer = Ent(rap, "NbNonPointees")
        Dim montantNP As Decimal = Dec(rap, "MontantNonPointe"), nbComptesRap As Integer = Ent(rap, "NbComptes")
        Dim pB As New List(Of Object)
        If nbNonPointees > 0 Then pB.Add(Puce(nbNonPointees & " " & T("non pointées", "uncleared", "no punteadas") & " · " & Montant(montantNP), "act"))
        If nbComptesRap > 0 Then pB.Add(Puce(nbComptesRap & " " & T("comptes", "accounts", "cuentas"), ""))
        If nbOps > 0 AndAlso nbNonPointees = 0 Then pB.Add(Puce(T("Tout est pointé", "Everything cleared", "Todo punteado"), "ok"))
        cartes.Add(New With {
            .k = "rapprochement", .no = 8, .ico = "rapprochement", .titre = T("Rapprochement bancaire", "Bank reconciliation", "Conciliación bancaria"), .src = nomSrc,
            .etat = If(nbOps = 0, "vide", "fait"),
            .liste = New Object() {
                Point(T("Lire l'état de pointage de chaque opération", "Read the cleared status of each transaction", "Leer el estado de punteo de cada operación"), EtatDe(nbOps > 0, False)),
                Point(T("Garder les chèques et dépôts en circulation à la bascule", "Keep the cheques and deposits outstanding at switch-over", "Conservar los cheques y depósitos en tránsito al cambio"), EtatDe(nbOps > 0, False)),
                Point(T("Les présenter au premier rapprochement dans 60secondes", "Present them at the first reconciliation in 60secondes", "Presentarlos en la primera conciliación en 60secondes"), EtatDe(False, nbNonPointees > 0))},
            .puces = pB, .n = nbOps, .unite = T("opérations", "transactions", "operaciones"), .extra = "",
            .bouton = New With {.t = String.Format(T("Voir les {0} opérations", "See the {0} transactions", "Ver las {0} operaciones"), nbNonPointees), .op = "page", .url = "ValiderNonRapprochees.aspx", .actif = nbNonPointees > 0},
            .voir = "ValiderNonRapprochees.aspx",
            .pct = If(nbOps = 0, 0, 100),
            .dit = If(nbNonPointees > 0,
                      String.Format(T("{0} opérations n'étaient pas pointées à la bascule ({1}) : elles attendront le premier rapprochement.", "{0} transactions were not cleared at switch-over ({1}): they will wait for the first reconciliation.", "{0} operaciones no estaban punteadas al cambio ({1}): esperarán la primera conciliación."), nbNonPointees, Montant(montantNP)),
                      T("Tout était pointé à la bascule.", "Everything was cleared at switch-over.", "Todo estaba punteado al cambio."))})

        ' ---- 7 : comptes bancaires (s0825, lecture) -----------------------------
        Dim cb As DataRow = Nothing
        Try
            cb = Rang0(Table(Lire("s0825GetComptesBancaires"), 0))
        Catch
        End Try
        Dim nbCB As Integer = Ent(cb, "NbComptes"), nbCBActifs As Integer = Ent(cb, "NbActifs"), nbCartes As Integer = Ent(cb, "NbCartes")
        Dim pCB As New List(Of Object)
        If nbCBActifs > 0 Then pCB.Add(Puce(nbCBActifs & " " & T("actifs", "active", "activas"), "ok"))
        If nbCartes > 0 Then pCB.Add(Puce(nbCartes & " " & T("cartes de crédit", "credit cards", "tarjetas de crédito"), ""))
        If nbCB - nbCBActifs > 0 Then pCB.Add(Puce((nbCB - nbCBActifs) & " " & T("inactifs", "inactive", "inactivas"), ""))
        cartes.Add(New With {
            .k = "comptesbanque", .no = 6, .ico = "comptesbanque", .titre = T("Comptes bancaires", "Bank accounts", "Cuentas bancarias"), .src = nomSrc,
            .etat = If(nbCB = 0, "vide", "fait"),
            .liste = New Object() {
                Point(T("Lire les comptes de banque et de carte de crédit", "Read the bank and credit card accounts", "Leer las cuentas bancarias y de tarjeta de crédito"), EtatDe(nbCB > 0, False)),
                Point(T("Relever le solde de chaque compte à la date d'arrêté", "Note each account's balance at the cut-off date", "Anotar el saldo de cada cuenta a la fecha de corte"), EtatDe(nbCB > 0, False)),
                Point(T("Les confronter aux soldes de la balance", "Compare them with the trial balance", "Compararlos con la balanza"), EtatDe(nbCB > 0, False))},
            .puces = pCB, .n = nbCB, .unite = T("comptes", "accounts", "cuentas"), .extra = If(nbCB > 0, " · " & Montant(Dec(cb, "TotalSoldes")), ""),
            .bouton = New With {.t = T("Voir les soldes", "See the balances", "Ver los saldos"), .op = "page", .url = "ValiderSoldesBancaires.aspx", .actif = nbCB > 0},
            .voir = "ValiderSoldesBancaires.aspx",
            .pct = If(nbCB = 0, 0, 100),
            .dit = String.Format(T("{0} comptes bancaires et cartes de crédit lus.", "{0} bank accounts and credit cards read.", "{0} cuentas bancarias y tarjetas de crédito leídas."), nbCB)})

        ' ---- 11 : rapports de taxes déclarées (s0823, lecture) -----------------
        Dim rt As DataRow = Nothing
        Try
            rt = Rang0(Table(Lire("s0823GetRapportTaxes"), 0))
        Catch
        End Try
        Dim nbPeriodes As Integer = Ent(rt, "NbPeriodes"), nbAgences As Integer = Ent(rt, "NbAgences"), nbLignesRT As Integer = Ent(rt, "NbLignes")
        Dim pRT As New List(Of Object)
        If nbPeriodes > 0 Then pRT.Add(Puce(nbPeriodes & " " & T("périodes", "periods", "períodos"), "ok"))
        If nbAgences > 0 Then pRT.Add(Puce(nbAgences & " " & T("agences", "agencies", "agencias"), ""))
        If nbPeriodes > 0 Then pRT.Add(Puce(Txt(rt, "PeriodeDebut") & " → " & Txt(rt, "PeriodeFin"), ""))
        cartes.Add(New With {
            .k = "rapportstaxes", .no = 10, .ico = "rapportstaxes", .titre = T("Rapports de taxes", "Tax reports", "Informes de impuestos"), .src = nomSrc,
            .etat = If(nbPeriodes = 0, "vide", "fait"),
            .liste = New Object() {
                Point(T("Lire les déclarations de TPS et TVQ par période", "Read the GST and QST returns by period", "Leer las declaraciones de TPS y TVQ por período"), EtatDe(nbPeriodes > 0, False)),
                Point(T("Garder chaque ligne de la déclaration (101 à 217)", "Keep each line of the return (101 to 217)", "Conservar cada línea de la declaración (101 a 217)"), EtatDe(nbPeriodes > 0, False)),
                Point(T("Partir du bon solde à la première déclaration dans 60secondes", "Start from the right balance at the first return in 60secondes", "Partir del saldo correcto en la primera declaración en 60secondes"), EtatDe(False, nbPeriodes > 0))},
            .puces = pRT, .n = nbLignesRT, .unite = T("lignes de déclaration", "return lines", "líneas de declaración"), .extra = "",
            .bouton = New With {.t = T("Voir les déclarations", "See the returns", "Ver las declaraciones"), .op = "page", .url = "ValiderRapportTaxes.aspx", .actif = nbPeriodes > 0},
            .voir = "ValiderRapportTaxes.aspx",
            .pct = If(nbPeriodes = 0, 0, 100),
            .dit = String.Format(T("{0} périodes de déclaration de taxes lues.", "{0} tax return periods read.", "{0} períodos de declaración leídos."), nbPeriodes)})

        ' ---- 12 : paie (s0830, lecture) -----------------------------------------
        Dim pa As DataRow = Nothing
        Try
            pa = Rang0(Table(Lire("s0830GetPaie"), 0))
        Catch
        End Try
        Dim nbEmp As Integer = Ent(pa, "NbEmployes"), nbPaies As Integer = Ent(pa, "NbPaies"), nbAnoPaie As Integer = Ent(pa, "NbAnomalies")
        Dim pPaie As New List(Of Object)
        If nbEmp > 0 Then pPaie.Add(Puce(nbEmp & " " & T("employés", "employees", "empleados"), "ok"))
        If nbPaies > 0 Then pPaie.Add(Puce(nbPaies & " " & T("paies", "pays", "pagas") & " · " & T("brut", "gross", "bruto") & " " & Montant(Dec(pa, "TotalBrut")), ""))
        If nbAnoPaie > 0 Then pPaie.Add(Puce(nbAnoPaie & " " & T("anomalies", "issues", "anomalías"), "bad"))
        cartes.Add(New With {
            .k = "paie", .no = 11, .ico = "paie", .titre = T("Paie", "Payroll", "Nómina"), .src = nomSrc,
            .etat = If(nbEmp = 0 AndAlso nbPaies = 0, "vide", If(nbAnoPaie = 0, "fait", "afaire")),
            .liste = New Object() {
                Point(T("Lire les employés : poste, taux, vacances, dépôt direct", "Read the employees: position, rate, vacation, direct deposit", "Leer los empleados: puesto, tasa, vacaciones, depósito directo"), EtatDe(nbEmp > 0, False)),
                Point(T("Lire les paies et leurs retenues (impôts, RRQ, AE, RQAP)", "Read the pays and their deductions (taxes, QPP, EI, QPIP)", "Leer las pagas y sus retenciones (impuestos, RRQ, AE, RQAP)"), EtatDe(nbPaies > 0, False)),
                Point(T("Garder le cumul de l'année pour les feuillets", "Keep the year-to-date for the slips", "Conservar el acumulado del año para los comprobantes"), EtatDe(nbPaies > 0 AndAlso nbAnoPaie = 0, False)),
                Point(T("Signaler les paies dont le net ne balance pas", "Flag pays whose net does not balance", "Señalar las pagas cuyo neto no cuadra"), EtatDe(nbPaies > 0 AndAlso nbAnoPaie = 0, nbAnoPaie > 0))},
            .puces = pPaie, .n = nbPaies, .unite = T("paies", "pays", "pagas"), .extra = "",
            .bouton = New With {.t = T("Vérifier la paie", "Check the payroll", "Verificar la nómina"), .op = "page", .url = "ValiderPaie.aspx", .actif = nbEmp > 0 OrElse nbPaies > 0},
            .voir = "ValiderPaie.aspx",
            .pct = If(nbPaies = 0, 0, If(nbAnoPaie = 0, 100, 60)),
            .dit = If(nbAnoPaie > 0,
                      String.Format(T("{0} paies ont une anomalie à vérifier.", "{0} pays have an issue to check.", "{0} pagas tienen una anomalía por verificar."), nbAnoPaie),
                      String.Format(T("{0} employés et {1} paies lus.", "{0} employees and {1} pays read.", "{0} empleados y {1} pagas leídos."), nbEmp, nbPaies))})

        ' ---- 13 : fiche de la compagnie (s0789 ; s0791 applique, à l'écran) -----
        Dim soc As DataTable = Nothing
        Try
            soc = Table(Lire("s0789GetSocieteImport"), 0)
        Catch
        End Try
        Dim nbChamps As Integer = 0, nbDiff As Integer = 0, nbIdent As Integer = 0, nbApp As Integer = 0
        If soc IsNot Nothing Then
            For Each r As DataRow In soc.Rows
                nbChamps += 1
                Dim statutSoc As String = Txt(r, "Statut")
                If Not IsDBNull(r("AppliqueLe")) Then
                    nbApp += 1
                ElseIf statutSoc = "DIFFERENT" Then
                    nbDiff += 1
                ElseIf statutSoc = "IDENTIQUE" Then
                    nbIdent += 1
                End If
            Next
        End If
        ' ---- 1 : compagnie, clients et fournisseurs — une seule carte ------------
        ' Les trois se font d'eux-mêmes à l'arrivée au tableau (ArriveeAuTableau) :
        ' la fiche reprend les champs que QuickBooks donne autrement, les nouveaux
        ' clients et fournisseurs sont créés. La carte montre les trois chiffres.
        Dim fichesAFaire As Integer = cliNouveaux + fouNouveaux
        Dim errTiers As Integer = cliErr + fouErr
        Dim pS As New List(Of Object)
        If nbDiff > 0 Then pS.Add(Puce(nbDiff & " " & T("champs différents", "fields different", "campos diferentes"), "act"))
        If nbApp > 0 Then pS.Add(Puce(nbApp & " " & T("champs repris", "fields applied", "campos aplicados"), "ok"))
        If fichesAFaire > 0 Then pS.Add(Puce(fichesAFaire & " " & T("fiches à créer", "records to create", "fichas por crear"), "act"))
        If errTiers > 0 Then pS.Add(Puce(errTiers & " " & T("erreurs", "errors", "errores"), "bad"))
        Dim videTiers As Boolean = nbChamps = 0 AndAlso cliLignes = 0 AndAlso fouLignes = 0
        Dim faitTiers As Boolean = nbDiff = 0 AndAlso fichesAFaire = 0
        Dim boutonTiers As Object
        If fichesAFaire > 0 Then
            boutonTiers = New With {.t = String.Format(T("Créer {0} fiches", "Create {0} records", "Crear {0} fichas"), fichesAFaire), .op = "creerTiers", .url = "", .actif = True, .cache = False}
        Else
            boutonTiers = New With {.t = String.Format(T("Comparer {0} champs", "Compare {0} fields", "Comparar {0} campos"), nbDiff), .op = "page", .url = "ValiderSociete.aspx", .actif = nbDiff > 0, .cache = nbDiff = 0}
        End If
        cartes.Add(New With {
            .k = "tiers", .no = 1, .ico = "tiers", .titre = T("Compagnie, clients et fournisseurs", "Company, customers and suppliers", "Compañía, clientes y proveedores"), .src = nomSrc,
            .etat = If(videTiers, "vide", If(faitTiers, "fait", "afaire")),
            .liste = New Object() {
                Point(T("Reprendre la fiche de la compagnie : nom légal, adresse, téléphone", "Apply the company profile: legal name, address, phone", "Aplicar la ficha de la compañía: nombre legal, dirección, teléfono"), EtatDe(nbChamps > 0 AndAlso nbDiff = 0, nbDiff > 0)),
                Point(T("Créer les nouveaux clients et leur adresse", "Create the new customers and their address", "Crear los nuevos clientes y su dirección"), EtatDe(cliLignes > 0 AndAlso cliNouveaux = 0, cliCrees > 0)),
                Point(T("Créer les nouveaux fournisseurs et leur adresse", "Create the new suppliers and their address", "Crear los nuevos proveedores y su dirección"), EtatDe(fouLignes > 0 AndAlso fouNouveaux = 0, fouCrees > 0)),
                Point(T("N'en créer aucun en double", "Create none twice", "No crear ninguno en duplicado"), EtatDe(cliLignes + fouLignes > 0, False))},
            .puces = pS, .n = cliLignes + fouLignes, .unite = T("fiches", "records", "fichas"), .extra = "",
            .chiffres = New Object() {
                New With {.n = nbChamps, .t = T("champs de la fiche", "profile fields", "campos de la ficha"), .c = If(nbDiff = 0, "ok", "dec")},
                New With {.n = cliLignes, .t = T("clients", "customers", "clientes"), .c = If(cliNouveaux = 0, "ok", "dec")},
                New With {.n = fouLignes, .t = T("fournisseurs", "suppliers", "proveedores"), .c = If(fouNouveaux = 0, "ok", "dec")}},
            .bouton = boutonTiers,
            .voir = "ImportClients.aspx",
            .pct = If(videTiers, 0, If(faitTiers, 100, 60)),
            .dit = If(faitTiers,
                      String.Format(T("Fiche de la compagnie à jour, {0} clients et {1} fournisseurs repris.", "Company profile up to date, {0} customers and {1} suppliers brought in.", "Ficha de la compañía al día, {0} clientes y {1} proveedores importados."), cliLignes, fouLignes),
                      String.Format(T("{0} champs de la fiche et {1} fiches restent à reprendre.", "{0} profile fields and {1} records remain to bring in.", "Quedan {0} campos de la ficha y {1} fichas por importar."), nbDiff, fichesAFaire))})

        ' L'ordre affiché suit le numéro : 1 Compagnie, clients et fournisseurs,
        ' 2 Plan comptable, 3 Produits, 4 Factures, 5 Balance, 6 Comptes bancaires,
        ' 7 Encaissements et décaissements, 8 Rapprochement bancaire, 9 Codes et taux
        ' de taxe, 10 Rapports de taxes, 11 Paie (le calcul, lui, garde son ordre :
        ' le plan doit être lu avant les produits, les factures et la balance).
        Dim ordonnees As List(Of Object) = cartes.OrderBy(Function(c) CInt(c.GetType().GetProperty("no").GetValue(c))).ToList()

        Dim prep As DonneesEnPreparation = Preparation()
        Return New With {
            .cartes = ordonnees,
            .comptesDecides = decides, .comptesTotal = total, .aDecider = aDecider,
            .fichesCreees = fichesCreees, .facturesBrouillon = docCrees,
            .balanceEquilibree = equilibree, .balanceTotal = If(nbBal > 0, Montant(debit), ""),
            .ressources = If(prep Is Nothing, 0, prep.ressources), .enregistrements = If(prep Is Nothing, 0, prep.nb),
            .bascule = Bascule, .basculeSource = Not String.IsNullOrEmpty(Bascule) AndAlso Bascule = DateProposee()}
    End Function

    Private Function NomSource() As String
        Dim nom As String
        Select Case Logiciel
            Case "qbo" : nom = "QuickBooks Online"
            Case "xero" : nom = "Xero"
            Case "sagebca" : nom = "Sage"
            Case "fresh" : nom = "FreshBooks"
            Case "wave" : nom = "Wave"
            Case "zoho" : nom = "Zoho Books"
            Case Else : nom = T("Votre logiciel", "Your software", "Su software")
        End Select
        Return nom & ", " & If(Mode = "fichier", T("par fichiers", "by files", "por archivos"), T("en direct", "live", "en directo"))
    End Function

    ''' <summary>Ce que compte une carte de fiches : « 172 clients », « 138 fournisseurs », « 214 produits ».</summary>
    Private Function UniteFiches(k As String) As String
        Select Case k
            Case "clients" : Return T("clients", "customers", "clientes")
            Case "fournisseurs" : Return T("fournisseurs", "suppliers", "proveedores")
            Case Else : Return T("produits et services", "products and services", "productos y servicios")
        End Select
    End Function

    ''' <summary>Le plan comptable est-il terminé : tout décidé (s0758), plus rien à créer (s0766) ?</summary>
    Private Function PlanTermine() As Boolean
        Try
            Dim st As DataRow = Rang0(Table(Lire("s0758StatsCorrespondance"), 0))
            Dim t0 As DataTable = Table(Lire("s0766GetAAppliquer"), 0)
            Return Ent(st, "Total") > 0 AndAlso Ent(st, "ADecider") = 0 AndAlso (t0 Is Nothing OrElse t0.Rows.Count = 0)
        Catch
            Return False
        End Try
    End Function

    ''' <summary>Cartes 1, 2 et 5 : crée les nouvelles fiches du dernier fichier (s0774, comme ImportDonnees.ascx).</summary>
    Private Function CreerFiches(typeImport As String) As Object
        If Array.IndexOf({"Client", "Fournisseur", "Produit"}, typeImport) < 0 Then
            Return New With {.ok = False, .erreur = T("Type inconnu.", "Unknown type.", "Tipo desconocido.")}
        End If
        If typeImport = "Produit" AndAlso Not PlanTermine() Then
            Return New With {.ok = False, .erreur = T("Terminez d'abord le plan comptable : les comptes de vente et d'achat des produits doivent exister.", "Finish the chart of accounts first: the products' sales and purchase accounts must exist.", "Termine primero el plan contable: las cuentas de venta y compra de los productos deben existir.")}
        End If
        Dim fid As Integer = 0
        FichierImport(typeImport, fid)
        If fid = 0 Then Return New With {.ok = False, .erreur = T("Rien en préparation pour ce type.", "Nothing in preparation for this type.", "Nada en preparación para este tipo.")}

        Dim r As DataRow = Rang0(Table(Lire("s0774AppliquerImportFichier", New SqlClient.SqlParameter("@ImportFileId", fid)), 0))
        Dim msg As String = String.Format(T("{0} créés, {1} écartés, {2} erreurs.", "{0} created, {1} skipped, {2} errors.", "{0} creados, {1} descartados, {2} errores."),
                                          Ent(r, "Migrated"), Ent(r, "Skipped"), Ent(r, "Errors"))
        Return New With {.ok = True, .message = msg, .tableau = Tableau()}
    End Function

    ''' <summary>
    ''' Carte 4 : l'écriture d'ouverture tirée de la balance (s1025, T401), au
    ''' journal OD, datée de la date de début de la comptabilité, en brouillon. Le dernier jeu de
    ''' résultats est le statut ; l'avant-dernier, les lignes qui bloquent.
    ''' </summary>
    Private Function SoldesOuverture(creer As Boolean) As DataSet
        Dim d As Date
        Dim bascule As Object = DBNull.Value
        If Date.TryParseExact(Bascule, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, d) Then bascule = d
        Return Lire("s1025SoldesOuverture",
                    New SqlClient.SqlParameter("@DateBascule", bascule),
                    New SqlClient.SqlParameter("@UserId", UserId),
                    New SqlClient.SqlParameter("@Creer", creer))
    End Function

    ''' <summary>
    ''' Vrai si la balance en préparation est une balance d'OUVERTURE : arrêtée avant
    ''' la date de début (le « … au AAAA-MM-JJ » de son nom). Arrêtée à la date de
    ''' début ou après — du début de l'exercice à aujourd'hui —, c'est un contrôle :
    ''' en tirer des soldes d'ouverture compterait deux fois les opérations reprises.
    ''' </summary>
    Private Function BalanceDOuverture(bal As DataTable, ByRef fin As String) As Boolean
        fin = ""
        For Each r As DataRow In bal.Rows
            Dim m = System.Text.RegularExpressions.Regex.Match(Txt(r, "NomFichier"), "au (\d{4}-\d{2}-\d{2})\s*$")
            If m.Success Then fin = m.Groups(1).Value : Exit For
        Next
        Dim dFin As Date, dDebut As Date
        If fin = "" OrElse Not Date.TryParseExact(fin, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, dFin) Then Return True
        If Not Date.TryParseExact(Bascule, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, dDebut) Then
            If Not Date.TryParseExact(DebutExercice(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, dDebut) Then Return True
        End If
        Return dFin < dDebut
    End Function

    Private Function CreerOuverture() As Object
        Dim balO As DataTable = Nothing, finO As String = ""
        Try
            balO = Table(Lire("s0770GetBalanceVerification"), 0)
        Catch
        End Try
        If balO IsNot Nothing AndAlso balO.Rows.Count > 0 AndAlso Not BalanceDOuverture(balO, finO) Then
            Return New With {.ok = False, .erreur = String.Format(T("La balance va jusqu'au {0} : c'est un contrôle, pas une balance d'ouverture. Les opérations de l'exercice sont reprises une à une.", "The trial balance runs to {0}: it is a control, not an opening balance. The year's transactions are brought over one by one.", "La balanza va hasta el {0}: es un control, no una balanza de apertura. Las operaciones del ejercicio se retoman una a una."), finO)}
        End If
        If Not PlanTermine() Then
            Return New With {.ok = False, .erreur = T("Terminez d'abord le plan comptable : chaque solde d'ouverture doit tomber sur le compte décidé.", "Finish the chart of accounts first: each opening balance must land on the decided account.", "Termine primero el plan contable: cada saldo de apertura debe caer en la cuenta decidida.")}
        End If
        Dim ds As DataSet = SoldesOuverture(True)
        Dim r As DataRow = Rang0(Table(ds, ds.Tables.Count - 1))
        Dim statut As String = Txt(r, "Statut")
        If statut <> "CREE" Then
            Return New With {.ok = False, .erreur = If(Txt(r, "Message") <> "", Txt(r, "Message"), T("L'écriture d'ouverture n'a pas pu être créée.", "The opening entry could not be created.", "No se pudo crear el asiento de apertura."))}
        End If
        Return New With {.ok = True, .message = Txt(r, "Message"), .tableau = Tableau()}
    End Function

    ''' <summary>Carte 6 : crée en brouillon les factures prêtes (s0785, comme ValiderFactures.aspx).</summary>
    ''' <summary>
    ''' Crée en brouillon (s0785) toutes les factures prêtes : nouvelles, statut OK,
    ''' tiers retrouvé. Les tiers sont d'abord résolus (s0855), pour que les clients
    ''' et fournisseurs créés depuis le dernier passage comptent. Nothing si aucune.
    ''' </summary>
    Private Function CreerFacturesPretes() As DataRow
        ' TPS et TVQ d'abord (s0794, où le total de taxes de la source fait foi
        ' quand elle est cohérente — T409), puis tiers, comptes et produits.
        Try
            Lire("s0794RepartirTaxesImport")
        Catch
        End Try
        Lire("s0855ResoudreDocumentsImport")
        ' Les pièces fournisseur sans aucun fournisseur dans la source vont à
        ' « Fournisseurs divers » (T410) — après s0855, qui remettrait leur tiers à vide.
        Try
            Lire("s1032AttribuerFournisseurDivers")
        Catch
        End Try
        Dim ids As New List(Of String)
        Dim docs As DataTable = Table(Lire("s0782GetDocumentsImport"), 0)
        If docs IsNot Nothing Then
            For Each r As DataRow In docs.Rows
                If IsDBNull(r("DocumentId")) AndAlso Txt(r, "Statut") = "OK" AndAlso Not IsDBNull(r("PartyGUID")) Then ids.Add(Txt(r, "Id"))
            Next
        End If
        If ids.Count = 0 Then Return Nothing
        Return Rang0(Table(Lire("s0785CreerDocumentsDepuisImport",
                                New SqlClient.SqlParameter("@Ids", String.Join(",", ids)),
                                New SqlClient.SqlParameter("@UserId", UserId)), 0))
    End Function

    Private Function CreerFactures() As Object
        ' Chaque ligne doit trouver son compte (plan terminé) et son produit (produits créés).
        If Not PlanTermine() Then
            Return New With {.ok = False, .erreur = T("Terminez d'abord le plan comptable : chaque ligne de facture doit trouver son compte.", "Finish the chart of accounts first: each invoice line must find its account.", "Termine primero el plan contable: cada línea de factura debe encontrar su cuenta.")}
        End If
        Dim fidProd As Integer = 0
        Dim rp As DataRow = FichierImport("Produit", fidProd)
        If fidProd > 0 AndAlso Ent(rp, "Nouveaux") > 0 Then
            Return New With {.ok = False, .erreur = T("Créez d'abord les produits : chaque ligne de facture doit trouver son produit.", "Create the products first: each invoice line must find its product.", "Cree primero los productos: cada línea de factura debe encontrar su producto.")}
        End If
        Dim r0 As DataRow = CreerFacturesPretes()
        If r0 Is Nothing Then Return New With {.ok = False, .erreur = T("Aucune facture n'est prête.", "No invoice is ready.", "Ninguna factura está lista.")}
        Dim msg As String = String.Format(T("{0} factures créées en brouillon. {1} sans tiers, {2} écartées, {3} déséquilibrées.",
                                            "{0} invoices created as draft. {1} without party, {2} skipped, {3} unbalanced.",
                                            "{0} facturas creadas en borrador. {1} sin tercero, {2} descartadas, {3} desequilibradas."),
                                          Ent(r0, "NbCrees"), Ent(r0, "NbSansTiers"), Ent(r0, "NbEcartes"), Ent(r0, "NbDesequilibres"))
        Return New With {.ok = True, .message = msg, .tableau = Tableau()}
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
            .vider = T("Recommencer l'assistant", "Restart the wizard", "Reiniciar el asistente"),
            .viderTip = T("Défait ce que l'importation a créé et revient à l'étape 1 ; les données importées de QuickBooks restent", "Undoes what the import created and goes back to step 1; the data imported from QuickBooks stays", "Deshace lo que creó la importación y vuelve al paso 1; los datos importados de QuickBooks se quedan"),
            .viderConfirme = T("Tout ce que l'importation a créé sera retiré : les comptes créés au plan, les clients, fournisseurs et produits créés, les factures en brouillon et l'écriture d'ouverture. Chaque compte redevient « à décider » et l'assistant revient à l'étape 1. Les données importées de QuickBooks restent, prêtes à être reprises. Ce qui a été validé depuis, ou utilisé ailleurs, est gardé.", "Everything the import created will be removed: the accounts created in the chart, the customers, suppliers and products created, the draft invoices and the opening entry. Every account goes back to ""to decide"" and the wizard returns to step 1. The data imported from QuickBooks stays, ready to be imported again. Anything validated since, or used elsewhere, is kept.", "Se retirará todo lo que creó la importación: las cuentas creadas en el plan, los clientes, proveedores y productos creados, las facturas en borrador y el asiento de apertura. Cada cuenta vuelve a «por decidir» y el asistente vuelve al paso 1. Los datos importados de QuickBooks se quedan, listos para importarse de nuevo. Lo validado desde entonces, o usado en otro lugar, se conserva."),
            .viderOk = T("Assistant recommencé", "Wizard restarted", "Asistente reiniciado"),
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
            .e3 = T("Compagnie, clients et fournisseurs", "Company, customers and suppliers", "Compañía, clientes y proveedores"),
            .e4 = T("Plan comptable", "Chart of accounts", "Plan contable"),
            .e5 = T("Produits et factures", "Products and invoices", "Productos y facturas"),
            .e6 = T("Balance, banque, taxes et paie", "Balance, bank, taxes and payroll", "Balanza, banco, impuestos y nómina"),
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
            .date = T("Date de début de la comptabilité", "Accounting start date", "Fecha de inicio de la contabilidad"),
            .dateAide = T("Le premier jour de la comptabilité dans 60secondes : proposée d'après le début des livres dans QuickBooks. La balance est lue à cette date.", "The first day of the accounting in 60secondes: suggested from the start of the books in QuickBooks. The trial balance is read at this date.", "El primer día de la contabilidad en 60secondes: propuesta según el inicio de los libros en QuickBooks. La balanza se lee en esta fecha."),
            .dateLue = T("Date de début de la comptabilité : le {0}, proposée d'après {w} (clôture des livres, sinon début de l'exercice en cours, jamais avant le début des livres).", "Accounting start date: {0}, suggested from {w} (books close date, otherwise start of the current fiscal year, never before the start of the books).", "Fecha de inicio de la contabilidad: el {0}, propuesta según {w} (cierre de los libros, si no inicio del ejercicio en curso, nunca antes del inicio de los libros)."),
            .dateALire = T("Date de début de la comptabilité : elle sera proposée d'après {w} (clôture des livres, sinon début de l'exercice en cours).", "Accounting start date: it will be suggested from {w} (books close date, otherwise start of the current fiscal year).", "Fecha de inicio de la contabilidad: se propondrá según {w} (cierre de los libros, si no inicio del ejercicio en curso)."),
            .dateManuelle = T("Choisir une date manuellement", "Choose a date manually", "Elegir una fecha manualmente"),
            .exercice = T("Date de début de l'exercice", "Fiscal year start date", "Fecha de inicio del ejercicio"),
            .importEffaceTitre = T("L'import remplace toute la comptabilité", "The import replaces all the accounting", "La importación reemplaza toda la contabilidad"),
            .importEffaceOk = T("Effacer et importer", "Erase and import", "Borrar e importar"),
            .importEfface = T("Avant d'importer depuis {n}, toute la comptabilité de {0} est effacée : factures, règlements, écritures, clients, fournisseurs, produits et rendez-vous ; le plan comptable revient au plan par défaut. Les données de {n} prennent leur place. Les taxes et les paramètres (taux, numéros TPS et TVQ, fin d'exercice, fréquence de déclaration) sont remplacés par ceux de {n}. L'exercice, les journaux et les autres paramètres (courriel, PDF, numérotation) restent. Continuer ?",
                              "Before importing from {n}, all of {0}'s accounting is erased: invoices, payments, entries, customers, suppliers, products and appointments; the chart of accounts goes back to the default one. The data from {n} takes its place. Taxes and settings (rates, GST and QST numbers, fiscal year end, filing frequency) are replaced by those of {n}. The fiscal year, journals and other settings (email, PDF, numbering) stay. Continue?",
                              "Antes de importar desde {n}, se borra toda la contabilidad de {0}: facturas, pagos, asientos, clientes, proveedores, productos y citas; el plan contable vuelve al plan por defecto. Los datos de {n} ocupan su lugar. Los impuestos y los parámetros (tasas, números TPS y TVQ, fin del ejercicio, frecuencia de declaración) se reemplazan por los de {n}. El ejercicio, los diarios y los demás parámetros (correo, PDF, numeración) se mantienen. ¿Continuar?"),
            .exerciceAide = T("QuickBooks n'a pas de date de début d'exercice : on n'y choisit que le premier mois (Paramètres › Compte et paramètres › Avancé). Indiquez le jour exact où commence votre exercice ; il est mémorisé pour cette compagnie.",
                              "QuickBooks has no fiscal year start date: you only pick the first month there (Settings › Account and settings › Advanced). Enter the exact day your fiscal year starts; it is remembered for this company.",
                              "QuickBooks no tiene fecha de inicio del ejercicio: allí solo se elige el primer mes (Configuración › Cuenta y configuración › Avanzado). Indique el día exacto en que comienza su ejercicio; se memoriza para esta compañía."),
            .dateSource = T("proposée d'après {w}", "suggested from {w}", "propuesta según {w}"),
            .dateChoisie = T("choisie à la main", "chosen manually", "elegida manualmente"),
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
            .ditOauth = T("Je lis {n} en direct. Choisissez la date de début de la comptabilité, puis connectez-vous chez {w}.", "I read {n} live. Choose the accounting start date, then sign in at {w}.", "Leo {n} en directo. Elija la fecha de inicio de la contabilidad y luego conéctese en {w}."),
            .ditQbd = T("QuickBooks Desktop est installé sur un poste : on passe par son Web Connector.", "QuickBooks Desktop is installed on a computer: we go through its Web Connector.", "QuickBooks Desktop está instalado en un equipo: pasamos por su Web Connector."),
            .ditOdoo = T("Odoo se relie par une clé d'API.", "Odoo connects with an API key.", "Odoo se conecta con una clave de API."),
            .ditFichiers = T("{n} n'a pas de lecture en direct. Préparez les exports listés ; je les lirai un à un.", "{n} has no live reading. Prepare the listed exports; I will read them one by one.", "{n} no tiene lectura en directo. Prepare las exportaciones de la lista; las leeré una por una."),
            .ditFichiersChoix = T("D'accord, on passe par les fichiers : préparez les exports listés ; je les lirai un à un.", "All right, we go with files: prepare the listed exports; I will read them one by one.", "De acuerdo, pasamos por archivos: prepare las exportaciones de la lista; las leeré una por una."),
            .extraction = T("Lecture des données de {n}", "Reading the {n} data", "Lectura de los datos de {n}"),
            .extractionProgres = T("{0} ressources lues sur {1}. {2}", "{0} of {1} resources read. {2}", "{0} recursos leídos de {1}. {2}"),
            .extractionFin = T("Lecture terminée : {0} enregistrements, {1} ressources en échec.", "Reading finished: {0} records, {1} resources failed.", "Lectura terminada: {0} registros, {1} recursos con error."),
            .attenteAutorisation = T("En attente de votre autorisation dans la fenêtre {w}…", "Waiting for your authorization in the {w} window…", "Esperando su autorización en la ventana de {w}…"),
            .pasRecu = T("Je n'ai pas reçu l'autorisation. Recommencez quand vous serez prêt.", "I did not receive the authorization. Start again when you are ready.", "No recibí la autorización. Vuelva a empezar cuando esté listo."),
            .connexion = T("Connexion", "Connection", "Conexión"),
            .relieOk = T("Source reliée", "Source connected", "Origen conectado"),
            .relieTexte = T("{n} est relié en lecture seule. Prochaine étape : le plan comptable.", "{n} is connected read-only. Next step: the chart of accounts.", "{n} está conectado en solo lectura. Próximo paso: el plan contable."),
            .fichiersOk = T("Fichiers", "Files", "Archivos"),
            .t3Voir = T("Voir le détail", "See the details", "Ver el detalle"),
            .t3Vide = T("Rien en préparation", "Nothing in preparation", "Nada en preparación"),
            .t3Fait = T("Terminé", "Done", "Terminado"),
            .t3Charge = T("Lecture du tableau…", "Loading the board…", "Cargando el tablero…"),
            .t3Travail = T("60 s'en occupe…", "60 is on it…", "60 se encarga…"),
            .t3ToutFait = T("Tous les imports sont faits. Prochaine étape : le contrôle.", "All imports are done. Next step: the review.", "Todas las importaciones están hechas. Próximo paso: el control."),
            .t3Ordre = T("Suivez l'ordre des numéros : chaque import s'appuie sur les précédents.", "Follow the numbers: each import builds on the previous ones.", "Siga el orden de los números: cada importación se apoya en las anteriores."),
            .t3Lecture = T("Lecture terminée", "Reading done", "Lectura terminada"),
            .t3EnCours = T("Reprise en cours · {0} compte(s) à décider", "Migration in progress · {0} account(s) to decide", "Migración en curso · {0} cuenta(s) por decidir"),
            .t3EnCoursSans = T("Reprise en cours", "Migration in progress", "Migración en curso"),
            .t3Equilibree = T("Équilibrée · {0}", "Balanced · {0}", "Equilibrada · {0}"),
            .t3Desequilibree = T("Déséquilibrée", "Unbalanced", "Desequilibrada"),
            .t3Fermer = T("Fermer ✕", "Close ✕", "Cerrar ✕"),
            .t3Deplacer = T("Déplacer", "Move", "Mover"),
            .reinit = T("Réinitialiser {0}", "Reset {0}", "Reiniciar {0}"),
            .reinitTip = T("Outil de test : efface la comptabilité de cette compagnie pour rejouer la reprise", "Test tool: clears this company's accounting to replay the migration", "Herramienta de prueba: borra la contabilidad de esta compañía para repetir la migración"),
            .reinitConfirme = T("Outil de test. Pour {0}, seront EFFACÉS : toutes les factures et tous les documents, les règlements, toutes les écritures, tous les rendez-vous, tous les clients et fournisseurs, tous les produits, et toutes les décisions de correspondance des comptes. Le plan comptable revient au plan par défaut. La préparation est gardée et redevient « à faire ». C'est irréversible.",
                                "Test tool. For {0}, these will be DELETED: all invoices and documents, payments, all journal entries, all appointments, all customers and suppliers, all products, and all account matching decisions. The chart of accounts returns to the default chart. The preparation is kept and becomes ""to do"" again. This cannot be undone.",
                                "Herramienta de prueba. Para {0}, se BORRARÁN: todas las facturas y documentos, los pagos, todos los asientos, todas las citas, todos los clientes y proveedores, todos los productos y todas las decisiones de correspondencia de cuentas. El plan contable vuelve al plan por defecto. La preparación se conserva y vuelve a «por hacer». Es irreversible."),
            .reinitOk = T("Réinitialisation faite", "Reset done", "Reinicio hecho"),
            .reinitTexte = T("{0} est vidée : la reprise peut repartir des données en préparation.", "{0} is cleared: the migration can start again from the prepared data.", "{0} está vacía: la migración puede repetirse con los datos en preparación."),
            .t3Recharger = T("Actualiser", "Refresh", "Actualizar"),
            .prepTitre = T("Des données sont déjà en préparation", "Data is already in preparation", "Ya hay datos en preparación"),
            .prepTexte = T("{nb} enregistrements ({r} types) extraits de {n} le {d} attendent d'être validés. Vous pouvez continuer avec eux, sans relier {n} de nouveau.",
                           "{nb} records ({r} types) extracted from {n} on {d} are waiting to be validated. You can continue with them, without connecting {n} again.",
                           "{nb} registros ({r} tipos) extraídos de {n} el {d} esperan validación. Puede continuar con ellos, sin volver a conectar {n}."),
            .prepContinuer = T("Continuer avec ces données", "Continue with this data", "Continuar con estos datos"),
            .prepOk = T("Données en préparation", "Data in preparation", "Datos en preparación"),
            .prepOkTexte = T("On continue avec les données de {n} déjà extraites, sans nouvelle connexion. Prochaine étape : le plan comptable.",
                             "Continuing with the {n} data already extracted, without a new connection. Next step: the chart of accounts.",
                             "Se continúa con los datos de {n} ya extraídos, sin nueva conexión. Próximo paso: el plan contable."),
            .viaPrep = T("Données déjà en préparation", "Data already in preparation", "Datos ya en preparación"),
            .fichiersTexte = T("Réglages retenus. Prochaine étape : déposer le plan comptable.", "Settings kept. Next step: drop the chart of accounts.", "Ajustes guardados. Próximo paso: depositar el plan contable."),
            .e3Titre = T("Étape 3 — Plan comptable", "Step 3 — Chart of accounts", "Paso 3 — Plan contable"),
            .e3LeadDirect = T("{n} est relié. 60 rapatriera le plan comptable, puis vous aidera à associer chaque compte.", "{n} is connected. 60 will bring back the chart of accounts, then help you match each account.", "{n} está conectado. 60 traerá el plan contable y luego le ayudará a asociar cada cuenta."),
            .e3LeadFichiers = T("Vous déposerez d'abord l'export du plan comptable de {n} ; 60 vous aidera ensuite à associer chaque compte.", "You will first drop the chart of accounts export from {n}; 60 will then help you match each account.", "Primero depositará la exportación del plan contable de {n}; luego 60 le ayudará a asociar cada cuenta."),
            .aVenir = T("Cette étape arrive bientôt. Vos réglages sont gardés.", "This step is coming soon. Your settings are kept.", "Este paso llegará pronto. Sus ajustes se conservan."),
            .modifierReglages = T("Revenir à l'étape 2", "Back to step 2", "Volver al paso 2"),
            .exp_plan = T("la liste des comptes (plan comptable)", "the list of accounts (chart of accounts)", "la lista de cuentas (plan contable)"),
            .exp_bal = T("la balance de vérification arrêtée à la date de début de la comptabilité", "the trial balance struck at the accounting start date", "la balanza de comprobación cerrada en la fecha de inicio de la contabilidad"),
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
