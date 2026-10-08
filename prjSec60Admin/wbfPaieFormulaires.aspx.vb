Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Paie › Formulaires T4 et Relevé 1 : les formulaires officiels à remplir, par année, pour toutes les
''' compagnies (paie.FormulaireFeuillet, CompagnieId = 0). 60secPaie les prend dès qu'ils sont là ; une
''' compagnie qui téléverse les siens dans sa configuration passe avant.
''' </summary>
Public Class wbfPaieFormulaires
    Inherits clsData

    ''' <summary>Les formulaires de la plateforme sont rangés sous la compagnie 0.</summary>
    Private Const Plateforme As Integer = 0
    Private Const TailleMaximale As Integer = 10 * 1024 * 1024

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then
            For a = Date.Today.Year To Date.Today.Year - 3 Step -1
                ddlAnnee.Items.Add(a.ToString())
            Next
            ' Les feuillets se produisent en janvier et février, pour l'année qui vient de finir.
            If Date.Today.Month <= 3 Then ddlAnnee.SelectedValue = (Date.Today.Year - 1).ToString()
            Charger()
        End If
    End Sub

    Private Sub Charger()
        Dim p As New Collection
        p.Add(New SqlParameter("@c", Plateforme))
        Dim ds As DataSet = ExecuteSQLds("paie.spFormulaireFeuillet_Liste", p)
        Dim t As DataTable = If(ds Is Nothing OrElse ds.Tables.Count = 0, Nothing, ds.Tables(0))
        rptFormulaires.DataSource = t
        rptFormulaires.DataBind()
        Dim vide = t Is Nothing OrElse t.Rows.Count = 0
        rptFormulaires.Visible = Not vide
        lblAucun.Visible = vide
    End Sub

    Protected Function LibelleType(type As Object) As String
        Return If(Convert.ToString(type) = clsFormulairePdf.TypeT4, "T4 (ARC)", "Relevé 1 (Revenu Québec)")
    End Function

    Protected Function Quand(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value Then Return ""
        Return Convert.ToDateTime(v).ToString("yyyy-MM-dd HH:mm")
    End Function

    Protected Function Taille(octets As Object) As String
        If octets Is Nothing OrElse octets Is DBNull.Value Then Return ""
        Return (Convert.ToInt64(octets) / 1024D).ToString("N0") & " Ko"
    End Function

    Private Sub btnTeleverser_Click(sender As Object, e As EventArgs) Handles btnTeleverser.Click
        Try
            If Not fuFichier.HasFile Then Throw New ArgumentException("Choisissez d'abord un fichier.")
            If Not fuFichier.FileName.ToLowerInvariant().EndsWith(".pdf") Then Throw New ArgumentException("Seul un fichier PDF est accepté.")
            If fuFichier.PostedFile.ContentLength > TailleMaximale Then Throw New ArgumentException("Fichier trop volumineux : 10 Mo au maximum.")

            Dim type = ddlType.SelectedValue
            Dim annee = Integer.Parse(ddlAnnee.SelectedValue)
            Dim prepare = clsFormulairePdf.Preparer(fuFichier.FileBytes, type)
            Dim nom = IO.Path.GetFileName(fuFichier.FileName)

            Dim p As New Collection
            p.Add(New SqlParameter("@c", Plateforme))
            p.Add(New SqlParameter("@a", annee))
            p.Add(New SqlParameter("@type", type))
            p.Add(New SqlParameter("@nom", nom))
            p.Add(New SqlParameter("@contenu", SqlDbType.VarBinary, -1) With {.Value = prepare})
            p.Add(New SqlParameter("@u", If(UserEmail, "")))
            ExecuteSQL("paie.spFormulaireFeuillet_Enregistrer", p)

            Charger()
            ShowMsg("Formulaire " & LibelleType(type) & " " & annee.ToString() & " téléversé (" & nom & "). Les feuillets de cette année sortiront dessus dans 60secPaie, pour toutes les compagnies.")
        Catch ex As ArgumentException
            ShowMsg(ex.Message, True)
        Catch ex As SqlException
            ShowMsg(ex.Message, True)
        End Try
    End Sub

    Private Sub rptFormulaires_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptFormulaires.ItemCommand
        If e.CommandName <> "Supprimer" Then Return
        Dim parts = Convert.ToString(e.CommandArgument).Split("|"c)
        Dim annee As Integer
        If parts.Length <> 2 OrElse Not Integer.TryParse(parts(0), annee) Then Return
        Dim p As New Collection
        p.Add(New SqlParameter("@c", Plateforme))
        p.Add(New SqlParameter("@a", annee))
        p.Add(New SqlParameter("@type", parts(1)))
        ExecuteSQL("paie.spFormulaireFeuillet_Supprimer", p)
        Charger()
        ShowMsg("Formulaire " & LibelleType(parts(1)) & " " & annee.ToString() & " retiré.")
    End Sub

    Private Sub ShowMsg(text As String, Optional isError As Boolean = False)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "pf-msg " & If(isError, "bad", "ok")
    End Sub

End Class