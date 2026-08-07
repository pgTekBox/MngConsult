Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Création / édition d'un abonné.
'''   wbfAbonne.aspx            -> création
'''   wbfAbonne.aspx?id=N       -> édition de l'abonné N
''' </summary>
Public Class wbfAbonne
    Inherits clsData

    Private ReadOnly Property AbonneId() As Integer
        Get
            Dim v As Integer
            Integer.TryParse(Request.QueryString("id"), v)
            Return v
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Le master redirige les non-authentifiés ; on évite tout accès BD ici.
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            If AbonneId > 0 Then
                LoadAbonne(AbonneId)
            End If
            If Request.QueryString("saved") = "1" Then
                pnlOk.Visible = True
                litOk.Text = "Abonné enregistré avec succès."
            End If
        End If
    End Sub

    Private Sub LoadAbonne(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            Dim ds As DataSet = ExecuteSQLds("s0005GetAbonne", p)

            If ds.Tables(0).Rows.Count = 0 Then
                ShowError("Abonné introuvable.")
                Return
            End If

            Dim r As DataRow = ds.Tables(0).Rows(0)

            litTitle.Text = Server.HtmlEncode(Val(r, "RaisonSociale"))
            litMeta.Text = "Réf. locataire : " & Val(r, "TenantGUID") &
                           " · Créé le " & FormatDate(r("CreatedUtc"))

            ' Accès aux clients et au grand livre de cet abonné (édition uniquement).
            lnkClients.Visible = True
            lnkClients.Text = "Clients"
            lnkClients.NavigateUrl = "wbfClients.aspx?abonneId=" & id
            lnkGrandLivre.Visible = True
            lnkGrandLivre.Text = "Grand livre"
            lnkGrandLivre.NavigateUrl = "wbfGrandLivre.aspx?abonneId=" & id
            lnkPaiements.Visible = True
            lnkPaiements.Text = "Paiements"
            lnkPaiements.NavigateUrl = "wbfPaiements.aspx?abonneId=" & id
            lnkFournisseurs.Visible = True
            lnkFournisseurs.Text = "Fournisseurs"
            lnkFournisseurs.NavigateUrl = "wbfFournisseurs.aspx?abonneId=" & id
            lnkDecaissements.Visible = True
            lnkDecaissements.Text = "Décaissements"
            lnkDecaissements.NavigateUrl = "wbfDecaissements.aspx?abonneId=" & id
            lnkApiKeys.Visible = True
            lnkApiKeys.Text = "Clés API"
            lnkApiKeys.NavigateUrl = "wbfApiKeys.aspx?abonneId=" & id
            lnkWebhooks.Visible = True
            lnkWebhooks.Text = "Webhooks"
            lnkWebhooks.NavigateUrl = "wbfWebhooks.aspx?abonneId=" & id

            tbRaisonSociale.Text = Val(r, "RaisonSociale")
            tbNomAffichage.Text = Val(r, "NomAffichage")
            tbNumeroEntreprise.Text = Val(r, "NumeroEntreprise")
            tbCourriel.Text = Val(r, "CourrielContact")
            tbTelephone.Text = Val(r, "Telephone")
            tbAdresse1.Text = Val(r, "Adresse1")
            tbAdresse2.Text = Val(r, "Adresse2")
            tbVille.Text = Val(r, "Ville")
            tbProvince.Text = Val(r, "Province")
            tbCodePostal.Text = Val(r, "CodePostal")
            tbPays.Text = Val(r, "Pays")
            SelectValue(ddlDevise, Val(r, "Devise"))
            SelectValue(ddlStatut, Val(r, "Statut"))
            SelectValue(ddlKyb, Val(r, "StatutKYB"))
            tbNotes.Text = Val(r, "Notes")
        Catch ex As Exception
            ShowError("Impossible de charger l'abonné. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("LoadAbonne: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)

        Dim raison As String = If(tbRaisonSociale.Text, "").Trim()
        If raison.Length = 0 Then
            ShowError("La raison sociale est obligatoire.")
            Return
        End If

        Try
            Dim newId As Integer = AbonneId

            Dim p As New Collection
            p.Add(New SqlParameter("@Id", newId))
            p.Add(New SqlParameter("@RaisonSociale", raison))
            p.Add(New SqlParameter("@NomAffichage", ParamOrNull(tbNomAffichage.Text)))
            p.Add(New SqlParameter("@NumeroEntreprise", ParamOrNull(tbNumeroEntreprise.Text)))
            p.Add(New SqlParameter("@CourrielContact", ParamOrNull(tbCourriel.Text)))
            p.Add(New SqlParameter("@Telephone", ParamOrNull(tbTelephone.Text)))
            p.Add(New SqlParameter("@Adresse1", ParamOrNull(tbAdresse1.Text)))
            p.Add(New SqlParameter("@Adresse2", ParamOrNull(tbAdresse2.Text)))
            p.Add(New SqlParameter("@Ville", ParamOrNull(tbVille.Text)))
            p.Add(New SqlParameter("@Province", ParamOrNull(tbProvince.Text)))
            p.Add(New SqlParameter("@CodePostal", ParamOrNull(tbCodePostal.Text)))
            p.Add(New SqlParameter("@Pays", ParamOrNull(tbPays.Text)))
            p.Add(New SqlParameter("@Devise", ddlDevise.SelectedValue))
            p.Add(New SqlParameter("@Statut", ddlStatut.SelectedValue))
            p.Add(New SqlParameter("@StatutKYB", ddlKyb.SelectedValue))
            p.Add(New SqlParameter("@Notes", ParamOrNull(tbNotes.Text)))
            p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))

            Dim ds As DataSet = ExecuteSQLds("s0006SaveAbonne", p)
            If ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                newId = CInt(ds.Tables(0).Rows(0)("Id"))
            End If

            Response.Redirect("wbfAbonne.aspx?id=" & newId & "&saved=1")

        Catch ex As Exception
            ShowError("Enregistrement impossible. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("SaveAbonne: " & ex.Message)
        End Try
    End Sub

    ' --- Helpers ---

    Private Function Val(r As DataRow, col As String) As String
        If IsDBNull(r(col)) Then Return ""
        Return r(col).ToString()
    End Function

    Private Function ParamOrNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    Private Sub SelectValue(ddl As DropDownList, value As String)
        Dim item As ListItem = ddl.Items.FindByValue(If(value, ""))
        If item IsNot Nothing Then
            ddl.ClearSelection()
            item.Selected = True
        End If
    End Sub

    Private Function FormatDate(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd")
    End Function

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

End Class
