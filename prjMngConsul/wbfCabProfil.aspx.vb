Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Profil du cabinet (Portail comptable, admin/solo). Nom, responsable, coordonnées,
''' langues, spécialités, « accepter de nouveaux clients » et « fiche visible dans
''' l'annuaire » (qui publie/retire une ligne T319 lue par CabinetsCertifies.aspx).
''' Procs s0935GetCabinetProfil / s0936SaveCabinetProfil.
''' </summary>
Public Class wbfCabProfil
    Inherits clsData

    Protected WithEvents litTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litSecIdent As System.Web.UI.WebControls.Literal
    Protected WithEvents litSecServ As System.Web.UI.WebControls.Literal
    Protected WithEvents litSecVis As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblNom As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblResp As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblDesc As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblVille As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblProv As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblMail As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblTel As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblSite As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblLangues As System.Web.UI.WebControls.Literal
    Protected WithEvents litLblSpec As System.Web.UI.WebControls.Literal
    Protected WithEvents litAccepteT As System.Web.UI.WebControls.Literal
    Protected WithEvents litAccepteS As System.Web.UI.WebControls.Literal
    Protected WithEvents litPubliqueT As System.Web.UI.WebControls.Literal
    Protected WithEvents litPubliqueS As System.Web.UI.WebControls.Literal
    Protected WithEvents txtNom As System.Web.UI.WebControls.TextBox
    Protected WithEvents txtResp As System.Web.UI.WebControls.TextBox
    Protected WithEvents txtDesc As System.Web.UI.WebControls.TextBox
    Protected WithEvents txtVille As System.Web.UI.WebControls.TextBox
    Protected WithEvents txtProv As System.Web.UI.WebControls.TextBox
    Protected WithEvents txtMail As System.Web.UI.WebControls.TextBox
    Protected WithEvents txtTel As System.Web.UI.WebControls.TextBox
    Protected WithEvents txtSite As System.Web.UI.WebControls.TextBox
    Protected WithEvents cblLangues As System.Web.UI.WebControls.CheckBoxList
    Protected WithEvents cblSpec As System.Web.UI.WebControls.CheckBoxList
    Protected WithEvents cbAccepte As System.Web.UI.WebControls.CheckBox
    Protected WithEvents cbPublique As System.Web.UI.WebControls.CheckBox
    Protected WithEvents btnSave As System.Web.UI.WebControls.Button
    Protected WithEvents litMsg As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        Dim role As String = RoleCabinet()
        If role <> "admin" AndAlso role <> "solo" Then
            Response.Redirect("~/wbfCabTableauBord.aspx") : Return
        End If

        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        If Not IsPostBack Then
            Textes()
            BindChoix()
            Charger()
        End If
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

    Private Sub Textes()
        litTitre.Text = Server.HtmlEncode(T("Profil du cabinet", "Firm profile", "Perfil del despacho"))
        litSous.Text = Server.HtmlEncode(T("Ce que vos clients et 60secondes savent de votre cabinet.",
                                           "What your clients and 60secondes know about your firm.",
                                           "Lo que sus clientes y 60secondes saben de su despacho."))
        litSecIdent.Text = Server.HtmlEncode(T("Identification", "Identification", "Identificación"))
        litSecServ.Text = Server.HtmlEncode(T("Service", "Service", "Servicio"))
        litSecVis.Text = Server.HtmlEncode(T("Clients et visibilité", "Clients and visibility", "Clientes y visibilidad"))
        litLblNom.Text = Server.HtmlEncode(T("Nom du cabinet", "Firm name", "Nombre del despacho"))
        litLblResp.Text = Server.HtmlEncode(T("Responsable", "Lead", "Responsable"))
        litLblDesc.Text = Server.HtmlEncode(T("Description", "Description", "Descripción"))
        litLblVille.Text = Server.HtmlEncode(T("Ville", "City", "Ciudad"))
        litLblProv.Text = Server.HtmlEncode(T("Province", "Province", "Provincia"))
        litLblMail.Text = Server.HtmlEncode(T("Courriel", "Email", "Correo"))
        litLblTel.Text = Server.HtmlEncode(T("Téléphone", "Phone", "Teléfono"))
        litLblSite.Text = Server.HtmlEncode(T("Site web", "Website", "Sitio web"))
        litLblLangues.Text = Server.HtmlEncode(T("Langues de service", "Service languages", "Idiomas de servicio"))
        litLblSpec.Text = Server.HtmlEncode(T("Spécialités", "Specialties", "Especialidades"))
        litAccepteT.Text = Server.HtmlEncode(T("Accepter de nouveaux clients", "Accept new clients", "Aceptar nuevos clientes"))
        litAccepteS.Text = Server.HtmlEncode(T("Les entreprises qui cherchent un comptable peuvent vous choisir.",
                                               "Businesses looking for an accountant can choose you.",
                                               "Las empresas que buscan un contador pueden elegirle."))
        litPubliqueT.Text = Server.HtmlEncode(T("Fiche visible dans l'annuaire", "Profile visible in the directory", "Ficha visible en el directorio"))
        litPubliqueS.Text = Server.HtmlEncode(T("Votre cabinet apparaît dans « Cabinets certifiés » des entreprises.",
                                                "Your firm appears in businesses' « Certified firms » directory.",
                                                "Su despacho aparece en el directorio « Despachos certificados »."))
        btnSave.Text = T("Enregistrer", "Save", "Guardar")
    End Sub

    Private Sub BindChoix()
        cblLangues.Items.Clear()
        cblLangues.Items.Add(New ListItem("FR", "FR"))
        cblLangues.Items.Add(New ListItem("EN", "EN"))
        cblLangues.Items.Add(New ListItem("ES", "ES"))

        cblSpec.Items.Clear()
        cblSpec.Items.Add(New ListItem(T("Travailleurs autonomes", "Self-employed", "Autónomos"), "ta"))
        cblSpec.Items.Add(New ListItem(T("Sociétés", "Corporations", "Sociedades"), "soc"))
        cblSpec.Items.Add(New ListItem(T("Paie et employés", "Payroll", "Nómina"), "paie"))
        cblSpec.Items.Add(New ListItem(T("Construction", "Construction", "Construcción"), "constr"))
        cblSpec.Items.Add(New ListItem(T("Santé et services", "Health and services", "Salud y servicios"), "sante"))
    End Sub

    Private Sub Charger()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0935GetCabinetProfil", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return
        Dim r As DataRow = ds.Tables(0).Rows(0)

        txtNom.Text = Convert.ToString(r("Nom"))
        txtResp.Text = SVal(r, "Responsable")
        txtDesc.Text = SVal(r, "Description")
        txtVille.Text = SVal(r, "Ville")
        txtProv.Text = SVal(r, "Province")
        txtMail.Text = SVal(r, "Courriel")
        txtTel.Text = SVal(r, "Telephone")
        txtSite.Text = SVal(r, "SiteWeb")
        CocherCsv(cblLangues, SVal(r, "Langues"))
        CocherCsv(cblSpec, SVal(r, "Specialites"))
        cbAccepte.Checked = Not IsDBNull(r("AccepteNouveauxClients")) AndAlso Convert.ToBoolean(r("AccepteNouveauxClients"))
        cbPublique.Checked = Not IsDBNull(r("FichePublique")) AndAlso Convert.ToBoolean(r("FichePublique"))
    End Sub

    Private Shared Function SVal(r As DataRow, col As String) As String
        If IsDBNull(r(col)) Then Return ""
        Return Convert.ToString(r(col))
    End Function

    Private Shared Sub CocherCsv(cbl As CheckBoxList, csv As String)
        For Each it As ListItem In cbl.Items
            it.Selected = False
        Next
        If String.IsNullOrEmpty(csv) Then Return
        For Each code As String In csv.Split(","c)
            Dim it As ListItem = cbl.Items.FindByValue(code.Trim())
            If it IsNot Nothing Then it.Selected = True
        Next
    End Sub

    Private Shared Function CsvDe(cbl As CheckBoxList) As String
        Dim sb As New StringBuilder()
        For Each it As ListItem In cbl.Items
            If it.Selected Then
                If sb.Length > 0 Then sb.Append(","c)
                sb.Append(it.Value)
            End If
        Next
        Return sb.ToString()
    End Function

    Protected Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        If txtNom.Text.Trim() = "" Then
            Msg("err", T("Le nom du cabinet est requis.", "The firm name is required.", "El nombre del despacho es obligatorio.")) : Return
        End If

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@Nom", txtNom.Text.Trim()))
        p.Add(New SqlParameter("@Responsable", Nz(txtResp.Text.Trim())))
        p.Add(New SqlParameter("@Description", Nz(txtDesc.Text.Trim())))
        p.Add(New SqlParameter("@Ville", Nz(txtVille.Text.Trim())))
        p.Add(New SqlParameter("@Province", Nz(txtProv.Text.Trim())))
        p.Add(New SqlParameter("@Courriel", Nz(txtMail.Text.Trim())))
        p.Add(New SqlParameter("@Telephone", Nz(txtTel.Text.Trim())))
        p.Add(New SqlParameter("@SiteWeb", Nz(txtSite.Text.Trim())))
        p.Add(New SqlParameter("@Langues", Nz(CsvDe(cblLangues))))
        p.Add(New SqlParameter("@Specialites", Nz(CsvDe(cblSpec))))
        p.Add(New SqlParameter("@AccepteNouveauxClients", cbAccepte.Checked))
        p.Add(New SqlParameter("@FichePublique", cbPublique.Checked))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s0936SaveCabinetProfil", p)

        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        If err = 0 Then
            Dim extra As String = If(cbPublique.Checked,
                " " & T("Votre fiche est maintenant visible dans « Cabinets certifiés ».", "Your profile is now visible in « Certified firms ».", "Su ficha ahora es visible en « Despachos certificados »."), "")
            Msg("ok", T("Profil enregistré.", "Profile saved.", "Perfil guardado.") & extra)
        Else
            Msg("err", T("L'enregistrement a échoué.", "Save failed.", "El guardado falló."))
        End If
    End Sub

    Private Shared Function Nz(s As String) As Object
        Return If(String.IsNullOrEmpty(s), CType(DBNull.Value, Object), s)
    End Function

    Private Sub Msg(kind As String, txt As String)
        litMsg.Text = "<div class=""msg " & kind & """>" & Server.HtmlEncode(txt) & "</div>"
    End Sub

End Class
