Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Édition d'un employé (ouverte dans une RadWindow depuis wbfEmployees).
''' Page autonome ; se ferme via closeWin() après enregistrement.
''' </summary>
Public Class wbfEmployeeEdit
    Inherits clsData

    Private ReadOnly Property EmployeeId As Integer
        Get
            Dim v As Integer = 0
            Integer.TryParse(Request.QueryString("id"), v)
            Return v
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        btnSave.Text = L("save")

        If Not IsPostBack Then
            litTitle.Text = If(EmployeeId > 0, L("editTitle"), L("addTitle"))
            If EmployeeId > 0 Then LoadEmployee() Else SetMailboxDisplay("")
        End If
    End Sub

    Private Sub LoadEmployee()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Id", EmployeeId))
        Dim ds As DataSet = ExecuteSQLds("s0720GetEmployeeById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ShowMsg(L("notFound"))
            Return
        End If
        Dim r = ds.Tables(0).Rows(0)
        txtNumber.Text = S(r("EmployeeNumber"))
        txtDisplay.Text = S(r("DisplayName"))
        txtFirst.Text = S(r("FirstName"))
        txtLast.Text = S(r("LastName"))
        txtJob.Text = S(r("JobTitle"))
        txtDept.Text = S(r("Department"))
        txtEmail.Text = S(r("Email"))
        txtPhone.Text = S(r("Phone"))
        txtMobile.Text = S(r("Mobile"))
        txtCity.Text = S(r("City"))
        If Not IsDBNull(r("HireDate")) Then txtHire.Text = CDate(r("HireDate")).ToString("yyyy-MM-dd")
        txtStatus.Text = S(r("EmploymentStatus"))
        txtType.Text = S(r("EmploymentType"))
        txtColor.Text = If(S(r("ColorHex")) = "", "#2563eb", S(r("ColorHex")))
        chkActive.Checked = IsDBNull(r("Active")) OrElse CBool(r("Active"))
        SetMailboxDisplay(S(r("Sec60Email")))
    End Sub

    Private Sub SetMailboxDisplay(box As String)
        If box = "" Then
            litMailbox.Text = "<span class=""box-none"">" & Server.HtmlEncode(L("boxNone")) & "</span>"
        Else
            litMailbox.Text = "<span class=""mono"">" & Server.HtmlEncode(box) & "</span> — " & Server.HtmlEncode(L("boxManage"))
        End If
    End Sub

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        If Not isAuthenticated Then Return

        ' validation minimale : un nom (affiché OU prénom/nom)
        If txtDisplay.Text.Trim() = "" AndAlso txtFirst.Text.Trim() = "" AndAlso txtLast.Text.Trim() = "" Then
            ShowMsg(L("needName"))
            Return
        End If

        Dim color As String = txtColor.Text.Trim()
        If Not System.Text.RegularExpressions.Regex.IsMatch(color, "^#[0-9A-Fa-f]{6}$") Then color = "#2563eb"

        Dim p As New Collection
        p.Add(New SqlParameter("@Id", EmployeeId))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@EmployeeNumber", Nz(txtNumber.Text)))
        p.Add(New SqlParameter("@FirstName", Nz(txtFirst.Text)))
        p.Add(New SqlParameter("@LastName", Nz(txtLast.Text)))
        p.Add(New SqlParameter("@DisplayName", Nz(txtDisplay.Text)))
        p.Add(New SqlParameter("@JobTitle", Nz(txtJob.Text)))
        p.Add(New SqlParameter("@Department", Nz(txtDept.Text)))
        p.Add(New SqlParameter("@Email", Nz(txtEmail.Text)))
        p.Add(New SqlParameter("@Phone", Nz(txtPhone.Text)))
        p.Add(New SqlParameter("@Mobile", Nz(txtMobile.Text)))
        p.Add(New SqlParameter("@City", Nz(txtCity.Text)))
        p.Add(New SqlParameter("@HireDate", NzDate(txtHire.Text)))
        p.Add(New SqlParameter("@EmploymentStatus", Nz(txtStatus.Text)))
        p.Add(New SqlParameter("@EmploymentType", Nz(txtType.Text)))
        p.Add(New SqlParameter("@Active", chkActive.Checked))
        p.Add(New SqlParameter("@ColorHex", color))
        p.Add(New SqlParameter("@UserId", CObj(DBNull.Value)))
        Dim outId As New SqlParameter("@NewId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outId)

        Try
            ExecuteSQL("s0721SaveEmployee", p)
            ' fermer la fenêtre puis rafraîchir la liste (via OnClientClose)
            Dim script As String = "function fw(){closeWin(); Sys.Application.remove_load(fw);}Sys.Application.add_load(fw);"
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closeWin", script, True)
        Catch ex As Exception
            ShowMsg(L("saveError") & ex.Message)
        End Try
    End Sub

    ' ---- Helpers ------------------------------------------------------------

    Private Sub ShowMsg(msg As String)
        pnlMsg.Visible = True
        litMsg.Text = Server.HtmlEncode(msg)
    End Sub

    Private Shared Function S(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return o.ToString()
    End Function

    Private Shared Function Nz(s As String) As Object
        If String.IsNullOrWhiteSpace(s) Then Return DBNull.Value
        Return s.Trim()
    End Function

    Private Shared Function NzDate(s As String) As Object
        Dim d As DateTime
        If DateTime.TryParse(s, d) Then Return d
        Return DBNull.Value
    End Function

    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Employé — 60Sec-AI", "Employee — 60Sec-AI", "Empleado — 60Sec-AI")
            Case "addTitle" : Return Choose3(lang, "Ajouter un employé", "Add an employee", "Agregar un empleado")
            Case "editTitle" : Return Choose3(lang, "Modifier un employé", "Edit an employee", "Editar un empleado")
            Case "empNumber" : Return Choose3(lang, "Numéro", "Number", "Número")
            Case "displayName" : Return Choose3(lang, "Nom affiché", "Display name", "Nombre visible")
            Case "firstName" : Return Choose3(lang, "Prénom", "First name", "Nombre")
            Case "lastName" : Return Choose3(lang, "Nom", "Last name", "Apellido")
            Case "jobTitle" : Return Choose3(lang, "Poste", "Job title", "Puesto")
            Case "department" : Return Choose3(lang, "Département", "Department", "Departamento")
            Case "extEmail" : Return Choose3(lang, "Courriel externe (pour réinitialiser le mot de passe @60sec.ca)", "External email (to reset the @60sec.ca password)", "Correo externo (para restablecer la contraseña @60sec.ca)")
            Case "phone" : Return Choose3(lang, "Téléphone", "Phone", "Teléfono")
            Case "mobile" : Return Choose3(lang, "Mobile", "Mobile", "Móvil")
            Case "city" : Return Choose3(lang, "Ville", "City", "Ciudad")
            Case "hireDate" : Return Choose3(lang, "Date d'embauche", "Hire date", "Fecha de contratación")
            Case "status" : Return Choose3(lang, "Statut d'emploi", "Employment status", "Estado laboral")
            Case "type" : Return Choose3(lang, "Type d'emploi", "Employment type", "Tipo de empleo")
            Case "color" : Return Choose3(lang, "Couleur (agenda)", "Color (agenda)", "Color (agenda)")
            Case "active" : Return Choose3(lang, "Actif", "Active", "Activo")
            Case "activeYes" : Return Choose3(lang, "Employé actif", "Active employee", "Empleado activo")
            Case "mailbox" : Return Choose3(lang, "Boîte @60sec.ca", "@60sec.ca mailbox", "Buzón @60sec.ca")
            Case "boxNone" : Return Choose3(lang, "Aucune boîte — attribuez-la depuis la liste des employés.", "No mailbox — assign it from the employee list.", "Sin buzón — asígnelo desde la lista de empleados.")
            Case "boxManage" : Return Choose3(lang, "gérez le mot de passe depuis la liste des employés.", "manage the password from the employee list.", "gestione la contraseña desde la lista de empleados.")
            Case "cancel" : Return Choose3(lang, "Annuler", "Cancel", "Cancelar")
            Case "save" : Return Choose3(lang, "Enregistrer", "Save", "Guardar")
            Case "needName" : Return Choose3(lang, "Indiquez au moins un nom.", "Enter at least a name.", "Indique al menos un nombre.")
            Case "notFound" : Return Choose3(lang, "Employé introuvable.", "Employee not found.", "Empleado no encontrado.")
            Case "saveError" : Return Choose3(lang, "Erreur lors de l'enregistrement : ", "Error while saving: ", "Error al guardar: ")
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

End Class
