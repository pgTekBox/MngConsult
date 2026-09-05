Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization

''' <summary>
''' Boîte de messages des tâches planifiées : ce que ServiceExecuteur s'apprête
''' à faire et qui attend une décision de l'utilisateur.
'''
''' Une occurrence n'arrive ici que si sa définition porte RequiertApprobation ;
''' le service la met alors en A_APPROUVER (s0742) et refuse de la promouvoir
''' tant que personne n'a tranché. Approuver la remet dans le flux normal,
''' refuser l'annule définitivement.
'''
''' Tout est cadré sur la compagnie de la session : s0743 et s0744 prennent le
''' CompanyGUID et s0744 refuse (erreur 50202) une occurrence qui n'appartient
''' pas à l'appelant.
''' </summary>
Public Class wbfApprobations
    Inherits clsData

#Region "Cycle de vie"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load

        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx")
            Return
        End If

        ApplyLocalization()

        If Not IsPostBack Then
            BuildFilter()
            LoadAll()
        End If
    End Sub

    ''' <summary>Libellés fixes de la page (fr/en/es).</summary>
    Private Sub ApplyLocalization()
        litTitle.Text = T("Tâches à approuver", "Tasks awaiting approval", "Tareas por aprobar")
        litLead.Text = T("L'exécuteur de tâches dépose ici ce qu'il s'apprête à faire lorsque la tâche exige une validation. Rien ne s'exécute tant que vous n'avez pas tranché.",
                         "The task executor drops here what it is about to do whenever a task requires validation. Nothing runs until you decide.",
                         "El ejecutor de tareas deja aquí lo que va a hacer cuando una tarea exige validación. Nada se ejecuta hasta que usted decida.")

        litStatWaitLabel.Text = T("À approuver", "Awaiting approval", "Por aprobar")
        litStatLateLabel.Text = T("Échéance dépassée", "Past due", "Vencidas")

        btnRefresh.Text = "🔄 " & T("Rafraîchir", "Refresh", "Actualizar")

        litEmpty.Text = T("Aucune tâche n'attend de décision.", "No task is waiting for a decision.", "Ninguna tarea espera una decisión.")
        litEmptyHint.Text = T("Une tâche n'apparaît ici que si sa définition demande une approbation.",
                              "A task shows up here only when its definition requires approval.",
                              "Una tarea aparece aquí solo si su definición exige aprobación.")
    End Sub

    ''' <summary>Sélecteur de langue simple (fr/en/es) pour les libellés de la page.</summary>
    Protected Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Sub BuildFilter()
        ddlEtat.Items.Clear()
        ddlEtat.Items.Add(New ListItem(T("À approuver", "Awaiting approval", "Por aprobar"), "A_APPROUVER"))
        ddlEtat.Items.Add(New ListItem(T("Approuvées", "Approved", "Aprobadas"), "APPROUVE"))
        ddlEtat.Items.Add(New ListItem(T("Refusées", "Refused", "Rechazadas"), "REFUSE"))
        ddlEtat.Items.Add(New ListItem(T("Toutes", "All", "Todas"), "TOUTES"))
    End Sub

#End Region

#Region "Libellés utilisés dans le gabarit du Repeater"

    ' Des propriétés plutôt que des <%= %> : ces valeurs sont lues pendant le
    ' DataBind de chaque ligne, une par ligne, et restent traduites.

    Protected ReadOnly Property LblPrevue As String
        Get
            Return T("Prévue le", "Scheduled for", "Prevista el")
        End Get
    End Property

    Protected ReadOnly Property LblCode As String
        Get
            Return T("Code", "Code", "Código")
        End Get
    End Property

    Protected ReadOnly Property LblCategorie As String
        Get
            Return T("Catégorie", "Category", "Categoría")
        End Get
    End Property

    Protected ReadOnly Property LblBeneficiaire As String
        Get
            Return T("Bénéficiaire", "Payee", "Beneficiario")
        End Get
    End Property

    Protected ReadOnly Property LblMontant As String
        Get
            Return T("Montant", "Amount", "Importe")
        End Get
    End Property

    Protected ReadOnly Property LblNotes As String
        Get
            Return T("Notes", "Notes", "Notas")
        End Get
    End Property

    Protected ReadOnly Property LblApprouver As String
        Get
            Return "✔ " & T("Approuver", "Approve", "Aprobar")
        End Get
    End Property

    Protected ReadOnly Property LblRefuser As String
        Get
            Return "✖ " & T("Refuser", "Refuse", "Rechazar")
        End Get
    End Property

    Protected ReadOnly Property LblConfirmApprouver As String
        Get
            Return T("Approuver cette tâche ? Elle sera exécutée à l'heure prévue.",
                     "Approve this task? It will run at the scheduled time.",
                     "¿Aprobar esta tarea? Se ejecutará a la hora prevista.")
        End Get
    End Property

    Protected ReadOnly Property LblConfirmRefuser As String
        Get
            Return T("Refuser cette tâche ? Elle ne s'exécutera pas.",
                     "Refuse this task? It will not run.",
                     "¿Rechazar esta tarea? No se ejecutará.")
        End Get
    End Property

    ''' <summary>
    ''' Les asp:Button de l'ERP sont rendus type="button" : un OnClientClick qui
    ''' commence par « return » avale le __doPostBack et le bouton ne fait rien.
    ''' </summary>
    Protected Function ConfirmJs(question As String) As String
        Return "if (!confirm('" & question.Replace("'", "\'") & "')) { return false; }"
    End Function

#End Region

#Region "Rendu d'une ligne"

    Protected Shared Function Txt(value As Object) As String
        If value Is Nothing OrElse Convert.IsDBNull(value) Then Return ""
        Return Convert.ToString(value).Trim()
    End Function

    Protected Shared Function CardCss(approbation As Object, enRetard As Object) As String
        Select Case Txt(approbation)
            Case "APPROUVE" : Return "done"
            Case "REFUSE" : Return "refused"
            Case "A_APPROUVER" : Return If(Txt(enRetard) = "1", "late", "")
            Case Else : Return ""
        End Select
    End Function

    Protected Function EtatBadge(approbation As Object, enRetard As Object) As String
        Select Case Txt(approbation)
            Case "APPROUVE"
                Return "<span class=""badge badge-ok"">" & Server.HtmlEncode(T("Approuvée", "Approved", "Aprobada")) & "</span>"
            Case "REFUSE"
                Return "<span class=""badge badge-no"">" & Server.HtmlEncode(T("Refusée", "Refused", "Rechazada")) & "</span>"
            Case "A_APPROUVER"
                If Txt(enRetard) = "1" Then
                    Return "<span class=""badge badge-late"">" & Server.HtmlEncode(T("En retard", "Past due", "Vencida")) & "</span>"
                End If
                Return ""
            Case Else
                Return ""
        End Select
    End Function

    ''' <summary>Une méta ne s'affiche que si la donnée existe : sinon la ligne se remplit de vide.</summary>
    Protected Function MetaSiRempli(libelle As String, valeur As Object) As String
        Dim v As String = Txt(valeur)
        If v = "" Then Return ""
        Return "<span>" & Server.HtmlEncode(libelle) & " : <strong>" & Server.HtmlEncode(v) & "</strong></span>"
    End Function

    Protected Function MetaMontant(libelle As String, valeur As Object) As String
        If valeur Is Nothing OrElse Convert.IsDBNull(valeur) Then Return ""
        Dim m As Decimal = Convert.ToDecimal(valeur)
        Return "<span>" & Server.HtmlEncode(libelle) & " : <strong>" &
               m.ToString("C2", CultureInfo.GetCultureInfo("fr-CA")) & "</strong></span>"
    End Function

    Protected Function MetaDecision(approbation As Object, email As Object, quand As Object, motif As Object) As String
        Dim etat As String = Txt(approbation)
        If etat <> "APPROUVE" AndAlso etat <> "REFUSE" Then Return ""

        Dim sb As New Text.StringBuilder()
        Dim qui As String = Txt(email)
        Dim date_ As String = ""
        If quand IsNot Nothing AndAlso Not Convert.IsDBNull(quand) Then
            date_ = Convert.ToDateTime(quand).ToString("yyyy-MM-dd HH:mm")
        End If

        sb.Append("<span>")
        sb.Append(Server.HtmlEncode(T("Décision", "Decision", "Decisión")))
        sb.Append(" : <strong>")
        sb.Append(Server.HtmlEncode(If(qui = "", T("utilisateur inconnu", "unknown user", "usuario desconocido"), qui)))
        If date_ <> "" Then sb.Append(" — " & Server.HtmlEncode(date_))
        sb.Append("</strong></span>")

        Dim m As String = Txt(motif)
        If m <> "" Then
            sb.Append("<span>" & Server.HtmlEncode(T("Motif", "Reason", "Motivo")) & " : <strong>" & Server.HtmlEncode(m) & "</strong></span>")
        End If

        Return sb.ToString()
    End Function

#End Region

#Region "Chargement"

    Private Sub btnRefresh_Click(sender As Object, e As EventArgs) Handles btnRefresh.Click
        LoadAll()
    End Sub

    Private Sub ddlEtat_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlEtat.SelectedIndexChanged
        LoadAll()
    End Sub

    Private Sub LoadAll()
        LoadCount()
        LoadList()
    End Sub

    Private Sub LoadCount()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))

            Dim ds As DataSet = ExecuteSQLds("s0745GetApprobationsCount", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return

            Dim r As DataRow = ds.Tables(0).Rows(0)
            litStatWait.Text = Convert.ToString(r("AApprouver"))
            litStatLate.Text = Convert.ToString(r("EnRetard"))

        Catch ex As Exception
            ShowError(ex.Message)
        End Try
    End Sub

    Private Sub LoadList()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Etat", ddlEtat.SelectedValue))
            p.Add(New SqlParameter("@Top", 200))

            Dim ds As DataSet = ExecuteSQLds("s0743GetApprobations", p)
            Dim dt As DataTable = If(ds Is Nothing OrElse ds.Tables.Count = 0, Nothing, ds.Tables(0))

            rptApprobations.DataSource = dt
            rptApprobations.DataBind()

            pnlEmpty.Visible = (dt Is Nothing OrElse dt.Rows.Count = 0)

        Catch ex As Exception
            ShowError(ex.Message)
        End Try
    End Sub

#End Region

#Region "Décision"

    ''' <summary>
    ''' Approbation ou refus d'une occurrence. Le motif est facultatif à
    ''' l'approbation et utile au refus : c'est lui qui explique, plus tard,
    ''' pourquoi la tâche n'a jamais tourné.
    ''' </summary>
    Private Sub rptApprobations_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptApprobations.ItemCommand

        Dim decision As String
        Select Case e.CommandName
            Case "Approuver" : decision = "APPROUVE"
            Case "Refuser" : decision = "REFUSE"
            Case Else : Return
        End Select

        Dim plannedId As Integer
        If Not Integer.TryParse(Convert.ToString(e.CommandArgument), plannedId) Then Return

        Dim motif As String = ""
        Dim tb As TextBox = TryCast(e.Item.FindControl("txtMotif"), TextBox)
        If tb IsNot Nothing Then motif = tb.Text.Trim()

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@PlannedId", plannedId))
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Decision", decision))
            p.Add(New SqlParameter("@UserId", UserId))
            p.Add(New SqlParameter("@Motif", If(motif = "", CType(DBNull.Value, Object), motif)))

            ExecuteSQL("s0744DeciderApprobation", p)

            ShowAlert(If(decision = "APPROUVE",
                         T("Tâche approuvée : elle sera exécutée à l'heure prévue.",
                           "Task approved: it will run at the scheduled time.",
                           "Tarea aprobada: se ejecutará a la hora prevista."),
                         T("Tâche refusée : elle ne s'exécutera pas.",
                           "Task refused: it will not run.",
                           "Tarea rechazada: no se ejecutará.")))

        Catch ex As SqlException
            ' 50202 : quelqu'un d'autre a déjà tranché, ou l'occurrence n'est
            ' pas celle de cette compagnie. Ce n'est pas une panne.
            If ex.Number = 50202 Then
                ShowError(T("Cette tâche n'attend plus de décision.",
                            "This task is no longer waiting for a decision.",
                            "Esta tarea ya no espera una decisión."))
            Else
                ShowError(ex.Message)
            End If
        Catch ex As Exception
            ShowError(ex.Message)
        End Try

        LoadAll()
    End Sub

#End Region

#Region "Messages"

    Private Sub ShowAlert(message As String)
        litAlert.Text = Server.HtmlEncode(message)
        pnlAlert.Visible = True
        pnlError.Visible = False
    End Sub

    Private Sub ShowError(message As String)
        litError.Text = Server.HtmlEncode(message)
        pnlError.Visible = True
    End Sub

#End Region

End Class
