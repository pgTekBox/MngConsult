Imports System.Data
Imports System.Data.SqlClient

''' <summary>Liste des fournisseurs (bénéficiaires) d'un abonné. Scopé par ?abonneId=N.</summary>
Public Class wbfFournisseurs
    Inherits clsData

    Private ReadOnly Property AbonneId() As Integer
        Get
            Dim v As Integer
            Integer.TryParse(Request.QueryString("abonneId"), v)
            Return v
        End Get
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If AbonneId <= 0 Then
            Response.Redirect("~/wbfAbonnes.aspx")
            Return
        End If
        If Not IsPostBack Then
            If Not LoadAbonneHeader() Then Return
            btnNew.NavigateUrl = "wbfFournisseur.aspx?abonneId=" & AbonneId
            lnkCreateFirst.NavigateUrl = "wbfFournisseur.aspx?abonneId=" & AbonneId
            lnkAbonne.HRef = "wbfAbonne.aspx?id=" & AbonneId
            BindList()
        End If
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        BindList()
    End Sub

    Private Function LoadAbonneHeader() As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", AbonneId))
            Dim tbl As DataTable = ExecuteSQLds("s0005GetAbonne", p).Tables(0)
            If tbl.Rows.Count = 0 Then
                Response.Redirect("~/wbfAbonnes.aspx")
                Return False
            End If
            Dim nom As String = tbl.Rows(0)("RaisonSociale").ToString()
            litAbonne.Text = Server.HtmlEncode(nom)
            lnkAbonne.InnerText = nom
            Return True
        Catch ex As Exception
            pnlError.Visible = True
            litError.Text = "Impossible de charger l'abonné. Vérifiez que les scripts de base de données ont été exécutés."
            System.Diagnostics.Debug.WriteLine("Frn LoadHeader: " & ex.Message)
            Return False
        End Try
    End Function

    Private Sub BindList()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@AbonneId", AbonneId))
            p.Add(New SqlParameter("@Search", TextOrDbNull(tbSearch.Text)))
            p.Add(New SqlParameter("@Statut", TextOrDbNull(ddlStatut.SelectedValue)))
            Dim tbl As DataTable = ExecuteSQLds("s0035ListFournisseurs", p).Tables(0)
            rptList.DataSource = tbl
            rptList.DataBind()
            Dim n As Integer = tbl.Rows.Count
            rptList.Visible = (n > 0)
            pnlEmpty.Visible = (n = 0)
            litCount.Text = n & If(n = 1, " fournisseur", " fournisseurs")
        Catch ex As Exception
            pnlError.Visible = True
            litError.Text = "Impossible de charger les fournisseurs. Vérifiez que les scripts de base de données ont été exécutés."
            System.Diagnostics.Debug.WriteLine("Frn BindList: " & ex.Message)
            rptList.Visible = False : pnlEmpty.Visible = False
        End Try
    End Sub

    Private Function TextOrDbNull(s As String) As Object
        Dim v As String = If(s, "").Trim()
        If v.Length = 0 Then Return DBNull.Value
        Return v
    End Function

    Protected Function ItemUrl(id As Object) As String
        Return "wbfFournisseur.aspx?abonneId=" & AbonneId & "&id=" & id.ToString()
    End Function

    Protected Function VilleProvince(ville As Object, prov As Object) As String
        Dim v As String = If(ville Is Nothing OrElse IsDBNull(ville), "", ville.ToString())
        Dim p As String = If(prov Is Nothing OrElse IsDBNull(prov), "", prov.ToString())
        Dim parts As New List(Of String)
        If v.Trim().Length > 0 Then parts.Add(v)
        If p.Trim().Length > 0 Then parts.Add(p)
        Return String.Join(", ", parts)
    End Function

    Protected Function FormatDate(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return CDate(d).ToString("yyyy-MM-dd")
    End Function

    Protected Function BadgeStatut(s As Object) As String
        Select Case If(s, "").ToString()
            Case "Actif" : Return "badge-actif"
            Case "Bloque" : Return "badge-rejete"
            Case Else : Return "badge-inactif"
        End Select
    End Function

    Protected Function LabelStatut(s As Object) As String
        Select Case If(s, "").ToString()
            Case "Bloque" : Return "Bloqué"
            Case Else : Return If(s, "").ToString()
        End Select
    End Function

End Class
