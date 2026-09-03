Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Fiche d'un abonné (tenant) côté partenaire : création (provisioning) et
''' consultation, avec lancement de la vérification KYB. Toutes les
''' opérations sont scopées au PartenaireId de la session ; un partenaire ne
''' peut voir/toucher que SES propres abonnés (garde s0117).
''' </summary>
Public Class wbfAbonne
    Inherits clsData

    Protected WithEvents litTitle As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litSub As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlOk As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litOk As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlErr As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litErr As Global.System.Web.UI.WebControls.Literal

    ' Mode creation
    Protected WithEvents pnlCreate As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents tbNom As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbNomAff As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbNeq As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbEmail As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbTel As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbAdr1 As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbVille As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbProv As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbCp As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnCreate As Global.System.Web.UI.WebControls.Button

    ' Mode consultation
    Protected WithEvents pnlView As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litVNom As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litVNomAff As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litVNeq As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litVEmail As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litVTel As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litVAdr As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litVStatut As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litVKyb As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents pnlKybResult As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litKybMsg As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents btnKyb As Global.System.Web.UI.WebControls.Button
    Protected WithEvents pnlNewPwd As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litNewPwd As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litNewPwdUser As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents rptUsers As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlNoUsers As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents tbUserPwd As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbUserEmail As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbUserFirst As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents tbUserLast As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnCreateUser As Global.System.Web.UI.WebControls.Button
    Protected WithEvents litVId As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litVId2 As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litVGuid As Global.System.Web.UI.WebControls.Literal

    Private ReadOnly Property SelectedId() As Integer
        Get
            Dim v As Integer
            Integer.TryParse(Request.QueryString("id"), v)
            Return v
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            If SelectedId > 0 Then
                If Request.QueryString("created") = "1" Then
                    pnlOk.Visible = True
                    litOk.Text = "Abonné provisionné avec succès."
                End If
                LoadView()
            Else
                pnlCreate.Visible = True
            End If
        End If
    End Sub

    ' ================= Creation =================

    Protected Sub btnCreate_Click(sender As Object, e As EventArgs)
        Dim nom As String = If(tbNom.Text, "").Trim()
        If nom.Length = 0 Then
            ShowErr("La raison sociale est requise.")
            pnlCreate.Visible = True
            Return
        End If

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@PartenaireId", PartenaireId))
            p.Add(New SqlParameter("@RaisonSociale", nom))
            p.Add(New SqlParameter("@NomAffichage", NzParam(tbNomAff.Text)))
            p.Add(New SqlParameter("@NumeroEntreprise", NzParam(tbNeq.Text)))
            p.Add(New SqlParameter("@CourrielContact", NzParam(tbEmail.Text)))
            p.Add(New SqlParameter("@Telephone", NzParam(tbTel.Text)))
            p.Add(New SqlParameter("@Adresse1", NzParam(tbAdr1.Text)))
            p.Add(New SqlParameter("@Adresse2", DBNull.Value))
            p.Add(New SqlParameter("@Ville", NzParam(tbVille.Text)))
            p.Add(New SqlParameter("@Province", NzParam(tbProv.Text)))
            p.Add(New SqlParameter("@CodePostal", NzParam(tbCp.Text)))
            p.Add(New SqlParameter("@Pays", "Canada"))
            p.Add(New SqlParameter("@Statut", "Prospect"))
            Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = 0}
            p.Add(outId)

            Dim t As DataTable = ExecuteSQLds("s0115CreateAbonneForPartner", p).Tables(0)
            Dim newId As Integer = If(t.Rows.Count > 0, CInt(t.Rows(0)("Id")), CInt(outId.Value))

            ' Audit (provisioning par le partenaire)
            clsAudit.Write(0, "partner:" & UserEmail, "AbonneProvision", "Abonne", newId, nom,
                           "via PortailPartenaire (partenaire " & PartenaireId & ")", Request.UserHostAddress)

            Response.Redirect("wbfAbonne.aspx?id=" & newId & "&created=1")
        Catch ex As SqlException
            ShowErr("Création impossible : " & ex.Message)
            pnlCreate.Visible = True
        Catch ex As Exception
            ShowErr("Création impossible. Vérifiez que le script de base de données 42 a été exécuté.")
            System.Diagnostics.Debug.WriteLine("PTN Abonne create: " & ex.Message)
            pnlCreate.Visible = True
        End Try
    End Sub

    ' ================= Consultation =================

    Private Function LoadRow() As DataRow
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", SelectedId))
        p.Add(New SqlParameter("@PartenaireId", PartenaireId))
        Dim t As DataTable = ExecuteSQLds("s0117GetAbonneForPartner", p).Tables(0)
        If t.Rows.Count = 0 Then Return Nothing
        Return t.Rows(0)
    End Function

    Private Sub LoadView()
        Dim r As DataRow = LoadRow()
        If r Is Nothing Then
            ' N'appartient pas a ce partenaire (ou inexistant) -> retour liste.
            Response.Redirect("~/wbfAbonnes.aspx")
            Return
        End If

        pnlView.Visible = True
        litTitle.Text = Server.HtmlEncode(r("RaisonSociale").ToString())
        litSub.Text = "Abonné rattaché à votre canal"

        litVNom.Text = Enc(r("RaisonSociale"))
        litVNomAff.Text = Enc(r("NomAffichage"))
        litVNeq.Text = Enc(r("NumeroEntreprise"))
        litVEmail.Text = Enc(r("CourrielContact"))
        litVTel.Text = Enc(r("Telephone"))
        litVAdr.Text = BuildAddress(r)
        litVStatut.Text = StatutBadge(r("Statut"))
        litVKyb.Text = KybBadge(r("StatutKYB"))
        litVId.Text = SelectedId.ToString()
        litVId2.Text = SelectedId.ToString()
        litVGuid.Text = Enc(r("TenantGUID"))

        LoadLastKyb()
        BindUsers()
    End Sub

    ' ================= Acces au portail abonne =================

    ''' <summary>Comptes du portail abonné, scopés au partenaire (garde s0126).</summary>
    Private Sub BindUsers()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", SelectedId))
            p.Add(New SqlParameter("@PartenaireId", PartenaireId))
            Dim t As DataTable = ExecuteSQLds("s0126ListAbonneUsersForPartner", p).Tables(0)
            rptUsers.DataSource = t : rptUsers.DataBind()
            rptUsers.Visible = (t.Rows.Count > 0)
            pnlNoUsers.Visible = (t.Rows.Count = 0)
        Catch ex As Exception
            ShowErr("Impossible de charger les accès. Vérifiez que le script de base de données 47 a été exécuté.")
            System.Diagnostics.Debug.WriteLine("PTN Abonne users: " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Donne un nouveau mot de passe à un compte de l'abonné. L'ancien n'est pas
    ''' demandé : c'est le partenaire, responsable de son canal, qui agit. La
    ''' procédure s0125 revérifie que le compte appartient bien à un abonné de ce
    ''' partenaire avant d'écrire.
    ''' </summary>
    Protected Sub rptUsers_ItemCommand(source As Object, e As RepeaterCommandEventArgs)
        If e.CommandName <> "resetpwd" Then Return

        Dim userId As Integer
        If Not Integer.TryParse(TryCast(e.CommandArgument, String), userId) OrElse userId <= 0 Then Return

        Try
            Dim email As String = EmailOf(userId)
            If email.Length = 0 Then
                LoadView() : ShowErr("Compte introuvable pour cet abonné.") : Return
            End If

            Dim saisi As String = If(tbUserPwd.Text, "")
            Dim genere As Boolean = (saisi.Length = 0)
            If Not genere AndAlso saisi.Length < 8 Then
                LoadView() : ShowErr("Le mot de passe saisi doit contenir au moins 8 caractères (ou laissez le champ vide pour en générer un).") : Return
            End If

            Dim clair As String = If(genere, GeneratePassword(), saisi)
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", userId))
            p.Add(New SqlParameter("@PartenaireId", PartenaireId))
            p.Add(New SqlParameter("@PasswordHash", BCrypt.Net.BCrypt.HashPassword(clair, 11)))
            ExecuteSQL("s0125ResetAbonneUserPassword", p)

            clsAudit.Write(0, UserEmail, "AbonneUserPasswordReset", "Abonne", SelectedId, email,
                           If(genere, "Mot de passe redonné par le partenaire (généré).",
                                      "Mot de passe redonné par le partenaire (saisi)."),
                           Request.UserHostAddress)

            tbUserPwd.Text = ""
            LoadView()
            If genere Then
                ShowNewPassword(clair, email)
                ShowOk("Mot de passe réinitialisé. L'ancien ne fonctionne plus.")
            Else
                ShowOk("Mot de passe défini pour " & email & ". L'ancien ne fonctionne plus.")
            End If

        Catch ex As SqlException
            LoadView() : ShowErr(ex.Message)
        Catch ex As Exception
            LoadView() : ShowErr("Réinitialisation impossible.")
            System.Diagnostics.Debug.WriteLine("PTN Abonne pwd reset: " & ex.Message)
        End Try
    End Sub

    ''' <summary>Crée le premier (ou un nouvel) accès au portail abonné.</summary>
    Protected Sub btnCreateUser_Click(sender As Object, e As EventArgs)
        Dim email As String = If(tbUserEmail.Text, "").Trim().ToLowerInvariant()
        If email.Length = 0 Then
            LoadView() : ShowErr("Le courriel du nouvel accès est requis.") : Return
        End If

        Dim saisi As String = If(tbUserPwd.Text, "")
        Dim genere As Boolean = (saisi.Length = 0)
        If Not genere AndAlso saisi.Length < 8 Then
            LoadView() : ShowErr("Le mot de passe saisi doit contenir au moins 8 caractères (ou laissez le champ vide pour en générer un).") : Return
        End If

        Try
            Dim clair As String = If(genere, GeneratePassword(), saisi)
            Dim outId As New SqlParameter("@Id", SqlDbType.Int) With {.Direction = ParameterDirection.InputOutput, .Value = 0}
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", SelectedId))
            p.Add(New SqlParameter("@PartenaireId", PartenaireId))
            p.Add(New SqlParameter("@Email", email))
            p.Add(New SqlParameter("@PasswordHash", BCrypt.Net.BCrypt.HashPassword(clair, 11)))
            p.Add(New SqlParameter("@FirstName", NzParam(tbUserFirst.Text)))
            p.Add(New SqlParameter("@LastName", NzParam(tbUserLast.Text)))
            p.Add(New SqlParameter("@IsAdmin", True))
            p.Add(outId)
            ExecuteSQLds("s0127CreateAbonneUserForPartner", p)

            clsAudit.Write(0, UserEmail, "AbonneUserCreate", "Abonne", SelectedId, email,
                           "Accès au portail abonné créé par le partenaire.", Request.UserHostAddress)

            tbUserEmail.Text = "" : tbUserFirst.Text = "" : tbUserLast.Text = "" : tbUserPwd.Text = ""
            LoadView()
            If genere Then ShowNewPassword(clair, email)
            ShowOk("Accès créé pour " & email & ".")

        Catch ex As SqlException
            LoadView()
            If ex.Number = 2627 OrElse ex.Number = 2601 Then
                ShowErr("Ce courriel est déjà utilisé par un autre accès.")
            Else
                ShowErr("Création impossible : " & ex.Message)
            End If
        Catch ex As Exception
            LoadView() : ShowErr("Création impossible.")
            System.Diagnostics.Debug.WriteLine("PTN Abonne user create: " & ex.Message)
        End Try
    End Sub

    Private Sub ShowOk(msg As String)
        pnlOk.Visible = True
        litOk.Text = Server.HtmlEncode(msg)
    End Sub

    Private Sub ShowNewPassword(clair As String, email As String)
        pnlNewPwd.Visible = True
        litNewPwd.Text = Server.HtmlEncode(clair)
        litNewPwdUser.Text = Server.HtmlEncode(email)
    End Sub

    ''' <summary>Courriel d'un compte, via la liste scopée au partenaire.</summary>
    Private Function EmailOf(userId As Integer) As String
        Dim p As New Collection
        p.Add(New SqlParameter("@AbonneId", SelectedId))
        p.Add(New SqlParameter("@PartenaireId", PartenaireId))
        Dim t As DataTable = ExecuteSQLds("s0126ListAbonneUsersForPartner", p).Tables(0)
        For Each r As DataRow In t.Rows
            If CInt(r("Id")) = userId Then Return r("Email").ToString()
        Next
        Return ""
    End Function

    ''' <summary>Mot de passe temporaire lisible : 4 blocs de 4 caractères,
    ''' sans caractères ambigus, tirés au sort de façon sûre.</summary>
    Private Function GeneratePassword() As String
        Const alphabet As String = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789"
        Dim bytes(15) As Byte
        Using rng As System.Security.Cryptography.RandomNumberGenerator = System.Security.Cryptography.RandomNumberGenerator.Create()
            rng.GetBytes(bytes)
        End Using
        Dim sb As New System.Text.StringBuilder(19)
        For i As Integer = 0 To 15
            If i > 0 AndAlso i Mod 4 = 0 Then sb.Append("-"c)
            sb.Append(alphabet(bytes(i) Mod alphabet.Length))
        Next
        Return sb.ToString()
    End Function

    ''' <summary>Confirmation JavaScript (attribut délimité par des apostrophes).</summary>
    Protected Function ConfirmReset(o As Object) As String
        Dim email As String = If(o Is Nothing OrElse IsDBNull(o), "", o.ToString())
        email = email.Replace("\", "\\").Replace("""", "\""")
        Return "return confirm(""Réinitialiser le mot de passe de " & email &
               " ? Le mot de passe actuel cessera de fonctionner immédiatement."");"
    End Function

    Private Sub LoadLastKyb()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", SelectedId))
            p.Add(New SqlParameter("@Top", 1))
            Dim t As DataTable = ExecuteSQLds("s0102ListKybChecks", p).Tables(0)
            If t.Rows.Count = 0 Then Return
            Dim r As DataRow = t.Rows(0)
            pnlKybResult.Visible = True
            litKybMsg.Text = "<b>Dernière vérification :</b> " & Server.HtmlEncode(r("Status").ToString()) &
                             " · score " & Server.HtmlEncode(r("Score").ToString()) &
                             " · " & FormatDt(r("Utc")) & "<br />" &
                             Server.HtmlEncode(If(IsDBNull(r("Message")), "", r("Message").ToString()))
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("PTN last kyb: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnKyb_Click(sender As Object, e As EventArgs)
        ' Garde : l'abonne doit appartenir au partenaire connecte.
        Dim r As DataRow = LoadRow()
        If r Is Nothing Then
            Response.Redirect("~/wbfAbonnes.aspx")
            Return
        End If
        Try
            Dim res As KybResult = clsKyb.RunCheck(SelectedId, 0, UserEmail, Request.UserHostAddress)
            pnlOk.Visible = True
            litOk.Text = "Vérification KYB effectuée : " & Server.HtmlEncode(res.Status) & " (score " & res.Score & ")."
        Catch ex As Exception
            ShowErr("La vérification KYB a échoué : " & ex.Message)
        End Try
        LoadView()
    End Sub

    ' ================= Helpers =================

    Private Function BuildAddress(r As DataRow) As String
        Dim parts As New List(Of String)
        For Each c As String In New String() {"Adresse1", "Ville", "Province", "CodePostal", "Pays"}
            If r.Table.Columns.Contains(c) AndAlso Not IsDBNull(r(c)) AndAlso r(c).ToString().Trim().Length > 0 Then
                parts.Add(r(c).ToString().Trim())
            End If
        Next
        If parts.Count = 0 Then Return "—"
        Return Server.HtmlEncode(String.Join(", ", parts))
    End Function

    Private Function NzParam(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    Private Sub ShowErr(msg As String)
        pnlErr.Visible = True
        litErr.Text = Server.HtmlEncode(msg)
    End Sub

    Protected Function StatutBadge(o As Object) As String
        Dim s As String = If(o Is Nothing OrElse IsDBNull(o), "", o.ToString())
        Dim cls As String
        Select Case s
            Case "Actif" : cls = "badge-actif"
            Case "Prospect" : cls = "badge-prospect"
            Case "Suspendu" : cls = "badge-attente"
            Case Else : cls = "badge-neutre"
        End Select
        Return "<span class='badge " & cls & "'>" & Server.HtmlEncode(s) & "</span>"
    End Function

    Protected Function KybBadge(o As Object) As String
        Dim s As String = If(o Is Nothing OrElse IsDBNull(o), "", o.ToString())
        Dim cls As String, txt As String
        Select Case s
            Case "Verifie" : cls = "badge-actif" : txt = "Vérifié"
            Case "EnCours" : cls = "badge-encours" : txt = "En cours"
            Case "Rejete" : cls = "badge-rejete" : txt = "Rejeté"
            Case Else : cls = "badge-neutre" : txt = "Non débuté"
        End Select
        Return "<span class='badge " & cls & "'>" & txt & "</span>"
    End Function

End Class
