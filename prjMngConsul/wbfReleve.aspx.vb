Imports Telerik.Web.UI
Imports System.Data
Imports System.Data.SqlClient
Imports System.Linq
Imports System.Text

Public Class wbfReleve
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        ApplyLocalization()

        If Not IsPostBack Then
            rlvReleve.Rebind()
        End If
    End Sub

    ''' <summary>Applique la langue (fr/en/es) aux contrôles serveur / Literal de la page.</summary>
    Private Sub ApplyLocalization()
        SetLiteral(Me, "litPageTitle", L("pageTitleShort"))
        SetLiteral(Me, "litPageSub", L("pageSub"))
        SetLiteral(Me, "litConnectBtn", L("connectBank"))
        SetLiteral(Me, "litRubrique", L("rubrique"))
        SetLiteral(Me, "litComptesBtn", L("comptesBtn"))
        tbSearch.Attributes("placeholder") = L("searchPh")
        btnClear.ToolTip = L("clear")
    End Sub

    ''' <summary>Libellés du LayoutTemplate / EmptyDataTemplate du RadListView (via Literal).</summary>
    Private Sub rlvReleve_PreRender(sender As Object, e As EventArgs) Handles rlvReleve.PreRender
        SetLiteral(rlvReleve, "litColDate", L("colDate"))
        SetLiteral(rlvReleve, "litColDesc", L("colDesc"))
        SetLiteral(rlvReleve, "litColRef", L("colRef"))
        SetLiteral(rlvReleve, "litColStatus", L("colStatus"))
        SetLiteral(rlvReleve, "litColAmount", L("colAmount"))
        SetLiteral(rlvReleve, "litEmpty", L("empty"))
    End Sub

    Private Sub rlvReleve_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvReleve.NeedDataSource
        ChargerIndicateurs()
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
        If v.Substring(0, i) = "kpi" Then FiltreCourant = If(FiltreCourant = valeur, "", valeur)
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
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0).Rows.Cast(Of DataRow)().ToList()
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
        If dt Is Nothing OrElse FiltreCourant = "" Then Return dt
        Dim copie As DataTable = dt.Clone()
        For Each r As DataRow In dt.Rows
            If Cle(r("Statut")) = FiltreCourant Then copie.ImportRow(r)
        Next
        Return copie
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