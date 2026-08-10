Imports System.Data
Imports System.Data.SqlClient
Imports System.Text.RegularExpressions

''' <summary>
''' Creation / edition d'un fournisseur (beneficiaire) de l'abonne connecte,
''' incluant ses coordonnees bancaires (institution / transit / compte)
''' requises pour l'EFT (credit CPA-005). Isolation par AbonneId.
''' wbfFournisseur.aspx = creation ; ?id=N = edition.
''' </summary>
Public Class wbfFournisseur
    Inherits clsData

    Protected WithEvents litTitle As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litMeta As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents ddlType As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents ddlStatut As Global.System.Web.UI.WebControls.DropDownList
    Protected WithEvents tbNom As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbRef As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbEmail As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbTel As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbAdr1 As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbVille As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbProv As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbCP As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbInst As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbTransit As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbAccount As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnSave As Global.System.Web.UI.WebControls.Button

    Private ReadOnly Property EditId() As Integer
        Get
            Dim v As Integer
            Integer.TryParse(Request.QueryString("id"), v)
            Return v
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack AndAlso EditId > 0 Then
            LoadRecord(EditId)
        End If
    End Sub

    Private Function LoadRecord(id As Integer) As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            Dim t As DataTable = ExecuteSQLds("s0036GetFournisseur", p).Tables(0)
            If t.Rows.Count = 0 Then
                ShowError("Fournisseur introuvable.") : Return False
            End If
            Dim r As DataRow = t.Rows(0)
            If IsDBNull(r("AbonneId")) OrElse CInt(r("AbonneId")) <> AbonneId Then
                Response.Redirect("~/wbfFournisseurs.aspx") : Return False
            End If

            litTitle.Text = Server.HtmlEncode(V(r, "Nom"))
            litMeta.Text = "Créé le " & FormatDate(r("CreatedUtc"))
            SetDdl(ddlType, V(r, "TypeFournisseur"))
            SetDdl(ddlStatut, V(r, "Statut"))
            tbNom.Text = V(r, "Nom")
            tbRef.Text = V(r, "ReferenceExterne")
            tbEmail.Text = V(r, "CourrielContact")
            tbTel.Text = V(r, "Telephone")
            tbAdr1.Text = V(r, "Adresse1")
            tbVille.Text = V(r, "Ville")
            tbProv.Text = V(r, "Province")
            tbCP.Text = V(r, "CodePostal")
            tbInst.Text = V(r, "BankInstitution")
            tbTransit.Text = V(r, "BankTransit")
            tbAccount.Text = V(r, "BankAccount")
            Return True
        Catch ex As Exception
            ShowError("Impossible de charger le fournisseur. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN Fourn load: " & ex.Message)
            Return False
        End Try
    End Function

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)
        Dim nom As String = If(tbNom.Text, "").Trim()
        If nom.Length = 0 Then
            ShowError("Le nom du fournisseur est obligatoire.") : Return
        End If

        Dim inst As String = If(tbInst.Text, "").Trim()
        Dim transit As String = If(tbTransit.Text, "").Trim()
        Dim account As String = If(tbAccount.Text, "").Trim()
        Dim bankErr As String = ValidateBank(inst, transit, account)
        If bankErr IsNot Nothing Then
            ShowError(bankErr) : Return
        End If

        If EditId > 0 AndAlso Not BelongsToAbonne(EditId) Then
            Response.Redirect("~/wbfFournisseurs.aspx") : Return
        End If

        Try
            Dim p As New Collection
            Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = EditId}
            p.Add(outId)
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@TypeFournisseur", ddlType.SelectedValue))
            p.Add(New SqlParameter("@Nom", nom))
            p.Add(New SqlParameter("@ReferenceExterne", NzOrNull(tbRef.Text)))
            p.Add(New SqlParameter("@CourrielContact", NzOrNull(tbEmail.Text)))
            p.Add(New SqlParameter("@Telephone", NzOrNull(tbTel.Text)))
            p.Add(New SqlParameter("@Adresse1", NzOrNull(tbAdr1.Text)))
            p.Add(New SqlParameter("@Ville", NzOrNull(tbVille.Text)))
            p.Add(New SqlParameter("@Province", NzOrNull(tbProv.Text)))
            p.Add(New SqlParameter("@CodePostal", NzOrNull(tbCP.Text)))
            p.Add(New SqlParameter("@Statut", ddlStatut.SelectedValue))
            p.Add(New SqlParameter("@BankInstitution", NzOrNull(inst)))
            p.Add(New SqlParameter("@BankTransit", NzOrNull(transit)))
            p.Add(New SqlParameter("@BankAccount", NzOrNull(account)))
            ExecuteSQLds("s0037SaveFournisseur", p)

            Response.Redirect("~/wbfFournisseurs.aspx?saved=1")
        Catch sqlEx As SqlException When sqlEx.Number = 2601 OrElse sqlEx.Number = 2627
            ShowError("Cette référence externe est déjà utilisée pour un autre fournisseur.")
        Catch ex As Exception
            ShowError("Enregistrement impossible. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("ABN Fourn save: " & ex.Message)
        End Try
    End Sub

    Private Function ValidateBank(inst As String, transit As String, account As String) As String
        Dim anyFilled As Boolean = (inst.Length > 0 OrElse transit.Length > 0 OrElse account.Length > 0)
        If Not anyFilled Then Return Nothing
        If inst.Length = 0 OrElse transit.Length = 0 OrElse account.Length = 0 Then
            Return "Coordonnées bancaires incomplètes : renseignez institution, transit ET compte (ou laissez les trois vides)."
        End If
        If Not Regex.IsMatch(inst, "^\d{3}$") Then Return "L'institution doit compter exactement 3 chiffres."
        If Not Regex.IsMatch(transit, "^\d{5}$") Then Return "Le transit doit compter exactement 5 chiffres."
        If Not Regex.IsMatch(account, "^\d{1,12}$") Then Return "Le n° de compte doit contenir de 1 à 12 chiffres."
        Return Nothing
    End Function

    Private Function BelongsToAbonne(id As Integer) As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            Dim t As DataTable = ExecuteSQLds("s0036GetFournisseur", p).Tables(0)
            If t.Rows.Count = 0 Then Return False
            Return Not IsDBNull(t.Rows(0)("AbonneId")) AndAlso CInt(t.Rows(0)("AbonneId")) = AbonneId
        Catch
            Return False
        End Try
    End Function

    Private Sub SetDdl(ddl As DropDownList, value As String)
        Dim it As ListItem = ddl.Items.FindByValue(value)
        If it IsNot Nothing Then
            ddl.ClearSelection()
            it.Selected = True
        End If
    End Sub

    Private Function V(r As DataRow, col As String) As String
        If IsDBNull(r(col)) Then Return ""
        Return r(col).ToString()
    End Function

    Private Function NzOrNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = Server.HtmlEncode(msg)
    End Sub

End Class
