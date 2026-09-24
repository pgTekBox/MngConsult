Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Paie › Taux de l'année : les jeux de taux gouvernementaux de 60secPaie, une
''' ligne par année (paie.ParametresAnnee). D'ici on ouvre une année, ou on crée
''' la suivante en brouillon à partir de la plus récente.
''' </summary>
Public Class wbfPaieAnnees
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not IsPostBack Then Charger()
    End Sub

    Private Sub Charger()
        Dim ds As DataSet = ExecuteSQLds("paie.spParametresAnnee_Liste")
        Dim t As DataTable = If(ds Is Nothing OrElse ds.Tables.Count = 0, Nothing, ds.Tables(0))
        rptAnnees.DataSource = t
        rptAnnees.DataBind()
        Dim vide = t Is Nothing OrElse t.Rows.Count = 0
        rptAnnees.Visible = Not vide
        lblAucune.Visible = vide
        btnCreer.Visible = Not vide
    End Sub

    ''' <summary>La ligne grise sous la source : création, modification, validation, paies confirmées.</summary>
    Protected Function Meta(item As Object) As String
        Dim r As DataRowView = TryCast(item, DataRowView)
        If r Is Nothing Then Return ""
        Dim parts As New List(Of String)()
        parts.Add("Créée le " & Quand(r("CreeLe")) & Par(r("CreePar")))
        If Not IsDBNull(r("ModifieLe")) Then parts.Add("modifiée le " & Quand(r("ModifieLe")) & Par(r("ModifiePar")))
        If Not IsDBNull(r("ValideLe")) Then parts.Add("validée le " & Quand(r("ValideLe")) & Par(r("ValidePar")))
        Dim n = Convert.ToInt32(r("NbPaiesConfirmees"))
        parts.Add(If(n = 0, "aucune paie confirmée", n.ToString() & " paie(s) confirmée(s) cette année-là"))
        Return Server.HtmlEncode(String.Join(" · ", parts))
    End Function

    Private Shared Function Quand(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value Then Return "?"
        Return Convert.ToDateTime(v).ToString("yyyy-MM-dd HH:mm")
    End Function

    Private Shared Function Par(v As Object) As String
        If v Is Nothing OrElse v Is DBNull.Value OrElse v.ToString().Length = 0 Then Return ""
        Return " par " & v.ToString()
    End Function

    ''' <summary>Copie la dernière année en brouillon pour la suivante, puis l'ouvre.</summary>
    Private Sub btnCreer_Click(sender As Object, e As EventArgs) Handles btnCreer.Click
        Try
            Dim ds As DataSet = ExecuteSQLds("paie.spParametresAnnee_Liste")
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
                ShowMsg("Aucune année de départ.", True)
                Return
            End If
            Dim derniere As Integer = Convert.ToInt32(ds.Tables(0).Rows(0)("Annee"))   ' la liste est triée décroissante

            Dim p As New Collection
            p.Add(New SqlParameter("@De", derniere))
            p.Add(New SqlParameter("@Vers", derniere + 1))
            p.Add(New SqlParameter("@Par", UserEmail))
            ExecuteSQL("paie.spParametresAnnee_Copier", p)

            Response.Redirect("~/wbfPaieAnneeEdit.aspx?annee=" & (derniere + 1).ToString() & "&nouvelle=1", True)
        Catch ex As SqlException
            ShowMsg(ex.Message, True)
        End Try
    End Sub

    Private Sub ShowMsg(text As String, Optional isError As Boolean = False)
        pnlMsg.Visible = True
        pMsg.InnerText = text
        pMsg.Attributes("class") = "pa-msg " & If(isError, "bad", "ok")
    End Sub

End Class
