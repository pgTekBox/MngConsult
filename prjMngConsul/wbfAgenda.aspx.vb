Imports System.Data
Imports System.Data.SqlClient
Imports Newtonsoft.Json
Imports Telerik.Web.UI

Public Class wbfAgenda
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        rwAppointment.Title = T("Rendez-vous", "Appointment", "Cita")
        ApplyLocalization()

        If Not IsPostBack Then

            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            ' Date courante par défaut
            hfCurrentDate.Value = Date.Now.ToString("yyyy-MM-dd HH:mm:ss")
            hfViewMode.Value = "month"
            LoadAll()
        End If
    End Sub

    ''' <summary>
    ''' Libellés de la barre d'outils et de l'entête du mois.
    '''
    ''' Ils passent par des Literal et non par des &lt;%= %&gt; : la page porte un
    ''' RadAjaxPanel, et Telerik déplace l'UpdatePanel dans la collection de
    ''' contrôles du conteneur. Un seul bloc de code dans ce conteneur fait
    ''' échouer ce déplacement (« La collection Controls ne peut pas être
    ''' modifiée »). Les seuls &lt;%= %&gt; restants sont dans le RadCodeBlock du
    ''' bas de page, qui est justement là pour ça.
    ''' </summary>
    Private Sub ApplyLocalization()
        litTipPrev.Text = T("Précédent", "Previous", "Anterior")
        litTipNext.Text = T("Suivant", "Next", "Siguiente")
        litTipToday.Text = T("Aujourd'hui", "Today", "Hoy")

        litViewMonth.Text = T("Mois", "Month", "Mes")
        litViewWeek.Text = T("Semaine", "Week", "Semana")
        litViewDay.Text = T("Jour", "Day", "Día")

        litAddAppt.Text = T("Rendez-vous", "Appointment", "Cita")
        litEmployees.Text = T("Employés", "Employees", "Empleados")

        litDow1.Text = T("Lun", "Mon", "Lun")
        litDow2.Text = T("Mar", "Tue", "Mar")
        litDow3.Text = T("Mer", "Wed", "Mié")
        litDow4.Text = T("Jeu", "Thu", "Jue")
        litDow5.Text = T("Ven", "Fri", "Vie")
        litDow6.Text = T("Sam", "Sat", "Sáb")
        litDow7.Text = T("Dim", "Sun", "Dom")
    End Sub

    ''' <summary>Sélecteur de langue simple (fr/en/es) pour les libellés de la page.</summary>
    Protected Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    ''' <summary>Locale BCP-47 pour toLocaleDateString côté JS.</summary>
    Protected Function AgLocale() As String
        Select Case CurrentLang
            Case "en" : Return "en-CA"
            Case "es" : Return "es-ES"
            Case Else : Return "fr-CA"
        End Select
    End Function

    ''' <summary>
    ''' Handler unique pour les requêtes Ajax du RadAjaxManager.
    ''' Appelé depuis le JS via : $find('ram1').ajaxRequest('refresh' | 'move')
    ''' </summary>
    Protected Sub RAP1_AjaxRequest(sender As Object, e As AjaxRequestEventArgs) Handles RAP1.AjaxRequest
        Select Case e.Argument
            Case "refresh"
                LoadAll()
            Case "move"
                ProcessMove()
                LoadAll()
            Case Else
                LoadAll()
        End Select
    End Sub

    ''' <summary>
    ''' Traite un drag&drop : déplace le RDV dans la BD
    ''' Format hfMoveData : "Id|Start|End"
    ''' </summary>
    Private Sub ProcessMove()
        Dim raw As String = hfMoveData.Value
        If String.IsNullOrEmpty(raw) Then Return

        Dim parts() As String = raw.Split("|"c)
        If parts.Length < 3 Then Return

        Dim id As Integer = 0
        Dim dStart, dEnd As Date
        If Not Integer.TryParse(parts(0), id) Then Return
        If Not Date.TryParse(parts(1), dStart) Then Return
        If Not Date.TryParse(parts(2), dEnd) Then Return

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@StartDateTime", dStart))
        p.Add(New SqlParameter("@EndDateTime", dEnd))
        p.Add(New SqlParameter("@UserName", If(User.Identity.Name, "")))

        ExecuteSQL("s0104MoveAppointment", p)

        hfMoveData.Value = ""
    End Sub

    ''' <summary>
    ''' Charge events + employés + types selon la vue + date courante.
    ''' </summary>
    Private Sub LoadAll()
        Dim view As String = If(hfViewMode.Value, "month").ToLower()
        Dim current As Date = Date.Now
        Date.TryParse(hfCurrentDate.Value, current)

        ' Calcul de la plage selon la vue
        Dim rangeStart, rangeEnd As Date
        Select Case view
            Case "month"
                Dim first = New Date(current.Year, current.Month, 1)
                ' on prend une fenêtre élargie pour couvrir le grid 6x7
                rangeStart = first.AddDays(-7)
                rangeEnd = first.AddMonths(1).AddDays(7)
            Case "week"
                Dim sow = StartOfWeek(current)
                rangeStart = sow
                rangeEnd = sow.AddDays(7)
            Case "day"
                rangeStart = current.Date
                rangeEnd = current.Date.AddDays(1)
            Case Else
                rangeStart = current.AddDays(-15)
                rangeEnd = current.AddDays(15)
        End Select

        ' === Events ===
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@StartDate", rangeStart))
        p.Add(New SqlParameter("@EndDate", rangeEnd))
        p.Add(New SqlParameter("@EmployeeId", DBNull.Value))

        Dim ds As DataSet = ExecuteSQLds("s0100GetAppointmentsByRange", p)
        Dim eventsList As New List(Of Object)

        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                eventsList.Add(New With {
                    .Id = CInt(r("Id")),
                    .Title = If(r("Title") Is DBNull.Value, "", r("Title").ToString()),
                    .Description = If(r("Description") Is DBNull.Value, "", r("Description").ToString()),
                    .Start = CDate(r("StartDateTime")).ToString("yyyy-MM-ddTHH:mm:ss"),
                    .[End] = CDate(r("EndDateTime")).ToString("yyyy-MM-ddTHH:mm:ss"),
                    .IsAllDay = (Not (r("IsAllDay") Is DBNull.Value) AndAlso CBool(r("IsAllDay"))),
                    .CustomerId = If(r("CustomerId") Is DBNull.Value, Nothing, CInt(r("CustomerId"))),
                    .CustomerName = If(r("CustomerName") Is DBNull.Value, "", r("CustomerName").ToString()),
                    .EmployeeId = If(r("EmployeeId") Is DBNull.Value, Nothing, CInt(r("EmployeeId"))),
                    .EmployeeName = If(r("EmployeeName") Is DBNull.Value, "", r("EmployeeName").ToString()),
                    .TypeName = If(r("TypeName") Is DBNull.Value, "", r("TypeName").ToString()),
                    .Color = If(r("ColorHex") Is DBNull.Value, "#2563eb", r("ColorHex").ToString()),
                    .Status = If(r("Status") Is DBNull.Value, "", r("Status").ToString()),
                    .Location = If(r("Location") Is DBNull.Value, "", r("Location").ToString()),
                    .ReminderMinutes = If(r("ReminderMinutes") Is DBNull.Value, Nothing, CInt(r("ReminderMinutes")))
                })
            Next
        End If

        hfEvents.Value = JsonConvert.SerializeObject(eventsList)

        ' === Employés ===
        Dim pe As New Collection
        pe.Add(New SqlParameter("@CompanyGUID", Company))
        Dim dsEmp As DataSet = ExecuteSQLds("s0106GetEmployeesForAgenda", pe)
        Dim empList As New List(Of Object)
        If dsEmp IsNot Nothing AndAlso dsEmp.Tables.Count > 0 Then
            For Each r As DataRow In dsEmp.Tables(0).Rows
                empList.Add(New With {
                    .Id = CInt(r("Id")),
                    .FullName = r("FullName").ToString(),
                    .ColorHex = If(r("ColorHex") Is DBNull.Value, "#06b6d4", r("ColorHex").ToString())
                })
            Next
        End If
        hfEmployees.Value = JsonConvert.SerializeObject(empList)

        ' === Types ===
        Dim pt As New Collection
        pt.Add(New SqlParameter("@CompanyGUID", Company))
        Dim dsT As DataSet = ExecuteSQLds("s0105GetAppointmentTypes", pt)
        Dim typesList As New List(Of Object)
        If dsT IsNot Nothing AndAlso dsT.Tables.Count > 0 Then
            For Each r As DataRow In dsT.Tables(0).Rows
                typesList.Add(New With {
                    .Id = CInt(r("Id")),
                    .TypeName = r("TypeName").ToString(),
                    .ColorHex = If(r("ColorHex") Is DBNull.Value, "#2563eb", r("ColorHex").ToString())
                })
            Next
        End If
        hfTypes.Value = JsonConvert.SerializeObject(typesList)
    End Sub

    Private Function StartOfWeek(d As Date) As Date
        Dim diff As Integer = (CInt(d.DayOfWeek) + 6) Mod 7
        Return d.Date.AddDays(-diff)
    End Function

End Class
