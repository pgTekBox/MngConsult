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
        ' ---------- Les données ----------
        Dim ventes As DataTable = Table("s0026GetCustomersInvoices")
        Dim achats As DataTable = Table("s0023GetSuppliersInvoices")
        Dim comptes As DataTable = ComptesBancaires()
        Dim nbApprob As Integer = CompterApprobations()

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
                              L("catAchats") & " · " & Noms(retardsAchats) & " · " & Montant(payRetard),
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

        Dim prenom As String = ""
        Try : prenom = UserFirstName : Catch : End Try

        Return New With {
            .prenom = prenom,
            .lang = CurrentLang,
            .banque = New With {.aCompte = aCompte, .lib = libCompte, .solde = If(aCompte, Montant(encaisse), ""), .maj = majCompte},
            .entete = entete,
            .demandes = CompterDemandesRdv(),
            .activites = acts,
            .agenda = BatirAgenda(),
            .t = Textes()
        }
    End Function

    Private Function Activite(u As String, titre As String, sous As String, detail As String, bouton As String, url As String) As Object
        Return New With {.u = u, .t = titre, .d = sous, .det = detail, .btn = bouton, .url = url}
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
                    rdv.Add(New With {
                        .id = Convert.ToInt32(r("Id")),
                        .jour = debut.ToString("yyyy-MM-dd"),
                        .deb = debut.Hour * 60 + debut.Minute,
                        .fin = If(fin.Date > debut.Date, 24 * 60, fin.Hour * 60 + fin.Minute),
                        .h = Heure(debut),
                        .plage = Heure(debut) & " – " & Heure(fin),
                        .duree = Duree(fin - debut),
                        .client = If(client = "", titre, client),
                        .court = If(client = "", Txt(r("TypeName")), titre),
                        .cli = If(IsDBNull(r("CustomerId")), "", Convert.ToString(r("CustomerId"))),
                        .desc = Txt(r("Description")),
                        .lieu = Txt(r("Location")),
                        .typ = Txt(r("TypeName")),
                        .emp = empId,
                        .empNom = Txt(r("EmployeeName")),
                        .ini = Initiales(Txt(r("EmployeeName"))),
                        .c = If(empId <> "" AndAlso couleurs.ContainsKey(CInt(empId)), couleurs(CInt(empId)), "#1B4F9C"),
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
            "activiteAFaire", "indR", "indY", "messages", "msgAria", "rdvDemande", "rdvDemandeTip",
            "compteOp", "voirMontant", "masquerMontant", "brancher",
            "agenda", "agendaAria", "agendaTip", "agendaDe", "equipeN",
            "plagesLibres", "plagesAria", "plagesVide", "plageTip", "agAuj", "agAujAbr", "agRdvH", "agEmployes",
            "agVide", "libre", "stTermine", "stEnCours", "stAVenir",
            "facturer", "facturerAria", "plusRdv", "nouveauRdvAvec", "voirDetail",
            "iHeure", "iEmploye", "iType", "iLieu", "ouvrirRdv", "winRdv",
            "aVenir", "aVenirPlanif", "toutEquipe", "pSem", "pProch", "pMois", "pMoisP", "periode", "avVide",
            "replier", "deplier",
            "activites", "lRouge", "lJaune", "dateDepassee", "propose60", "a60Ici", "a60Choisir", "merci60", "conseil60",
            "toutFait", "tous", "segR", "segY"
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
            Case "msgAria" : Return Choose3(lang, "Ouvrir le centre de messages", "Open the message center", "Abrir el centro de mensajes")
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

            ' Agenda
            Case "agenda" : Return Choose3(lang, "Agenda", "Calendar", "Agenda")
            Case "agendaAria" : Return Choose3(lang, "Ouvrir l'agenda complet", "Open the full calendar", "Abrir la agenda completa")
            Case "agendaTip" : Return Choose3(lang, "Voir et mettre à jour tout l'agenda", "See and update the whole calendar", "Ver y actualizar toda la agenda")
            Case "agendaDe" : Return Choose3(lang, "Agenda de", "Calendar of", "Agenda de")
            Case "equipeN" : Return Choose3(lang, "Toute l'équipe ({0})", "Whole team ({0})", "Todo el equipo ({0})")
            Case "plagesLibres" : Return Choose3(lang, "Plages libres de l'agenda", "Free slots", "Huecos libres de la agenda")
            Case "plagesAria" : Return Choose3(lang, "3 prochaines plages libres", "Next 3 free slots", "3 próximos huecos libres")
            Case "plagesVide" : Return Choose3(lang, "aucune dans les deux prochaines semaines", "none in the next two weeks", "ninguno en las dos próximas semanas")
            Case "plageTip" : Return Choose3(lang, "Libre {0} de {1} à {2} — cliquez pour réserver", "Free {0} from {1} to {2} — click to book", "Libre {0} de {1} a {2} — haga clic para reservar")
            Case "agAuj" : Return Choose3(lang, "Aujourd'hui", "Today", "Hoy")
            Case "agAujAbr" : Return Choose3(lang, "Auj.", "Today", "Hoy")
            Case "agRdvH" : Return Choose3(lang, "{0} RDV · {1} h", "{0} appt · {1} h", "{0} citas · {1} h")
            Case "agEmployes" : Return Choose3(lang, "{0} employés", "{0} employees", "{0} empleados")
            Case "agVide" : Return Choose3(lang, "Aucun RDV : journée libre.", "No appointment: free day.", "Ninguna cita: día libre.")
            Case "libre" : Return Choose3(lang, "Libre", "Free", "Libre")
            Case "stTermine" : Return Choose3(lang, "Terminé", "Completed", "Terminado")
            Case "stEnCours" : Return Choose3(lang, "En cours", "In progress", "En curso")
            Case "stAVenir" : Return Choose3(lang, "À venir", "Upcoming", "Próximo")
            Case "facturer" : Return Choose3(lang, "Facturer", "Invoice", "Facturar")
            Case "facturerAria" : Return Choose3(lang, "Facturer {0}", "Invoice {0}", "Facturar a {0}")
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
