Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports Telerik.Web.UI

''' <summary>
''' La fiche d'un cabinet certifié (T319), en fenêtre depuis wbfCabinets.aspx :
''' nom, responsable, ville et province, certifié depuis, description, courriel,
''' téléphone, site web, langues parlées (FR, EN, ES), spécialités (codes
''' ta, soc, paie, constr, sante — traduits dans 60Sec-AI), actif. s0902 lit,
''' s0903 enregistre (nom obligatoire et unique), s0904 supprime.
''' </summary>
Public Class wbfCabinetEdit
    Inherits clsData

    ''' <summary>Les codes de spécialités, dans l'ordre des cases de la fiche.</summary>
    Private Shared ReadOnly Specialites As String() = {"ta", "soc", "paie", "constr", "sante"}

    ''' <summary>Le libellé français d'un code de spécialité (aussi pour la liste).</summary>
    Public Shared Function LibelleSpecialite(code As String) As String
        Select Case code.Trim().ToLowerInvariant()
            Case "ta" : Return "Travailleurs autonomes"
            Case "soc" : Return "Sociétés"
            Case "paie" : Return "Paie et employés"
            Case "constr" : Return "Construction"
            Case "sante" : Return "Santé et services"
            Case Else : Return code.Trim()
        End Select
    End Function

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Dim id As Integer = 0
            Integer.TryParse(Request.QueryString("id"), id)
            hfId.Value = id.ToString()

            If id > 0 Then
                LoadCabinet(id)
                litTitle.Text = "Modifier un cabinet"
                btnDelete.Visible = True
            Else
                litTitle.Text = "Nouveau cabinet"
            End If
        End If
    End Sub

    Private Sub LoadCabinet(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))

        Dim ds As DataSet = ExecuteSQLds("s0902GetCabinetById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ShowMsg("Cabinet introuvable.", isError:=True)
            Return
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        txtNom.Text = S(r("Nom"))
        txtResponsable.Text = S(r("Responsable"))
        txtVille.Text = S(r("Ville"))
        SetDdl(ddlProvince, S(r("Province")))
        txtCourriel.Text = S(r("Courriel"))
        txtTelephone.Text = S(r("Telephone"))
        txtSiteWeb.Text = S(r("SiteWeb"))
        txtDescription.Text = S(r("Description"))
        txtCertifieDepuis.Text = If(r("CertifieDepuis") Is DBNull.Value, "", Convert.ToDateTime(r("CertifieDepuis")).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture))
        cbActive.Checked = (Not r("IsActive") Is DBNull.Value) AndAlso CBool(r("IsActive"))

        Dim langues As New HashSet(Of String)(S(r("Langues")).Split(New Char() {","c}, StringSplitOptions.RemoveEmptyEntries).Select(Function(x) x.Trim().ToUpperInvariant()))
        cbLangFR.Checked = langues.Contains("FR")
        cbLangEN.Checked = langues.Contains("EN")
        cbLangES.Checked = langues.Contains("ES")

        Dim specs As New HashSet(Of String)(S(r("Specialites")).Split(New Char() {","c}, StringSplitOptions.RemoveEmptyEntries).Select(Function(x) x.Trim().ToLowerInvariant()))
        Dim cases As CheckBox() = CasesSpecialites()
        For i As Integer = 0 To Specialites.Length - 1
            cases(i).Checked = specs.Contains(Specialites(i))
        Next
    End Sub

    Private Function CasesSpecialites() As CheckBox()
        Return New CheckBox() {cbSpecTA, cbSpecSOC, cbSpecPAIE, cbSpecCONSTR, cbSpecSANTE}
    End Function

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)

        ' === Validations ===
        Dim nom As String = txtNom.Text.Trim()
        If String.IsNullOrEmpty(nom) Then
            ShowMsg("Le nom du cabinet est obligatoire.", isError:=True)
            Return
        End If
        Dim courriel As String = txtCourriel.Text.Trim()
        If courriel <> "" AndAlso Not Text.RegularExpressions.Regex.IsMatch(courriel, "^[^\s@]+@[^\s@]+\.[^\s@]+$") Then
            ShowMsg("Le courriel n'est pas valide.", isError:=True)
            Return
        End If
        Dim site As String = txtSiteWeb.Text.Trim()
        If site <> "" AndAlso Not (site.StartsWith("http://", StringComparison.OrdinalIgnoreCase) OrElse site.StartsWith("https://", StringComparison.OrdinalIgnoreCase)) Then
            ShowMsg("Le site web doit commencer par https:// (ou http://).", isError:=True)
            Return
        End If
        Dim depuis As Object = DBNull.Value
        If txtCertifieDepuis.Text.Trim() <> "" Then
            Dim d As Date
            If Not Date.TryParseExact(txtCertifieDepuis.Text.Trim(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, d) Then
                ShowMsg("La date « Certifié depuis » n'est pas valide.", isError:=True)
                Return
            End If
            depuis = d
        End If

        Dim langues As New List(Of String)
        If cbLangFR.Checked Then langues.Add("FR")
        If cbLangEN.Checked Then langues.Add("EN")
        If cbLangES.Checked Then langues.Add("ES")
        If langues.Count = 0 Then
            ShowMsg("Cochez au moins une langue parlée.", isError:=True)
            Return
        End If

        Dim specs As New List(Of String)
        Dim cases As CheckBox() = CasesSpecialites()
        For i As Integer = 0 To Specialites.Length - 1
            If cases(i).Checked Then specs.Add(Specialites(i))
        Next

        ' === Sauvegarde ===
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            p.Add(New SqlParameter("@Nom", nom))
            p.Add(New SqlParameter("@Responsable", Nz(txtResponsable.Text)))
            p.Add(New SqlParameter("@Ville", Nz(txtVille.Text)))
            p.Add(New SqlParameter("@Province", ddlProvince.SelectedValue))
            p.Add(New SqlParameter("@Courriel", Nz(courriel)))
            p.Add(New SqlParameter("@Telephone", Nz(txtTelephone.Text)))
            p.Add(New SqlParameter("@SiteWeb", Nz(site)))
            p.Add(New SqlParameter("@Langues", String.Join(",", langues)))
            p.Add(New SqlParameter("@Specialites", If(specs.Count = 0, CType(DBNull.Value, Object), String.Join(",", specs))))
            p.Add(New SqlParameter("@Description", Nz(txtDescription.Text)))
            p.Add(New SqlParameter("@CertifieDepuis", depuis))
            p.Add(New SqlParameter("@IsActive", cbActive.Checked))

            Dim outNew As New SqlParameter("@NewId", SqlDbType.Int)
            outNew.Direction = ParameterDirection.Output
            p.Add(outNew)

            ExecuteSQL("s0903SaveCabinet", p)

            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
                "if (typeof closeWin === 'function') closeWin();", True)

        Catch ex As Exception
            ShowMsg("Erreur : " & ex.Message, isError:=True)
        End Try
    End Sub

    Private Sub btnDelete_Click(sender As Object, e As EventArgs) Handles btnDelete.Click
        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)
        If id <= 0 Then Return

        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        ExecuteSQL("s0904DeleteCabinet", p)

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
            "if (typeof closeWin === 'function') closeWin();", True)
    End Sub

    ' ---------------------------------------------------------------------
    ' Helpers
    ' ---------------------------------------------------------------------
    Private Function S(o As Object) As String
        If o Is Nothing OrElse o Is DBNull.Value Then Return ""
        Return o.ToString()
    End Function

    ''' <summary>Retourne la valeur ou DBNull si vide (pour params NVARCHAR).</summary>
    Private Function Nz(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Return s.Trim()
    End Function

    Private Sub SetDdl(ddl As DropDownList, value As String)
        ddl.ClearSelection()
        Dim item As ListItem = ddl.Items.FindByValue(value)
        If item IsNot Nothing Then item.Selected = True
    End Sub

    Private Sub ShowMsg(text As String, Optional isError As Boolean = False)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "msg " & If(isError, "bad", "ok")
    End Sub

End Class
