Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' La fiche d'un lieu (nom, type, adresse, actif), ouverte en fenêtre par
''' Produits et services › Lieux (wbfLieux.aspx) : Id=0 pour un nouveau lieu.
''' Enregistrer ferme la fenêtre ; la liste se rafraîchit à la fermeture.
''' </summary>
Public Class wbfLieuEdit
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        btnSave.Text = L("enregistrer")

        If Not IsPostBack Then
            RemplirTypes()
            Dim id As Integer = 0
            Integer.TryParse(Request.QueryString("Id"), id)
            Charger(id)
        End If
    End Sub

    ''' <summary>Traductions de la fiche d'un lieu (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Lieu — Édition", "Location — Edit", "Lugar — Edición")
            Case "rubrique" : Return Choose3(lang, "Produits et services · Lieu", "Products and services · Location", "Productos y servicios · Lugar")
            Case "nouveau" : Return Choose3(lang, "Nouveau lieu", "New location", "Nuevo lugar")
            Case "modifier" : Return Choose3(lang, "Modifier le lieu", "Edit location", "Editar el lugar")
            Case "nom" : Return Choose3(lang, "Nom", "Name", "Nombre")
            Case "type" : Return Choose3(lang, "Type", "Type", "Tipo")
            Case "adresse" : Return Choose3(lang, "Adresse (facultatif)", "Address (optional)", "Dirección (opcional)")
            Case "actifLong" : Return Choose3(lang, "Lieu actif (offert dans les rendez-vous)", "Active location (offered in appointments)", "Lugar activo (ofrecido en las citas)")
            Case "enregistrer" : Return Choose3(lang, "Enregistrer", "Save", "Guardar")
            Case "fermer" : Return Choose3(lang, "Fermer", "Close", "Cerrar")
            Case "tClient" : Return Choose3(lang, "Chez le client", "At the customer's", "En casa del cliente")
            Case "tAffaires" : Return Choose3(lang, "Place d'affaires", "Place of business", "Su negocio")
            Case "tDistance" : Return Choose3(lang, "À distance", "Remote", "A distancia")
            Case "tAutre" : Return Choose3(lang, "Autre lieu", "Other location", "Otro lugar")
            Case "nomRequis" : Return Choose3(lang, "Le nom du lieu est obligatoire.", "The location name is required.", "El nombre del lugar es obligatorio.")
            Case "doublon" : Return Choose3(lang, "Un autre lieu porte déjà ce nom.", "Another location already has this name.", "Otro lugar ya tiene este nombre.")
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

    Private Sub RemplirTypes()
        ddlType.Items.Clear()
        ddlType.Items.Add(New ListItem(L("tClient"), "client"))
        ddlType.Items.Add(New ListItem(L("tAffaires"), "affaires"))
        ddlType.Items.Add(New ListItem(L("tDistance"), "distance"))
        ddlType.Items.Add(New ListItem(L("tAutre"), "autre"))
        ddlType.SelectedValue = "autre"
    End Sub

    Private Sub Charger(id As Integer)
        hfId.Value = id.ToString()
        litTitre.Text = Server.HtmlEncode(If(id = 0, L("nouveau"), L("modifier")))
        If id <= 0 Then Return

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Id", id))
        Dim ds As DataSet = ExecuteSQLds("s0919GetLieuById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

        Dim r As DataRow = ds.Tables(0).Rows(0)
        txtNom.Text = Convert.ToString(r("Nom"))
        txtAdresse.Text = Convert.ToString(r("Adresse"))
        If ddlType.Items.FindByValue(Convert.ToString(r("TypeLieu"))) IsNot Nothing Then ddlType.SelectedValue = Convert.ToString(r("TypeLieu"))
        chkActif.Checked = Convert.ToBoolean(r("Actif"))
    End Sub

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        If String.IsNullOrWhiteSpace(txtNom.Text) Then
            Erreur(L("nomRequis"))
            Return
        End If

        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)

        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Nom", txtNom.Text.Trim()))
        p.Add(New SqlParameter("@TypeLieu", ddlType.SelectedValue))
        p.Add(New SqlParameter("@Adresse", If(String.IsNullOrWhiteSpace(txtAdresse.Text), CObj(DBNull.Value), txtAdresse.Text.Trim())))
        p.Add(New SqlParameter("@Actif", chkActif.Checked))
        Dim outId As New SqlParameter("@NewId", SqlDbType.Int)
        outId.Direction = ParameterDirection.Output
        p.Add(outId)

        Try
            ExecuteSQL("s0920SaveLieu", p)
        Catch ex As SqlException
            ' s0920 refuse un nom déjà pris (le nom vide est vérifié plus haut)
            Erreur(L("doublon"))
            Return
        End Try

        ' Fermer la fenêtre : la liste se rafraîchit à la fermeture
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "close", "closeWin();", True)
    End Sub

    Private Sub Erreur(texte As String)
        pnlMsg.Visible = True
        litMsg.Text = Server.HtmlEncode(texte)
    End Sub

End Class
