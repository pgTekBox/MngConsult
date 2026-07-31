Imports Telerik.Web.UI
Imports System.Data
Imports System.Data.SqlClient

Public Class wbfReleve
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

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
        Dim dt As DataTable = GetData()
        rlvReleve.DataSource = dt
    End Sub

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvReleve.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
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

    Protected Function FormatDateOnly(value As Object) As String
        If value Is Nothing OrElse value Is DBNull.Value Then Return ""
        Return Convert.ToDateTime(value).ToString("dd MMM yyyy").ToLower()
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
            Return "montant-negatif"
        ElseIf m > 0D Then
            Return "montant-positif"
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
            Case "pageSub" : Return Choose3(lang, "Consultation des mouvements bancaires", "View of bank movements", "Consulta de movimientos bancarios")
            Case "connectBank" : Return Choose3(lang, "Connecter une banque", "Connect a bank", "Conectar un banco")
            Case "searchPh" : Return Choose3(lang, "Rechercher (description, référence, compte, statut…)", "Search (description, reference, account, status…)", "Buscar (descripción, referencia, cuenta, estado…)")
            Case "clear" : Return Choose3(lang, "Effacer", "Clear", "Borrar")
            Case "colDate" : Return Choose3(lang, "Date", "Date", "Fecha")
            Case "colDesc" : Return Choose3(lang, "Description", "Description", "Descripción")
            Case "colRef" : Return Choose3(lang, "Référence", "Reference", "Referencia")
            Case "colStatus" : Return Choose3(lang, "Statut", "Status", "Estado")
            Case "colAmount" : Return Choose3(lang, "Montant", "Amount", "Importe")
            Case "empty" : Return Choose3(lang, "Aucun mouvement bancaire trouvé.", "No bank movement found.", "Ningún movimiento bancario encontrado.")
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