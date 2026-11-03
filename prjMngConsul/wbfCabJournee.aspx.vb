Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web.Script.Serialization

''' <summary>
''' « Ma journée » du Portail comptable (maquette v2) : l'écran d'accueil du cabinet.
''' Liste d'actions priorisée (échéances gouvernementales, argent, client qui
''' attend, signalements de 60, reste), charge de l'équipe, « 60 a fait
''' aujourd'hui », échéances des 30 prochains jours, et une fenêtre de détail.
'''
''' Source réelle : les **tâches réelles** du périmètre du cabinet (T339, proc
''' s0956GetJourneeTaches), les **membres réels** (s0922), le journal (s0961, pour
''' « 60 a fait ») et les demandes entrantes (s0939, pour la tuile). Chaque tâche
''' non « fait » devient une action ; le bloc et la priorité sont déduits du titre.
''' « Faire » (ou « Faire en lot ») marque la/les tâche(s) « fait » via s0944
''' (POST léger op=done, annulation op=undo), inscrit au journal du dossier.
''' Le détail d'une action réelle est simplifié (pas d'étapes/pièces/autorisation,
''' absentes des tâches libres) : titre, échéance, responsable, description.
'''
''' Si le cabinet n'a aucune tâche à faire, un **repli illustratif** riche
''' s'affiche (un bandeau le signale). Réservé aux comptables (IsAccountant).
''' </summary>
Public Class wbfCabJournee
    Inherits clsData

    Protected WithEvents litData As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        ' Actions réelles « Faire » / « Annuler » : POST léger, réponse JSON.
        If String.Equals(Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase) Then
            Dim op As String = Convert.ToString(Request.Form("op"))
            If op = "done" OrElse op = "undo" Then
                TraiterStatut(op) : Return
            End If
        End If

        If Not IsPostBack Then Charger()
    End Sub

    Private Function RoleCabinet() As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0919GetUserCabinet", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return Convert.ToString(ds.Tables(0).Rows(0)("Role")).Trim().ToLowerInvariant()
            End If
        Catch
        End Try
        Return ""
    End Function

    ''' <summary>Marque les tâches « fait » (op=done) ou les remet « à faire » (op=undo).</summary>
    Private Sub TraiterStatut(op As String)
        Dim statut As String = If(op = "undo", "afaire", "fait")
        Dim n As Integer = 0
        For Each raw As String In Convert.ToString(Request.Form("ids")).Split(","c)
            Dim id As Integer
            If Integer.TryParse(raw.Trim(), id) Then
                Try
                    Dim p As New Collection
                    p.Add(New SqlParameter("@UserId", UserEmail))
                    p.Add(New SqlParameter("@Id", id))
                    p.Add(New SqlParameter("@Statut", statut))
                    Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
                    p.Add(outErr)
                    ExecuteSQL("s0944SetStatutTache", p)
                    If Not (outErr.Value Is Nothing OrElse IsDBNull(outErr.Value)) AndAlso CInt(outErr.Value) = 0 Then n += 1
                Catch
                End Try
            End If
        Next
        Response.Clear()
        Response.ContentType = "application/json"
        Response.Write("{""ok"":true,""n"":" & n & "}")
        Response.End()
    End Sub

    Private Shared Function Initiales(nom As String) As String
        Dim sb As New StringBuilder()
        For Each mot As String In If(nom, "").Split(New Char() {" "c, "-"c}, StringSplitOptions.RemoveEmptyEntries)
            If mot.Length > 0 AndAlso Char.IsLetter(mot(0)) Then sb.Append(Char.ToUpperInvariant(mot(0)))
            If sb.Length = 2 Then Exit For
        Next
        If sb.Length = 0 Then sb.Append("?"c)
        Return sb.ToString()
    End Function

    Private Shared Function Slug(s As String) As String
        Dim sb As New StringBuilder()
        For Each ch As Char In If(s, "").Normalize(NormalizationForm.FormD)
            If Globalization.CharUnicodeInfo.GetUnicodeCategory(ch) = Globalization.UnicodeCategory.NonSpacingMark Then Continue For
            If Char.IsLetterOrDigit(ch) Then sb.Append(Char.ToLowerInvariant(ch)) Else sb.Append("_"c)
        Next
        Dim r As String = sb.ToString().Trim("_"c)
        Return If(r = "", "act", r)
    End Function

    Private Shared Function Contient(t As String, ParamArray mots() As String) As Boolean
        For Each m As String In mots
            If t.Contains(m) Then Return True
        Next
        Return False
    End Function

    ''' <summary>Type de priorité déduit du titre : gouv / argent / attend / signal / autre.</summary>
    Private Shared Function DeriveType(titre As String) As String
        Dim t As String = If(titre, "").ToLowerInvariant()
        If Contient(t, "tps", "tvq", "taxe", "remise", "t2", "co-17", "cotisation", "gouvern", "déclaration", "declaration", "acompte provisionnel") Then Return "gouv"
        If Contient(t, "liquidit", "seuil", "signal", "alerte", "avertir", "manque") Then Return "signal"
        If Contient(t, "relanc", "document", "question", "échange", "echange", "pièce", "piece", "manquant", "réponse", "reponse") Then Return "attend"
        If Contient(t, "paie", "facture", "paiement", "acompte", "remettre") Then Return "argent"
        Return "autre"
    End Function

    ''' <summary>Bloc déduit du titre (mêmes familles que la maquette).</summary>
    Private Shared Function DeriveBloc(titre As String) As String
        Dim t As String = If(titre, "").ToLowerInvariant()
        If Contient(t, "tps", "tvq", "taxe", "seuil") Then Return "Taxes de vente"
        If Contient(t, "paie", "relevé d'emploi", "releve d'emploi") Then Return "Paie"
        If Contient(t, "facture", "paiement", "remise", "fournisseur") Then Return "Paiements"
        If Contient(t, "t2", "co-17", "états financiers", "etats financiers", "fin d'exercice", "fin d'année", "fin d'annee") Then Return "Fin d'année"
        If Contient(t, "question", "échange", "echange", "message") Then Return "Échanges"
        If Contient(t, "liquidit", "signal", "alerte", "manque") Then Return "Signalé par 60"
        If Contient(t, "concil", "classer", "document", "pièce", "piece", "fermer", "relevé", "releve", "manquant", "dépense", "depense") Then Return "Fin de mois"
        Return "Autres"
    End Function

    Private Sub Charger()
        Dim dt As DataTable = LireTaches()
        Dim aFaire As Integer = 0
        If dt IsNot Nothing Then
            For Each r As DataRow In dt.Rows
                If Convert.ToString(r("Statut")).Trim().ToLowerInvariant() <> "fait" Then aFaire += 1
            Next
        End If

        If aFaire = 0 Then
            litData.Text = "null"   ' repli illustratif (script)
            Return
        End If

        ' --- Membres réels (s0922) ---
        Dim pers As New List(Of Object)()
        Dim idParGuid As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase)
        Dim moi As String = ""
        Dim premierGuid As String = ""
        Dim estPatron As Boolean = (RoleCabinet() = "admin" OrElse RoleCabinet() = "solo")
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0922ListCabinetMembres", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    Dim g As String = Convert.ToString(r("UserGUID")).ToLowerInvariant()
                    Dim fn As String = Convert.ToString(r("FirstName")).Trim()
                    Dim ln As String = Convert.ToString(r("LastName")).Trim()
                    Dim nom As String = (fn & " " & ln).Trim()
                    If nom = "" Then nom = Convert.ToString(r("Email")).Split("@"c)(0)
                    Dim estMoi As Boolean = Convert.ToBoolean(r("IsMe"))
                    If estMoi Then moi = g
                    If premierGuid = "" Then premierGuid = g
                    pers.Add(New With {.id = g, .nom = nom, .role = "", .patron = (estMoi AndAlso estPatron), .cap = 8})
                    idParGuid(g) = g
                Next
            End If
        Catch
        End Try
        If moi = "" Then moi = premierGuid

        ' --- Tâches → actions + instances ---
        Dim actions As New Dictionary(Of String, Object)()
        Dim clients As New List(Of Object)()
        Dim idxDossier As New Dictionary(Of String, Integer)(StringComparer.OrdinalIgnoreCase)
        Dim tx As New List(Of Object)()
        Dim besoinNone As Boolean = False

        For Each r As DataRow In dt.Rows
            If Convert.ToString(r("Statut")).Trim().ToLowerInvariant() = "fait" Then Continue For
            Dim titre As String = Convert.ToString(r("Titre")).Trim()
            If titre = "" Then titre = "Tâche"
            Dim cle As String = Slug(titre)
            If Not actions.ContainsKey(cle) Then
                actions(cle) = New With {
                    .t = titre, .bloc = DeriveBloc(titre), .type = DeriveType(titre),
                    .verbe = "Faire", .s60 = 0, .lot = 1,
                    .pq = "", .droit = "", .auto = "", .et = New Object() {}, .pcs = New String() {}, .dit = "", .prep = New Object() {}}
            End If

            Dim dossier As String = Convert.ToString(r("DossierNom")).Trim()
            If dossier = "" Then dossier = "Dossier"
            Dim ci As Integer
            If Not idxDossier.TryGetValue(dossier, ci) Then
                ci = clients.Count
                idxDossier(dossier) = ci
                clients.Add(New With {.i = ci, .nom = dossier, .metier = "", .p = moi})
            End If

            Dim jours As Integer = 99
            If Not IsDBNull(r("Jours")) Then jours = Convert.ToInt32(r("Jours"))
            Dim resp As String = If(IsDBNull(r("AssignedUserGUID")), "", Convert.ToString(r("AssignedUserGUID")).ToLowerInvariant())
            If resp = "" OrElse Not idParGuid.ContainsKey(resp) Then
                resp = "none" : besoinNone = True
            End If
            Dim desc As String = If(IsDBNull(r("Description")), "", Convert.ToString(r("Description")).Trim())

            tx.Add(New With {
                .id = tx.Count + 1,
                .taskId = Convert.ToInt32(r("Id")),
                .c = ci, .a = cle, .j = jours, .resp = resp, .fait = False, .x = desc})
        Next
        If besoinNone Then pers.Add(New With {.id = "none", .nom = "Non assigné", .role = "", .patron = False, .cap = 8})

        Dim today As Date = Date.Today
        Dim payload As New Dictionary(Of String, Object) From {
            {"reel", True},
            {"auj", New Integer() {today.Year, today.Month - 1, today.Day}},
            {"me", moi},
            {"patron", estPatron},
            {"pers", pers},
            {"cli", clients},
            {"a", actions},
            {"t", tx},
            {"n60", CompterJournalAuj()},
            {"demandes", CompterDemandes()}
        }
        litData.Text = New JavaScriptSerializer() With {.MaxJsonLength = 16 * 1024 * 1024}.Serialize(payload)
    End Sub

    ''' <summary>Toutes les tâches du périmètre (s0956), ou Nothing.</summary>
    Private Function LireTaches() As DataTable
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0956GetJourneeTaches", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0)
        Catch
        End Try
        Return Nothing
    End Function

    ''' <summary>Nombre d'entrées de journal du cabinet datées d'aujourd'hui (« 60 a fait »).</summary>
    Private Function CompterJournalAuj() As Integer
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0961GetCabinetJournal", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                Dim n As Integer = 0
                For Each r As DataRow In ds.Tables(0).Rows
                    If Not IsDBNull(r("Utc")) AndAlso Convert.ToDateTime(r("Utc")).ToLocalTime().Date = Date.Today Then n += 1
                Next
                Return n
            End If
        Catch
        End Try
        Return 0
    End Function

    ''' <summary>Nombre de demandes de clients en attente (s0939), pour la tuile.</summary>
    Private Function CompterDemandes() As Integer
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0939ListDemandesCabinet", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0).Rows.Count
        Catch
        End Try
        Return 0
    End Function

End Class
