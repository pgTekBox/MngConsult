Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Création / édition d'un client d'un abonné.
'''   wbfClient.aspx?abonneId=A         -> création (client de l'abonné A)
'''   wbfClient.aspx (abonneId=A, id=N) -> édition du client N (doit appartenir à A)
''' </summary>
Public Class wbfClient
    Inherits clsData

    Private ReadOnly Property AbonneId() As Integer
        Get
            Dim v As Integer
            Integer.TryParse(Request.QueryString("abonneId"), v)
            Return v
        End Get
    End Property

    Private ReadOnly Property ClientRecordId() As Integer
        Get
            Dim v As Integer
            Integer.TryParse(Request.QueryString("id"), v)
            Return v
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return

        If AbonneId <= 0 Then
            Response.Redirect("~/wbfAbonnes.aspx")
            Return
        End If

        ' Liens de navigation dépendants du contexte
        lnkAbonne.HRef = "wbfAbonne.aspx?id=" & AbonneId
        lnkClients.NavigateUrl = "wbfClients.aspx?abonneId=" & AbonneId
        btnBack.NavigateUrl = "wbfClients.aspx?abonneId=" & AbonneId
        btnCancel.NavigateUrl = "wbfClients.aspx?abonneId=" & AbonneId

        If Not IsPostBack Then
            LoadAbonneName()
            If ClientRecordId > 0 Then
                LoadClient(ClientRecordId)
            End If
            If Request.QueryString("saved") = "1" Then
                pnlOk.Visible = True
                litOk.Text = "Client enregistré avec succès."
            End If
        End If
    End Sub

    Private Sub LoadAbonneName()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", AbonneId))
            Dim tbl As DataTable = ExecuteSQLds("s0005GetAbonne", p).Tables(0)
            If tbl.Rows.Count = 0 Then
                Response.Redirect("~/wbfAbonnes.aspx")
                Return
            End If
            Dim nom As String = tbl.Rows(0)("RaisonSociale").ToString()
            lnkAbonne.InnerText = nom
            litMeta.Text = "Client de l'abonné " & Server.HtmlEncode(nom) & "."
        Catch ex As Exception
            ShowError("Impossible de charger l'abonné. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("LoadAbonneName: " & ex.Message)
        End Try
    End Sub

    Private Sub LoadClient(id As Integer)
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            Dim tbl As DataTable = ExecuteSQLds("s0012GetClient", p).Tables(0)

            If tbl.Rows.Count = 0 Then
                ShowError("Client introuvable.")
                Return
            End If

            Dim r As DataRow = tbl.Rows(0)

            ' Garde d'isolation : le client doit appartenir à l'abonné de l'URL.
            If CInt(r("AbonneId")) <> AbonneId Then
                Response.Redirect("~/wbfClients.aspx?abonneId=" & AbonneId)
                Return
            End If

            litTitle.Text = Server.HtmlEncode(Val(r, "Nom"))
            litCrumbClient.Text = Server.HtmlEncode(Val(r, "Nom"))

            SelectValue(ddlType, Val(r, "TypeClient"))
            SelectValue(ddlStatut, Val(r, "Statut"))
            tbNom.Text = Val(r, "Nom")
            tbReference.Text = Val(r, "ReferenceExterne")
            tbCourriel.Text = Val(r, "CourrielContact")
            tbTelephone.Text = Val(r, "Telephone")
            tbAdresse1.Text = Val(r, "Adresse1")
            tbAdresse2.Text = Val(r, "Adresse2")
            tbVille.Text = Val(r, "Ville")
            tbProvince.Text = Val(r, "Province")
            tbCodePostal.Text = Val(r, "CodePostal")
            tbPays.Text = Val(r, "Pays")
            tbNotes.Text = Val(r, "Notes")
            tbBankInstitution.Text = Val(r, "BankInstitution")
            tbBankTransit.Text = Val(r, "BankTransit")
            tbBankAccount.Text = Val(r, "BankAccount")
        Catch ex As Exception
            ShowError("Impossible de charger le client. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("LoadClient: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnSave_Click(sender As Object, e As EventArgs)

        Dim nom As String = If(tbNom.Text, "").Trim()
        If nom.Length = 0 Then
            ShowError("Le nom / la raison sociale est obligatoire.")
            Return
        End If

        Try
            Dim newId As Integer = ClientRecordId

            Dim p As New Collection
            p.Add(New SqlParameter("@Id", newId))
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@TypeClient", ddlType.SelectedValue))
            p.Add(New SqlParameter("@Nom", nom))
            p.Add(New SqlParameter("@ReferenceExterne", ParamOrNull(tbReference.Text)))
            p.Add(New SqlParameter("@CourrielContact", ParamOrNull(tbCourriel.Text)))
            p.Add(New SqlParameter("@Telephone", ParamOrNull(tbTelephone.Text)))
            p.Add(New SqlParameter("@Adresse1", ParamOrNull(tbAdresse1.Text)))
            p.Add(New SqlParameter("@Adresse2", ParamOrNull(tbAdresse2.Text)))
            p.Add(New SqlParameter("@Ville", ParamOrNull(tbVille.Text)))
            p.Add(New SqlParameter("@Province", ParamOrNull(tbProvince.Text)))
            p.Add(New SqlParameter("@CodePostal", ParamOrNull(tbCodePostal.Text)))
            p.Add(New SqlParameter("@Pays", ParamOrNull(tbPays.Text)))
            p.Add(New SqlParameter("@Statut", ddlStatut.SelectedValue))
            p.Add(New SqlParameter("@Notes", ParamOrNull(tbNotes.Text)))
            p.Add(New SqlParameter("@AdminId", If(AdminId = 0, CObj(DBNull.Value), AdminId)))
            p.Add(New SqlParameter("@BankInstitution", ParamOrNull(tbBankInstitution.Text)))
            p.Add(New SqlParameter("@BankTransit", ParamOrNull(tbBankTransit.Text)))
            p.Add(New SqlParameter("@BankAccount", ParamOrNull(tbBankAccount.Text)))

            Dim ds As DataSet = ExecuteSQLds("s0013SaveClient", p)
            If ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                newId = CInt(ds.Tables(0).Rows(0)("Id"))
            End If

            Response.Redirect("wbfClient.aspx?abonneId=" & AbonneId & "&id=" & newId & "&saved=1")

        Catch sqlEx As SqlException When sqlEx.Number = 2601 OrElse sqlEx.Number = 2627
            ShowError("Cette référence externe est déjà utilisée pour un autre client de cet abonné.")
        Catch ex As Exception
            ShowError("Enregistrement impossible. Vérifiez que les scripts de base de données ont été exécutés.")
            System.Diagnostics.Debug.WriteLine("SaveClient: " & ex.Message)
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

    Private Sub ShowError(msg As String)
        pnlError.Visible = True
        litError.Text = msg
    End Sub

End Class
