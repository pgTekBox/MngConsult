Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports Telerik.Web.UI

Public Class wbfAppointmentEdit
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        ApplyLocalization()

        If Not IsPostBack Then
            If Not isAuthenticated Then
                Response.Redirect("~/wbfLogin.aspx")
                Return
            End If
            LoadCustomers()
            LoadEmployees()
            LoadTypes()      ' ← remplit aussi hfTypeDurations

            Dim id As Integer = 0
            Integer.TryParse(Request.QueryString("id"), id)
            hfId.Value = id.ToString()

            If id > 0 Then
                LoadAppointment(id)
                litTitle.Text = T("Modifier le rendez-vous", "Edit appointment", "Editar la cita")
                btnDelete.Visible = True
            Else
                ' Date suggérée venue de l'agenda
                Dim startStr As String = Request.QueryString("start")
                Dim startDt As Date = Date.Now.Date.AddHours(9)
                If Not String.IsNullOrEmpty(startStr) Then
                    Date.TryParse(startStr, startDt)
                End If
                Dim endDt As Date = startDt.AddHours(1)

                rdpStart.SelectedDate = startDt
                rtpStart.SelectedDate = New Date(1980, 1, 1, startDt.Hour, startDt.Minute, 0)
                rdpEnd.SelectedDate = endDt
                rtpEnd.SelectedDate = New Date(1980, 1, 1, endDt.Hour, endDt.Minute, 0)

                litTitle.Text = T("Nouveau rendez-vous", "New appointment", "Nueva cita")
            End If
        End If
    End Sub

    ''' <summary>Localisation fr/en/es des contrôles serveur (Telerik + boutons).</summary>
    Private Sub ApplyLocalization()
        btnDelete.Text = T("Supprimer", "Delete", "Eliminar")
        btnDelete.OnClientClick = "return confirm('" &
            T("Supprimer ce rendez-vous ?", "Delete this appointment?", "¿Eliminar esta cita?").Replace("'", "\'") & "');"
        lnkBack.Text = "← " & T("Annuler", "Cancel", "Cancelar")
        btnInvoice.Text = T("Facturer", "Invoice", "Facturar")
        btnInvoice.ToolTip = T("Sauvegarder le rendez-vous et créer une facture",
                               "Save the appointment and create an invoice",
                               "Guardar la cita y crear una factura")
        btnSave.Text = T("Enregistrer", "Save", "Guardar")

        Dim sel As String = T("Sélectionner…", "Select…", "Seleccionar…")
        rddlCustomer.DefaultMessage = sel
        rddlEmployee.DefaultMessage = sel
        rddlType.DefaultMessage = sel

        SetItem(rddlStatus, "Planifié", T("Planifié", "Planned", "Planificado"))
        SetItem(rddlStatus, "Confirmé", T("Confirmé", "Confirmed", "Confirmado"))
        SetItem(rddlStatus, "Terminé", T("Terminé", "Completed", "Terminado"))
        SetItem(rddlStatus, "Annulé", T("Annulé", "Cancelled", "Cancelado"))
        SetItem(rddlStatus, "NoShow", T("No-show", "No-show", "No se presentó"))

        SetItem(rddlRecurrence, "", T("Aucune", "None", "Ninguna"))
        SetItem(rddlRecurrence, "FREQ=DAILY;INTERVAL=1", T("Tous les jours", "Every day", "Todos los días"))
        SetItem(rddlRecurrence, "FREQ=WEEKLY;INTERVAL=1", T("Toutes les semaines", "Every week", "Cada semana"))
        SetItem(rddlRecurrence, "FREQ=WEEKLY;INTERVAL=2", T("Toutes les 2 semaines", "Every 2 weeks", "Cada 2 semanas"))
        SetItem(rddlRecurrence, "FREQ=MONTHLY;INTERVAL=1", T("Tous les mois", "Every month", "Cada mes"))
        SetItem(rddlRecurrence, "FREQ=YEARLY;INTERVAL=1", T("Tous les ans", "Every year", "Cada año"))

        SetItem(rddlReminder, "", T("Aucun", "None", "Ninguno"))
        SetItem(rddlReminder, "5", T("5 minutes avant", "5 minutes before", "5 minutos antes"))
        SetItem(rddlReminder, "15", T("15 minutes avant", "15 minutes before", "15 minutos antes"))
        SetItem(rddlReminder, "30", T("30 minutes avant", "30 minutes before", "30 minutos antes"))
        SetItem(rddlReminder, "60", T("1 heure avant", "1 hour before", "1 hora antes"))
        SetItem(rddlReminder, "1440", T("1 jour avant", "1 day before", "1 día antes"))
    End Sub

    Private Shared Sub SetItem(ddl As RadDropDownList, value As String, text As String)
        Dim it = ddl.FindItemByValue(value)
        If it IsNot Nothing Then it.Text = text
    End Sub

    ''' <summary>Sélecteur de langue simple (fr/en/es).</summary>
    Protected Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    ''' <summary>
    ''' AutoPostBack du dropdown Type → recalcule la date/heure de fin selon DurationMinutes
    ''' </summary>
    Private Sub rddlType_SelectedIndexChanged(sender As Object, e As DropDownListEventArgs) Handles rddlType.SelectedIndexChanged
        Dim typeIdStr As String = rddlType.SelectedValue
        If String.IsNullOrEmpty(typeIdStr) Then Return

        Dim typeId As Integer = 0
        If Not Integer.TryParse(typeIdStr, typeId) Then Return

        ' Lire la durée depuis le hidden JSON
        Dim durMin As Integer = GetTypeDurationFromJson(hfTypeDurations.Value, typeIdStr)
        If durMin <= 0 Then Return

        ' Composer la date de début
        If Not rdpStart.SelectedDate.HasValue Then Return
        Dim d As Date = rdpStart.SelectedDate.Value
        Dim hh As Integer = 9, mm As Integer = 0
        If rtpStart.SelectedDate.HasValue Then
            hh = rtpStart.SelectedDate.Value.Hour
            mm = rtpStart.SelectedDate.Value.Minute
        End If
        Dim startDt As New Date(d.Year, d.Month, d.Day, hh, mm, 0)
        Dim endDt As Date = startDt.AddMinutes(durMin)

        rdpEnd.SelectedDate = endDt.Date
        rtpEnd.SelectedDate = New Date(1980, 1, 1, endDt.Hour, endDt.Minute, 0)
    End Sub

    ''' <summary>
    ''' Lit la durée d'un type dans la chaîne JSON sans utiliser un parseur JSON.
    ''' Format attendu : { "1":30, "2":60, "3":15 }
    ''' </summary>
    Private Function GetTypeDurationFromJson(json As String, typeId As String) As Integer
        If String.IsNullOrEmpty(json) OrElse String.IsNullOrEmpty(typeId) Then Return 0

        Dim key As String = """" & typeId & """:"
        Dim idx As Integer = json.IndexOf(key)
        If idx < 0 Then Return 0

        Dim startPos As Integer = idx + key.Length
        Dim sb As New StringBuilder()
        Dim i As Integer = startPos
        While i < json.Length
            Dim ch As Char = json(i)
            If Char.IsDigit(ch) OrElse ch = "-"c Then
                sb.Append(ch)
            Else
                Exit While
            End If
            i += 1
        End While

        Dim n As Integer = 0
        Integer.TryParse(sb.ToString(), n)
        Return n
    End Function

    Private Sub LoadCustomers()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Search", DBNull.Value))
        Dim ds As DataSet = ExecuteSQLds("s0107GetCustomersLookup", p)

        rddlCustomer.Items.Clear()
        rddlCustomer.Items.Add(New DropDownListItem("-- Aucun --", ""))
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                rddlCustomer.Items.Add(New DropDownListItem(r("DisplayName").ToString(), r("Id").ToString()))
            Next
        End If
    End Sub

    Private Sub LoadEmployees()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0106GetEmployeesForAgenda", p)

        rddlEmployee.Items.Clear()
        rddlEmployee.Items.Add(New DropDownListItem("-- Aucun --", ""))
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                rddlEmployee.Items.Add(New DropDownListItem(r("FullName").ToString(), r("Id").ToString()))
            Next
        End If
    End Sub

    ''' <summary>
    ''' Charge la liste des types de RDV ET construit la map JSON
    ''' { "Id" : DurationMinutes, ... } pour le JS côté client.
    ''' </summary>
    Private Sub LoadTypes()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0105GetAppointmentTypes", p)

        rddlType.Items.Clear()
        rddlType.Items.Add(New DropDownListItem("-- Aucun --", ""))

        Dim sb As New StringBuilder()
        sb.Append("{")
        Dim first As Boolean = True

        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows

                Dim idStr As String = r("Id").ToString()
                Dim typeName As String = r("TypeName").ToString()

                ' Affichage avec durée (ex : "Consultation (30 min)")
                Dim durMin As Integer = 0
                If Not (r("DurationMinutes") Is DBNull.Value) Then
                    Integer.TryParse(r("DurationMinutes").ToString(), durMin)
                End If

                Dim displayText As String = typeName
                If durMin > 0 Then
                    displayText &= " (" & durMin.ToString() & " min)"
                End If

                rddlType.Items.Add(New DropDownListItem(displayText, idStr))

                ' Construction du JSON
                If Not first Then sb.Append(",")
                sb.Append("""").Append(idStr).Append(""":").Append(durMin)
                first = False
            Next
        End If

        sb.Append("}")
        hfTypeDurations.Value = sb.ToString()
    End Sub

    Private Sub LoadAppointment(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Id", id))

        Dim ds As DataSet = ExecuteSQLds("s0101GetAppointmentById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

        Dim r As DataRow = ds.Tables(0).Rows(0)

        txtTitle.Text = If(r("Title") Is DBNull.Value, "", r("Title").ToString())
        txtDescription.Text = If(r("Description") Is DBNull.Value, "", r("Description").ToString())

        Dim sDt As Date = CDate(r("StartDateTime"))
        Dim eDt As Date = CDate(r("EndDateTime"))
        rdpStart.SelectedDate = sDt.Date
        rtpStart.SelectedDate = New Date(1980, 1, 1, sDt.Hour, sDt.Minute, 0)
        rdpEnd.SelectedDate = eDt.Date
        rtpEnd.SelectedDate = New Date(1980, 1, 1, eDt.Hour, eDt.Minute, 0)

        cbAllDay.Checked = (Not (r("IsAllDay") Is DBNull.Value)) AndAlso CBool(r("IsAllDay"))
        txtLocation.Text = If(r("Location") Is DBNull.Value, "", r("Location").ToString())

        SafeSelect(rddlCustomer, If(r("CustomerId") Is DBNull.Value, "", r("CustomerId").ToString()))
        SafeSelect(rddlEmployee, If(r("EmployeeId") Is DBNull.Value, "", r("EmployeeId").ToString()))
        SafeSelect(rddlType, If(r("AppointmentTypeId") Is DBNull.Value, "", r("AppointmentTypeId").ToString()))
        SafeSelect(rddlStatus, If(r("Status") Is DBNull.Value, "Planifié", r("Status").ToString()))
        SafeSelect(rddlRecurrence, If(r("RecurrenceRule") Is DBNull.Value, "", r("RecurrenceRule").ToString()))
        SafeSelect(rddlReminder, If(r("ReminderMinutes") Is DBNull.Value, "", r("ReminderMinutes").ToString()))
    End Sub

    Private Sub SafeSelect(ddl As RadDropDownList, value As String)
        ddl.ClearSelection()
        Dim it As DropDownListItem = ddl.FindItemByValue(value)
        If it IsNot Nothing Then it.Selected = True
    End Sub

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click

        Dim newId As Integer = 0
        If Not SaveAppointment(newId) Then Return

        ' Fermer la fenêtre et rafraîchir le parent
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
            "if (typeof closeWin === 'function') closeWin();", True)
    End Sub

    ''' <summary>
    ''' Bouton Facturer : sauvegarde le RDV puis redirige vers la page de facturation
    ''' avec l'AppointmentId en paramètre.
    ''' </summary>
    Private Sub btnInvoice_Click(sender As Object, e As EventArgs) Handles btnInvoice.Click

        Dim newId As Integer = 0
        If Not SaveAppointment(newId) Then Return

        If newId <= 0 Then
            ShowMsg(T("Impossible de récupérer l'identifiant du rendez-vous sauvegardé.", "Unable to retrieve the saved appointment identifier.", "No se pudo recuperar el identificador de la cita guardada."), isError:=True)
            Return
        End If

        ' Redirection dans la même fenêtre vers l'écran de facturation
        ' Id=0 : nouvelle facture, AppointmentId=xxx : pour pré-remplir
        Response.Redirect("wbfInvoiceEdit.aspx?Id=0&AppointmentId=" & newId.ToString())
    End Sub

    ''' <summary>
    ''' Logique commune de sauvegarde du rendez-vous.
    ''' Retourne True si la sauvegarde a réussi, False sinon (validation échouée).
    ''' L'Id du RDV (nouveau ou existant) est retourné dans newId.
    ''' </summary>
    Private Function SaveAppointment(ByRef newId As Integer) As Boolean

        newId = 0

        ' Validations
        If String.IsNullOrWhiteSpace(txtTitle.Text) Then
            ShowMsg(T("Le titre est obligatoire.", "The title is required.", "El título es obligatorio."), isError:=True)
            Return False
        End If
        If Not rdpStart.SelectedDate.HasValue OrElse Not rdpEnd.SelectedDate.HasValue Then
            ShowMsg(T("Les dates de début et de fin sont obligatoires.", "Start and end dates are required.", "Las fechas de inicio y fin son obligatorias."), isError:=True)
            Return False
        End If
        If Not rtpStart.SelectedDate.HasValue OrElse Not rtpEnd.SelectedDate.HasValue Then
            ShowMsg(T("Les heures de début et de fin sont obligatoires.", "Start and end times are required.", "Las horas de inicio y fin son obligatorias."), isError:=True)
            Return False
        End If

        ' Recomposer DateTime complet
        Dim sDate As Date = rdpStart.SelectedDate.Value
        Dim sTime As Date = rtpStart.SelectedDate.Value
        Dim eDate As Date = rdpEnd.SelectedDate.Value
        Dim eTime As Date = rtpEnd.SelectedDate.Value

        Dim startDt As New Date(sDate.Year, sDate.Month, sDate.Day, sTime.Hour, sTime.Minute, 0)
        Dim endDt As New Date(eDate.Year, eDate.Month, eDate.Day, eTime.Hour, eTime.Minute, 0)

        If endDt <= startDt Then
            ShowMsg(T("La date/heure de fin doit être après la date/heure de début.", "The end date/time must be after the start date/time.", "La fecha/hora de fin debe ser posterior a la de inicio."), isError:=True)
            Return False
        End If

        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)

        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Title", txtTitle.Text.Trim()))
        p.Add(New SqlParameter("@Description", If(String.IsNullOrEmpty(txtDescription.Text), CObj(DBNull.Value), txtDescription.Text)))
        p.Add(New SqlParameter("@StartDateTime", startDt))
        p.Add(New SqlParameter("@EndDateTime", endDt))
        p.Add(New SqlParameter("@IsAllDay", cbAllDay.Checked))

        p.Add(New SqlParameter("@CustomerId", IfDbInt(rddlCustomer.SelectedValue)))
        p.Add(New SqlParameter("@EmployeeId", IfDbInt(rddlEmployee.SelectedValue)))
        p.Add(New SqlParameter("@AppointmentTypeId", IfDbInt(rddlType.SelectedValue)))
        p.Add(New SqlParameter("@Status", If(String.IsNullOrEmpty(rddlStatus.SelectedValue), "Planifié", rddlStatus.SelectedValue)))
        p.Add(New SqlParameter("@Location", If(String.IsNullOrEmpty(txtLocation.Text), CObj(DBNull.Value), txtLocation.Text)))
        p.Add(New SqlParameter("@RecurrenceRule", If(String.IsNullOrEmpty(rddlRecurrence.SelectedValue), CObj(DBNull.Value), rddlRecurrence.SelectedValue)))
        p.Add(New SqlParameter("@ReminderMinutes", IfDbInt(rddlReminder.SelectedValue)))
        p.Add(New SqlParameter("@UserName", If(User.Identity.Name, "")))

        Dim outNew As New SqlParameter("@NewId", SqlDbType.Int)
        outNew.Direction = ParameterDirection.Output
        p.Add(outNew)

        ExecuteSQL("s0102SaveAppointment", p)

        ' Récupérer l'Id retourné par la procédure
        If outNew.Value IsNot Nothing AndAlso Not IsDBNull(outNew.Value) Then
            newId = CInt(outNew.Value)
        ElseIf id > 0 Then
            newId = id
        End If

        Return True
    End Function

    Private Sub btnDelete_Click(sender As Object, e As EventArgs) Handles btnDelete.Click
        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)
        If id <= 0 Then Return

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@UserName", If(User.Identity.Name, "")))

        ExecuteSQL("s0103DeleteAppointment", p)

        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
            "if (typeof closeWin === 'function') closeWin();", True)
    End Sub

    Private Sub ShowMsg(text As String, Optional isError As Boolean = False)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "msg " & If(isError, "bad", "ok")
    End Sub

    Private Function IfDbInt(value As String) As Object
        Dim n As Integer
        If String.IsNullOrEmpty(value) OrElse Not Integer.TryParse(value, n) Then
            Return DBNull.Value
        End If
        Return n
    End Function

End Class
