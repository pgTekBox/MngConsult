Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

''' <summary>
''' « Clients non associés » (Portail comptable, admin/solo) — calqué sur la
''' maquette : les entreprises qui ont choisi ce cabinet dans l'annuaire et
''' attendent une réponse. Chaque fiche montre métier, profil, ville, services
''' demandés, contact et détails. Accepter → la compagnie devient un dossier
''' (s0940) ; Décliner → écartée ; Annuler → remise en attente (s0960).
''' Données réelles (s0939, T337) ; rendu + interactivité côté client ; actions
''' par POST léger (op=accept|decline|restore).
''' </summary>
Public Class wbfCabDemandes
    Inherits clsData

    Protected WithEvents litData As System.Web.UI.WebControls.Literal
    Protected WithEvents litLabels As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        Dim role As String = RoleCabinet()
        If role <> "admin" AndAlso role <> "solo" Then
            Response.Redirect("~/wbfCabJournee.aspx") : Return
        End If

        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        Dim op As String = Request.Form("op")
        If String.Equals(Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase) _
           AndAlso (op = "accept" OrElse op = "decline" OrElse op = "restore") Then
            TraiterAction(op)
            Return
        End If

        If Not IsPostBack Then Charger()
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

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

    Private Shared Function SVal(r As DataRow, col As String) As String
        If Not r.Table.Columns.Contains(col) OrElse IsDBNull(r(col)) Then Return ""
        Return Convert.ToString(r(col))
    End Function

    Private Shared Function Initiales(nom As String) As String
        Dim sb As New Text.StringBuilder()
        For Each mot As String In If(nom, "").Split(New Char() {" "c, "-"c}, StringSplitOptions.RemoveEmptyEntries)
            If mot.Length > 0 AndAlso Char.IsLetter(mot(0)) Then sb.Append(Char.ToUpperInvariant(mot(0)))
            If sb.Length = 2 Then Exit For
        Next
        If sb.Length = 0 Then sb.Append("?"c)
        Return sb.ToString()
    End Function

    Private Sub Charger()
        Dim demandes As New List(Of Object)()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0939ListDemandesCabinet", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
                For Each r As DataRow In ds.Tables(0).Rows
                    If IsDBNull(r("Id")) Then Continue For
                    Dim nom As String = SVal(r, "Name")
                    Dim services As String() = If(SVal(r, "ServicesCsv") = "", New String() {}, SVal(r, "ServicesCsv").Split("|"c))
                    Dim details As New List(Of Object)()
                    If SVal(r, "Taille") <> "" Then details.Add(New With {.k = T("Taille", "Size", "Tamaño"), .v = SVal(r, "Taille")})
                    If SVal(r, "Logiciel") <> "" Then details.Add(New With {.k = T("Logiciel actuel", "Current software", "Software actual"), .v = SVal(r, "Logiciel")})
                    If SVal(r, "FinExercice") <> "" Then details.Add(New With {.k = T("Fin d'exercice", "Year-end", "Cierre de ejercicio"), .v = SVal(r, "FinExercice")})
                    Dim jours As Integer = 0
                    If Not IsDBNull(r("Jours")) Then jours = Convert.ToInt32(r("Jours"))
                    demandes.Add(New With {
                        .id = Convert.ToInt32(r("Id")),
                        .ini = Initiales(nom),
                        .nom = nom,
                        .metier = SVal(r, "Metier"),
                        .profil = SVal(r, "Profil"),
                        .ville = SVal(r, "Ville"),
                        .jours = jours,
                        .services = services,
                        .message = SVal(r, "Message"),
                        .contact = New With {.nom = SVal(r, "ContactNom"), .mail = SVal(r, "ContactMail"), .tel = SVal(r, "ContactTel")},
                        .details = details})
                Next
            End If
        Catch
        End Try

        Dim data As New Dictionary(Of String, Object) From {{"demandes", demandes}}
        Dim js As New JavaScriptSerializer() With {.MaxJsonLength = 8 * 1024 * 1024}
        litData.Text = js.Serialize(data)
        litLabels.Text = js.Serialize(Libelles())
    End Sub

    Private Sub TraiterAction(op As String)
        Dim id As Integer
        Dim ok As Boolean = False
        If Integer.TryParse(Request.Form("id"), id) Then
            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@UserId", UserEmail))
                p.Add(New SqlParameter("@Id", id))
                Dim proc As String
                If op = "restore" Then
                    proc = "s0960RestoreDemandeCabinet"
                Else
                    proc = "s0940TraiterDemandeCabinet"
                    p.Add(New SqlParameter("@Decision", If(op = "accept", "accepter", "refuser")))
                End If
                Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
                p.Add(outErr)
                ExecuteSQL(proc, p)
                ok = (Not (outErr.Value Is Nothing OrElse IsDBNull(outErr.Value))) AndAlso CInt(outErr.Value) = 0
            Catch
            End Try
        End If
        Response.Clear()
        Response.ContentType = "application/json"
        Response.Write("{""ok"":" & If(ok, "true", "false") & "}")
        Response.End()
    End Sub

    Private Function Libelles() As Dictionary(Of String, String)
        Return New Dictionary(Of String, String) From {
            {"titre", T("Clients non associés", "Unassigned clients", "Clientes sin asignar")},
            {"introUne", T("entreprise a choisi votre cabinet sur 60secondes.", "business chose your firm on 60secondes.", "empresa eligió su despacho en 60secondes.")},
            {"introN", T("entreprises ont choisi votre cabinet sur 60secondes.", "businesses chose your firm on 60secondes.", "empresas eligieron su despacho en 60secondes.")},
            {"introFin", T("Acceptez en un clic : 60 s'occupe du reste, y compris le transfert de leurs données.", "Accept in one click: 60 handles the rest, including transferring their data.", "Acepte con un clic: 60 se encarga del resto, incluida la transferencia de sus datos.")},
            {"attendDepuis", T("{n} jours", "{n} days", "{n} días")},
            {"attendUn", T("1 jour", "1 day", "1 día")},
            {"attendRouge", T("{nom} attend depuis {n} jours.", "{nom} has been waiting {n} days.", "{nom} espera desde hace {n} días.")},
            {"vide", T("Aucune demande en attente. Les entreprises qui choisiront votre cabinet apparaîtront ici.", "No pending request. Businesses that choose your firm will appear here.", "Ninguna solicitud pendiente. Las empresas que elijan su despacho aparecerán aquí.")},
            {"souhaite", T("Souhaite vous confier", "Wishes to entrust you with", "Desea confiarle")},
            {"accepter", T("Accepter", "Accept", "Aceptar")},
            {"ecrire", T("Écrire", "Write", "Escribir")},
            {"decliner", T("Décliner", "Decline", "Rechazar")},
            {"attendLab", T("Attend depuis", "Waiting for", "Espera desde hace")},
            {"contact", T("Contact", "Contact", "Contacto")},
            {"raison", T("Raison", "Reason", "Motivo")},
            {"raison1", T("Pas de capacité en ce moment", "No capacity right now", "Sin capacidad por ahora")},
            {"raison2", T("Service hors de notre offre", "Service outside our offering", "Servicio fuera de nuestra oferta")},
            {"raison3", T("Région non desservie", "Region not served", "Región no atendida")},
            {"raison4", T("Autre raison", "Other reason", "Otro motivo")},
            {"declineNote", T("60 avise le client avec courtoisie et lui propose d'autres cabinets certifiés.", "60 courteously notifies the client and suggests other certified firms.", "60 avisa al cliente con cortesía y le propone otros despachos certificados.")},
            {"annuler", T("Annuler", "Undo", "Deshacer")},
            {"traites", T("Traités aujourd'hui", "Handled today", "Tratados hoy")},
            {"accepte", T("Accepté", "Accepted", "Aceptado")},
            {"decline", T("Décliné", "Declined", "Rechazado")},
            {"ajoute", T("Ajouté à vos clients · 60 l'accompagne pour le transfert", "Added to your clients · 60 helps with the transfer", "Añadido a sus clientes · 60 le acompaña en la transferencia")},
            {"declineTxt", T("Décliné", "Declined", "Rechazado")},
            {"estClient", T("{nom} est maintenant votre client.", "{nom} is now your client.", "{nom} ahora es su cliente.")},
            {"declinee", T("Demande de {nom} déclinée.", "{nom}'s request declined.", "Solicitud de {nom} rechazada.")},
            {"erreur", T("Action impossible pour l'instant.", "Action not possible right now.", "Acción no posible por ahora.")},
            {"sujetCourriel", T("Votre demande à notre cabinet", "Your request to our firm", "Su solicitud a nuestro despacho")}
        }
    End Function

End Class
