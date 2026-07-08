Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports Telerik.Web.UI

Public Class HeaderUser
    Inherits clsDataUC    ' ou System.Web.UI.UserControl si vous préférez

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

        ' Si pas connecté, on n'affiche rien (le filtre Global.asax devrait déjà rediriger)
        If Not isAuthenticated Then
            Me.Visible = False
            Return
        End If

        ' Le sélecteur de langue doit être rendu à chaque chargement (aussi au postback).
        BuildLangSwitcher()

        If IsPostBack Then Return

        BindUserInfo()
        BindCompanies()

    End Sub

    ''' <summary>
    ''' Construit le sélecteur FR / EN / ES. Chaque lien recharge la page courante
    ''' avec ?lang=xx (en conservant les autres paramètres). La langue courante est
    ''' surlignée. Les pages localisées (login, inscription, activation, paiement,
    ''' profil…) lisent ce paramètre ?lang.
    ''' </summary>
    Private Sub BuildLangSwitcher()
        Dim cur As String = If(Request.QueryString("lang"), "").Trim().ToLowerInvariant()
        If cur <> "en" AndAlso cur <> "es" Then cur = "fr"

        ' Paramètres existants (sauf lang), à préserver dans le lien.
        Dim extra As New StringBuilder()
        For Each k As String In Request.QueryString.AllKeys
            If k Is Nothing Then Continue For
            If String.Equals(k, "lang", StringComparison.OrdinalIgnoreCase) Then Continue For
            extra.Append("&"c)
            extra.Append(System.Web.HttpUtility.UrlEncode(k))
            extra.Append("="c)
            extra.Append(System.Web.HttpUtility.UrlEncode(Request.QueryString(k)))
        Next

        Dim basePath As String = Request.Url.AbsolutePath
        Dim codes() As String = {"fr", "en", "es"}
        Dim labels() As String = {"FR", "EN", "ES"}

        Dim sb As New StringBuilder()
        For i As Integer = 0 To codes.Length - 1
            Dim href As String = basePath & "?lang=" & codes(i) & extra.ToString()
            Dim cls As String = If(codes(i) = cur, "active", "")
            sb.Append("<a class=""" & cls & """ href=""" & href & """>" & labels(i) & "</a>")
        Next
        litLang.Text = sb.ToString()
    End Sub

    ''' <summary>
    ''' Affiche le nom complet, les initiales et le rôle.
    ''' </summary>
    Private Sub BindUserInfo()


        ' Nom affiché
        Dim fullName As String = (UserFirstName & " " & UserLastName).Trim()
        If String.IsNullOrEmpty(fullName) Then fullName = UserEmail
        litUserName.Text = fullName

        ' Initiales pour l'avatar
        litInitials.Text = ComputeInitials(UserFirstName, UserLastName, UserEmail)

        ' Rôle


        If IsAccountant AndAlso isAdmin Then
            litUserRole.Text = "Comptable · Admin"
        ElseIf IsAccountant Then
            litUserRole.Text = "Comptable"
        ElseIf isAdmin Then
            litUserRole.Text = "Administrateur"
        Else
            litUserRole.Text = "Utilisateur"
        End If
    End Sub

    Private Function ComputeInitials(firstName As String, lastName As String, email As String) As String
        Dim fn As String = If(firstName, "").Trim()
        Dim ln As String = If(lastName, "").Trim()

        If fn.Length > 0 AndAlso ln.Length > 0 Then
            Return (fn.Substring(0, 1) & ln.Substring(0, 1)).ToUpper()
        ElseIf fn.Length > 0 Then
            Return fn.Substring(0, 1).ToUpper()
        ElseIf Not String.IsNullOrEmpty(email) Then
            Return email.Substring(0, 1).ToUpper()
        End If
        Return "?"
    End Function

    ''' <summary>
    ''' Charge les compagnies accessibles à l'utilisateur.
    ''' Affiche un dropdown si > 1, un simple label sinon.
    ''' </summary>
    Private Sub BindCompanies()


        ' s0210GetUserCompanies attend l'EMAIL (WHERE email = @UserId), pas l'Id entier.
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0210GetUserCompanies", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ' Aucune compagnie : ne rien afficher
            pnlCompanyPicker.Visible = False
            pnlCompanyLabel.Visible = False

            Return
        End If

        Dim dt As DataTable = ds.Tables(0)


        If dt.Rows.Count = 1 Then
            ' Une seule compagnie : label simple
            Dim r As DataRow = dt.Rows(0)
            litCompanyName.Text = r("Name").ToString()
            pnlCompanyLabel.Visible = True
            pnlCompanyPicker.Visible = False

            ' Sécurité : forcer la session à cette compagnie
            Company = CType(r("CompanyGUID"), Guid)

        Else
            ' Plusieurs compagnies : dropdown
            ' ⚠ IMPORTANT : on désactive AutoPostBack pendant le bind
            ' pour éviter qu'un changement programmatique de SelectedIndex
            ' ne déclenche SelectedIndexChanged.

            'Dim previousAutoPostBack As Boolean = ddlCompany.AutoPostBack
            'ddlCompany.AutoPostBack = False



            ' Plusieurs compagnies : dropdown
            ddlCompany.Items.Clear()
            For Each r As DataRow In dt.Rows
                Dim sguid As String = r("CompanyGUID").ToString().ToUpper()
                Dim name As String = r("Name").ToString()
                Dim item As New ListItem(name, sguid)
                If sguid = Company.ToString.ToUpper Then item.Selected = True
                ddlCompany.Items.Add(item)
            Next

            ' Si la compagnie en session n'est pas dans la liste, sélectionner la 1ère
            If ddlCompany.SelectedIndex < 0 AndAlso ddlCompany.Items.Count > 0 Then
                ddlCompany.SelectedIndex = 0
                Company = New Guid(ddlCompany.Items(0).Value)

            End If

            If Company.ToString = "00000000-0000-0000-0000-000000000000" Then
                ddlCompany.SelectedIndex = 0
                Company = New Guid(ddlCompany.Items(0).Value)
            End If




            'ddlCompany.AutoPostBack = previousAutoPostBack
            pnlCompanyPicker.Visible = True
            pnlCompanyLabel.Visible = False
        End If
    End Sub

    ''' <summary>
    ''' Quand l'utilisateur change de compagnie via le dropdown :
    ''' - Vérifier qu'il y a bien accès (sécurité côté serveur)
    ''' - Mettre à jour la session
    ''' - Rediriger vers Default.aspx
    ''' </summary>
    Private Sub ddlCompany_SelectedIndexChanged(sender As Object, e As EventArgs) Handles ddlCompany.SelectedIndexChanged

        Dim newGuidStr As String = ddlCompany.SelectedValue
        If String.IsNullOrEmpty(newGuidStr) Then Return

        Dim newGuid As Guid
        If Not Guid.TryParse(newGuidStr, newGuid) Then Return

        ' Si c'est déjà la compagnie courante, ne rien faire (évite les redirections inutiles)
        If Company = newGuid Then Return


        ' Vérifier l'accès côté serveur
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserId))
        p.Add(New SqlParameter("@CompanyGUID", newGuid))

        Dim outAccess As New SqlParameter("@HasAccess", SqlDbType.Bit)
        outAccess.Direction = ParameterDirection.Output
        p.Add(outAccess)

        ExecuteSQL("s0211ValidateCompanyAccess", p)

        Dim hasAccess As Boolean = False
        If outAccess.Value IsNot Nothing AndAlso Not IsDBNull(outAccess.Value) Then
            hasAccess = CBool(outAccess.Value)
        End If

        If Not hasAccess Then
            ' Tentative non autorisée → revenir à la sélection actuelle
            'BindCompanies()
            Return
        End If

        ' Mettre à jour la session
        Company = newGuid
        'Session("CompanyName") = ddlCompany.SelectedItem.Text

        ' Redirection vers le tableau de bord
        Response.Redirect("~/Default.aspx")
    End Sub


End Class
