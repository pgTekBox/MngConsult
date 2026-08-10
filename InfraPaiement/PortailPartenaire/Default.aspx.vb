Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Tableau de bord du portail partenaire : indicateurs (nombre d'abonnés,
''' actifs, KYB) et liste des abonnés récemment provisionnés. Tout est scopé
''' au PartenaireId de la session.
''' </summary>
Public Class Default_aspx
    Inherits clsData

    Protected WithEvents litNbAbonnes As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litNbActifs As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litNbKyb As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litNbAttente As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents litNbCles As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents rptRecents As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlEmpty As Global.System.Web.UI.WebControls.Panel

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            BindKpis()
            BindRecents()
        End If
    End Sub

    Private Sub BindKpis()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@PartenaireId", PartenaireId))
            Dim t As DataTable = ExecuteSQLds("s0118GetPartnerDashboard", p).Tables(0)
            If t.Rows.Count = 0 Then Return
            Dim r As DataRow = t.Rows(0)
            litNbAbonnes.Text = r("NbAbonnes").ToString()
            litNbActifs.Text = r("NbActifs").ToString()
            litNbKyb.Text = r("NbKybVerifie").ToString()
            litNbAttente.Text = r("NbKybEnAttente").ToString()
            litNbCles.Text = r("NbClesActives").ToString()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("PTN Dashboard KPI: " & ex.Message)
        End Try
    End Sub

    Private Sub BindRecents()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@PartenaireId", PartenaireId))
            p.Add(New SqlParameter("@Search", DBNull.Value))
            p.Add(New SqlParameter("@Limit", 5))
            p.Add(New SqlParameter("@Offset", 0))
            Dim t As DataTable = ExecuteSQLds("s0116ListAbonnesForPartner", p).Tables(0)
            rptRecents.DataSource = t
            rptRecents.DataBind()
            rptRecents.Visible = (t.Rows.Count > 0)
            pnlEmpty.Visible = (t.Rows.Count = 0)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("PTN Dashboard recents: " & ex.Message)
        End Try
    End Sub

    ' --- Helpers d'affichage (badges) ---

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
