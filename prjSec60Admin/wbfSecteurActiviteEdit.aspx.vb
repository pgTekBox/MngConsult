Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' La fiche d'un secteur d'activité (T333SecteurActivite), en fenêtre depuis
''' wbfSecteursActivite.aspx : son nom. s0931 lit, s0932 enregistre (nom unique ; les
''' métiers portent l'Id du secteur et suivent un renommage), s0933 supprime (refusé si
''' des métiers le portent encore).
''' </summary>
Public Class wbfSecteurActiviteEdit
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Dim id As Integer = 0
            Integer.TryParse(Request.QueryString("id"), id)
            hfId.Value = id.ToString()

            If id > 0 Then
                LoadSecteur(id)
                litTitle.Text = "Modifier un secteur"
                btnDelete.Visible = True
            Else
                litTitle.Text = "Nouveau secteur"
            End If
        End If
    End Sub

    Private Sub LoadSecteur(id As Integer)
        Dim p As New Collection
        p.Add(New SqlParameter("@Id", id))
        Dim ds As DataSet = ExecuteSQLds("s0931GetSecteurActiviteById", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            ShowMsg("Secteur introuvable.", isError:=True)
            Return
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        txtNom.Text = S(r("Nom"))
        Dim nb As Integer = Convert.ToInt32(r("NbMetiers"))
        If nb > 0 Then
            litMetiers.Text = If(nb = 1, "1 métier porte", nb & " métiers portent") &
                " ce secteur ; le renommer les met à jour."
        Else
            litMetiers.Text = "Aucun métier ne porte ce secteur."
        End If
    End Sub

    Private Sub btnSave_Click(sender As Object, e As EventArgs) Handles btnSave.Click
        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)

        ' === Validations ===
        Dim nom As String = txtNom.Text.Trim()
        If nom = "" Then
            ShowMsg("Le nom du secteur est obligatoire.", isError:=True)
            Return
        End If

        ' === Sauvegarde ===
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            p.Add(New SqlParameter("@Nom", nom))
            Dim outNew As New SqlParameter("@NewId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
            p.Add(outNew)

            ExecuteSQL("s0932SaveSecteurActivite", p)

            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
                "if (typeof closeWin === 'function') closeWin();", True)

        Catch ex As SqlException
            ShowMsg(ex.Message, isError:=True)
        Catch ex As Exception
            ShowMsg("Erreur : " & ex.Message, isError:=True)
        End Try
    End Sub

    Private Sub btnDelete_Click(sender As Object, e As EventArgs) Handles btnDelete.Click
        Dim id As Integer = 0
        Integer.TryParse(hfId.Value, id)
        If id <= 0 Then Return

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", id))
            ExecuteSQL("s0933DeleteSecteurActivite", p)
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "closewin",
                "if (typeof closeWin === 'function') closeWin();", True)
        Catch ex As SqlException
            ShowMsg(ex.Message, isError:=True)
        End Try
    End Sub

    ' ---------------------------------------------------------------------
    ' Helpers
    ' ---------------------------------------------------------------------
    Private Function S(o As Object) As String
        If o Is Nothing OrElse o Is DBNull.Value Then Return ""
        Return o.ToString()
    End Function

    Private Sub ShowMsg(text As String, Optional isError As Boolean = False)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "msg " & If(isError, "bad", "ok")
    End Sub

End Class
