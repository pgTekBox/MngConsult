Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports Newtonsoft.Json

''' <summary>
''' Le tableau de bord, au modèle de l'accueil 60secondes (accueil-60secondes-complet.html) :
'''   1. la fenêtre de 60 (bonjour, ce qui passe en premier, À faire rouge / jaune),
'''      le bouton « + Facture » et la tuile noire qui mène aux 12 éléments du menu ;
'''   2. Mon argent : mois, compte bancaire, six cases (Encaisse, Revenus, À recevoir,
'''      À payer, En retard, Encaisse prévue sur 4 semaines) ;
'''   3. l'Agenda : la journée en liste et la semaine de 5 jours ouvrables ;
'''   4. les Activités à faire, classées par couleur (rouge = date dépassée,
'''      jaune = date qui approche, noir = fait par 60).
''' Tout est calculé à partir des vraies données de la compagnie (factures clients
''' s0026, factures fournisseurs s0023, comptes bancaires T143PlaidAccount,
''' rendez-vous s0100, tâches à approuver s0745, essai s0687). Le serveur bâtit un
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
        Dim c As CultureInfo = Cult()

        ' ---------- Le mois affiché (?mois=aaaa-mm), le mois courant par défaut ----------
        Dim debutMoisCourant As New Date(aujourdhui.Year, aujourdhui.Month, 1)
        Dim moisAffiche As Date = debutMoisCourant
        Dim q As String = If(Request.QueryString("mois"), "")
        Dim m As Date
        If Date.TryParseExact(q & "-01", "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, m) Then
            If m <= debutMoisCourant AndAlso m >= debutMoisCourant.AddMonths(-11) Then moisAffiche = m
        End If
        Dim optionsMois As New List(Of Object)
        For i As Integer = 0 To 11
            Dim d As Date = debutMoisCourant.AddMonths(-i)
            optionsMois.Add(New With {.v = d.ToString("yyyy-MM"), .lab = Majuscule(d.ToString("MMMM yyyy", c))})
        Next

        ' ---------- Les données ----------
        Dim ventes As DataTable = Table("s0026GetCustomersInvoices")
        Dim achats As DataTable = Table("s0023GetSuppliersInvoices")
        Dim comptes As DataTable = ComptesBancaires()
        Dim nbApprob As Integer = CompterApprobations()

        ' ---------- Mon argent ----------
        Dim encaisse As Decimal = 0D, aCompte As Boolean = comptes IsNot Nothing AndAlso comptes.Rows.Count > 0
        Dim libCompte As String = L("bqAucun"), majCompte As String = ""
        If aCompte Then
            For Each r As DataRow In comptes.Rows : encaisse += Dec(r("BalanceCurrent")) : Next
            Dim r0 As DataRow = comptes.Rows(0)
            libCompte = Txt(r0("BankName"))
            If Txt(r0("AccountName")) <> "" Then libCompte &= " · " & Txt(r0("AccountName"))
            If Txt(r0("Mask")) <> "" Then libCompte &= " ••• " & Txt(r0("Mask"))
            If comptes.Rows.Count > 1 Then libCompte &= " " & String.Format(L("bqAutres"), comptes.Rows.Count - 1)
            Dim maj As Date? = DateN(r0("BalanceUpdated"))
            majCompte = Txt(r0("BankName")) & If(maj.HasValue, " · " & String.Format(L("auDate"), JourMois(maj.Value)), "")
        End If

        Dim finMois As Date = moisAffiche.AddMonths(1)
        Dim revenus As Decimal = 0D, nbRevenus As Integer = 0
        Dim aRecevoir As Decimal = 0D, nbARecevoir As Integer = 0
        Dim enRetard As Decimal = 0D
        Dim retardsVentes As New List(Of DataRow)
        Dim prochesVentes As New List(Of DataRow)
        Dim brouillonsVentes As Integer = 0
        Dim dans28 As Date = aujourdhui.AddDays(28)
        Dim entrees28 As Decimal = 0D

        If ventes IsNot Nothing Then
            For Each r As DataRow In ventes.Rows
                Dim compta As Boolean = Txt(r("ComptabilisationStatus")).ToUpperInvariant() = "COMPTABILISE"
                If Not compta Then brouillonsVentes += 1 : Continue For
                Dim dd As Date? = DateN(r("DocumentDate"))
                If dd.HasValue AndAlso dd.Value >= moisAffiche AndAlso dd.Value < finMois Then
                    revenus += Dec(r("Total")) : nbRevenus += 1
                End If
                Dim reste As Decimal = Dec(r("ResteAPayer"))
                If reste <= 0.005D OrElse Txt(r("StatutPaiement")).ToUpperInvariant() = "PAYEE" Then Continue For
                aRecevoir += reste : nbARecevoir += 1
                Dim ech As Date? = DateN(r("DueDate"))
                If (ech.HasValue AndAlso ech.Value < aujourdhui) OrElse Txt(r("StatutPaiement")).ToUpperInvariant() = "EN_RETARD" Then
                    enRetard += reste : retardsVentes.Add(r)
                Else
                    If ech.HasValue AndAlso ech.Value <= aujourdhui.AddDays(7) Then prochesVentes.Add(r)
                    If Not ech.HasValue OrElse ech.Value <= dans28 Then entrees28 += reste
                End If
            Next
        End If

        Dim aPayer As Decimal = 0D, nbAPayer As Integer = 0
        Dim retardsAchats As New List(Of DataRow)
        Dim prochesAchats As New List(Of DataRow)
        Dim sorties28 As Decimal = 0D
        If achats IsNot Nothing Then
            For Each r As DataRow In achats.Rows
                If Txt(r("ComptabilisationStatus")).ToUpperInvariant() <> "COMPTABILISE" Then Continue For
                Dim reste As Decimal = Dec(r("ResteAPayer"))
                If reste <= 0.005D OrElse Txt(r("StatutPaiement")).ToUpperInvariant() = "PAYEE" Then Continue For
                aPayer += reste : nbAPayer += 1
                Dim ech As Date? = DateN(r("DueDate"))
                If ech.HasValue AndAlso ech.Value < aujourdhui Then
                    retardsAchats.Add(r)
                ElseIf ech.HasValue AndAlso ech.Value <= aujourdhui.AddDays(7) Then
                    prochesAchats.Add(r)
                End If
                If Not ech.HasValue OrElse ech.Value <= dans28 Then sorties28 += reste
            Next
        End If

        retardsVentes = retardsVentes.OrderBy(Function(r) If(DateN(r("DueDate")), aujourdhui)).ToList()
        Dim prevue As Decimal = encaisse + entrees28 - sorties28

        Dim argent As New List(Of Object)
        argent.Add(Case6(L("kEncaisse"), If(aCompte, Montant(encaisse), "—"), If(aCompte, majCompte, L("kEncaisseSansBanque")), "", "PlaidAccounts.aspx", True))
        argent.Add(Case6(L("kRevenus"), Montant(revenus),
                         If(nbRevenus = 0, L("kRevenusAucune"), String.Format(L("kRevenusN"), nbRevenus)), "", "wbfCustomersInvoices.aspx", False))
        argent.Add(Case6(L("kARecevoir"), Montant(aRecevoir),
                         If(enRetard > 0, String.Format(L("kDontRetard"), Montant(enRetard)), String.Format(L("kFacturesClients"), nbARecevoir)),
                         If(enRetard > 0, "r", ""), "wbfCustomersInvoices.aspx", False))
        argent.Add(Case6(L("kAPayer"), Montant(aPayer), String.Format(L("kFacturesFourn"), nbAPayer),
                         If(retardsAchats.Count > 0, "r", If(prochesAchats.Count > 0, "y", "")), "wbfSuppliersInvoices.aspx", False))
        Dim sousRetard As String = L("kRetardAucun")
        If retardsVentes.Count > 0 Then
            Dim pire As Date? = DateN(retardsVentes(0)("DueDate"))
            sousRetard = String.Format(L("kRetardN"), retardsVentes.Count) &
                         If(pire.HasValue, " · " & String.Format(L("echueDepuis"), (aujourdhui - pire.Value).Days), "")
        End If
        argent.Add(Case6(L("kEnRetard"), Montant(enRetard), sousRetard, If(enRetard > 0, "r", ""), "wbfCustomersInvoices.aspx", False))
        Dim dotPrevue As String = ""
        If aCompte Then dotPrevue = If(prevue < 0, "r", If(prevue < encaisse, "y", ""))
        argent.Add(Case6(L("kPrevue"), If(aCompte, Montant(prevue), "—"),
                         If(aCompte, String.Format(L("kPrevueSous"), JourMois(dans28)), L("kEncaisseSansBanque")),
                         dotPrevue, "PlaidAccounts.aspx", False))

        ' ---------- Activités à faire ----------
        Dim acts As New List(Of Object)
        Dim nRetardMax As Integer = 5
        For Each r As DataRow In retardsVentes.Take(nRetardMax)
            Dim ech As Date? = DateN(r("DueDate"))
            Dim jours As Integer = If(ech.HasValue, (aujourdhui - ech.Value).Days, 0)
            acts.Add(Activite("r", String.Format(L("aFactRetard"), NumFacture(r)),
                              L("catVentes") & " · " & If(ech.HasValue, String.Format(L("echueLe"), JourMois(ech.Value)) & " · ", "") & Txt(r("NameSort")) & " · " & Montant(Dec(r("ResteAPayer"))),
                              String.Format(L("aFactRetardDet"), Txt(r("NameSort")), Montant(Dec(r("ResteAPayer"))), jours),
                              L("btnRelancer"), "wbfCustomersInvoices.aspx"))
        Next
        If retardsVentes.Count > nRetardMax Then
            acts.Add(Activite("r", String.Format(L("aAutresRetards"), retardsVentes.Count - nRetardMax),
                              L("catVentes") & " · " & Montant(retardsVentes.Skip(nRetardMax).Sum(Function(r) Dec(r("ResteAPayer")))),
                              L("aAutresRetardsDet"), L("btnVoir"), "wbfCustomersInvoices.aspx"))
        End If
        If retardsAchats.Count > 0 Then
            acts.Add(Activite("r", String.Format(L("aFournRetard"), retardsAchats.Count),
                              L("catAchats") & " · " & Noms(retardsAchats) & " · " & Montant(retardsAchats.Sum(Function(r) Dec(r("ResteAPayer")))),
                              L("aFournRetardDet"), L("btnPreparer"), "wbfSuppliersInvoices.aspx"))
        End If
        If nbApprob > 0 Then
            acts.Add(Activite("y", String.Format(L("aApprob"), nbApprob), L("catTaches") & " · " & L("aApprobSous"),
                              L("aApprobDet"), L("btnApprouver"), "wbfApprobations.aspx"))
        End If
        If prochesAchats.Count > 0 Then
            Dim proch As Date = prochesAchats.Min(Function(r) DateN(r("DueDate")).Value)
            acts.Add(Activite("y", String.Format(L("aFournProches"), prochesAchats.Count),
                              L("catAchats") & " · " & String.Format(L("avantLe"), JourMois(proch)) & " · " & Noms(prochesAchats) & " · " & Montant(prochesAchats.Sum(Function(r) Dec(r("ResteAPayer")))),
                              L("aFournProchesDet"), L("btnPreparer"), "wbfSuppliersInvoices.aspx"))
        End If
        If prochesVentes.Count > 0 Then
            acts.Add(Activite("y", String.Format(L("aVentesProches"), prochesVentes.Count),
                              L("catVentes") & " · " & L("dans7Jours") & " · " & Montant(prochesVentes.Sum(Function(r) Dec(r("ResteAPayer")))),
                              L("aVentesProchesDet"), L("btnVoir"), "wbfCustomersInvoices.aspx"))
        End If
        If brouillonsVentes > 0 Then
            acts.Add(Activite("y", String.Format(L("aBrouillons"), brouillonsVentes), L("catVentes") & " · " & L("aBrouillonsSous"),
                              L("aBrouillonsDet"), L("btnVoir"), "wbfCustomersInvoices.aspx"))
        End If
        If Not aCompte Then
            acts.Add(Activite("y", L("aBanque"), L("catComptabilite") & " · " & L("aBanqueSous"),
                              L("aBanqueDet"), L("btnBrancher"), "PlaidAccounts.aspx"))
        End If
        Dim essai As Object = EtatEssai()
        If essai IsNot Nothing Then acts.Add(essai)

        ' ---------- Agenda ----------
        Dim agenda As Object = BatirAgenda(c)

        ' ---------- La tuile noire : les 12 éléments du menu ----------
        Dim tuile As New List(Of Object) From {
            Nav(L("dashboard"), "Default.aspx"), Nav(L("sales"), "wbfCustomersInvoices.aspx"),
            Nav(L("purchases"), "wbfSuppliersInvoices.aspx"), Nav(L("payments"), "wbfPaymentProcessors.aspx"),
            Nav(L("reports"), "wbfEtatResultats.aspx"), Nav(L("agenda"), "wbfAgenda.aspx"),
            Nav(L("employees"), "wbfEmployees.aspx"), Nav(L("accounting"), "wbfJournal.aspx"),
            Nav(L("products"), "wbfProducts.aspx"), Nav(L("approvals"), "wbfApprobations.aspx"),
            Nav(L("myFirm"), "CabinetsCertifies.aspx?popup=1", True), Nav(L("settings"), "wbfSetting.aspx")
        }

        Dim prenom As String = ""
        Try : prenom = UserFirstName : Catch : End Try

        Return New With {
            .prenom = prenom,
            .lang = CurrentLang,
            .mois = New With {.val = moisAffiche.ToString("yyyy-MM"), .courant = (moisAffiche = debutMoisCourant), .options = optionsMois},
            .banque = New With {.aCompte = aCompte, .lib = libCompte, .solde = If(aCompte, Montant(encaisse), "")},
            .argent = argent,
            .activites = acts,
            .agenda = agenda,
            .tuile = tuile,
            .t = Textes()
        }
    End Function

    Private Function Case6(lab As String, val As String, sous As String, dot As String, url As String, oeil As Boolean) As Object
        Return New With {.lab = lab, .val = val, .sous = sous, .dot = dot, .url = url, .oeil = oeil}
    End Function

    Private Function Activite(u As String, titre As String, sous As String, detail As String, bouton As String, url As String) As Object
        Return New With {.u = u, .t = titre, .d = sous, .det = detail, .btn = bouton, .url = url}
    End Function

    Private Function Nav(lab As String, url As String, Optional fenetre As Boolean = False) As Object
        Return New With {.lab = lab, .url = ResolveUrl("~/" & url), .fen = fenetre}
    End Function

    ''' <summary>L'essai gratuit (s0687) : une activité jaune dans les 30 derniers jours.</summary>
    Private Function EtatEssai() As Object
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0687GetCompanyTrialStatus", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return Nothing
            Dim r As DataRow = ds.Tables(0).Rows(0)
            If Not Vrai(r("IsTrial")) OrElse IsDBNull(r("DaysRemaining")) Then Return Nothing
            Dim jours As Integer = Convert.ToInt32(r("DaysRemaining"))
            If jours < 0 OrElse jours > 30 Then Return Nothing
            Dim fin As Date? = DateN(r("TrialEndOn"))
            Return Activite(If(jours <= 3, "r", "y"), String.Format(L("aEssai"), jours),
                            L("catAbonnement") & If(fin.HasValue, " · " & String.Format(L("avantLe"), JourMois(fin.Value)), "") & " · " & L("aEssaiSous"),
                            L("aEssaiDet"), L("btnForfait"), "wbfPayment.aspx")
        Catch
            Return Nothing
        End Try
    End Function

    ''' <summary>
    ''' L'agenda : 5 jours ouvrables à partir d'aujourd'hui (?sem=n décale d'autant de
    ''' semaines), les employés et les rendez-vous de la période (s0100, s0106).
    ''' </summary>
    Private Function BatirAgenda(c As CultureInfo) As Object
        Dim decalage As Integer = 0
        Integer.TryParse(If(Request.QueryString("sem"), "0"), decalage)
        If decalage < -52 OrElse decalage > 52 Then decalage = 0

        Dim depart As Date = aujourdhui.AddDays(7 * decalage)
        Dim jours As New List(Of Date)
        Dim d As Date = depart
        While jours.Count < 5
            If d.DayOfWeek <> DayOfWeek.Saturday AndAlso d.DayOfWeek <> DayOfWeek.Sunday Then jours.Add(d)
            d = d.AddDays(1)
        End While

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

        Dim rdv As New List(Of Object)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@StartDate", jours(0)))
            p.Add(New SqlParameter("@EndDate", jours(4).AddDays(1)))
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
                    Dim ecart As TimeSpan = fin - debut
                    Dim client As String = Txt(r("CustomerName"))
                    Dim titre As String = Txt(r("Title"))
                    rdv.Add(New With {
                        .id = Convert.ToInt32(r("Id")),
                        .jour = debut.ToString("yyyy-MM-dd"),
                        .tri = debut.ToString("HHmm"),
                        .h = Heure(debut),
                        .plage = Heure(debut) & " – " & Heure(fin) & " · " & Duree(ecart),
                        .client = If(client = "", titre, client),
                        .court = If(client = "", Txt(r("TypeName")), titre),
                        .desc = Txt(r("Description")),
                        .lieu = Txt(r("Location")),
                        .typ = Txt(r("TypeName")),
                        .emp = empId,
                        .empNom = Txt(r("EmployeeName")),
                        .ini = Initiales(Txt(r("EmployeeName"))),
                        .c = If(empId <> "" AndAlso couleurs.ContainsKey(CInt(empId)), couleurs(CInt(empId)), "#1B4F9C"),
                        .etat = etat,
                        .statut = If(statut = "", "Planifié", statut)
                    })
                Next
            End If
        Catch
        End Try

        Dim lesJours As New List(Of Object)
        For Each j As Date In jours
            lesJours.Add(New With {
                .v = j.ToString("yyyy-MM-dd"),
                .court = Majuscule(j.ToString("ddd", c).TrimEnd("."c)) & " " & j.Day.ToString(),
                .libLong = Majuscule(j.ToString("dddd d MMMM", c)),
                .auj = (j = aujourdhui)
            })
        Next

        Dim titreSemaine As String
        If jours(0).Month = jours(4).Month Then
            titreSemaine = String.Format(L("agDuAu"), jours(0).Day, jours(4).ToString("d MMMM yyyy", c))
        Else
            titreSemaine = String.Format(L("agDuAu"), jours(0).ToString("d MMMM", c), jours(4).ToString("d MMMM yyyy", c))
        End If

        Return New With {
            .emps = emps,
            .jours = lesJours,
            .rdv = rdv,
            .sem = decalage,
            .titre = titreSemaine,
            .aujourdhui = aujourdhui.ToString("yyyy-MM-dd"),
            .debutRdv = jours(0).ToString("yyyy-MM-ddT09:00:00")
        }
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

    ''' <summary>Les tâches en attente d'une décision (même décompte que la pastille du menu, s0745).</summary>
    Private Function CompterApprobations() As Integer
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0745GetApprobationsCount", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return 0
            Return Convert.ToInt32(ds.Tables(0).Rows(0)("AApprouver"))
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

    Private Shared Function Majuscule(s As String) As String
        If String.IsNullOrEmpty(s) Then Return s
        Return Char.ToUpper(s(0)) & s.Substring(1)
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
        Return New With {
            .bonjour = L("bonjour"), .bonjourNom = L("bonjourNom"),
            .gUrgent1 = L("gUrgent1"), .gUrgentN = L("gUrgentN"), .gVeille = L("gVeille"), .gOk = L("gOk"),
            .enPremier = L("enPremier"), .aFaire = L("aFaire"), .rienUrgent = L("rienUrgent"),
            .indR = L("indR"), .indY = L("indY"),
            .allerA = L("allerA"), .ouvrir = L("ouvrir"),
            .voirMontant = L("voirMontant"), .masquerMontant = L("masquerMontant"),
            .moisCourant = L("moisCourant"), .moisPasse = L("moisPasse"),
            .lRouge = L("lRouge"), .lJaune = L("lJaune"), .lNoir = L("lNoir"), .faitPar60 = L("faitPar60"),
            .toutFait = L("toutFait"), .tous = L("tous"),
            .choses1 = L("choses1"), .chosesN = L("chosesN"),
            .equipe = L("equipe"), .agAuj = L("agAuj"), .agRdv1 = L("agRdv1"), .agRdvN = L("agRdvN"), .agLibre = L("agLibre"),
            .agVide = L("agVide"), .agSemSous = L("agSemSous"),
            .stTermine = L("stTermine"), .stEnCours = L("stEnCours"), .stAVenir = L("stAVenir"),
            .iHeure = L("iHeure"), .iEmploye = L("iEmploye"), .iType = L("iType"), .iLieu = L("iLieu"),
            .ouvrirRdv = L("ouvrirRdv"), .winRdv = L("winRdv"),
            .assistant60 = L("assistant60"),
            .factureBtn = L("factureBtn"),
            .autresFct = L("autresFct"),
            .fctPrec = L("fctPrec"),
            .fctSuiv = L("fctSuiv"),
            .monArgent = L("monArgent"),
            .moisPrec = L("moisPrec"),
            .moisSuiv = L("moisSuiv"),
            .moisAffiche = L("moisAffiche"),
            .noteArgent = L("noteArgent"),
            .agenda = L("agenda"),
            .agendaDe = L("agendaDe"),
            .messages = L("messages"),
            .ajouterRdv = L("ajouterRdv"),
            .rdvBtn = L("rdvBtn"),
            .semPrec = L("semPrec"),
            .semaine = L("semaine"),
            .semSuiv = L("semSuiv"),
            .activites = L("activites")
        }
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
            Case "aFaire" : Return Choose3(lang, "À faire", "To do", "Por hacer")
            Case "rienUrgent" : Return Choose3(lang, "Rien d'urgent. Tout est sous contrôle.", "Nothing urgent. Everything is under control.", "Nada urgente. Todo está bajo control.")
            Case "indR" : Return Choose3(lang, "{0} activité(s) en retard, à faire obligatoirement", "{0} overdue activity(ies), must be done", "{0} actividad(es) atrasada(s), obligatorias")
            Case "indY" : Return Choose3(lang, "{0} activité(s) dont la date approche", "{0} activity(ies) coming due", "{0} actividad(es) cuya fecha se acerca")
            Case "factureBtn" : Return Choose3(lang, "Facture", "Invoice", "Factura")
            Case "allerA" : Return Choose3(lang, "Aller à", "Go to", "Ir a")
            Case "ouvrir" : Return Choose3(lang, "Ouvrir", "Open", "Abrir")
            Case "fctPrec" : Return Choose3(lang, "Fonction précédente", "Previous function", "Función anterior")
            Case "fctSuiv" : Return Choose3(lang, "Fonction suivante", "Next function", "Función siguiente")
            Case "autresFct" : Return Choose3(lang, "Autres fonctions", "Other functions", "Otras funciones")
            Case "assistant60" : Return Choose3(lang, "60, votre assistant", "60, your assistant", "60, su asistente")

            ' Mon argent
            Case "monArgent" : Return Choose3(lang, "Mon argent", "My money", "Mi dinero")
            Case "moisPrec" : Return Choose3(lang, "Mois précédent", "Previous month", "Mes anterior")
            Case "moisSuiv" : Return Choose3(lang, "Mois suivant", "Next month", "Mes siguiente")
            Case "moisAffiche" : Return Choose3(lang, "Mois affiché", "Month shown", "Mes mostrado")
            Case "moisCourant" : Return Choose3(lang, "Mois en cours", "Current month", "Mes en curso")
            Case "moisPasse" : Return Choose3(lang, "Mois passé", "Past month", "Mes pasado")
            Case "voirMontant" : Return Choose3(lang, "Voir le solde", "Show balance", "Ver el saldo")
            Case "masquerMontant" : Return Choose3(lang, "Masquer le solde", "Hide balance", "Ocultar el saldo")
            Case "bqAucun" : Return Choose3(lang, "Aucun compte bancaire branché", "No bank account connected", "Ninguna cuenta bancaria conectada")
            Case "bqAutres" : Return Choose3(lang, "(+{0})", "(+{0})", "(+{0})")
            Case "auDate" : Return Choose3(lang, "au {0}", "as of {0}", "al {0}")
            Case "kEncaisse" : Return Choose3(lang, "Encaisse aujourd'hui", "Cash today", "Efectivo hoy")
            Case "kEncaisseSansBanque" : Return Choose3(lang, "branchez votre banque", "connect your bank", "conecte su banco")
            Case "kRevenus" : Return Choose3(lang, "Revenus du mois", "Revenue for the month", "Ingresos del mes")
            Case "kRevenusAucune" : Return Choose3(lang, "aucune facture comptabilisée", "no invoice posted", "ninguna factura contabilizada")
            Case "kRevenusN" : Return Choose3(lang, "{0} facture(s) comptabilisée(s)", "{0} invoice(s) posted", "{0} factura(s) contabilizada(s)")
            Case "kARecevoir" : Return Choose3(lang, "À recevoir", "Receivable", "Por cobrar")
            Case "kDontRetard" : Return Choose3(lang, "dont {0} en retard", "of which {0} overdue", "de los cuales {0} atrasados")
            Case "kFacturesClients" : Return Choose3(lang, "{0} facture(s) client(s)", "{0} customer invoice(s)", "{0} factura(s) de cliente")
            Case "kAPayer" : Return Choose3(lang, "À payer", "Payable", "Por pagar")
            Case "kFacturesFourn" : Return Choose3(lang, "{0} facture(s) fournisseur(s)", "{0} supplier invoice(s)", "{0} factura(s) de proveedor")
            Case "kEnRetard" : Return Choose3(lang, "En retard", "Overdue", "Atrasado")
            Case "kRetardAucun" : Return Choose3(lang, "aucune facture en retard", "no overdue invoice", "ninguna factura atrasada")
            Case "kRetardN" : Return Choose3(lang, "{0} facture(s)", "{0} invoice(s)", "{0} factura(s)")
            Case "echueDepuis" : Return Choose3(lang, "échue depuis {0} jours", "{0} days overdue", "vencida hace {0} días")
            Case "kPrevue" : Return Choose3(lang, "Encaisse prévue · 4 semaines", "Projected cash · 4 weeks", "Efectivo previsto · 4 semanas")
            Case "kPrevueSous" : Return Choose3(lang, "prévue au {0}", "projected for {0}", "prevista al {0}")
            Case "noteArgent" : Return Choose3(lang, "Montants en dollars canadiens ($ CA). Revenus : mois affiché ; les autres montants : en date d'aujourd'hui.", "Amounts in Canadian dollars (CAD). Revenue: month shown; other amounts: as of today.", "Importes en dólares canadienses (CAD). Ingresos: mes mostrado; los demás importes: a la fecha de hoy.")

            ' Agenda
            Case "agenda" : Return Choose3(lang, "Agenda", "Calendar", "Agenda")
            Case "agendaDe" : Return Choose3(lang, "Agenda de", "Calendar of", "Agenda de")
            Case "equipe" : Return Choose3(lang, "Toute l'équipe", "Whole team", "Todo el equipo")
            Case "messages" : Return Choose3(lang, "Messages", "Messages", "Mensajes")
            Case "rdvBtn" : Return Choose3(lang, "RDV", "Appt", "Cita")
            Case "ajouterRdv" : Return Choose3(lang, "Ajouter un rendez-vous", "Add an appointment", "Añadir una cita")
            Case "agAuj" : Return Choose3(lang, "Aujourd'hui", "Today", "Hoy")
            Case "agRdv1" : Return Choose3(lang, "1 RDV", "1 appt", "1 cita")
            Case "agRdvN" : Return Choose3(lang, "{0} RDV", "{0} appts", "{0} citas")
            Case "agLibre" : Return Choose3(lang, "libre", "free", "libre")
            Case "agVide" : Return Choose3(lang, "Aucun RDV : journée libre.", "No appointment: free day.", "Ninguna cita: día libre.")
            Case "agSemSous" : Return Choose3(lang, "5 jours ouvrables · cliquez un jour", "5 business days · click a day", "5 días hábiles · haga clic en un día")
            Case "agDuAu" : Return Choose3(lang, "{0} au {1}", "{0} to {1}", "{0} al {1}")
            Case "semPrec" : Return Choose3(lang, "Semaine précédente", "Previous week", "Semana anterior")
            Case "semSuiv" : Return Choose3(lang, "Semaine suivante", "Next week", "Semana siguiente")
            Case "semaine" : Return Choose3(lang, "Semaine", "Week", "Semana")
            Case "stTermine" : Return Choose3(lang, "Terminé", "Completed", "Terminado")
            Case "stEnCours" : Return Choose3(lang, "En cours", "In progress", "En curso")
            Case "stAVenir" : Return Choose3(lang, "À venir", "Upcoming", "Próximo")
            Case "iHeure" : Return Choose3(lang, "Heure et temps", "Time and duration", "Hora y duración")
            Case "iEmploye" : Return Choose3(lang, "Employé", "Employee", "Empleado")
            Case "iType" : Return Choose3(lang, "Service", "Service", "Servicio")
            Case "iLieu" : Return Choose3(lang, "Lieu", "Location", "Lugar")
            Case "ouvrirRdv" : Return Choose3(lang, "Ouvrir le rendez-vous", "Open the appointment", "Abrir la cita")

            ' Activités
            Case "activites" : Return Choose3(lang, "Activités à faire", "Activities to do", "Actividades por hacer")
            Case "lRouge" : Return Choose3(lang, "Rouge : date dépassée, à faire obligatoirement", "Red: date passed, must be done", "Rojo: fecha vencida, obligatorio")
            Case "lJaune" : Return Choose3(lang, "Jaune : la date d'action approche", "Yellow: action date is near", "Amarillo: la fecha de acción se acerca")
            Case "lNoir" : Return Choose3(lang, "Noir : fait automatiquement par 60", "Black: done automatically by 60", "Negro: hecho automáticamente por 60")
            Case "faitPar60" : Return Choose3(lang, "Fait par 60", "Done by 60", "Hecho por 60")
            Case "toutFait" : Return Choose3(lang, "Tout est fait pour aujourd'hui. Bravo!", "Everything is done for today. Well done!", "Todo está hecho por hoy. ¡Bravo!")
            Case "tous" : Return Choose3(lang, "Tout voir", "See all", "Ver todo")
            Case "choses1" : Return Choose3(lang, "1 chose à regarder", "1 thing to look at", "1 cosa que mirar")
            Case "chosesN" : Return Choose3(lang, "{0} choses à regarder", "{0} things to look at", "{0} cosas que mirar")
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
            Case "btnVoir" : Return Choose3(lang, "Voir", "View", "Ver")
            Case "btnPreparer" : Return Choose3(lang, "Préparer le paiement", "Prepare the payment", "Preparar el pago")
            Case "btnApprouver" : Return Choose3(lang, "Voir et approuver", "See and approve", "Ver y aprobar")
            Case "btnBrancher" : Return Choose3(lang, "Brancher ma banque", "Connect my bank", "Conectar mi banco")
            Case "btnForfait" : Return Choose3(lang, "Choisir mon forfait", "Choose my plan", "Elegir mi plan")

            ' La tuile noire (mêmes mots que le menu)
            Case "dashboard" : Return Choose3(lang, "Tableau de bord", "Dashboard", "Panel de control")
            Case "sales" : Return Choose3(lang, "Ventes", "Sales", "Ventas")
            Case "purchases" : Return Choose3(lang, "Achats", "Purchases", "Compras")
            Case "payments" : Return Choose3(lang, "Paiements", "Payments", "Pagos")
            Case "reports" : Return Choose3(lang, "Rapports", "Reports", "Informes")
            Case "employees" : Return Choose3(lang, "Employés", "Employees", "Empleados")
            Case "accounting" : Return Choose3(lang, "Comptabilité", "Accounting", "Contabilidad")
            Case "products" : Return Choose3(lang, "Produits et services", "Products and services", "Productos y servicios")
            Case "approvals" : Return Choose3(lang, "Tâches à approuver", "Tasks to approve", "Tareas por aprobar")
            Case "myFirm" : Return Choose3(lang, "Mon cabinet comptable", "My accounting firm", "Mi despacho contable")
            Case "settings" : Return Choose3(lang, "Paramètres", "Settings", "Ajustes")
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
