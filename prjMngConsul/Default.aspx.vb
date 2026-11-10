Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports Newtonsoft.Json

''' <summary>
''' Le tableau de bord, au modèle de la page d'accueil 60secondes du 21 octobre
''' (60secondes-plateforme-complete-page-premiere-21-oct.html) :
'''   1. la fenêtre de 60 : bonjour, « En premier », puis sur la même ligne
'''      Activité à faire (rouge / jaune), Messages, Revenu en retard,
'''      Paiements en retard et le compte d'opérations (l'œil montre le solde) ;
'''   2. l'Agenda : Aujourd'hui (plages libres, RDV, Facturer, + RDV) et
'''      À venir (7 prochains jours, semaine suivante, ce mois-ci, mois prochain) ;
'''   3. les Activités à faire, classées par couleur (rouge = date dépassée,
'''      jaune = date qui approche) ; 60 se rend sur l'enjeu prioritaire.
'''      Elles viennent TOUTES des tâches planifiées T204JobPlanned (s0974) :
'''      la tâche SYNC_ACTIVITES (s0973, script T362) les y inscrit.
''' Le reste est calculé à partir des vraies données de la compagnie (factures
''' clients s0026, factures fournisseurs s0023, comptes bancaires T143PlaidAccount,
''' rendez-vous s0100). Le serveur bâtit un
''' modèle (JSON) ; la page le dessine et gère les clics sans aller-retour.
''' </summary>
Public Class _Default
    Inherits clsData

    ''' <summary>
    ''' Vrai quand personne n'est connecté : le tableau de bord se dessine vide et
    ''' la connexion s'ouvre en fenêtre par-dessus (wbfLogin.aspx?popup=1 dans un iframe).
    ''' </summary>
    Protected AfficherConnexion As Boolean

    ''' <summary>Le modèle de la page, en JSON (null quand personne n'est connecté).</summary>
    Protected ModeleJson As String = "null"

    ''' <summary>L'adresse de la page de connexion en mode fenêtre ; elle revient ici une fois connecté.</summary>
    Protected ReadOnly Property UrlConnexion As String
        Get
            Return ResolveUrl("~/wbfLogin.aspx") & "?popup=1&lang=" & CurrentLang &
                   "&ReturnUrl=" & HttpUtility.UrlEncode(Request.RawUrl)
        End Get
    End Property

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        Page.Title = L("pageTitle")
        ' Les boîtes du tableau de bord posent sur le fond de la page, sans cadre blanc autour.
        DirectCast(Master, SiteMaster).FondDePage = True

        ' Pas connecté : on ne charge aucune donnée, la fenêtre de connexion couvre la page.
        If Not isAuthenticated Then
            AfficherConnexion = True
            Return
        End If

        ' Un comptable en mode « Portail comptable » (sélecteur de l'en-tête sur
        ' « Portail comptable ») a pour page d'accueil « Ma journée », pas le tableau
        ' de bord d'une compagnie. Le logo et tout lien vers Default.aspx le ramènent
        ' donc à son portail. Dès qu'il entre dans un dossier, EnPortailComptable
        ' passe à False et le tableau de bord de la compagnie s'affiche normalement.
        If EnPortailComptable Then
            Response.Redirect("~/wbfCabJournee.aspx")
            Return
        End If

        ' Mesure temporaire : un passage du service exécuteur (planning, promotion,
        ' exécutions) en arrière-plan, au plus une fois par minute — voir clsExecuteurTaches.
        clsExecuteurTaches.Lancer()

        Try
            ModeleJson = JsonConvert.SerializeObject(BatirModele(), New JsonSerializerSettings With {
                .StringEscapeHandling = StringEscapeHandling.EscapeHtml
            })
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Accueil : " & ex.Message)
            ModeleJson = "null"
        End Try
    End Sub

    ' =====================================================================
    ' Le modèle
    ' =====================================================================

    Private aujourdhui As Date = Date.Today

    Private Function BatirModele() As Object
        ' ---------- Les données ----------
        Dim ventes As DataTable = Table("s0026GetCustomersInvoices")
        Dim achats As DataTable = Table("s0023GetSuppliersInvoices")
        Dim comptes As DataTable = ComptesBancaires()

        ' ---------- Le compte d'opérations ----------
        Dim encaisse As Decimal = 0D, aCompte As Boolean = comptes IsNot Nothing AndAlso comptes.Rows.Count > 0
        Dim libCompte As String = L("bqAucun"), majCompte As String = ""
        If aCompte Then
            For Each r As DataRow In comptes.Rows : encaisse += Dec(r("BalanceCurrent")) : Next
            Dim r0 As DataRow = comptes.Rows(0)
            libCompte = Txt(r0("BankName"))
            If Txt(r0("Mask")) <> "" Then libCompte &= " ••• " & Txt(r0("Mask"))
            If comptes.Rows.Count > 1 Then libCompte &= " " & String.Format(L("bqAutres"), comptes.Rows.Count - 1)
            Dim maj As Date? = DateN(r0("BalanceUpdated"))
            majCompte = Txt(r0("BankName")) & If(Txt(r0("AccountName")) <> "", " · " & Txt(r0("AccountName")), "") &
                        If(maj.HasValue, " · " & String.Format(L("auDate"), JourMois(maj.Value)), "")
        End If

        ' ---------- Ventes : en retard, à échéance dans 7 jours, brouillons ----------
        Dim enRetard As Decimal = 0D
        Dim retardsVentes As New List(Of DataRow)
        Dim prochesVentes As New List(Of DataRow)
        Dim brouillonsVentes As Integer = 0
        If ventes IsNot Nothing Then
            For Each r As DataRow In ventes.Rows
                If Txt(r("ComptabilisationStatus")).ToUpperInvariant() <> "COMPTABILISE" Then brouillonsVentes += 1 : Continue For
                Dim reste As Decimal = Dec(r("ResteAPayer"))
                If reste <= 0.005D OrElse Txt(r("StatutPaiement")).ToUpperInvariant() = "PAYEE" Then Continue For
                Dim ech As Date? = DateN(r("DueDate"))
                If (ech.HasValue AndAlso ech.Value < aujourdhui) OrElse Txt(r("StatutPaiement")).ToUpperInvariant() = "EN_RETARD" Then
                    enRetard += reste : retardsVentes.Add(r)
                ElseIf ech.HasValue AndAlso ech.Value <= aujourdhui.AddDays(7) Then
                    prochesVentes.Add(r)
                End If
            Next
        End If

        ' ---------- Achats : en retard, à échéance dans 7 jours ----------
        Dim retardsAchats As New List(Of DataRow)
        Dim prochesAchats As New List(Of DataRow)
        If achats IsNot Nothing Then
            For Each r As DataRow In achats.Rows
                If Txt(r("ComptabilisationStatus")).ToUpperInvariant() <> "COMPTABILISE" Then Continue For
                Dim reste As Decimal = Dec(r("ResteAPayer"))
                If reste <= 0.005D OrElse Txt(r("StatutPaiement")).ToUpperInvariant() = "PAYEE" Then Continue For
                Dim ech As Date? = DateN(r("DueDate"))
                If ech.HasValue AndAlso ech.Value < aujourdhui Then
                    retardsAchats.Add(r)
                ElseIf ech.HasValue AndAlso ech.Value <= aujourdhui.AddDays(7) Then
                    prochesAchats.Add(r)
                End If
            Next
        End If

        retardsVentes = retardsVentes.OrderBy(Function(r) If(DateN(r("DueDate")), aujourdhui)).ToList()
        Dim payRetard As Decimal = retardsAchats.Sum(Function(r) Dec(r("ResteAPayer")))

        ' ---------- Les montants de la ligne de 60 : Revenu en retard, Paiements en retard ----------
        Dim sousRetard As String = L("kRetardAucun")
        If retardsVentes.Count > 0 Then
            Dim pire As Date? = DateN(retardsVentes(0)("DueDate"))
            sousRetard = String.Format(L("kRetardN"), retardsVentes.Count) &
                         If(pire.HasValue, " · " & String.Format(L("echueDepuis"), (aujourdhui - pire.Value).Days), "")
        End If
        Dim sousPay As String = If(retardsAchats.Count = 0, L("kPayAucun"),
                                   String.Format(L("kFacturesFourn"), retardsAchats.Count) & " · " & Noms(retardsAchats))
        Dim entete As New List(Of Object) From {
            New With {.lab = L("kEnRetard"), .val = Montant(enRetard), .sous = sousRetard, .actif = enRetard > 0, .url = "wbfCustomersInvoices.aspx"},
            New With {.lab = L("kPayRetard"), .val = Montant(payRetard), .sous = sousPay, .actif = payRetard > 0, .url = "wbfSuppliersInvoices.aspx"}
        }

        ' ---------- Activités à faire ----------
        ' Toutes viennent des tâches planifiées T204JobPlanned (s0974) : les types ACT_*
        ' qu'inscrit la tâche SYNC_ACTIVITES (s0973, service exécuteur, toutes les 30 min)
        ' et les occurrences en attente d'approbation. Les montants de la ligne de 60
        ' ci-dessus restent calculés en direct sur les factures.
        Dim lignesT204 As List(Of DataRow) = ActivitesT204()
        Dim deType = Function(code As String) lignesT204.Where(Function(r) Txt(r("JobCode")).ToUpperInvariant() = code).ToList()
        Dim enRetardT204 = Function(r As DataRow) As Boolean
                               Dim e As Date? = DateN(r("DueDate"))
                               Return (e.HasValue AndAlso e.Value.Date < aujourdhui) OrElse Txt(r("StatutPaiement")).ToUpperInvariant() = "EN_RETARD"
                           End Function

        Dim factClients As List(Of DataRow) = deType("ACT_FACT_CLIENT")
        Dim factFourn As List(Of DataRow) = deType("ACT_FACT_FOURN")
        Dim aRetardsVentes As List(Of DataRow) = factClients.Where(enRetardT204).OrderBy(Function(r) If(DateN(r("DueDate")), aujourdhui)).ToList()
        Dim aProchesVentes As List(Of DataRow) = factClients.Where(Function(r) Not enRetardT204(r)).ToList()
        Dim aRetardsAchats As List(Of DataRow) = factFourn.Where(enRetardT204).ToList()
        Dim aProchesAchats As List(Of DataRow) = factFourn.Where(Function(r) Not enRetardT204(r) AndAlso DateN(r("DueDate")).HasValue).ToList()
        Dim aBrouillons As Integer = deType("ACT_BROUILLON").Count
        Dim aApprob As Integer = lignesT204.Where(Function(r) Txt(r("Approbation")).ToUpperInvariant() = "A_APPROUVER").Count()
        Dim aBanque As Boolean = deType("ACT_BANQUE").Count > 0
        Dim aEssai As DataRow = deType("ACT_ESSAI").FirstOrDefault()

        Dim acts As New List(Of Object)
        Dim nRetardMax As Integer = 5
        For Each r As DataRow In aRetardsVentes.Take(nRetardMax)
            Dim ech As Date? = DateN(r("DueDate"))
            Dim jours As Integer = If(ech.HasValue, (aujourdhui - ech.Value).Days, 0)
            ' Ouverte, l'activité montre client, facture, retard, montant, dernier rappel
            ' et les boutons Texto / Courriel / Paiement déjà reçu (RappelFacture.ashx).
            Dim rap As Date? = DateN(r("DernierRappel"))
            Dim rappel As String = L("rappelAucun")
            If rap.HasValue Then
                rappel = If(Txt(r("DernierRappelCanal")).ToUpperInvariant() = "TEXTO", L("canalTexto"), L("canalCourriel")) & " · " &
                         If(rap.Value.Date = aujourdhui, L("aujourdhuiMin"), JourMois(rap.Value))
            End If
            acts.Add(New With {
                .u = "r",
                .t = String.Format(L("aFactRetard"), NumFacture(r)),
                .d = L("catVentes") & " · " & If(ech.HasValue, String.Format(L("echueLe"), JourMois(ech.Value)) & " · ", "") & Txt(r("NameSort")) & " · " & Montant(Dec(r("ResteAPayer"))),
                .det = L("aFactRetardConseil"),
                .btn = "", .url = "",
                .k = "factRetard",
                .docId = If(IsDBNull(r("DocumentId")), 0, Convert.ToInt32(r("DocumentId"))),
                .partyId = If(IsDBNull(r("PartyId")), 0, Convert.ToInt32(r("PartyId"))),
                .client = Txt(r("NameSort")),
                .numero = NumFacture(r),
                .retard = String.Format(L("echueDepuisJ"), jours),
                .montant = Montant(Dec(r("ResteAPayer"))),
                .rappel = rappel
            })
        Next
        If aRetardsVentes.Count > nRetardMax Then
            acts.Add(Activite("r", String.Format(L("aAutresRetards"), aRetardsVentes.Count - nRetardMax),
                              L("catVentes") & " · " & Montant(aRetardsVentes.Skip(nRetardMax).Sum(Function(r) Dec(r("ResteAPayer")))),
                              L("aAutresRetardsDet"), L("btnVoir"), "wbfCustomersInvoices.aspx"))
        End If
        ' Factures fournisseurs en retard : une activité par facture (les 5 plus vieilles),
        ' comme les factures clients. Ouverte : fournisseur, facture, retard, montant et
        ' « Payer la facture » (fenêtre de décaissement du fournisseur).
        Dim retardsAchatsTries As List(Of DataRow) = aRetardsAchats.OrderBy(Function(r) If(DateN(r("DueDate")), aujourdhui)).ToList()
        For Each r As DataRow In retardsAchatsTries.Take(nRetardMax)
            Dim ech As Date? = DateN(r("DueDate"))
            Dim jours As Integer = If(ech.HasValue, (aujourdhui - ech.Value).Days, 0)
            acts.Add(New With {
                .u = "r",
                .t = String.Format(L("aFactFournRetard"), NumFacture(r)),
                .d = L("catAchats") & " · " & If(ech.HasValue, String.Format(L("echueLe"), JourMois(ech.Value)) & " · ", "") & Txt(r("NameSort")) & " · " & Montant(Dec(r("ResteAPayer"))),
                .det = L("aFactFournConseil"),
                .btn = "", .url = "",
                .k = "factFournRetard",
                .docId = If(IsDBNull(r("DocumentId")), 0, Convert.ToInt32(r("DocumentId"))),
                .partyId = If(IsDBNull(r("PartyId")), 0, Convert.ToInt32(r("PartyId"))),
                .client = Txt(r("NameSort")),
                .numero = NumFacture(r),
                .retard = String.Format(L("echueDepuisJ"), jours),
                .montant = Montant(Dec(r("ResteAPayer")))
            })
        Next
        If retardsAchatsTries.Count > nRetardMax Then
            Dim autres As List(Of DataRow) = retardsAchatsTries.Skip(nRetardMax).ToList()
            acts.Add(Activite("r", String.Format(L("aAutresFournRetard"), autres.Count),
                              L("catAchats") & " · " & Noms(autres) & " · " & Montant(autres.Sum(Function(r) Dec(r("ResteAPayer")))),
                              L("aFournRetardDet"), L("btnPreparer"), UrlFacturesFournisseurs(autres)))
        End If
        If aApprob > 0 Then
            acts.Add(Activite("y", String.Format(L("aApprob"), aApprob), L("catTaches") & " · " & L("aApprobSous"),
                              L("aApprobDet"), L("btnApprouver"), "wbfApprobations.aspx"))
        End If
        If aProchesAchats.Count > 0 Then
            Dim proch As Date = aProchesAchats.Min(Function(r) DateN(r("DueDate")).Value)
            acts.Add(Activite("y", String.Format(L("aFournProches"), aProchesAchats.Count),
                              L("catAchats") & " · " & String.Format(L("avantLe"), JourMois(proch)) & " · " & Noms(aProchesAchats) & " · " & Montant(aProchesAchats.Sum(Function(r) Dec(r("ResteAPayer")))),
                              L("aFournProchesDet"), L("btnPreparer"), UrlFacturesFournisseurs(aProchesAchats)))
        End If
        If aProchesVentes.Count > 0 Then
            acts.Add(Activite("y", String.Format(L("aVentesProches"), aProchesVentes.Count),
                              L("catVentes") & " · " & L("dans7Jours") & " · " & Montant(aProchesVentes.Sum(Function(r) Dec(r("ResteAPayer")))),
                              L("aVentesProchesDet"), L("btnVoir"), "wbfCustomersInvoices.aspx"))
        End If
        If aBrouillons > 0 Then
            acts.Add(Activite("y", String.Format(L("aBrouillons"), aBrouillons), L("catVentes") & " · " & L("aBrouillonsSous"),
                              L("aBrouillonsDet"), L("btnVoir"), "wbfCustomersInvoices.aspx"))
        End If
        If aBanque Then
            acts.Add(Activite("y", L("aBanque"), L("catComptabilite") & " · " & L("aBanqueSous"),
                              L("aBanqueDet"), L("btnBrancher"), "PlaidAccounts.aspx"))
        End If
        Dim essai As Object = ActiviteEssai(aEssai)
        If essai IsNot Nothing Then acts.Add(essai)

        Dim prenom As String = ""
        Try : prenom = UserFirstName : Catch : End Try

        Return New With {
            .prenom = prenom,
            .lang = CurrentLang,
            .banque = New With {.aCompte = aCompte, .lib = libCompte, .solde = If(aCompte, Montant(encaisse), ""), .maj = majCompte},
            .entete = entete,
            .demandes = CompterDemandesRdv(),
            .msgNonLu = CompterMessagesNonLus(),
            .presence = BatirPresence(),
            .activites = acts,
            .agenda = BatirAgenda(),
            .t = Textes()
        }
    End Function

    Private Function Activite(u As String, titre As String, sous As String, detail As String, bouton As String, url As String) As Object
        Return New With {.u = u, .t = titre, .d = sous, .det = detail, .btn = bouton, .url = url}
    End Function

    ''' <summary>
    ''' La liste des factures fournisseurs ouverte sur ces factures seulement :
    ''' wbfSuppliersInvoices.aspx?factures=FFD-0012,FFD-0018 (recherche par numéros, T364).
    ''' Sans numéro, la liste complète.
    ''' </summary>
    Private Function UrlFacturesFournisseurs(rows As List(Of DataRow)) As String
        Dim nums As List(Of String) = rows.Select(Function(r) Txt(r("NumeroSort"))).Where(Function(n) n <> "").Distinct().ToList()
        If nums.Count = 0 Then Return "wbfSuppliersInvoices.aspx"
        Return "wbfSuppliersInvoices.aspx?factures=" & HttpUtility.UrlEncode(String.Join(",", nums))
    End Function

    ''' <summary>
    ''' L'essai gratuit : la ligne ACT_ESSAI de T204 (fin de l'essai dans DueDate),
    ''' rouge à 3 jours ou moins, jaune avant.
    ''' </summary>
    Private Function ActiviteEssai(r As DataRow) As Object
        If r Is Nothing Then Return Nothing
        Dim fin As Date? = DateN(r("DueDate"))
        If Not fin.HasValue Then Return Nothing
        Dim jours As Integer = (fin.Value.Date - aujourdhui).Days
        If jours < 0 OrElse jours > 30 Then Return Nothing
        Return Activite(If(jours <= 3, "r", "y"), String.Format(L("aEssai"), jours),
                        L("catAbonnement") & " · " & String.Format(L("avantLe"), JourMois(fin.Value)) & " · " & L("aEssaiSous"),
                        L("aEssaiDet"), L("btnForfait"), "wbfPayment.aspx")
    End Function

    ''' <summary>
    ''' Les activités à faire de la compagnie, toutes lues dans T204JobPlanned (s0974) :
    ''' types ACT_* inscrits par SYNC_ACTIVITES et occurrences à approuver.
    ''' </summary>
    Private Function ActivitesT204() As List(Of DataRow)
        ' Réinscription immédiate des activités de la compagnie (s0973, ~100-150 ms) :
        ' une facture payée, un brouillon comptabilisé ou une banque branchée ailleurs
        ' dans l'ERP disparaît dès l'affichage, sans attendre la tâche SYNC_ACTIVITES
        ' du service exécuteur (qui reste le moteur de fond, toutes compagnies).
        Try
            Dim ps As New Collection
            ps.Add(New SqlParameter("@CompanyGUID", Company))
            ExecuteSQLds("s0973SyncActivitesAFaire", ps)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Accueil s0973 : " & ex.Message)
        End Try

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0974GetActivitesAFaire", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return New List(Of DataRow)
            Return ds.Tables(0).Rows.Cast(Of DataRow)().ToList()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Accueil s0974 : " & ex.Message)
            Return New List(Of DataRow)
        End Try
    End Function

    ''' <summary>
    ''' L'agenda : les employés et les rendez-vous d'aujourd'hui jusqu'à la fin du mois
    ''' prochain (s0100, s0106). La page en tire Aujourd'hui, les plages libres et À venir.
    ''' </summary>
    Private Function BatirAgenda() As Object
        Dim emps As New List(Of Object)
        Dim couleurs As New Dictionary(Of Integer, String)
        Try
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
        Catch
        End Try

        Dim finPeriode As Date = New Date(aujourdhui.Year, aujourdhui.Month, 1).AddMonths(2)
        Dim rdv As New List(Of Object)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@StartDate", aujourdhui))
            p.Add(New SqlParameter("@EndDate", finPeriode))
            p.Add(New SqlParameter("@EmployeeId", DBNull.Value))
            Dim ds As DataSet = ExecuteSQLds("s0100GetAppointmentsByRange", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    Dim debut As Date = Convert.ToDateTime(r("StartDateTime"))
                    Dim fin As Date = Convert.ToDateTime(r("EndDateTime"))
                    Dim statut As String = Txt(r("Status"))
                    If statut = "Annulé" Then Continue For
                    Dim empId As String = If(IsDBNull(r("EmployeeId")), "", Convert.ToInt32(r("EmployeeId")).ToString())
                    Dim etat As String = "avenir"
                    If statut = "Terminé" OrElse fin < Date.Now Then
                        etat = "termine"
                    ElseIf debut <= Date.Now Then
                        etat = "encours"
                    End If
                    Dim client As String = Txt(r("CustomerName"))
                    Dim titre As String = Txt(r("Title"))
                    ' Le service affiché vient des LIGNES du brouillon/facture lié (suit
                    ' un changement de service, et liste les services multiples « A · B »).
                    ' Repli sur le type du RDV s'il n'y a pas de document.
                    Dim docSvc As String = Txt(r("DocumentServices"))
                    Dim svc As String = If(docSvc <> "", docSvc, Txt(r("TypeName")))
                    ' Texte secondaire de la rangée : on affiche le SERVICE (type de RDV)
                    ' et, s'il y en a un, le titre libre en plus — mais seulement quand il
                    ' ajoute de l'information (on ne répète pas le titre quand il reprend
                    ' déjà le nom du service). Sans client, le titre reste le libellé
                    ' principal et le service passe en secondaire.
                    ' Le titre libre n'est montré que s'il AJOUTE de l'info : différent du
                    ' client ET du service (les anciens titres auto-remplis reprenaient
                    ' l'un ou l'autre — on ne les répète pas).
                    Dim titreUtile As Boolean =
                        titre <> "" AndAlso
                        Not titre.Equals(client, StringComparison.OrdinalIgnoreCase) AndAlso
                        (svc = "" OrElse (Not titre.StartsWith(svc, StringComparison.OrdinalIgnoreCase) AndAlso
                                          Not svc.StartsWith(titre, StringComparison.OrdinalIgnoreCase)))
                    Dim courtTxt As String
                    If client = "" Then
                        courtTxt = If(svc <> "", svc, titre)
                    ElseIf svc <> "" Then
                        courtTxt = If(titreUtile, svc & " · " & titre, svc)
                    Else
                        courtTxt = If(titreUtile, titre, "")
                    End If
                    rdv.Add(New With {
                        .id = Convert.ToInt32(r("Id")),
                        .jour = debut.ToString("yyyy-MM-dd"),
                        .deb = debut.Hour * 60 + debut.Minute,
                        .fin = If(fin.Date > debut.Date, 24 * 60, fin.Hour * 60 + fin.Minute),
                        .h = Heure(debut),
                        .plage = Heure(debut) & " – " & Heure(fin),
                        .duree = Duree(fin - debut),
                        .client = If(client = "", titre, client),
                        .court = courtTxt,
                        .cli = If(IsDBNull(r("CustomerId")), "", Convert.ToString(r("CustomerId"))),
                        .desc = Txt(r("Description")),
                        .lieu = Txt(r("Location")),
                        .typ = svc,
                        .typId = If(IsDBNull(r("AppointmentTypeId")), "", Convert.ToString(r("AppointmentTypeId"))),
                        .emp = empId,
                        .empNom = Txt(r("EmployeeName")),
                        .ini = Initiales(Txt(r("EmployeeName"))),
                        .c = If(empId <> "" AndAlso couleurs.ContainsKey(CInt(empId)), couleurs(CInt(empId)), "#1B4F9C"),
                        .doc = If(Txt(r("DocumentNumber")) <> "", Txt(r("DocumentNumber")), DocLabel(Txt(r("ModeFacturation")), etat)),
                        .docId = If(IsDBNull(r("DocumentId")), 0, Convert.ToInt32(r("DocumentId"))),
                        .estFacture = (Not IsDBNull(r("EstFacture")) AndAlso Convert.ToInt32(r("EstFacture")) = 1),
                        .docT = DocType(Txt(r("ModeFacturation")), etat),
                        .montant = If(Not IsDBNull(r("DocumentTotal")) AndAlso Dec(r("DocumentTotal")) <> 0D,
                                      Montant(Dec(r("DocumentTotal"))),
                                      If(IsDBNull(r("MontantPrevu")), "", Montant(Dec(r("MontantPrevu"))))),
                        .etat = etat
                    })
                Next
            End If
        Catch
        End Try

        Return New With {
            .emps = emps,
            .rdv = rdv,
            .aujourdhui = aujourdhui.ToString("yyyy-MM-dd"),
            .maintenant = Date.Now.Hour * 60 + Date.Now.Minute
        }
    End Function

    ''' <summary>Le libellé du document produit par un RDV (soumission / facture / tâche).
    ''' À défaut de mode enregistré : terminé → facture, sinon soumission.</summary>
    Private Function DocLabel(mode As String, etat As String) As String
        Select Case DocType(mode, etat)
            Case "facture" : Return L("docFacture")
            Case "tache" : Return L("docTache")
            Case Else : Return L("docSoumission")
        End Select
    End Function

    Private Shared Function DocType(mode As String, etat As String) As String
        Select Case mode.ToLowerInvariant()
            Case "facture" : Return "facture"
            Case "tache" : Return "tache"
            Case "soumission" : Return "soumission"
            Case Else : Return If(etat = "termine", "facture", "soumission")
        End Select
    End Function

    ''' <summary>La présence du jour (absences, retards ; s0969) pour la pastille « Présence ».</summary>
    Private Function BatirPresence() As Object
        Dim abs As New List(Of Object), ret As New List(Of Object)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Jour", aujourdhui))
            Dim ds As DataSet = ExecuteSQLds("s0969GetPresenceDuJour", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    Dim o As Object = New With {.nom = Txt(r("EmployeeName")), .note = Txt(r("Note"))}
                    If Txt(r("Type")) = "absence" Then abs.Add(o) Else ret.Add(o)
                Next
            End If
        Catch
        End Try
        Return New With {.abs = abs.Count, .ret = ret.Count, .absL = abs, .retL = ret}
    End Function

    ' =====================================================================
    ' Les lectures
    ' =====================================================================

    Private Function Table(proc As String) As DataTable
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Search", ""))
            Dim ds As DataSet = ExecuteSQLds(proc, p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
            Return ds.Tables(0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Accueil " & proc & " : " & ex.Message)
            Return Nothing
        End Try
    End Function

    ''' <summary>Les comptes bancaires actifs de la compagnie (Plaid).</summary>
    Private Function ComptesBancaires() As DataTable
        Try
            Using cn As New SqlConnection(ConnectionString)
                Using cmd As New SqlCommand("SELECT BankName, AccountName, Mask, BalanceCurrent, BalanceUpdated " &
                                            "FROM dbo.T143PlaidAccount WHERE CompanyGUID = @CompanyGUID AND Active = 1 " &
                                            "ORDER BY BalanceCurrent DESC", cn)
                    cmd.Parameters.AddWithValue("@CompanyGUID", Company)
                    Using da As New SqlDataAdapter(cmd)
                        Dim dt As New DataTable()
                        da.Fill(dt)
                        Return dt
                    End Using
                End Using
            End Using
        Catch
            Return Nothing
        End Try
    End Function

    ''' <summary>Les demandes de RDV des clients en attente (nouveau, déplacement, annulation ; s0910, T328).</summary>
    Private Function CompterDemandesRdv() As Integer
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0910GetRdvDemandes", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return 0
            Return ds.Tables(0).Rows.Count
        Catch
            Return 0
        End Try
    End Function

    ''' <summary>Les messages du cabinet non lus par le client (s0955, côté « client » ;
    ''' même décompte que la pastille « Messages du cabinet » du menu).</summary>
    Private Function CompterMessagesNonLus() As Integer
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Cote", "client"))
            Dim ds As DataSet = ExecuteSQLds("s0955CountEchangesNonLus", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return 0
            Return Convert.ToInt32(ds.Tables(0).Rows(0)("N"))
        Catch
            Return 0
        End Try
    End Function

    ' =====================================================================
    ' Petits outils
    ' =====================================================================

    Private Shared Function Txt(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return Convert.ToString(o).Trim()
    End Function

    Private Shared Function Dec(o As Object) As Decimal
        If o Is Nothing OrElse IsDBNull(o) Then Return 0D
        Try : Return Convert.ToDecimal(o) : Catch : Return 0D : End Try
    End Function

    Private Shared Function Vrai(o As Object) As Boolean
        If o Is Nothing OrElse IsDBNull(o) Then Return False
        Try : Return Convert.ToBoolean(o) : Catch : Return False : End Try
    End Function

    Private Shared Function DateN(o As Object) As Date?
        If o Is Nothing OrElse IsDBNull(o) Then Return Nothing
        Try : Return Convert.ToDateTime(o).Date : Catch : Return Nothing : End Try
    End Function

    Private Function Montant(v As Decimal) As String
        If CurrentLang = "en" Then
            Return If(v < 0, "-", "") & "$" & Math.Abs(v).ToString("N2", New CultureInfo("en-CA"))
        End If
        Return v.ToString("N2", Cult()).Replace(ChrW(&H202F), ChrW(&HA0)) & " $"
    End Function

    Private Function JourMois(d As Date) As String
        Return d.ToString(If(CurrentLang = "en", "MMMM d", "d MMMM"), Cult())
    End Function

    Private Function Heure(d As Date) As String
        If CurrentLang = "en" Then Return d.ToString("h:mm tt", CultureInfo.InvariantCulture)
        If CurrentLang = "es" Then Return d.ToString("H:mm")
        Return d.Hour & " h" & If(d.Minute > 0, " " & d.Minute.ToString("00"), "")
    End Function

    Private Function Duree(t As TimeSpan) As String
        If t.TotalMinutes <= 0 Then Return ""
        Dim h As Integer = CInt(Math.Floor(t.TotalHours)), mn As Integer = t.Minutes
        If h = 0 Then Return mn & " min"
        Return h & " h" & If(mn > 0, " " & mn.ToString("00"), "")
    End Function

    Private Shared Function Initiales(nom As String) As String
        Dim parts = nom.Split(New Char() {" "c, "-"c}, StringSplitOptions.RemoveEmptyEntries)
        If parts.Length = 0 Then Return ""
        If parts.Length = 1 Then Return parts(0).Substring(0, Math.Min(2, parts(0).Length)).ToUpperInvariant()
        Return (parts(0).Substring(0, 1) & parts(parts.Length - 1).Substring(0, 1)).ToUpperInvariant()
    End Function

    Private Shared Function NumFacture(r As DataRow) As String
        Dim n As String = Txt(r("NumeroSort"))
        If n = "" Then Return ""
        Return If(Char.IsDigit(n(0)), "#" & n, n)
    End Function

    ''' <summary>Les noms des fournisseurs, les trois premiers.</summary>
    Private Function Noms(rows As List(Of DataRow)) As String
        Dim liste As List(Of String) = rows.Select(Function(r) Txt(r("NameSort"))).Where(Function(x) x <> "").Distinct().ToList()
        Dim texte As String = String.Join(", ", liste.Take(3))
        If liste.Count > 3 Then texte &= " " & String.Format(L("etAutres"), liste.Count - 3)
        Return texte
    End Function

    ''' <summary>Culture pour le format des dates et montants selon la langue courante.</summary>
    Private Function Cult() As CultureInfo
        Select Case CurrentLang
            Case "en" : Return New CultureInfo("en-CA")
            Case "es" : Return New CultureInfo("es-ES")
            Case Else : Return New CultureInfo("fr-CA")
        End Select
    End Function

    ''' <summary>Les textes dont la page a besoin côté navigateur.</summary>
    Private Function Textes() As Object
        Dim cles As String() = {
            "bonjour", "bonjourNom", "gUrgent1", "gUrgentN", "gVeille", "gOk",
            "enPremier", "rienUrgent", "assistant60", "a60Aria", "a60Retour", "a60RetourTip",
            "activiteAFaire", "indR", "indY", "messages", "msgAria", "msgNonLuN", "rdvDemande", "rdvDemandeTip",
            "compteOp", "voirMontant", "masquerMontant", "brancher",
            "docSoumission", "docFacture", "docTache", "montantPrevu", "ouvrirBrouillon", "voirFacture", "rdvFacture",
            "presence", "presenceAbs", "presenceRet", "presAbsTitre", "presRetTitre", "presRien", "presenceAria",
            "lieuPlace", "lieuChez", "lieuTel", "lieuVisio",
            "agenda", "agendaAria", "agendaTip", "agendaDe", "equipeN",
            "plagesLibres", "plagesAria", "plagesVide", "plageTip", "agAuj", "agAujAbr", "agRdvH", "agEmployes",
            "agVide", "libre", "exFictifs", "stTermine", "stEnCours", "stAVenir",
            "facturer", "facturerAria", "plusRdv", "nouveauRdvAvec", "voirDetail",
            "iHeure", "iEmploye", "iType", "iLieu", "ouvrirRdv", "winRdv",
            "aVenir", "aVenirPlanif", "toutEquipe", "pSem", "pProch", "pMois", "pMoisP", "periode", "avVide",
            "replier", "deplier",
            "activites", "lRouge", "lJaune", "dateDepassee", "propose60", "a60Ici", "a60Choisir", "merci60", "conseil60",
            "toutFait", "tous", "segR", "segY",
            "jePremier", "lClient", "lFacture", "lDernierRappel", "btnTexto", "btnCourriel", "btnPaiementRecu",
            "rappelCourrielConfirm", "rappelCourrielEnvoye", "rappelTextoOuvert", "rappelErreur", "envoyer",
            "canalTexto", "canalCourriel", "aujourdhuiMin", "winEncaissement",
            "texteSimule", "courrielSimule", "voirCourriel", "fermer",
            "lFournisseur", "btnPayerFacture", "winDecaissement"
        }
        Dim t As New Dictionary(Of String, String)
        For Each k As String In cles : t(k) = L(k) : Next
        Return t
    End Function

    ''' <summary>Traductions du tableau de bord (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Tableau de bord — 60secondes", "Dashboard — 60secondes", "Panel — 60secondes")
            Case "loginTitle" : Return Choose3(lang, "Connexion", "Sign in", "Iniciar sesión")
            Case "winAddInvoice" : Return Choose3(lang, "Nouvelle facture", "New invoice", "Nueva factura")
            Case "winEditInvoice" : Return Choose3(lang, "Modifier la facture", "Edit invoice", "Editar factura")
            Case "winRdv" : Return Choose3(lang, "Rendez-vous", "Appointment", "Cita")

            ' Fenêtre de 60
            Case "bonjour" : Return Choose3(lang, "Bonjour!", "Hello!", "¡Hola!")
            Case "bonjourNom" : Return Choose3(lang, "Bonjour, {0}!", "Hello, {0}!", "¡Hola, {0}!")
            Case "gUrgent1" : Return Choose3(lang, "Un geste urgent", "One urgent action", "Una acción urgente")
            Case "gUrgentN" : Return Choose3(lang, "{0} gestes urgents", "{0} urgent actions", "{0} acciones urgentes")
            Case "gVeille" : Return Choose3(lang, "À surveiller", "To watch", "A vigilar")
            Case "gOk" : Return Choose3(lang, "Tout va bien", "All good", "Todo va bien")
            Case "enPremier" : Return Choose3(lang, "En premier", "First", "Primero")
            Case "rienUrgent" : Return Choose3(lang, "Rien d'urgent. Tout est sous contrôle.", "Nothing urgent. Everything is under control.", "Nada urgente. Todo está bajo control.")
            Case "assistant60" : Return Choose3(lang, "60, votre assistant", "60, your assistant", "60, su asistente")
            Case "a60Aria" : Return Choose3(lang, "60 : aller à l'enjeu prioritaire", "60: go to the top priority", "60: ir al asunto prioritario")
            Case "a60Retour" : Return Choose3(lang, "Ramener 60 près de vous", "Bring 60 back", "Traer a 60 de vuelta")
            Case "a60RetourTip" : Return Choose3(lang, "60 est en train de régler l'enjeu — cliquez pour le ramener", "60 is handling the issue — click to bring it back", "60 está resolviendo el asunto — haga clic para traerlo")
            Case "activiteAFaire" : Return Choose3(lang, "Activité à faire", "Activities to do", "Actividades por hacer")
            Case "indR" : Return Choose3(lang, "{0} activité(s) en retard, à faire obligatoirement", "{0} overdue activity(ies), must be done", "{0} actividad(es) atrasada(s), obligatorias")
            Case "indY" : Return Choose3(lang, "{0} activité(s) dont la date approche", "{0} activity(ies) coming due", "{0} actividad(es) cuya fecha se acerca")
            Case "rdvDemande" : Return Choose3(lang, "RDV demandé", "Requested appt", "Cita solicitada")
            Case "rdvDemandeTip" : Return Choose3(lang, "Des clients demandent un RDV, ou de déplacer ou d'annuler un RDV : ouvrez l'Agenda pour répondre", "Customers are asking for an appointment, or to move or cancel one: open the Calendar to answer", "Unos clientes piden una cita, o moverla o cancelarla: abra la Agenda para responder")
            Case "messages" : Return Choose3(lang, "Messages", "Messages", "Mensajes")
            Case "msgAria" : Return Choose3(lang, "Ouvrir les messages du cabinet", "Open firm messages", "Abrir los mensajes del despacho")
            Case "msgNonLuN" : Return Choose3(lang, "{0} message(s) du cabinet non lu(s)", "{0} unread firm message(s)", "{0} mensaje(s) del despacho sin leer")
            Case "compteOp" : Return Choose3(lang, "Compte d'opérations", "Operating account", "Cuenta operativa")
            Case "voirMontant" : Return Choose3(lang, "Voir le solde", "Show balance", "Ver el saldo")
            Case "masquerMontant" : Return Choose3(lang, "Masquer le solde", "Hide balance", "Ocultar el saldo")
            Case "brancher" : Return Choose3(lang, "Brancher", "Connect", "Conectar")
            Case "bqAucun" : Return Choose3(lang, "Aucun compte branché", "No account connected", "Ninguna cuenta conectada")
            Case "bqAutres" : Return Choose3(lang, "(+{0})", "(+{0})", "(+{0})")
            Case "auDate" : Return Choose3(lang, "au {0}", "as of {0}", "al {0}")
            Case "kEnRetard" : Return Choose3(lang, "Revenu en retard", "Overdue revenue", "Ingresos atrasados")
            Case "kRetardAucun" : Return Choose3(lang, "aucune facture client en retard", "no overdue customer invoice", "ninguna factura de cliente atrasada")
            Case "kRetardN" : Return Choose3(lang, "{0} facture(s) client(s)", "{0} customer invoice(s)", "{0} factura(s) de cliente")
            Case "echueDepuis" : Return Choose3(lang, "échue depuis {0} jours", "{0} days overdue", "vencida hace {0} días")
            Case "kPayRetard" : Return Choose3(lang, "Paiements en retard", "Overdue payments", "Pagos atrasados")
            Case "kPayAucun" : Return Choose3(lang, "aucune facture fournisseur en retard", "no overdue supplier invoice", "ninguna factura de proveedor atrasada")
            Case "kFacturesFourn" : Return Choose3(lang, "{0} facture(s) fournisseur(s)", "{0} supplier invoice(s)", "{0} factura(s) de proveedor")

            ' Agenda : document, montant, lieu, présence
            Case "docSoumission" : Return Choose3(lang, "Soumission", "Quote", "Cotización")
            Case "docFacture" : Return Choose3(lang, "Facture", "Invoice", "Factura")
            Case "docTache" : Return Choose3(lang, "Tâche", "Task", "Tarea")
            Case "montantPrevu" : Return Choose3(lang, "Montant prévu", "Expected amount", "Importe previsto")
            Case "ouvrirBrouillon" : Return Choose3(lang, "Ouvrir le brouillon {0}", "Open draft {0}", "Abrir el borrador {0}")
            Case "voirFacture" : Return Choose3(lang, "Voir la facture {0}", "View invoice {0}", "Ver la factura {0}")
            Case "rdvFacture" : Return Choose3(lang, "Facturé", "Invoiced", "Facturado")
            Case "presence" : Return Choose3(lang, "Présence", "Attendance", "Presencia")
            Case "presenceAbs" : Return Choose3(lang, "{0} absence(s) aujourd'hui", "{0} absence(s) today", "{0} ausencia(s) hoy")
            Case "presenceRet" : Return Choose3(lang, "{0} retard(s) aujourd'hui", "{0} late arrival(s) today", "{0} retraso(s) hoy")
            Case "presAbsTitre" : Return Choose3(lang, "Absences", "Absences", "Ausencias")
            Case "presRetTitre" : Return Choose3(lang, "Retards", "Late arrivals", "Retrasos")
            Case "presRien" : Return Choose3(lang, "Toute l'équipe est présente aujourd'hui.", "The whole team is present today.", "Todo el equipo está presente hoy.")
            Case "presenceAria" : Return Choose3(lang, "Présence de l'équipe : absences et retards du jour", "Team attendance: today's absences and late arrivals", "Presencia del equipo: ausencias y retrasos del día")
            Case "lieuPlace" : Return Choose3(lang, "À votre place", "At your place", "En su local")
            Case "lieuChez" : Return Choose3(lang, "Chez le client", "At the customer", "En el cliente")
            Case "lieuTel" : Return Choose3(lang, "Téléphone", "Phone", "Teléfono")
            Case "lieuVisio" : Return Choose3(lang, "Visio", "Video", "Videollamada")

            ' Agenda
            Case "agenda" : Return Choose3(lang, "Agenda", "Calendar", "Agenda")
            Case "agendaAria" : Return Choose3(lang, "Ouvrir l'agenda complet", "Open the full calendar", "Abrir la agenda completa")
            Case "agendaTip" : Return Choose3(lang, "Voir et mettre à jour tout l'agenda", "See and update the whole calendar", "Ver y actualizar toda la agenda")
            Case "agendaDe" : Return Choose3(lang, "Agenda de", "Calendar of", "Agenda de")
            Case "equipeN" : Return Choose3(lang, "Toute l'équipe ({0})", "Whole team ({0})", "Todo el equipo ({0})")
            Case "plagesLibres" : Return Choose3(lang, "Prochaines plages libres", "Next free slots", "Próximos huecos libres")
            Case "plagesAria" : Return Choose3(lang, "3 prochaines plages libres", "Next 3 free slots", "3 próximos huecos libres")
            Case "plagesVide" : Return Choose3(lang, "aucune dans les deux prochaines semaines", "none in the next two weeks", "ninguno en las dos próximas semanas")
            Case "plageTip" : Return Choose3(lang, "Libre {0} de {1} à {2} — cliquez pour réserver", "Free {0} from {1} to {2} — click to book", "Libre {0} de {1} a {2} — haga clic para reservar")
            Case "agAuj" : Return Choose3(lang, "Aujourd'hui", "Today", "Hoy")
            Case "agAujAbr" : Return Choose3(lang, "Auj.", "Today", "Hoy")
            Case "agRdvH" : Return Choose3(lang, "{0} RDV · {1} h", "{0} appt · {1} h", "{0} citas · {1} h")
            Case "agEmployes" : Return Choose3(lang, "{0} employés", "{0} employees", "{0} empleados")
            Case "agVide" : Return Choose3(lang, "Aucun RDV : journée libre.", "No appointment: free day.", "Ninguna cita: día libre.")
            Case "exFictifs" : Return Choose3(lang, "Exemples fictifs, pour illustrer. Vos vrais rendez-vous s'afficheront ici.", "Sample data, for illustration. Your real appointments will show here.", "Ejemplos ficticios, para ilustrar. Sus citas reales aparecerán aquí.")
            Case "libre" : Return Choose3(lang, "Libre", "Free", "Libre")
            Case "stTermine" : Return Choose3(lang, "Terminé", "Completed", "Terminado")
            Case "stEnCours" : Return Choose3(lang, "En cours", "In progress", "En curso")
            Case "stAVenir" : Return Choose3(lang, "À venir", "Upcoming", "Próximo")
            Case "facturer" : Return Choose3(lang, "Facturer", "Invoice", "Facturar")
            Case "facturerAria" : Return Choose3(lang, "Facturer {0}", "Invoice {0}", "Facturar a {0}")
            Case "factConfirm" : Return Choose3(lang, "Comptabiliser ce rendez-vous en facture ?", "Post this appointment as an invoice?", "¿Contabilizar esta cita como factura?")
            Case "factEncours" : Return Choose3(lang, "Facturation…", "Invoicing…", "Facturando…")
            Case "factClient" : Return Choose3(lang, "Choisissez d'abord un client sur le brouillon.", "Choose a customer on the draft first.", "Elija primero un cliente en el borrador.")
            Case "factErreur" : Return Choose3(lang, "La facture n'a pas pu être comptabilisée.", "The invoice could not be posted.", "No se pudo contabilizar la factura.")
            Case "annuler" : Return Choose3(lang, "Annuler", "Cancel", "Cancelar")
            Case "plusRdv" : Return Choose3(lang, "+ RDV", "+ Appt", "+ Cita")
            Case "nouveauRdvAvec" : Return Choose3(lang, "Nouveau RDV avec {0}", "New appointment with {0}", "Nueva cita con {0}")
            Case "voirDetail" : Return Choose3(lang, "Voir le détail du RDV de {0}", "See the details of {0}'s appointment", "Ver el detalle de la cita de {0}")
            Case "iHeure" : Return Choose3(lang, "Heure et temps", "Time and duration", "Hora y duración")
            Case "iEmploye" : Return Choose3(lang, "Employé", "Employee", "Empleado")
            Case "iType" : Return Choose3(lang, "Service", "Service", "Servicio")
            Case "iLieu" : Return Choose3(lang, "Lieu", "Location", "Lugar")
            Case "ouvrirRdv" : Return Choose3(lang, "Ouvrir le rendez-vous", "Open the appointment", "Abrir la cita")
            Case "aVenir" : Return Choose3(lang, "À venir", "Upcoming", "Próximamente")
            Case "aVenirPlanif" : Return Choose3(lang, "{0} RDV · {1} h planifiées", "{0} appt · {1} h scheduled", "{0} citas · {1} h planificadas")
            Case "toutEquipe" : Return Choose3(lang, " · toute l'équipe", " · whole team", " · todo el equipo")
            Case "pSem" : Return Choose3(lang, "Prochains 7 jours", "Next 7 days", "Próximos 7 días")
            Case "pProch" : Return Choose3(lang, "Semaine suivante ({0})", "Following week ({0})", "Semana siguiente ({0})")
            Case "pMois" : Return Choose3(lang, "Ce mois-ci", "This month", "Este mes")
            Case "pMoisP" : Return Choose3(lang, "Mois prochain", "Next month", "Mes próximo")
            Case "periode" : Return Choose3(lang, "Période", "Period", "Período")
            Case "avVide" : Return Choose3(lang, "Aucun RDV pour cette période.", "No appointment for this period.", "Ninguna cita para este período.")
            Case "replier" : Return Choose3(lang, "Replier", "Collapse", "Plegar")
            Case "deplier" : Return Choose3(lang, "Déplier", "Expand", "Desplegar")

            ' Activités
            Case "activites" : Return Choose3(lang, "Activités à faire", "Activities to do", "Actividades por hacer")
            Case "lRouge" : Return Choose3(lang, "Rouge : date dépassée, à faire obligatoirement", "Red: date passed, must be done", "Rojo: fecha vencida, obligatorio")
            Case "lJaune" : Return Choose3(lang, "Jaune : la date d'action approche", "Yellow: action date is near", "Amarillo: la fecha de acción se acerca")
            Case "dateDepassee" : Return Choose3(lang, "Date dépassée", "Date passed", "Fecha vencida")
            Case "propose60" : Return Choose3(lang, "Proposée par 60, en haut", "Suggested by 60, on top", "Propuesta por 60, arriba")
            Case "a60Ici" : Return Choose3(lang, "60 · je suis là pour régler cet enjeu avec vous", "60 · I'm here to settle this with you", "60 · estoy aquí para resolver esto con usted")
            Case "a60Choisir" : Return Choose3(lang, "Choisissez une action ci-dessous : je passe ensuite au prochain enjeu.", "Choose an action below: I'll then move on to the next issue.", "Elija una acción abajo: luego paso al siguiente asunto.")
            Case "merci60" : Return Choose3(lang, "Merci, 60", "Thanks, 60", "Gracias, 60")
            Case "conseil60" : Return Choose3(lang, "Conseil de 60 :", "60's advice:", "Consejo de 60:")
            Case "toutFait" : Return Choose3(lang, "Tout est fait pour aujourd'hui. Bravo!", "Everything is done for today. Well done!", "Todo está hecho por hoy. ¡Bravo!")
            Case "tous" : Return Choose3(lang, "Tout voir", "See all", "Ver todo")
            Case "segR" : Return Choose3(lang, "{0} en retard — afficher seulement celles-ci", "{0} overdue — show only these", "{0} atrasadas — mostrar solo estas")
            Case "segY" : Return Choose3(lang, "{0} dont la date approche — afficher seulement celles-ci", "{0} coming due — show only these", "{0} por vencer — mostrar solo estas")
            Case "catVentes" : Return Choose3(lang, "Ventes", "Sales", "Ventas")
            Case "catAchats" : Return Choose3(lang, "Achats", "Purchases", "Compras")
            Case "catTaches" : Return Choose3(lang, "Tâches", "Tasks", "Tareas")
            Case "catComptabilite" : Return Choose3(lang, "Comptabilité", "Accounting", "Contabilidad")
            Case "catAbonnement" : Return Choose3(lang, "Abonnement", "Subscription", "Suscripción")
            Case "echueLe" : Return Choose3(lang, "échue le {0}", "due {0}", "vencida el {0}")
            Case "avantLe" : Return Choose3(lang, "avant le {0}", "before {0}", "antes del {0}")
            Case "dans7Jours" : Return Choose3(lang, "dans les 7 prochains jours", "within the next 7 days", "en los próximos 7 días")
            Case "etAutres" : Return Choose3(lang, "et {0} autre(s)", "and {0} more", "y {0} más")
            Case "aFactRetard" : Return Choose3(lang, "Facture {0} en retard", "Invoice {0} overdue", "Factura {0} atrasada")
            Case "aFactRetardDet" : Return Choose3(lang, "{0} doit encore {1}. La facture est échue depuis {2} jour(s) : un rappel courtois suffit souvent.", "{0} still owes {1}. The invoice is {2} day(s) overdue: a polite reminder is often enough.", "{0} todavía debe {1}. La factura venció hace {2} día(s): un recordatorio cortés suele bastar.")
            Case "aAutresRetards" : Return Choose3(lang, "{0} autres factures en retard", "{0} more overdue invoices", "{0} facturas atrasadas más")
            Case "aAutresRetardsDet" : Return Choose3(lang, "Voyez-les toutes dans les factures clients, filtrées « En retard ».", "See them all in customer invoices, filtered « Overdue ».", "Véalas todas en las facturas de clientes, filtradas « Atrasada ».")
            Case "aFactFournRetard" : Return Choose3(lang, "Facture fournisseur {0} en retard", "Supplier invoice {0} overdue", "Factura de proveedor {0} atrasada")
            Case "aAutresFournRetard" : Return Choose3(lang, "{0} autres factures fournisseurs en retard", "{0} more overdue supplier invoices", "{0} facturas de proveedor atrasadas más")
            Case "aFactFournConseil" : Return Choose3(lang, "un fournisseur payé en retard peut suspendre vos commandes ou ajouter des frais. Réglez-la dès que possible.", "a supplier paid late may hold your orders or add fees. Pay it as soon as possible.", "un proveedor pagado con retraso puede suspender sus pedidos o añadir cargos. Páguela lo antes posible.")
            Case "lFournisseur" : Return Choose3(lang, "Fournisseur", "Supplier", "Proveedor")
            Case "btnPayerFacture" : Return Choose3(lang, "Payer la facture", "Pay the invoice", "Pagar la factura")
            Case "winDecaissement" : Return Choose3(lang, "Payer un fournisseur", "Pay a supplier", "Pagar a un proveedor")
            Case "aFournRetard" : Return Choose3(lang, "{0} facture(s) fournisseur(s) en retard", "{0} overdue supplier invoice(s)", "{0} factura(s) de proveedor atrasada(s)")
            Case "aFournRetardDet" : Return Choose3(lang, "La date d'échéance est passée. 60secondes prépare le paiement ; vous l'autorisez.", "The due date has passed. 60secondes prepares the payment; you authorize it.", "La fecha de vencimiento pasó. 60secondes prepara el pago; usted lo autoriza.")
            Case "aFournProches" : Return Choose3(lang, "{0} facture(s) fournisseur(s) à suivre", "{0} supplier invoice(s) to follow", "{0} factura(s) de proveedor por seguir")
            Case "aFournProchesDet" : Return Choose3(lang, "Elles arrivent à échéance cette semaine. Préparez le paiement pour ne pas être en retard.", "They come due this week. Prepare the payment to avoid being late.", "Vencen esta semana. Prepare el pago para no atrasarse.")
            Case "aVentesProches" : Return Choose3(lang, "{0} facture(s) client(s) arrivent à échéance", "{0} customer invoice(s) coming due", "{0} factura(s) de cliente por vencer")
            Case "aVentesProchesDet" : Return Choose3(lang, "Un rappel avant l'échéance aide à être payé à temps.", "A reminder before the due date helps you get paid on time.", "Un recordatorio antes del vencimiento ayuda a cobrar a tiempo.")
            Case "aBrouillons" : Return Choose3(lang, "{0} facture(s) en brouillon", "{0} draft invoice(s)", "{0} factura(s) en borrador")
            Case "aBrouillonsSous" : Return Choose3(lang, "pas encore comptabilisées", "not posted yet", "aún no contabilizadas")
            Case "aBrouillonsDet" : Return Choose3(lang, "Une facture en brouillon n'est ni envoyée ni comptée dans vos revenus. Complétez-la et comptabilisez-la.", "A draft invoice is neither sent nor counted in your revenue. Complete and post it.", "Una factura en borrador no se envía ni cuenta en sus ingresos. Complétela y contabilícela.")
            Case "aApprob" : Return Choose3(lang, "{0} tâche(s) à approuver", "{0} task(s) to approve", "{0} tarea(s) por aprobar")
            Case "aApprobSous" : Return Choose3(lang, "en attente de votre décision", "waiting for your decision", "esperan su decisión")
            Case "aApprobDet" : Return Choose3(lang, "60 ne lancera pas ces tâches sans votre accord.", "60 will not run these tasks without your approval.", "60 no ejecutará estas tareas sin su aprobación.")
            Case "aBanque" : Return Choose3(lang, "Branchez votre compte bancaire", "Connect your bank account", "Conecte su cuenta bancaria")
            Case "aBanqueSous" : Return Choose3(lang, "pour l'encaisse et le rapprochement", "for cash and reconciliation", "para el efectivo y la conciliación")
            Case "aBanqueDet" : Return Choose3(lang, "Sans compte branché, 60 ne peut ni afficher votre encaisse ni rapprocher vos transactions.", "Without a connected account, 60 can neither show your cash nor reconcile your transactions.", "Sin cuenta conectada, 60 no puede mostrar su efectivo ni conciliar sus transacciones.")
            Case "aEssai" : Return Choose3(lang, "Essai : {0} jours restants", "Trial: {0} days left", "Prueba: quedan {0} días")
            Case "aEssaiSous" : Return Choose3(lang, "fin de l'essai · choisissez votre forfait", "end of trial · choose your plan", "fin de la prueba · elija su plan")
            Case "aEssaiDet" : Return Choose3(lang, "Choisissez votre forfait avant la fin de l'essai pour garder vos données et vos branchements.", "Choose your plan before the trial ends to keep your data and connections.", "Elija su plan antes del fin de la prueba para conservar sus datos y conexiones.")
            Case "btnRelancer" : Return Choose3(lang, "Relancer", "Follow up", "Recordar")
            ' Activité « Facture en retard » ouverte
            Case "aFactRetardConseil" : Return Choose3(lang, "plus un retard s'allonge, plus le paiement devient difficile. Un texto poli suffit souvent.", "the longer a payment is late, the harder it gets to collect. A polite text is often enough.", "cuanto más se alarga un retraso, más difícil es cobrar. Un mensaje de texto cortés suele bastar.")
            Case "jePremier" : Return Choose3(lang, "Je la place en premier : ", "I put it first: ", "La pongo en primer lugar: ")
            Case "lClient" : Return Choose3(lang, "Client", "Customer", "Cliente")
            Case "lFacture" : Return Choose3(lang, "Facture {0}", "Invoice {0}", "Factura {0}")
            Case "echueDepuisJ" : Return Choose3(lang, "échue depuis {0} jour(s)", "{0} day(s) overdue", "vencida hace {0} día(s)")
            Case "lDernierRappel" : Return Choose3(lang, "Dernier rappel", "Last reminder", "Último recordatorio")
            Case "rappelAucun" : Return Choose3(lang, "aucun", "none", "ninguno")
            Case "canalTexto" : Return Choose3(lang, "texto", "text", "SMS")
            Case "canalCourriel" : Return Choose3(lang, "courriel", "email", "correo")
            Case "aujourdhuiMin" : Return Choose3(lang, "aujourd'hui", "today", "hoy")
            Case "btnTexto" : Return Choose3(lang, "Envoyer un texto", "Send a text", "Enviar un SMS")
            Case "btnCourriel" : Return Choose3(lang, "Envoyer un courriel", "Send an email", "Enviar un correo")
            Case "btnPaiementRecu" : Return Choose3(lang, "Paiement déjà reçu", "Payment already received", "Pago ya recibido")
            Case "envoyer" : Return Choose3(lang, "Envoyer", "Send", "Enviar")
            Case "rappelCourrielConfirm" : Return Choose3(lang, "Envoyer un rappel par courriel à {0} pour la facture {1} ?", "Send an email reminder to {0} for invoice {1}?", "¿Enviar un recordatorio por correo a {0} por la factura {1}?")
            Case "rappelCourrielEnvoye" : Return Choose3(lang, "Rappel déposé pour {0}. Il partira dans quelques minutes.", "Reminder queued for {0}. It will go out in a few minutes.", "Recordatorio en cola para {0}. Saldrá en unos minutos.")
            Case "rappelTextoOuvert" : Return Choose3(lang, "Votre application de messagerie s'ouvre avec le texto prêt à envoyer à {0}.", "Your messaging app opens with the text ready to send to {0}.", "Su aplicación de mensajes se abre con el SMS listo para enviar a {0}.")
            Case "rappelErreur" : Return Choose3(lang, "Le rappel n'a pas pu être envoyé.", "The reminder could not be sent.", "No se pudo enviar el recordatorio.")
            Case "winEncaissement" : Return Choose3(lang, "Ajouter un encaissement", "Add cash receipt", "Agregar cobro")
            ' Rappels en mode simulé (RappelFacture.ashx) : rien n'est envoyé
            Case "texteSimule" : Return Choose3(lang, "Texto simulé pour {0} : rien n'a été envoyé. Voici le message qui serait parti :", "Simulated text to {0}: nothing was sent. Here is the message that would have gone out:", "SMS simulado para {0}: no se envió nada. Este es el mensaje que habría salido:")
            Case "courrielSimule" : Return Choose3(lang, "Courriel simulé pour {0} : rien n'a été envoyé. Vous pouvez voir le courriel qui serait parti.", "Simulated email to {0}: nothing was sent. You can view the email that would have gone out.", "Correo simulado para {0}: no se envió nada. Puede ver el correo que habría salido.")
            Case "voirCourriel" : Return Choose3(lang, "Voir le courriel", "View the email", "Ver el correo")
            Case "fermer" : Return Choose3(lang, "Fermer", "Close", "Cerrar")
            Case "btnVoir" : Return Choose3(lang, "Voir", "View", "Ver")
            Case "btnPreparer" : Return Choose3(lang, "Préparer le paiement", "Prepare the payment", "Preparar el pago")
            Case "btnApprouver" : Return Choose3(lang, "Voir et approuver", "See and approve", "Ver y aprobar")
            Case "btnBrancher" : Return Choose3(lang, "Brancher ma banque", "Connect my bank", "Conectar mi banco")
            Case "btnForfait" : Return Choose3(lang, "Choisir mon forfait", "Choose my plan", "Elegir mi plan")
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
