Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Produits et services › Lieux : les lieux où la compagnie rend ses services
''' (chez le client, à sa place d'affaires, à distance, ou un autre lieu nommé).
''' Chaque service choisit ses lieux dans sa fiche (wbfProductEdit) ; la fenêtre
''' « Nouveau RDV » offre les lieux du service choisi. La première visite pose les
''' trois lieux de base (s0918). La fiche d'un lieu s'ouvre en fenêtre (wbfLieuEdit).
''' </summary>
Public Class wbfLieux
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        ' Les boîtes posent sur le fond de la page, comme dans le gabarit.
        DirectCast(Master, SiteMaster).FondDePage = True
        ApplyLocalization()

        If Not IsPostBack Then Lier()
    End Sub

    Private Sub ApplyLocalization()
        litRubrique.Text = Server.HtmlEncode(L("rubrique"))
        litPageTitle.Text = Server.HtmlEncode(L("pageTitleShort"))
        litSousTitre.Text = Server.HtmlEncode(L("sousTitre"))
    End Sub

    ''' <summary>Traductions de la page Lieux (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Lieux — 60Sec-AI", "Locations — 60Sec-AI", "Lugares — 60Sec-AI")
            Case "pageTitleShort" : Return Choose3(lang, "Lieux", "Locations", "Lugares")
            Case "rubrique" : Return Choose3(lang, "Produits et services", "Products and services", "Productos y servicios")
            Case "sousTitre" : Return Choose3(lang, "Où vous rendez vos services ; chaque service choisit ses lieux dans sa fiche.", "Where you deliver your services; each service picks its locations in its record.", "Dónde presta sus servicios; cada servicio elige sus lugares en su ficha.")
            Case "ajouter" : Return Choose3(lang, "+ Ajouter un lieu", "+ Add a location", "+ Agregar un lugar")
            Case "nouveau" : Return Choose3(lang, "Nouveau lieu", "New location", "Nuevo lugar")
            Case "modifier" : Return Choose3(lang, "Modifier le lieu", "Edit location", "Editar el lugar")
            Case "colNom" : Return Choose3(lang, "Nom", "Name", "Nombre")
            Case "colType" : Return Choose3(lang, "Type", "Type", "Tipo")
            Case "colAdresse" : Return Choose3(lang, "Adresse", "Address", "Dirección")
            Case "colServices" : Return Choose3(lang, "Services", "Services", "Servicios")
            Case "colActif" : Return Choose3(lang, "Actif", "Active", "Activo")
            Case "tClient" : Return Choose3(lang, "Chez le client", "At the customer's", "En casa del cliente")
            Case "tAffaires" : Return Choose3(lang, "Place d'affaires", "Place of business", "Su negocio")
            Case "tDistance" : Return Choose3(lang, "À distance", "Remote", "A distancia")
            Case "tAutre" : Return Choose3(lang, "Autre lieu", "Other location", "Otro lugar")
            Case "actifOui" : Return Choose3(lang, "Actif", "Active", "Activo")
            Case "actifNon" : Return Choose3(lang, "Inactif", "Inactive", "Inactivo")
            Case "nbServices" : Return Choose3(lang, "{0} service(s)", "{0} service(s)", "{0} servicio(s)")
            Case "vide" : Return Choose3(lang, "Aucun lieu.", "No location.", "Ningún lugar.")
            Case "pied" : Return Choose3(lang, "{0} lieu(x)", "{0} location(s)", "{0} lugar(es)")
            Case "confirmSuppr" : Return Choose3(lang, "Supprimer ce lieu ? Les services qui l'avaient choisi ne l'offriront plus.", "Delete this location? Services that had chosen it will no longer offer it.", "¿Eliminar este lugar? Los servicios que lo habían elegido ya no lo ofrecerán.")
            Case "supprime" : Return Choose3(lang, "Lieu supprimé.", "Location deleted.", "Lugar eliminado.")
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

    ' ── La liste ──

    Private Sub Lier()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0918GetLieux", p)
        Dim dt As DataTable = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), Nothing)
        Dim n As Integer = If(dt Is Nothing, 0, dt.Rows.Count)

        rptLieux.DataSource = dt
        rptLieux.DataBind()
        pnlVide.Visible = (n = 0)
        litPied.Text = Server.HtmlEncode(String.Format(L("pied"), n))
    End Sub

    ''' <summary>La fenêtre d'un lieu vient de se fermer : la liste se recharge.</summary>
    Private Sub btnRafraichir_Click(sender As Object, e As EventArgs) Handles btnRafraichir.Click
        pnlMsg.Visible = False
        Lier()
    End Sub

    Private Sub rptLieux_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptLieux.ItemCommand
        Dim id As Integer = 0
        Integer.TryParse(Convert.ToString(e.CommandArgument), id)
        If id <= 0 OrElse e.CommandName <> "Supprimer" Then Return

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Id", id))
        ExecuteSQL("s0921DeleteLieu", p)

        pnlMsg.Visible = True
        divMsg.InnerText = L("supprime")
        divMsg.Attributes("class") = "li-msg ok"
        Lier()
    End Sub

    ' ── Les cellules de la liste ──

    Public Function ConfirmerSuppression() As String
        Return "return confirm(" & HttpUtility.JavaScriptStringEncode(L("confirmSuppr"), True) & ");"
    End Function

    Public Function TypeTexte(t As Object) As String
        Select Case Convert.ToString(t)
            Case "client" : Return L("tClient")
            Case "affaires" : Return L("tAffaires")
            Case "distance" : Return L("tDistance")
            Case Else : Return L("tAutre")
        End Select
    End Function

    Public Function NbServicesTexte(nb As Object) As String
        Dim n As Integer = 0
        If nb IsNot Nothing AndAlso Not IsDBNull(nb) Then n = Convert.ToInt32(nb)
        Return If(n = 0, "—", Server.HtmlEncode(String.Format(L("nbServices"), n)))
    End Function

    ''' <summary>Un point vert « Actif » ou gris « Inactif ».</summary>
    Public Function ActifCell(actif As Object) As String
        Dim ok As Boolean = actif IsNot Nothing AndAlso Not IsDBNull(actif) AndAlso Convert.ToBoolean(actif)
        Return "<span class=""li-etat"" style=""color:" & If(ok, "#0F5A3A", "#5B6B86") & """><i style=""background:" & If(ok, "#43B47A", "#AEBBCD") & """></i>" &
               Server.HtmlEncode(If(ok, L("actifOui"), L("actifNon"))) & "</span>"
    End Function

End Class
