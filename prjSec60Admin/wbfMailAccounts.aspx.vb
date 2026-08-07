Imports System.Data
Imports System.Data.SqlClient
Imports Telerik.Web.UI
Imports BCrypt.Net

''' <summary>
''' Gestion des comptes de courriel @60sec.ca (console Admin).
'''   - Comptes des compagnies : attribuer, renommer, activer/désactiver la boîte.
'''   - Adresses système : activer/désactiver les boîtes locales non rattachées.
''' Tout passe par des procédures stockées (s0712, s0715-s0718).
''' </summary>
Public Class wbfMailAccounts
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            BindAll()
        End If
    End Sub

    Private Sub BindAll()
        rlvAccounts.Rebind()
        rlvSystem.Rebind()
    End Sub

    ' ---- Sources de données -------------------------------------------------

    Private Sub rlvAccounts_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvAccounts.NeedDataSource
        Dim p As New Collection
        p.Add(New SqlParameter("@Search", tbSearch.Text.Trim()))
        Dim ds As DataSet = ExecuteSQLds("s0715MailAccountsList", p)
        rlvAccounts.DataSource = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), Nothing)
    End Sub

    Private Sub rlvSystem_NeedDataSource(sender As Object, e As RadListViewNeedDataSourceEventArgs) Handles rlvSystem.NeedDataSource
        Dim ds As DataSet = ExecuteSQLds("s0716LocalRecipientsList")
        rlvSystem.DataSource = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), Nothing)
    End Sub

    ' ---- Recherche ----------------------------------------------------------

    Private Sub btnSearch_Click(sender As Object, e As EventArgs) Handles btnSearch.Click
        rlvAccounts.Rebind()
    End Sub

    Private Sub btnClear_Click(sender As Object, e As EventArgs) Handles btnClear.Click
        tbSearch.Text = ""
        rlvAccounts.Rebind()
    End Sub

    ' ---- Commandes sur les comptes de compagnie -----------------------------

    Private Sub rlvAccounts_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvAccounts.ItemCommand
        Dim arg As String = If(e.CommandArgument IsNot Nothing, e.CommandArgument.ToString(), "")
        Select Case e.CommandName
            Case "assign"
                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", New Guid(arg)))
                p.Add(New SqlParameter("@AllowFallback", True))   ' action explicite : repli « abonne » toléré
                ExecuteSQLds("s0712AssignMailbox", p)   ' retourne l'adresse ; on ignore le résultat
            Case "activate"
                SetRecipientActive(arg, True)
            Case "deactivate"
                SetRecipientActive(arg, False)
        End Select
        BindAll()
    End Sub

    ' ---- Commandes sur les adresses système ---------------------------------

    Private Sub rlvSystem_ItemCommand(sender As Object, e As RadListViewCommandEventArgs) Handles rlvSystem.ItemCommand
        Dim email As String = If(e.CommandArgument IsNot Nothing, e.CommandArgument.ToString(), "")
        Select Case e.CommandName
            Case "activate" : SetRecipientActive(email, True)
            Case "deactivate" : SetRecipientActive(email, False)
        End Select
        rlvSystem.Rebind()
    End Sub

    Private Sub SetRecipientActive(email As String, active As Boolean)
        If email = "" Then Return
        Dim p As New Collection
        p.Add(New SqlParameter("@Email", email))
        p.Add(New SqlParameter("@Active", active))
        ExecuteSQL("s0718MailRecipientSetActive", p)
    End Sub

    ' ---- Renommer / attribuer une adresse -----------------------------------

    Private Sub btnSaveRename_Click(sender As Object, e As EventArgs) Handles btnSaveRename.Click
        Dim guid As String = hfRenameGuid.Value
        Dim local As String = tbRenameLocal.Text.Trim()

        If guid = "" Then Return

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", New Guid(guid)))
        p.Add(New SqlParameter("@LocalPart", local))
        Dim ds As DataSet = ExecuteSQLds("s0717MailAccountRename", p)

        Dim ok As Boolean = False
        Dim msg As String = "Erreur inconnue."
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
            Dim r = ds.Tables(0).Rows(0)
            ok = Not IsDBNull(r("Ok")) AndAlso CBool(r("Ok"))
            If Not IsDBNull(r("Msg")) Then msg = r("Msg").ToString()
        End If

        If ok Then
            BindAll()
            ' fermer la fenêtre + rafraîchir déjà fait par le postback
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closeRn", "closeRenameWin();", True)
        Else
            ' réafficher la modale avec le message d'erreur
            lblRenameMsg.Text = msg
            lblRenameMsg.CssClass = "rn-msg err"
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "reopenRn", "openRnModal();", True)
        End If
    End Sub

    ' ---- Mot de passe de la boîte (SmtpLocalRecipient.PasswordHash) ----------

    Private Sub btnSavePwd_Click(sender As Object, e As EventArgs) Handles btnSavePwd.Click
        Dim email As String = hfPwdEmail.Value.Trim()
        Dim pwd As String = tbPwd.Text
        If email = "" Then Return

        If pwd Is Nothing OrElse pwd.Length < 6 Then
            lblPwdMsg.Text = "Le mot de passe doit contenir au moins 6 caractères."
            lblPwdMsg.CssClass = "rn-msg err"
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "reopenPw", "openPwdModal();", True)
            Return
        End If

        Dim hash As String = BCrypt.Net.BCrypt.HashPassword(pwd, 11)
        SetMailboxPassword(email, hash)
        BindAll()
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closePw", "closePwdModal();", True)
    End Sub

    Private Sub btnRemovePwd_Click(sender As Object, e As EventArgs) Handles btnRemovePwd.Click
        Dim email As String = hfPwdEmail.Value.Trim()
        If email = "" Then Return
        SetMailboxPassword(email, "")   ' '' => retire le mot de passe
        BindAll()
        ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closePw", "closePwdModal();", True)
    End Sub

    Private Sub SetMailboxPassword(email As String, hash As String)
        Dim p As New Collection
        p.Add(New SqlParameter("@Email", email))
        p.Add(New SqlParameter("@PasswordHash", If(hash Is Nothing, "", hash)))
        ExecuteSQLMail("s0629SetLocalRecipientPassword", p)   ' BD MailService
    End Sub

    ' ---- Helpers de rendu ---------------------------------------------------

    Public Function GetInitials(name As Object) As String
        Dim nm As String = If(name Is Nothing OrElse name Is DBNull.Value, "", name.ToString().Trim())
        If nm.Length > 0 Then Return nm.Substring(0, 1).ToUpper()
        Return "?"
    End Function

    Public Function StateClass(hasMailbox As Object, isActive As Object) As String
        If Not ToBool(hasMailbox) Then Return "none"
        Return If(ToBool(isActive), "active", "inactive")
    End Function

    Public Function StateLabel(hasMailbox As Object, isActive As Object) As String
        If Not ToBool(hasMailbox) Then Return "Aucune"
        Return If(ToBool(isActive), "Actif", "Inactif")
    End Function

    Public Function FormatDate(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value Then Return "—"
        Dim d As DateTime
        If DateTime.TryParse(v.ToString(), d) Then Return d.ToString("yyyy-MM-dd")
        Return v.ToString()
    End Function

    ''' <summary>Échappe une chaîne pour l'insérer dans un littéral JS entre apostrophes.</summary>
    Public Function JsEsc(v As Object) As String
        Dim s As String = If(v Is Nothing OrElse v Is DBNull.Value, "", v.ToString())
        s = s.Replace("\", "\\").Replace("'", "\'").Replace(ChrW(34), "\""")
        s = s.Replace(vbCr, "").Replace(vbLf, "")
        Return s
    End Function

    Private Function ToBool(v As Object) As Boolean
        If v Is Nothing OrElse v Is DBNull.Value Then Return False
        Dim b As Boolean
        If Boolean.TryParse(v.ToString(), b) Then Return b
        Return v.ToString() = "1"
    End Function

End Class
