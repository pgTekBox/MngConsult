Imports Telerik.Web.UI
Imports System.Data
Imports System.Data.SqlClient
Imports System.Linq
Imports System.Text

Public Class wbfReleve
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        ApplyLocalization()

        If Not IsPostBack Then
            InitPeriode()
            rlvReleve.Rebind()
        End If
    End Sub

    ' =====================================================================
    ' Période du relevé et conciliation bancaire (script T368, s0983-s0986).
    ' La période (du / au) et le compte vivent en session ; ils bornent la
    ' liste, les indicateurs et la boîte de conciliation.
    ' =====================================================================

    Private Property Du As Date
        Get
            Return If(TypeOf Session("Releve.Du") Is Date, CDate(Session("Releve.Du")), Date.Today.AddDays(1 - Date.Today.Day).AddMonths(-1))
        End Get
        Set(value As Date)
            Session("Releve.Du") = value
        End Set
    End Property

    Private Property Au As Date
        Get
            Return If(TypeOf Session("Releve.Au") Is Date, CDate(Session("Releve.Au")), Date.Today.AddDays(-Date.Today.Day))
        End Get
        Set(value As Date)
            Session("Releve.Au") = value
        End Set
    End Property

    Private Property CompteCourant As String
        Get
            Return If(TryCast(Session("Releve.Compte"), String), "")
        End Get
        Set(value As String)
            Session("Releve.Compte") = value
        End Set
    End Property

    ''' <summary>Message d'une action de conciliation, affiché une fois (ok|… ou err|…).</summary>
    Private MessageConcil As String = ""

    Private Sub InitPeriode()
        ' Les comptes du relevé ; la liste n'apparaît que s'il y en a plusieurs.
        ddlCompte.Items.Clear()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@DateDebut", Date.Today))
            p.Add(New SqlParameter("@DateFin", Date.Today))
            Dim ds As DataSet = ExecuteSQLds("s0983GetConciliation", p)
            For Each r As DataRow In ds.Tables(3).Rows
                ddlCompte.Items.Add(New ListItem(Convert.ToString(r("Nom")), Convert.ToString(r("AccountId"))))
            Next
            If CompteCourant = "" OrElse ddlCompte.Items.FindByValue(CompteCourant) Is Nothing Then
                CompteCourant = Convert.ToString(ds.Tables(0).Rows(0)("CompteBanque"))
            End If
        Catch
        End Try
        ddlCompte.Visible = ddlCompte.Items.Count > 1
        If ddlCompte.Items.FindByValue(CompteCourant) IsNot Nothing Then ddlCompte.SelectedValue = CompteCourant

        ' Période par défaut : le lendemain de la dernière conciliation clôturée jusqu'à la
        ' fin de ce mois-là ; sinon le mois précédent.
        If Not (TypeOf Session("Releve.Du") Is Date) Then
            Dim verrou As Date? = DerniereCloture()
            If verrou.HasValue Then
                Dim d As Date = verrou.Value.AddDays(1)
                Du = d
                Au = Min(New Date(d.Year, d.Month, Date.DaysInMonth(d.Year, d.Month)), Date.Today)
            Else
                Du = Date.Today.AddDays(1 - Date.Today.Day).AddMonths(-1)
                Au = Date.Today.AddDays(-Date.Today.Day)
            End If
        End If
        ' Ouvert depuis l'activité « Faire la conciliation bancaire » du tableau de bord
        ' (ACT_CONCILIATION, T372) : ?du=aaaa-mm-jj&au=aaaa-mm-jj impose la période.
        Dim qDu, qAu As Date
        If Date.TryParseExact(Request.QueryString("du"), "yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture, Globalization.DateTimeStyles.None, qDu) AndAlso
           Date.TryParseExact(Request.QueryString("au"), "yyyy-MM-dd", Globalization.CultureInfo.InvariantCulture, Globalization.DateTimeStyles.None, qAu) AndAlso
           qAu >= qDu Then
            Du = qDu : Au = qAu
        End If
        AfficherPeriode()
    End Sub

    Private Shared Function Min(a As Date, b As Date) As Date
        Return If(a < b, a, b)
    End Function

    Private Sub AfficherPeriode()
        tbDu.Text = Du.ToString("yyyy-MM-dd")
        tbAu.Text = Au.ToString("yyyy-MM-dd")
    End Sub

    Private Function Historique() As DataTable
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@CompteBanque", If(CompteCourant = "", CObj(DBNull.Value), CompteCourant)))
            Return ExecuteSQLds("s0985GetConciliations", p).Tables(0)
        Catch
            Return Nothing
        End Try
    End Function

    Private Function DerniereCloture() As Date?
        Dim h As DataTable = Historique()
        If h Is Nothing OrElse h.Rows.Count = 0 Then Return Nothing
        Return CDate(h.Rows(0)("DateFin"))
    End Function

    Private Sub btnPeriode_Click(sender As Object, e As EventArgs) Handles btnPeriode.Click
        Dim d1, d2 As Date
        If Date.TryParse(tbDu.Text, d1) AndAlso Date.TryParse(tbAu.Text, d2) Then
            If d2 < d1 Then
                MessageConcil = "err|" & L("cErrDates")
            Else
                Du = d1 : Au = d2
            End If
        End If
        If ddlCompte.Visible AndAlso ddlCompte.SelectedValue <> "" Then CompteCourant = ddlCompte.SelectedValue
        AfficherPeriode()
        rlvReleve.Rebind()
    End Sub

    ''' <summary>Les puces de période : mois précédent, ce mois-ci, après la dernière clôture.</summary>
    Private Function PeriodeChips() As String
        Dim sb As New StringBuilder()
        sb.Append("<button type=""button"" class=""fc-chip"" onclick=""fcChip('periode','prec')"">" & Server.HtmlEncode(L("pPrec")) & "</button>")
        sb.Append("<button type=""button"" class=""fc-chip"" onclick=""fcChip('periode','courant')"">" & Server.HtmlEncode(L("pCourant")) & "</button>")
        If DerniereCloture().HasValue Then
            sb.Append("<button type=""button"" class=""fc-chip"" onclick=""fcChip('periode','suite')"">" & Server.HtmlEncode(L("pSuite")) & "</button>")
        End If
        Return sb.ToString()
    End Function

    Private Sub ActionPeriode(valeur As String)
        Dim t As Date = Date.Today
        Select Case valeur
            Case "prec"
                Du = t.AddDays(1 - t.Day).AddMonths(-1) : Au = t.AddDays(-t.Day)
            Case "courant"
                Du = t.AddDays(1 - t.Day) : Au = t
            Case "suite"
                Dim v As Date? = DerniereCloture()
                If v.HasValue Then
                    Dim d As Date = v.Value.AddDays(1)
                    Du = d : Au = Min(New Date(d.Year, d.Month, Date.DaysInMonth(d.Year, d.Month)), t)
                End If
            Case Else
                ' « aaaa-mm-jj_aaaa-mm-jj » : une conciliation de l'historique
                Dim parts As String() = valeur.Split("_"c)
                Dim d1, d2 As Date
                If parts.Length = 2 AndAlso Date.TryParse(parts(0), d1) AndAlso Date.TryParse(parts(1), d2) Then Du = d1 : Au = d2
        End Select
        AfficherPeriode()
    End Sub

    Private Sub ActionConciliation(valeur As String)
        Try
            If valeur = "cloturer" Then
                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", Company))
                p.Add(New SqlParameter("@DateDebut", Du))
                p.Add(New SqlParameter("@DateFin", Au))
                p.Add(New SqlParameter("@CompteBanque", CompteCourant))
                p.Add(New SqlParameter("@UserId", UserId))
                ExecuteSQLds("s0984CloturerConciliation", p)
                MessageConcil = "ok|" & L("cClotureOk")
            ElseIf valeur.StartsWith("rouvrir:") Then
                Dim id As Integer
                If Integer.TryParse(valeur.Substring(8), id) Then
                    Dim p As New Collection
                    p.Add(New SqlParameter("@CompanyGUID", Company))
                    p.Add(New SqlParameter("@Id", id))
                    ExecuteSQLds("s0986RouvrirConciliation", p)
                    MessageConcil = "ok|" & L("cRouvertOk")
                End If
            End If
        Catch ex As Exception
            MessageConcil = "err|" & If(ex.InnerException IsNot Nothing, ex.InnerException.Message, ex.Message)
        End Try
    End Sub

    Private Function FmtM(o As Object) As String
        Return Server.HtmlEncode(FormatMontant(If(o Is Nothing OrElse IsDBNull(o), 0D, Math.Abs(Convert.ToDecimal(o)))))
    End Function

    Private Function FmtJ(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return Server.HtmlEncode(Convert.ToDateTime(o).ToString("d MMM", Globalization.CultureInfo.GetCultureInfo(If(CurrentLang = "en", "en-CA", If(CurrentLang = "es", "es-ES", "fr-CA")))))
    End Function

    Private Function FmtJA(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return Server.HtmlEncode(Convert.ToDateTime(o).ToString("d MMM yyyy", Globalization.CultureInfo.GetCultureInfo(If(CurrentLang = "en", "en-CA", If(CurrentLang = "es", "es-ES", "fr-CA")))))
    End Function

    Private Shared Function Ligne(lib_ As String, montant As String, Optional total As Boolean = False) As String
        Return "<div class=""cb-l" & If(total, " tot", "") & """><span>" & lib_ & "</span><b>" & montant & "</b></div>"
    End Function

    ''' <summary>La boîte de conciliation de la période.</summary>
    Private Sub ChargerConciliation()
        SetLiteral(Me, "litPeriodeChips", PeriodeChips())
        Dim sb As New StringBuilder()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@DateDebut", Du))
            p.Add(New SqlParameter("@DateFin", Au))
            p.Add(New SqlParameter("@CompteBanque", If(CompteCourant = "", CObj(DBNull.Value), CompteCourant)))
            Dim ds As DataSet = ExecuteSQLds("s0983GetConciliation", p)
            Dim r As DataRow = ds.Tables(0).Rows(0)
            If CompteCourant = "" Then CompteCourant = Convert.ToString(r("CompteBanque"))

            Dim ecart As Decimal = Convert.ToDecimal(r("Ecart"))
            Dim conciliee As Boolean = Math.Abs(ecart) < 0.005D
            Dim idClot As Integer = If(IsDBNull(r("ConciliationId")), 0, Convert.ToInt32(r("ConciliationId")))
            Dim verrou As Date? = If(IsDBNull(r("VerrouJusquau")), CType(Nothing, Date?), CDate(r("VerrouJusquau")))
            Dim h As DataTable = Historique()

            sb.Append("<section class=""cb-carte""><div class=""cb-tete""><h2>" & Server.HtmlEncode(L("cTitre")) & "</h2>")
            sb.Append("<span class=""sous"">" & Server.HtmlEncode(String.Format(L("cSous"), FmtJA(r("DateDebut")), FmtJA(r("DateFin")), Convert.ToString(r("NomCompte")), Convert.ToString(r("CompteGL")) & " " & Convert.ToString(r("NomGL")))) & "</span>")
            If idClot > 0 Then
                sb.Append("<span class=""cb-etat close"">" & Server.HtmlEncode(L("cCloturee")) & "</span>")
            ElseIf conciliee Then
                sb.Append("<span class=""cb-etat ok"">" & Server.HtmlEncode(L("cOk")) & "</span>")
            Else
                sb.Append("<span class=""cb-etat ecart"">" & Server.HtmlEncode(L("cEcartEtat")) & "</span>")
            End If
            sb.Append("</div>")

            ' Les deux colonnes : relevé et livres
            sb.Append("<div class=""cb-cols""><div class=""cb-col""><h3>" & Server.HtmlEncode(L("cReleve")) & "</h3>")
            sb.Append(Ligne(Server.HtmlEncode(String.Format(L("cOuverture"), FmtJA(r("DateDebut")))), FmtM(r("SoldeOuverture"))))
            sb.Append(Ligne("+ " & Server.HtmlEncode(String.Format(L("cEntrees"), r("NbMouvements"))), FmtM(r("Entrees"))))
            sb.Append(Ligne("− " & Server.HtmlEncode(L("cSorties")), FmtM(r("Sorties"))))
            sb.Append(Ligne(Server.HtmlEncode(String.Format(L("cFermeture"), FmtJA(r("DateFin")))), FmtM(r("SoldeFermeture")), True))
            sb.Append(Ligne("+ " & Server.HtmlEncode(L("cDepCirc")), FmtM(r("DepotsCirculation"))))
            sb.Append(Ligne("− " & Server.HtmlEncode(L("cPaieCirc")), FmtM(r("PaiementsCirculation"))))
            sb.Append(Ligne(Server.HtmlEncode(L("cBanqueRaj")), FmtM(r("BanqueRajuste")), True))
            sb.Append("</div><div class=""cb-col""><h3>" & Server.HtmlEncode(L("cLivres")) & "</h3>")
            sb.Append(Ligne(Server.HtmlEncode(String.Format(L("cSoldeLivres"), FmtJA(r("DateFin")))), FmtM(r("SoldeLivres"))))
            sb.Append(Ligne("+ " & Server.HtmlEncode(L("cEntNI")), FmtM(r("EntreesNonInscrites"))))
            sb.Append(Ligne("− " & Server.HtmlEncode(L("cSorNI")), FmtM(r("SortiesNonInscrites"))))
            sb.Append(Ligne(Server.HtmlEncode(L("cLivresRaj")), FmtM(r("LivresRajuste")), True))
            sb.Append("</div></div>")

            ' L'écart et le geste de clôture
            sb.Append("<div class=""cb-bas""><span>" & Server.HtmlEncode(L("cEcart")) & "</span><span class=""ecart " & If(conciliee, "zero", "non") & """>" &
                      Server.HtmlEncode(FormatMontant(ecart)) & "</span>")
            If idClot > 0 Then
                Dim estDerniere As Boolean = h IsNot Nothing AndAlso h.Rows.Count > 0 AndAlso Convert.ToInt32(h.Rows(0)("Id")) = idClot
                Dim ligneH As DataRow = If(h Is Nothing, Nothing, h.Select("Id = " & idClot).FirstOrDefault())
                Dim par As String = If(ligneH Is Nothing, "", String.Format(L("cClotureePar"), FmtJA(ligneH("Created")), Convert.ToString(ligneH("Par")).Trim()))
                sb.Append("<span class=""note"">" & Server.HtmlEncode(par) & "</span>")
                If estDerniere Then
                    sb.Append("<button type=""button"" class=""fc-btn"" onclick=""if (confirm(" & JsStr(L("cConfRouvrir")) & ")) { fcChip('concil','rouvrir:" & idClot & "'); }"">" & Server.HtmlEncode(L("cRouvrir")) & "</button>")
                End If
            Else
                Dim raison As String = ""
                If Au > Date.Today Then
                    raison = L("cPasFinie")
                ElseIf verrou.HasValue AndAlso Du <= verrou.Value Then
                    raison = String.Format(L("cChevauche"), FmtJA(verrou.Value))
                ElseIf verrou.HasValue AndAlso Du > verrou.Value.AddDays(1) Then
                    raison = String.Format(L("cTrou"), FmtJA(verrou.Value.AddDays(1)))
                End If
                If raison <> "" Then
                    sb.Append("<span class=""note"">" & Server.HtmlEncode(raison) & "</span>")
                Else
                    sb.Append("<span class=""note"">" & Server.HtmlEncode(If(conciliee, L("cNoteOk"), L("cNoteEcart"))) & "</span>")
                    Dim conf As String = If(conciliee, L("cConfCloturer"), String.Format(L("cConfCloturerEcart"), FormatMontant(ecart)))
                    sb.Append("<button type=""button"" class=""fc-btn primaire"" onclick=""if (confirm(" & JsStr(conf) & ")) { fcChip('concil','cloturer'); }"">" & Server.HtmlEncode(L("cCloturer")) & "</button>")
                End If
            End If
            sb.Append("</div>")

            If MessageConcil <> "" Then
                Dim i As Integer = MessageConcil.IndexOf("|"c)
                sb.Append("<div class=""cb-msg " & MessageConcil.Substring(0, i) & """>" & Server.HtmlEncode(MessageConcil.Substring(i + 1)) & "</div>")
            End If

            ' Ce qui fait l'écart : en circulation, et au relevé mais pas aux livres
            sb.Append("<div class=""cb-listes""><div><h4>" & Server.HtmlEncode(String.Format(L("cListeCirc"), r("NbCirculation"))) & "</h4>")
            sb.Append(ListeItems(ds.Tables(1), "DateReglement", Function(x) (If(Convert.ToString(x("Sens")) = "ENCAISSEMENT", L("lienEnc"), L("lienDec")) & " · " & Convert.ToString(x("Tiers")) & If(Convert.ToString(x("Numeros")) <> "", " · " & Convert.ToString(x("Numeros")), "")), "Montant"))
            sb.Append("</div><div><h4>" & Server.HtmlEncode(String.Format(L("cListeNI"), r("NbNonInscrits"))) & "</h4>")
            sb.Append(ListeItems(ds.Tables(2), "DateMouvement", Function(x) Convert.ToString(x("Description")) & If(Cle(x("Statut")) = "ignore", " (" & L("stIgnored") & ")", ""), "Montant", True))
            sb.Append("</div></div>")

            ' L'historique
            If h IsNot Nothing AndAlso h.Rows.Count > 0 Then
                sb.Append("<div class=""cb-hist""><h4>" & Server.HtmlEncode(L("cHist")) & "</h4>")
                For Each x As DataRow In h.Rows
                    Dim clePeriode As String = CDate(x("DateDebut")).ToString("yyyy-MM-dd") & "_" & CDate(x("DateFin")).ToString("yyyy-MM-dd")
                    sb.Append("<button type=""button"" onclick=""fcChip('periode','" & clePeriode & "')""><span>" & FmtJA(x("DateDebut")) & " – " & FmtJA(x("DateFin")) & "</span>" &
                              "<span>" & Server.HtmlEncode(L("cEcart")) & " " & Server.HtmlEncode(FormatMontant(x("Ecart"))) & "</span>" &
                              "<span>" & Server.HtmlEncode(Convert.ToString(x("Par")).Trim()) & "</span></button>")
                Next
                sb.Append("</div>")
            End If
            sb.Append("</section>")
        Catch ex As Exception
            sb.Clear()
            sb.Append("<section class=""cb-carte""><div class=""cb-msg err"">" & Server.HtmlEncode(If(ex.InnerException IsNot Nothing, ex.InnerException.Message, ex.Message)) & "</div></section>")
        End Try
        SetLiteral(Me, "litConcil", sb.ToString())
    End Sub

    Private Function ListeItems(t As DataTable, colDate As String, libelle As Func(Of DataRow, String), colMontant As String, Optional signe As Boolean = False) As String
        If t Is Nothing OrElse t.Rows.Count = 0 Then Return "<div class=""cb-vide"">" & Server.HtmlEncode(L("cRien")) & "</div>"
        Dim sb As New StringBuilder()
        Dim n As Integer = 0
        For Each x As DataRow In t.Rows
            n += 1
            If n > 8 Then Exit For
            Dim montant As Decimal = Convert.ToDecimal(x(colMontant))
            ' Au relevé (convention Plaid), un montant négatif est une entrée
            Dim txt As String = If(signe, If(montant < 0, "+ ", "− "), "") & FormatMontant(Math.Abs(montant))
            sb.Append("<div class=""cb-it""><span>" & FmtJ(x(colDate)) & "</span><span>" & Server.HtmlEncode(libelle(x)) & "</span><b>" & Server.HtmlEncode(txt) & "</b></div>")
        Next
        If t.Rows.Count > 8 Then sb.Append("<div class=""cb-vide"">" & Server.HtmlEncode(String.Format(L("cAutres"), t.Rows.Count - 8)) & "</div>")
        Return sb.ToString()
    End Function

    Private Shared Function JsStr(s As String) As String
        Return Server_JsEncode(s)
    End Function

    Private Shared Function Server_JsEncode(s As String) As String
        Return System.Web.HttpUtility.HtmlAttributeEncode(System.Web.HttpUtility.JavaScriptStringEncode(s, True))
    End Function

    Private Function DansPeriode(r As DataRow) As Boolean
        If r Is Nothing OrElse IsDBNull(r("DateMouvement")) Then Return False
        Dim d As Date = CDate(r("DateMouvement")).Date
        If d < Du OrElse d > Au Then Return False
        If CompteCourant <> "" AndAlso Convert.ToString(r("CompteBanque")) <> CompteCourant Then Return False
        Return True
    End Function

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal de la page.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        SetLiteral(Me, "litPageSub", L("pageSub"))
        SetLiteral(Me, "litConnectBtn", L("connectBank"))
        SetLiteral(Me, "litRubrique", L("rubrique"))
        SetLiteral(Me, "litComptesBtn", L("comptesBtn"))
        SetLiteral(Me, "litPeriode", L("pTitre"))
        SetLiteral(Me, "litDu", L("pDu"))
        SetLiteral(Me, "litAu", L("pAu"))
        btnPeriode.Text = L("pAppliquer")
        tbSearch.Attributes("placeholder") = L("searchPh")
        btnClear.ToolTip = L("clear")
    End Sub

    ''' <summary>Libellés du LayoutTemplate / EmptyDataTemplate du RadListView (via Literal).</summary>
    Private Sub rlvReleve_PreRender(sender As Object, e As EventArgs) Handles rlvReleve.PreRender
        SetLiteral(rlvReleve, "litColDate", L("colDate"))
        SetLiteral(rlvReleve, "litColDesc", L("colDesc"))
        SetLiteral(rlvReleve, "litColRef", L("colRef"))
        SetLiteral(rlvReleve, "litColStatus", L("colStatus"))
        SetLiteral(rlvReleve, "litColAmount", L("colSorties"))
        SetLiteral(rlvReleve, "litColEntrees", L("colEntrees"))
        SetLiteral(rlvReleve, "litEmpty", L("empty"))
    End Sub

    Private Sub rlvReleve_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvReleve.NeedDataSource
        ChargerIndicateurs()
        ChargerConciliation()
        Dim dt As DataTable = Filtrer(GetData())
        rlvReleve.DataSource = dt
        SetLiteral(Me, "litPied", Server.HtmlEncode(String.Format(L("pied"), If(dt Is Nothing, 0, dt.Rows.Count), TotalMouvements)))
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvReleve.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        FiltreCourant = ""
        rlvReleve.Rebind()
    End Sub

    Private Function GetData() As DataTable
        Dim dt As New DataTable()
        Dim q As String = tbSearch.Text.Trim()

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlClient.SqlParameter("@Search", q))
        dt = ExecuteSQLds("s0047GetReleveBancaire", p).Tables(0)

        'Using cn As New SqlConnection(GetConnectionString())
        '    Using cmd As New SqlCommand("
        '        SELECT
        '            Id,
        '            ReleveBancaireGUID,
        '            CompanyGUID,
        '            DateMouvement,
        '            Description,
        '            Reference,
        '            Montant,
        '            CompteBanque,
        '            Statut,
        '            ReglementId,
        '            Created,
        '            CreatedBy
        '        FROM dbo.T142ReleveBancaire
        '        WHERE CompanyGUID = @CompanyGUID
        '          AND (
        '                @Search = ''
        '                OR Description LIKE '%' + @Search + '%'
        '                OR Reference LIKE '%' + @Search + '%'
        '                OR CompteBanque LIKE '%' + @Search + '%'
        '                OR Statut LIKE '%' + @Search + '%'
        '              )
        '        ORDER BY DateMouvement DESC, Id DESC", cn)

        '        cmd.Parameters.AddWithValue("@CompanyGUID", Company)
        '        cmd.Parameters.AddWithValue("@Search", q)

        '        Using da As New SqlDataAdapter(cmd)
        '            da.Fill(dt)
        '        End Using
        '    End Using
        'End Using

        Return dt
    End Function

    ' =====================================================================
    ' Les indicateurs (mouvements / à apparier / réglés / ignorés), le filtre
    ' qu'ils posent (en session) et les cellules au style du gabarit.
    ' Les décomptes se font sur tout le relevé, sans la recherche.
    ' =====================================================================

    Private Property FiltreCourant As String
        Get
            Return If(TryCast(Session("Releve.Filtre"), String), "")
        End Get
        Set(value As String)
            Session("Releve.Filtre") = value
        End Set
    End Property

    Private TotalMouvements As Integer

    Protected Sub btnChip_Click(sender As Object, e As EventArgs) Handles btnChip.Click
        Dim v As String = If(hfChip.Value, "")
        hfChip.Value = ""
        Dim i As Integer = v.IndexOf("|"c)
        If i < 0 Then Return
        Dim valeur As String = v.Substring(i + 1).Trim().ToLowerInvariant()
        Select Case v.Substring(0, i)
            Case "kpi" : FiltreCourant = If(FiltreCourant = valeur, "", valeur)
            Case "periode" : ActionPeriode(valeur)
            Case "concil" : ActionConciliation(valeur)
        End Select
        rlvReleve.Rebind()
    End Sub

    ''' <summary>Le statut de la base ramené à une clé : apparier (importé, en attente), regle, ignore.</summary>
    Private Shared Function Cle(statut As Object) As String
        If statut Is Nothing OrElse IsDBNull(statut) Then Return "apparier"
        Select Case statut.ToString().Trim().ToLowerInvariant()
            Case "réglé", "reglé", "regle", "payé", "paye", "traité", "traite", "settled", "reconciled", "conciliado", "pagado"
                Return "regle"
            Case "ignoré", "ignore", "ignored", "ignorado"
                Return "ignore"
            Case Else
                Return "apparier"
        End Select
    End Function

    Private Shared Function Nombre(o As Object) As Decimal
        If o Is Nothing OrElse IsDBNull(o) Then Return 0D
        Try
            Return Convert.ToDecimal(o)
        Catch
            Return 0D
        End Try
    End Function

    Private Function LireTout() As List(Of DataRow)
        Try
            Dim p As New Collection
            p.Add(New SqlClient.SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlClient.SqlParameter("@Search", ""))
            Dim ds As DataSet = ExecuteSQLds("s0047GetReleveBancaire", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0).Rows.Cast(Of DataRow)().Where(Function(r) DansPeriode(r)).ToList()
        Catch
        End Try
        Return New List(Of DataRow)
    End Function

    Private Sub ChargerIndicateurs()
        Dim rows As List(Of DataRow) = LireTout()
        TotalMouvements = rows.Count
        Dim aApparier As Integer = rows.Where(Function(r) Cle(r("Statut")) = "apparier").Count()
        Dim regles As Integer = rows.Where(Function(r) Cle(r("Statut")) = "regle").Count()
        Dim ignores As Integer = rows.Where(Function(r) Cle(r("Statut")) = "ignore").Count()
        ' Convention Plaid : un montant positif est une sortie, un négatif une entrée.
        Dim sorties As Decimal = rows.Where(Function(r) Nombre(r("Montant")) > 0D).Sum(Function(r) Nombre(r("Montant")))
        Dim entrees As Decimal = -rows.Where(Function(r) Nombre(r("Montant")) < 0D).Sum(Function(r) Nombre(r("Montant")))

        Dim sb As New StringBuilder()
        sb.Append("<div class=""fc-kpi""><span class=""lab""><i style=""background:#1B4F9C""></i>" & Server.HtmlEncode(L("kpiMouv")) & "</span><span class=""val"">" & rows.Count &
                  "</span><span class=""sub"">" & Server.HtmlEncode(String.Format(L("kpiMouvSub"), FormatMontant(entrees), FormatMontant(sorties))) & "</span></div>")
        sb.Append(Kpi("apparier", L("kpiApparier"), aApparier.ToString(), L("kpiApparierSub"), If(aApparier > 0, "#E3B341", "#43B47A")))
        sb.Append(Kpi("regle", L("kpiRegles"), regles.ToString(), L("kpiReglesSub"), "#43B47A"))
        sb.Append(Kpi("ignore", L("kpiIgnores"), ignores.ToString(), L("kpiIgnoresSub"), "#AEBBCD"))
        SetLiteral(Me, "litKpis", sb.ToString())
    End Sub

    Private Function Kpi(valeur As String, lab As String, val As String, sub_ As String, point As String) As String
        Dim actif As Boolean = (FiltreCourant = valeur)
        Return "<button type=""button"" class=""fc-kpi" & If(actif, " on", "") & """ aria-pressed=""" & If(actif, "true", "false") &
               """ onclick=""fcChip('kpi','" & valeur & "')"">" &
               "<span class=""lab""><i style=""background:" & point & """></i>" & Server.HtmlEncode(lab) & "</span>" &
               "<span class=""val"">" & Server.HtmlEncode(val) & "</span>" &
               "<span class=""sub"">" & Server.HtmlEncode(sub_) & "</span></button>"
    End Function

    Private Function Filtrer(dt As DataTable) As DataTable
        If dt Is Nothing Then Return dt
        Dim copie As DataTable = dt.Clone()
        For Each r As DataRow In dt.Rows
            If DansPeriode(r) AndAlso (FiltreCourant = "" OrElse Cle(r("Statut")) = FiltreCourant) Then copie.ImportRow(r)
        Next
        ' Comme un relevé de banque : du plus ancien au plus récent.
        copie.DefaultView.Sort = "DateMouvement ASC, Id ASC"
        Return copie.DefaultView.ToTable()
    End Function

    ''' <summary>La colonne Sorties : un montant positif (convention Plaid), sans signe.</summary>
    Protected Function MontantSortie(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return ""
        Dim m As Decimal = Convert.ToDecimal(value)
        Return If(m > 0D, FormatMontant(m), "")
    End Function

    ''' <summary>La colonne Entrées : un montant négatif (convention Plaid), sans signe.</summary>
    Protected Function MontantEntree(value As Object) As String
        If value Is Nothing OrElse IsDBNull(value) Then Return ""
        Dim m As Decimal = Convert.ToDecimal(value)
        Return If(m < 0D, FormatMontant(-m), "")
    End Function

    ''' <summary>La description en gras, la référence Plaid dessous.</summary>
    Public Function DescCell(description As Object, reference As Object) As String
        Dim d As String = Convert.ToString(description).Trim()
        Dim r As String = Convert.ToString(reference).Trim()
        Return "<b>" & Server.HtmlEncode(If(d = "", "—", d)) & "</b>" & If(r <> "", "<span>" & Server.HtmlEncode(r) & "</span>", "")
    End Function

    ''' <summary>L'état en pastille colorée : à apparier (ambre), réglé (vert), ignoré (gris).</summary>
    Public Function StatutPill(statut As Object) As String
        Dim libelle As String = LocalizeStatut(statut)
        If libelle = "" Then libelle = L("stImported")
        Select Case Cle(statut)
            Case "regle" : Return "<span class=""fc-pay"" style=""background:#E3F3EA;color:#0F5A3A"">" & Server.HtmlEncode(libelle) & "</span>"
            Case "ignore" : Return "<span class=""fc-pay"" style=""background:#F2F5F9;color:#5B6B86"">" & Server.HtmlEncode(libelle) & "</span>"
            Case Else : Return "<span class=""fc-pay"" style=""background:#FBF1DC;color:#7A5200"">" & Server.HtmlEncode(libelle) & "</span>"
        End Select
    End Function

    ''' <summary>L'état, et dessous le règlement relié (« Dépôt · Samuel Cloutier · FCD-0030 »).</summary>
    ''' <summary>L'état, et dessous les pièces reliées (« Encaissement · Samuel Cloutier · FCD-0030 »,
    ''' « Écriture REL-8879-1 · 4000 Ventes ») ; une ligne partielle dit aussi ce qui reste.</summary>
    Public Function StatutCell(statut As Object, info As Object, montant As Object, relie As Object) As String
        Dim html As String = StatutPill(statut)
        Dim s As String = Convert.ToString(info)
        If s <> "" Then
            Dim pieces As New List(Of String)
            For Each piece As String In s.Split(New String() {" | "}, StringSplitOptions.RemoveEmptyEntries)
                Dim p As String() = piece.Split("~"c)
                If p.Length < 3 Then Continue For
                Dim morceaux As New List(Of String)
                Select Case p(0)
                    Case "ENC" : morceaux.Add(L("lienEnc"))
                    Case "DEC" : morceaux.Add(L("lienDec"))
                    Case Else : morceaux.Add(L("lienEcr") & If(p(1).Trim() <> "", " " & p(1).Trim(), ""))
                End Select
                If p(0) <> "ECR" AndAlso p(1).Trim() <> "" Then morceaux.Add(p(1).Trim())
                If p(2).Trim() <> "" Then morceaux.Add(p(2).Trim())
                pieces.Add(String.Join(" · ", morceaux))
            Next
            For Each piece As String In pieces
                html &= "<span class=""rb-lien"">" & Server.HtmlEncode(piece) & "</span>"
            Next
        End If
        Dim reste As Decimal = Math.Abs(Nombre(montant)) - Nombre(relie)
        If Nombre(relie) > 0D AndAlso reste > 0.005D Then
            html &= "<span class=""rb-lien rb-reste"">" & Server.HtmlEncode(String.Format(L("resteARelier"), FormatMontant(reste))) & "</span>"
        End If
        Return html
    End Function

    ''' <summary>Les gestes d'une ligne : Relier + Ignorer ; Délier quand elle a des pièces
    ''' (et Relier tant qu'il reste un montant) ; Rétablir quand elle est ignorée.</summary>
    Public Function ActionsCell(id As Object, statut As Object, nbLiens As Object, montant As Object, relie As Object) As String
        Dim n As String = Convert.ToInt32(id).ToString()
        Dim aDesLiens As Boolean = Nombre(nbLiens) > 0D
        If aDesLiens Then
            Dim reste As Decimal = Math.Abs(Nombre(montant)) - Nombre(relie)
            Return If(reste > 0.005D, "<button type=""button"" class=""rb-act primaire"" onclick=""rbRelier(" & n & ")"">" & Server.HtmlEncode(L("aRelier")) & "</button>", "") &
                   "<button type=""button"" class=""rb-act"" onclick=""rbAction('delier'," & n & ")"">" & Server.HtmlEncode(L("aDelier")) & "</button>"
        End If
        If Cle(statut) = "ignore" Then
            Return "<button type=""button"" class=""rb-act"" onclick=""rbAction('retablir'," & n & ")"">" & Server.HtmlEncode(L("aRetablir")) & "</button>"
        End If
        Return "<button type=""button"" class=""rb-act primaire"" onclick=""rbRelier(" & n & ")"">" & Server.HtmlEncode(L("aRelier")) & "</button>" &
               "<button type=""button"" class=""rb-act"" onclick=""rbAction('ignorer'," & n & ")"">" & Server.HtmlEncode(L("aIgnorer")) & "</button>"
    End Function

    ''' <summary>Les libellés de la fenêtre « Relier », en JSON pour le script.</summary>
    Protected Function LibellesRelier() As String
        Dim cles As String() = {"mTitre", "mDepot", "mSortie", "mRegs", "mRegsVide", "mFactsCli", "mFactsFour", "mFactsVide",
                                "mProbable", "mRelier", "mEncaisser", "mPayer", "mFermer", "mEchue", "mReste", "mErreur",
                                "mConfDelier", "mRegleOk", "mPartiel", "mChargement",
                                "mLigneMontant", "mDejaRelie", "mResteARelier", "mRetirer", "mConfRetirer", "mTropGrand",
                                "mInscrire", "mInscrireAide", "mCompte", "mChoisirCompte", "mLibelle", "mMontant", "mInscrireBtn",
                                "mToutRelie", "mVerrou", "mSuggere", "mDepasse"}
        Dim d As New Dictionary(Of String, String)
        For Each c As String In cles
            d(c) = L(c)
        Next
        Return New System.Web.Script.Serialization.JavaScriptSerializer().Serialize(d)
    End Function

    Protected Function FormatDateOnly(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return ""
        Return Convert.ToDateTime(value).ToString("d MMM yyyy").ToLower()
    End Function

    Protected Function FormatMontant(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return "0.00 $"
        Dim m As Decimal = Convert.ToDecimal(value)
        Return m.ToString("#,##0.00 $")
    End Function

    Protected Function GetMontantCss(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return ""
        Dim m As Decimal = Convert.ToDecimal(value)

        If m < 0D Then
            Return "entree"
        ElseIf m > 0D Then
            Return "sortie"
        End If

        Return ""
    End Function

    Protected Function GetStatutCss(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then
            Return "badge-statut"
        End If

        Dim s As String = value.ToString().Trim().ToLower()

        Select Case s
            Case "réglé", "reglé", "regle", "payé", "paye", "traité", "traite"
                Return "badge-statut regle"

            Case "en attente", "attente", "a traiter", "à traiter"
                Return "badge-statut enattente"

            Case "ignoré", "ignore"
                Return "badge-statut ignore"

            Case Else
                Return "badge-statut"
        End Select
    End Function

    Private Function GetConnectionString() As String
        Return ConnectionString
    End Function

    ''' <summary>
    ''' Traduit l'AFFICHAGE d'un statut (la valeur reste stockée telle quelle en base).
    ''' Normalise la valeur DB puis renvoie le libellé dans la langue courante ;
    ''' un statut inconnu est renvoyé tel quel.
    ''' </summary>
    Protected Function LocalizeStatut(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return ""
        Dim raw As String = value.ToString().Trim()
        Dim s As String = raw.ToLowerInvariant()

        Select Case s
            Case "importé", "importe", "imported", "importado"
                Return L("stImported")
            Case "réglé", "reglé", "regle", "payé", "paye", "traité", "traite", "settled", "reconciled", "conciliado", "pagado"
                Return L("stSettled")
            Case "partiel", "partial", "parcial"
                Return L("stPartial")
            Case "en attente", "attente", "a traiter", "à traiter", "pending", "pendiente"
                Return L("stPending")
            Case "ignoré", "ignore", "ignored", "ignorado"
                Return L("stIgnored")
            Case Else
                Return raw
        End Select
    End Function

    ''' <summary>Traductions de l'interface Relevé bancaire (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Relevé bancaire — 60Sec-AI", "Bank statement — 60Sec-AI", "Estado de cuenta — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Relevé bancaire", "Bank statement", "Estado de cuenta")
            Case "pageSub" : Return Choose3(lang, "Les mouvements de vos comptes connectés, et ce qui reste à apparier.", "The movements of your connected accounts, and what is still to match.", "Los movimientos de sus cuentas conectadas, y lo que queda por conciliar.")
            Case "connectBank" : Return Choose3(lang, "Connecter une banque", "Connect a bank", "Conectar un banco")
            Case "searchPh" : Return Choose3(lang, "Chercher une description, une référence ou un compte", "Search a description, a reference or an account", "Buscar una descripción, una referencia o una cuenta")
            Case "clear" : Return Choose3(lang, "Effacer", "Clear", "Borrar")
            Case "colDate" : Return Choose3(lang, "Date", "Date", "Fecha")
            Case "colDesc" : Return Choose3(lang, "Description", "Description", "Descripción")
            Case "colRef" : Return Choose3(lang, "Compte", "Account", "Cuenta")
            Case "colStatus" : Return Choose3(lang, "Statut", "Status", "Estado")
            Case "colAmount" : Return Choose3(lang, "Montant", "Amount", "Importe")
            Case "empty" : Return Choose3(lang, "Aucun mouvement ne correspond.", "No movement matches.", "Ningún movimiento coincide.")
            Case "rubrique" : Return Choose3(lang, "Comptabilité", "Accounting", "Contabilidad")
            Case "comptesBtn" : Return Choose3(lang, "Comptes bancaires", "Bank accounts", "Cuentas bancarias")
            Case "kpiMouv" : Return Choose3(lang, "Mouvements", "Movements", "Movimientos")
            Case "kpiMouvSub" : Return Choose3(lang, "entrées {0} · sorties {1}", "in {0} · out {1}", "entradas {0} · salidas {1}")
            Case "kpiApparier" : Return Choose3(lang, "À apparier", "To match", "Por conciliar")
            Case "kpiApparierSub" : Return Choose3(lang, "importés ou en attente", "imported or pending", "importados o pendientes")
            Case "kpiRegles" : Return Choose3(lang, "Réglés", "Settled", "Conciliados")
            Case "kpiReglesSub" : Return Choose3(lang, "reliés à un règlement", "linked to a payment", "vinculados a un pago")
            Case "kpiIgnores" : Return Choose3(lang, "Ignorés", "Ignored", "Ignorados")
            Case "kpiIgnoresSub" : Return Choose3(lang, "laissés de côté", "set aside", "dejados de lado")
            Case "pied" : Return Choose3(lang, "{0} sur {1} mouvements", "{0} of {1} movements", "{0} de {1} movimientos")
            Case "stImported" : Return Choose3(lang, "Importé", "Imported", "Importado")
            Case "stSettled" : Return Choose3(lang, "Réglé", "Settled", "Conciliado")
            Case "stPending" : Return Choose3(lang, "En attente", "Pending", "Pendiente")
            Case "stIgnored" : Return Choose3(lang, "Ignoré", "Ignored", "Ignorado")
            Case "mRef" : Return Choose3(lang, "Référence : ", "Reference: ", "Referencia: ")
            Case "mAccount" : Return Choose3(lang, "Compte : ", "Account: ", "Cuenta: ")
            Case "jsExchangeError" : Return Choose3(lang, "Erreur lors de l'échange du token.", "Error while exchanging the token.", "Error al intercambiar el token.")
            Case "jsConnected" : Return Choose3(lang, "Compte bancaire connecté avec succès.", "Bank account connected successfully.", "Cuenta bancaria conectada con éxito.")
            Case "jsLinkTokenError" : Return Choose3(lang, "Erreur lors de la création du link token.", "Error while creating the link token.", "Error al crear el link token.")
            Case "jsPlaidError" : Return Choose3(lang, "Erreur Plaid.", "Plaid error.", "Error de Plaid.")
            Case "colSorties" : Return Choose3(lang, "Sorties", "Withdrawals", "Salidas")
            Case "colEntrees" : Return Choose3(lang, "Entrées", "Deposits", "Entradas")
            ' Période et conciliation (T368)
            Case "pTitre" : Return Choose3(lang, "Période du relevé", "Statement period", "Período del extracto")
            Case "pDu" : Return Choose3(lang, "Du", "From", "Del")
            Case "pAu" : Return Choose3(lang, "au", "to", "al")
            Case "pAppliquer" : Return Choose3(lang, "Appliquer", "Apply", "Aplicar")
            Case "pPrec" : Return Choose3(lang, "Mois précédent", "Previous month", "Mes anterior")
            Case "pCourant" : Return Choose3(lang, "Ce mois-ci", "This month", "Este mes")
            Case "pSuite" : Return Choose3(lang, "Après la dernière conciliation", "After the last reconciliation", "Tras la última conciliación")
            Case "cErrDates" : Return Choose3(lang, "La date de fin précède la date de début.", "The end date is before the start date.", "La fecha de fin es anterior a la de inicio.")
            Case "cClotureOk" : Return Choose3(lang, "Conciliation clôturée. Les lignes de la période sont verrouillées.", "Reconciliation closed. The period's lines are locked.", "Conciliación cerrada. Las líneas del período quedan bloqueadas.")
            Case "cRouvertOk" : Return Choose3(lang, "Conciliation rouverte. Les lignes de la période peuvent de nouveau être modifiées.", "Reconciliation reopened. The period's lines can be changed again.", "Conciliación reabierta. Las líneas del período pueden modificarse de nuevo.")
            Case "cTitre" : Return Choose3(lang, "Conciliation bancaire", "Bank reconciliation", "Conciliación bancaria")
            Case "cSous" : Return Choose3(lang, "du {0} au {1} · {2} ↔ {3}", "{0} to {1} · {2} ↔ {3}", "del {0} al {1} · {2} ↔ {3}")
            Case "cCloturee" : Return Choose3(lang, "Clôturée", "Closed", "Cerrada")
            Case "cOk" : Return Choose3(lang, "Conciliée", "Reconciled", "Conciliada")
            Case "cEcartEtat" : Return Choose3(lang, "Écart à expliquer", "Difference to explain", "Diferencia por explicar")
            Case "cReleve" : Return Choose3(lang, "Relevé de la banque", "Bank statement", "Extracto del banco")
            Case "cOuverture" : Return Choose3(lang, "Solde d'ouverture ({0})", "Opening balance ({0})", "Saldo inicial ({0})")
            Case "cEntrees" : Return Choose3(lang, "Entrées de la période", "Period deposits", "Entradas del período")
            Case "cSorties" : Return Choose3(lang, "Sorties de la période", "Period withdrawals", "Salidas del período")
            Case "cFermeture" : Return Choose3(lang, "Solde de fermeture ({0})", "Closing balance ({0})", "Saldo final ({0})")
            Case "cDepCirc" : Return Choose3(lang, "Dépôts en circulation", "Deposits in transit", "Depósitos en tránsito")
            Case "cPaieCirc" : Return Choose3(lang, "Paiements en circulation", "Outstanding payments", "Pagos en tránsito")
            Case "cBanqueRaj" : Return Choose3(lang, "Solde bancaire rajusté", "Adjusted bank balance", "Saldo bancario ajustado")
            Case "cLivres" : Return Choose3(lang, "Livres comptables", "Books", "Libros contables")
            Case "cSoldeLivres" : Return Choose3(lang, "Solde aux livres ({0})", "Book balance ({0})", "Saldo en libros ({0})")
            Case "cEntNI" : Return Choose3(lang, "Entrées du relevé non inscrites", "Statement deposits not recorded", "Entradas del extracto no registradas")
            Case "cSorNI" : Return Choose3(lang, "Sorties du relevé non inscrites", "Statement withdrawals not recorded", "Salidas del extracto no registradas")
            Case "cLivresRaj" : Return Choose3(lang, "Solde aux livres rajusté", "Adjusted book balance", "Saldo en libros ajustado")
            Case "cEcart" : Return Choose3(lang, "Écart", "Difference", "Diferencia")
            Case "cClotureePar" : Return Choose3(lang, "Clôturée le {0} par {1}.", "Closed on {0} by {1}.", "Cerrada el {0} por {1}.")
            Case "cConfRouvrir" : Return Choose3(lang, "Rouvrir cette conciliation ? Les lignes de la période pourront de nouveau être modifiées.", "Reopen this reconciliation? The period's lines can be changed again.", "¿Reabrir esta conciliación? Las líneas del período podrán modificarse de nuevo.")
            Case "cRouvrir" : Return Choose3(lang, "Rouvrir", "Reopen", "Reabrir")
            Case "cPasFinie" : Return Choose3(lang, "La période n'est pas terminée : elle se clôture une fois la date de fin passée.", "The period is not over: it can be closed once the end date has passed.", "El período no ha terminado: se cierra una vez pasada la fecha de fin.")
            Case "cChevauche" : Return Choose3(lang, "Cette période chevauche la conciliation clôturée jusqu'au {0}.", "This period overlaps the reconciliation closed up to {0}.", "Este período se solapa con la conciliación cerrada hasta el {0}.")
            Case "cTrou" : Return Choose3(lang, "Pour clôturer, la période doit commencer le {0}, lendemain de la dernière conciliation clôturée.", "To close, the period must start on {0}, the day after the last closed reconciliation.", "Para cerrar, el período debe empezar el {0}, día siguiente a la última conciliación cerrada.")
            Case "cNoteOk" : Return Choose3(lang, "Le relevé et les livres concordent.", "The statement and the books agree.", "El extracto y los libros coinciden.")
            Case "cNoteEcart" : Return Choose3(lang, "Reliez les lignes à leurs règlements ou inscrivez les mouvements manquants pour ramener l'écart à zéro.", "Link the lines to their payments or record the missing movements to bring the difference to zero.", "Vincule las líneas a sus pagos o registre los movimientos que faltan para llevar la diferencia a cero.")
            Case "cConfCloturer" : Return Choose3(lang, "Clôturer la conciliation de cette période ? Ses lignes seront verrouillées.", "Close this period's reconciliation? Its lines will be locked.", "¿Cerrar la conciliación de este período? Sus líneas quedarán bloqueadas.")
            Case "cConfCloturerEcart" : Return Choose3(lang, "Il reste un écart de {0}. Clôturer quand même ? Les lignes de la période seront verrouillées.", "A difference of {0} remains. Close anyway? The period's lines will be locked.", "Queda una diferencia de {0}. ¿Cerrar de todos modos? Las líneas del período quedarán bloqueadas.")
            Case "cCloturer" : Return Choose3(lang, "Clôturer la conciliation", "Close the reconciliation", "Cerrar la conciliación")
            Case "cListeCirc" : Return Choose3(lang, "En circulation : aux livres, pas encore au relevé ({0})", "In transit: in the books, not yet on the statement ({0})", "En tránsito: en libros, aún no en el extracto ({0})")
            Case "cListeNI" : Return Choose3(lang, "Au relevé, pas aux livres ({0})", "On the statement, not in the books ({0})", "En el extracto, no en libros ({0})")
            Case "cHist" : Return Choose3(lang, "Conciliations clôturées", "Closed reconciliations", "Conciliaciones cerradas")
            Case "cRien" : Return Choose3(lang, "Rien.", "None.", "Nada.")
            Case "cAutres" : Return Choose3(lang, "+ {0} autres", "+ {0} more", "+ {0} más")
            ' Rapprochement (T367)
            ' Liens multiples et inscription aux livres (T370)
            Case "lienEcr" : Return Choose3(lang, "Écriture", "Entry", "Asiento")
            Case "resteARelier" : Return Choose3(lang, "Reste à relier : {0}", "Left to link: {0}", "Queda por vincular: {0}")
            Case "stPartial" : Return Choose3(lang, "Partiel", "Partial", "Parcial")
            Case "mLigneMontant" : Return Choose3(lang, "Montant de la ligne", "Line amount", "Importe de la línea")
            Case "mDejaRelie" : Return Choose3(lang, "Déjà relié", "Already linked", "Ya vinculado")
            Case "mResteARelier" : Return Choose3(lang, "Reste à relier", "Left to link", "Queda por vincular")
            Case "mRetirer" : Return Choose3(lang, "Retirer", "Remove", "Quitar")
            Case "mConfRetirer" : Return Choose3(lang, "Retirer cette pièce de la ligne ? Elle reste enregistrée dans les livres.", "Remove this item from the line? It stays recorded in the books.", "¿Quitar esta partida de la línea? Sigue registrada en los libros.")
            Case "mTropGrand" : Return Choose3(lang, "Plus grand que le reste à relier", "Larger than what is left to link", "Mayor que lo que queda por vincular")
            Case "mInscrire" : Return Choose3(lang, "Inscrire aux livres", "Record in the books", "Registrar en los libros")
            Case "mInscrireAide" : Return Choose3(lang, "Pour ce qui ne correspond à aucune facture (vente au comptoir, frais bancaires, loyer, paie…) : une écriture au journal de banque, à la date du relevé, contre le compte choisi.", "For what matches no invoice (counter sale, bank fees, rent, payroll…): an entry in the bank journal, on the statement date, against the chosen account.", "Para lo que no corresponde a ninguna factura (venta en mostrador, cargos bancarios, alquiler, nómina…): un asiento en el diario de banco, en la fecha del extracto, contra la cuenta elegida.")
            Case "mCompte" : Return Choose3(lang, "Compte", "Account", "Cuenta")
            Case "mChoisirCompte" : Return Choose3(lang, "— Choisir un compte —", "— Choose an account —", "— Elegir una cuenta —")
            Case "mLibelle" : Return Choose3(lang, "Libellé", "Description", "Concepto")
            Case "mMontant" : Return Choose3(lang, "Montant", "Amount", "Importe")
            Case "mInscrireBtn" : Return Choose3(lang, "Inscrire et relier", "Record and link", "Registrar y vincular")
            Case "mToutRelie" : Return Choose3(lang, "La ligne est entièrement reliée.", "The line is fully linked.", "La línea está totalmente vinculada.")
            Case "mVerrou" : Return Choose3(lang, "Cette ligne fait partie d'une conciliation clôturée : elle ne peut plus être modifiée.", "This line belongs to a closed reconciliation: it can no longer be changed.", "Esta línea pertenece a una conciliación cerrada: ya no puede modificarse.")
            Case "mSuggere" : Return Choose3(lang, "déjà utilisé pour ce genre de ligne", "already used for this kind of line", "ya usado para este tipo de línea")
            Case "mDepasse" : Return Choose3(lang, "Le montant dépasse le reste à relier.", "The amount exceeds what is left to link.", "El importe supera lo que queda por vincular.")
            Case "lienEnc" : Return Choose3(lang, "Encaissement", "Receipt", "Cobro")
            Case "lienDec" : Return Choose3(lang, "Paiement", "Payment", "Pago")
            Case "aRelier" : Return Choose3(lang, "Relier", "Link", "Vincular")
            Case "aIgnorer" : Return Choose3(lang, "Ignorer", "Ignore", "Ignorar")
            Case "aDelier" : Return Choose3(lang, "Délier", "Unlink", "Desvincular")
            Case "aRetablir" : Return Choose3(lang, "Rétablir", "Restore", "Restablecer")
            Case "mTitre" : Return Choose3(lang, "Relier la ligne du relevé", "Link the statement line", "Vincular la línea del estado")
            Case "mDepot" : Return Choose3(lang, "Dépôt", "Deposit", "Depósito")
            Case "mSortie" : Return Choose3(lang, "Sortie", "Withdrawal", "Salida")
            Case "mRegs" : Return Choose3(lang, "Un règlement déjà saisi", "A payment already entered", "Un pago ya registrado")
            Case "mRegsVide" : Return Choose3(lang, "Aucun règlement libre dans ce sens.", "No free payment in this direction.", "Ningún pago libre en este sentido.")
            Case "mFactsCli" : Return Choose3(lang, "Une facture client encore ouverte", "A customer invoice still open", "Una factura de cliente aún abierta")
            Case "mFactsFour" : Return Choose3(lang, "Une facture fournisseur encore ouverte", "A supplier invoice still open", "Una factura de proveedor aún abierta")
            Case "mFactsVide" : Return Choose3(lang, "Aucune facture ouverte.", "No open invoice.", "Ninguna factura abierta.")
            Case "mProbable" : Return Choose3(lang, "Probable", "Likely", "Probable")
            Case "mRelier" : Return Choose3(lang, "Relier", "Link", "Vincular")
            Case "mEncaisser" : Return Choose3(lang, "Encaisser et relier", "Receive and link", "Cobrar y vincular")
            Case "mPayer" : Return Choose3(lang, "Payer et relier", "Pay and link", "Pagar y vincular")
            Case "mFermer" : Return Choose3(lang, "Fermer", "Close", "Cerrar")
            Case "mEchue" : Return Choose3(lang, "échéance", "due", "vencimiento")
            Case "mReste" : Return Choose3(lang, "reste", "balance", "saldo")
            Case "mErreur" : Return Choose3(lang, "Erreur", "Error", "Error")
            Case "mConfDelier" : Return Choose3(lang, "Délier cette ligne ? Le règlement reste enregistré dans les livres.", "Unlink this line? The payment stays recorded in the books.", "¿Desvincular esta línea? El pago sigue registrado en los libros.")
            Case "mRegleOk" : Return Choose3(lang, "Règlement enregistré et relié : {0}", "Payment recorded and linked: {0}", "Pago registrado y vinculado: {0}")
            Case "mPartiel" : Return Choose3(lang, "Il reste {0} à payer sur la facture.", "{0} is still owed on the invoice.", "Quedan {0} por pagar en la factura.")
            Case "mChargement" : Return Choose3(lang, "Chargement…", "Loading…", "Cargando…")
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

    Private Shared Sub SetLiteral(root As Control, id As String, text As String)
        Dim lit = TryCast(FindDeep(root, id), Literal)
        If lit IsNot Nothing Then lit.Text = text
    End Sub

    Private Shared Function FindDeep(root As Control, id As String) As Control
        If root Is Nothing Then Return Nothing
        Dim direct As Control = root.FindControl(id)
        If direct IsNot Nothing Then Return direct
        For Each ch As Control In root.Controls
            Dim r As Control = FindDeep(ch, id)
            If r IsNot Nothing Then Return r
        Next
        Return Nothing
    End Function

End Class