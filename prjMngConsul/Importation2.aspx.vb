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
                         .reinit = Reinitialisable(), .compagnie = CompanyName}
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
                Case "fichiers" : res = PasserAuxFichiers()
                Case "continuerPrep" : res = ContinuerAvecPreparation()
                Case "tableau" : res = New With {.ok = True, .tableau = Tableau()}
                Case "creerFiches" : res = CreerFiches(Convert.ToString(Request.Form("type")))
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
    ''' l'extraction a déjà eu lieu. La date de bascule, si elle est saisie
    ''' (étape 2), est retenue ; sinon elle se donne plus tard.
    ''' </summary>
    Private Function ContinuerAvecPreparation() As Object
        Dim prep As DonneesEnPreparation = Preparation()
        If prep Is Nothing Then
            Return New With {.ok = False, .erreur = T("Aucune donnée n'attend en préparation.", "No data is waiting in preparation.", "No hay datos esperando en preparación.")}
        End If

        ' Étape 1 : aucune date n'est envoyée — Request.Form rend Nothing.
        If If(Request.Form("bascule"), "").Trim() <> "" Then
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

#Region "Étape 3 : le tableau des sept imports"

    ' Chaque carte lit les procédures des écrans d'import existants : rien n'est
    ' recalculé ici, et les boutons appellent les mêmes procédures de création.
    '   1 Plan comptable        s0758 + s0766       → AssocierCompte.aspx?popup=1 (décider), puis AppliquerPlanComptable.aspx (créer)
    '   2 Balance               s0770 + s0771       → s1025 (écriture d'ouverture en brouillon)
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
    Private Sub ArriveeAuTableau()
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
            Try
                Dim fid As Integer = 0
                Dim rp As DataRow = FichierImport("Produit", fid)
                If fid > 0 AndAlso Ent(rp, "Nouveaux") > 0 Then
                    Lire("s0774AppliquerImportFichier", New SqlClient.SqlParameter("@ImportFileId", fid))
                End If
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
            .k = "plan", .no = 1, .ico = "plan", .titre = T("Plan comptable", "Chart of accounts", "Plan contable"),
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
        Try
            Dim bal As DataTable = Table(Lire("s0770GetBalanceVerification"), 0)
            If bal IsNot Nothing Then
                nbBal = bal.Rows.Count
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
        If nbBal > 0 Then
            Try
                Dim dsO As DataSet = SoldesOuverture(False)
                ouv = Rang0(Table(dsO, dsO.Tables.Count - 1))
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
        If erreurs > 0 Then
            dit3 = String.Format(T("La balance a {0} erreurs à corriger face au plan comptable.", "The trial balance has {0} errors against the chart of accounts.", "La balanza tiene {0} errores frente al plan contable."), erreurs)
        ElseIf Not equilibree Then
            dit3 = T("La balance n'est pas équilibrée : vérifiez l'export.", "The trial balance does not balance: check the export.", "La balanza no está equilibrada: verifique la exportación.")
        ElseIf ouvPrete Then
            dit3 = T("La balance est prête : créez l'écriture d'ouverture en brouillon.", "The trial balance is ready: create the opening entry as a draft.", "La balanza está lista: cree el asiento de apertura en borrador.")
        ElseIf Not ouvFaite AndAlso Not planFait Then
            dit3 = msgPlan
        Else
            dit3 = Txt(ouv, "Message")
        End If

        cartes.Add(New With {
            .k = "balance", .no = 2, .ico = "balance", .titre = T("Balance de vérification", "Trial balance", "Balanza de comprobación"), .src = nomSrc,
            .etat = If(nbBal = 0, "vide", If(ouvFaite, "fait", "afaire")),
            .liste = New Object() {
                Point(T("Lire l'export, écarter titres, total et pied de page", "Read the export, drop titles, total and footer", "Leer la exportación, descartar títulos, total y pie"), EtatDe(nbBal > 0, False)),
                Point(T("Contrôler l'équilibre et le total", "Check the balance and the total", "Controlar el equilibrio y el total"), EtatDe(equilibree, nbBal > 0)),
                Point(T("Confronter chaque ligne au plan comptable", "Compare each line with the chart of accounts", "Confrontar cada línea con el plan contable"), EtatDe(nbBal > 0 AndAlso erreurs = 0 AndAlso ouvBloquees = 0, nbBal > 0)),
                Point(T("Créer les soldes d'ouverture, en brouillon", "Create the opening balances, as a draft", "Crear los saldos de apertura, en borrador"), EtatDe(ouvFaite, ouvPrete))},
            .puces = p3, .n = nbBal, .unite = T("lignes", "lines", "líneas"), .extra = If(nbBal > 0, " · " & Montant(debit), ""),
            .bouton = If(ouvFaite,
                New With {.t = T("Voir l'écriture", "See the entry", "Ver el asiento"), .op = "page", .url = "wbfJournalEntryEdit.aspx?Id=" & Ent(ouv, "EcritureId"), .actif = True, .info = Txt(ouv, "Message")},
                New With {.t = T("Créer les soldes d'ouverture", "Create opening balances", "Crear los saldos de apertura"), .op = "creerOuverture", .url = "", .actif = ouvPrete, .info = If(ouvPrete, "", If(planFait, Txt(ouv, "Message"), msgPlan))}),
            .voir = "ImportBalanceVerification.aspx",
            .pct = If(nbBal = 0, 0, If(ouvFaite, 100, If(ouvPrete, 75, 40))),
            .dit = dit3})

        ' ---- 3, 4, 5 : clients, fournisseurs, produits ------------------------
        Dim fichesCreees As Integer = 0, produitsAFaire As Integer = 0
        For Each def As String() In {
                New String() {"clients", "3", "Client", "client", T("Clients", "Customers", "Clientes"), "ImportClients.aspx"},
                New String() {"fournisseurs", "4", "Fournisseur", "fournisseur", T("Fournisseurs", "Suppliers", "Proveedores"), "ImportFournisseurs.aspx"},
                New String() {"produits", "5", "Produit", "produit", T("Produits et services", "Products and services", "Productos y servicios"), "ImportProduits.aspx"}}
            Dim fid As Integer = 0, r As DataRow = Nothing
            Try
                r = FichierImport(def(2), fid)
            Catch
            End Try
            Dim lignes As Integer = Ent(r, "Lignes"), nouveaux As Integer = Ent(r, "Nouveaux"), existants As Integer = Ent(r, "Existants")
            Dim doublons As Integer = Ent(r, "Doublons"), crees As Integer = Ent(r, "Crees"), errs As Integer = Ent(r, "Erreurs")
            fichesCreees += crees
            If def(0) = "produits" Then produitsAFaire = nouveaux
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
                .liste = liste, .puces = pp, .n = lignes, .unite = T("lignes lues", "lines read", "líneas leídas"), .extra = "",
                .bouton = New With {.t = String.Format(nomBouton, nouveaux), .op = "creerFiches", .type = def(2), .actif = nouveaux > 0 AndAlso (def(0) <> "produits" OrElse planFait)},
                .voir = def(5),
                .pct = If(lignes = 0, 0, CInt(100 * (lignes - nouveaux) / lignes)),
                .dit = If(def(0) = "produits" AndAlso nouveaux > 0 AndAlso Not planFait,
                          T("Les produits attendent la fin du plan comptable : leurs comptes de vente et d'achat doivent d'abord exister. Ils se créeront d'eux-mêmes.", "Products wait for the chart of accounts to be finished: their sales and purchase accounts must exist first. They will be created automatically.", "Los productos esperan a que termine el plan contable: sus cuentas de venta y compra deben existir primero. Se crearán solos."),
                          String.Format(T("{0} nouvelles fiches prêtes à créer.", "{0} new records ready to create.", "{0} fichas nuevas listas para crear."), nouveaux))})
        Next

        ' ---- 6 : factures ------------------------------------------------------
        Dim nbDoc As Integer = 0, prets As Integer = 0, sansTiers As Integer = 0, aCorriger As Integer = 0, docCrees As Integer = 0, ouvertes As Integer = 0, deja As Integer = 0
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
        cartes.Add(New With {
            .k = "factures", .no = 6, .ico = "factures", .titre = T("Factures clients et fournisseurs", "Customer and supplier invoices", "Facturas de clientes y proveedores"), .src = nomSrc,
            .etat = If(nbDoc = 0, "vide", If(prets = 0 AndAlso sansTiers = 0 AndAlso aCorriger = 0, "fait", "afaire")),
            .liste = New Object() {
                Point(T("Un verdict par facture : nouvelle ou à corriger", "One verdict per invoice: new or to fix", "Un veredicto por factura: nueva o por corregir"), EtatDe(nbDoc > 0, False)),
                Point(T("Trier ouvertes et fermées", "Sort open and closed", "Ordenar abiertas y cerradas"), EtatDe(nbDoc > 0, False)),
                Point(T("Rapprocher le tiers que la source n'a pas retrouvé", "Match the party the source didn't find", "Conciliar el tercero que el origen no encontró"), EtatDe(nbDoc > 0 AndAlso sansTiers = 0, sansTiers > 0)),
                Point(T("Répartir TPS et TVQ, puis créer en brouillon", "Split GST and QST, then create as draft", "Repartir TPS y TVQ, luego crear en borrador"), EtatDe(nbDoc > 0 AndAlso prets = 0 AndAlso sansTiers = 0 AndAlso aCorriger = 0, docCrees > 0))},
            .puces = p7, .n = nbDoc, .unite = T("factures lues", "invoices read", "facturas leídas"), .extra = "",
            .bouton = New With {.t = String.Format(T("Créer {0} en brouillon", "Create {0} as draft", "Crear {0} en borrador"), prets), .op = "creerFactures", .actif = prets > 0 AndAlso planFait AndAlso produitsAFaire = 0},
            .voir = "ValiderFactures.aspx",
            .pct = If(nbDoc = 0, 0, CInt(100 * (docCrees + deja) / nbDoc)),
            .dit = If(prets > 0 AndAlso Not (planFait AndAlso produitsAFaire = 0),
                      T("Les factures attendent la fin du plan comptable et la création des produits : chaque ligne doit trouver son compte et son produit.", "Invoices wait for the chart of accounts to be finished and the products to be created: each line must find its account and product.", "Las facturas esperan a que termine el plan contable y se creen los productos: cada línea debe encontrar su cuenta y su producto."),
                  If(prets > 0, String.Format(T("{0} factures sont prêtes à créer en brouillon.", "{0} invoices are ready to create as draft.", "{0} facturas están listas para crear en borrador."), prets),
                      T("Créez d'abord les clients et les fournisseurs : certaines factures n'ont pas encore de tiers.", "Create customers and suppliers first: some invoices have no party yet.", "Cree primero los clientes y proveedores: algunas facturas aún no tienen tercero.")))})

        ' ---- 7 : taxes ---------------------------------------------------------
        Dim tx As DataRow = Nothing
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
            .k = "taxes", .no = 7, .ico = "taxes", .titre = T("Codes et taux de taxe", "Tax codes and rates", "Códigos y tasas de impuesto"), .src = nomSrc,
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

        Dim prep As DonneesEnPreparation = Preparation()
        Return New With {
            .cartes = cartes,
            .comptesDecides = decides, .comptesTotal = total, .aDecider = aDecider,
            .fichesCreees = fichesCreees, .facturesBrouillon = docCrees,
            .balanceEquilibree = equilibree, .balanceTotal = If(nbBal > 0, Montant(debit), ""),
            .ressources = If(prep Is Nothing, 0, prep.ressources), .enregistrements = If(prep Is Nothing, 0, prep.nb)}
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

    ''' <summary>Cartes 3 à 5 : crée les nouvelles fiches du dernier fichier (s0774, comme ImportDonnees.ascx).</summary>
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
    ''' Carte 2 : l'écriture d'ouverture tirée de la balance (s1025, T401), au
    ''' journal OD, datée de la date de bascule, en brouillon. Le dernier jeu de
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

    Private Function CreerOuverture() As Object
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
        Dim ids As New List(Of String)
        Dim docs As DataTable = Table(Lire("s0782GetDocumentsImport"), 0)
        If docs IsNot Nothing Then
            For Each r As DataRow In docs.Rows
                If IsDBNull(r("DocumentId")) AndAlso Txt(r, "Statut") = "OK" AndAlso Not IsDBNull(r("PartyGUID")) Then ids.Add(Txt(r, "Id"))
            Next
        End If
        If ids.Count = 0 Then Return New With {.ok = False, .erreur = T("Aucune facture n'est prête.", "No invoice is ready.", "Ninguna factura está lista.")}

        Dim r0 As DataRow = Rang0(Table(Lire("s0785CreerDocumentsDepuisImport",
                                             New SqlClient.SqlParameter("@Ids", String.Join(",", ids)),
                                             New SqlClient.SqlParameter("@UserId", UserId)), 0))
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
