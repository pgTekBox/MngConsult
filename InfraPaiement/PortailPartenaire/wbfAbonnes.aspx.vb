Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Liste des abonnés (tenants) provisionnés par le partenaire connecté.
''' Recherche + pagination. Scopé au PartenaireId de la session (isolation).
''' </summary>
Public Class wbfAbonnes
    Inherits clsData

    Protected WithEvents tbSearch As Global.System.Web.UI.WebControls.TextBox
    Protected WithEvents btnSearch As Global.System.Web.UI.WebControls.Button
    Protected WithEvents pnlError As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents litError As Global.System.Web.UI.WebControls.Literal
    Protected WithEvents rptList As Global.System.Web.UI.WebControls.Repeater
    Protected WithEvents pnlEmpty As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents pnlPager As Global.System.Web.UI.WebControls.Panel
    Protected WithEvents btnPrev As Global.System.Web.UI.WebControls.LinkButton
    Protected WithEvents btnNext As Global.System.Web.UI.WebControls.LinkButton
    Protected WithEvents litRange As Global.System.Web.UI.WebControls.Literal

    Private Const PageSize As Integer = 25

    Private Property Offset() As Integer
        Get
            Return If(ViewState("off") Is Nothing, 0, CInt(ViewState("off")))
        End Get
        Set(value As Integer)
            ViewState("off") = value
        End Set
    End Property

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsAuthenticated Then Return
        If Not IsPostBack Then
            Offset = 0
            Bind()
        End If
    End Sub

    Protected Sub btnSearch_Click(sender As Object, e As EventArgs)
        Offset = 0
        Bind()
    End Sub

    Protected Sub btnPrev_Click(sender As Object, e As EventArgs)
        Offset = Math.Max(0, Offset - PageSize)
        Bind()
    End Sub

    Protected Sub btnNext_Click(sender As Object, e As EventArgs)
        Offset = Offset + PageSize
        Bind()
    End Sub

    Private Sub Bind()
        Try
            Dim search As String = If(tbSearch.Text, "").Trim()
            Dim p As New Collection
            p.Add(New SqlParameter("@PartenaireId", PartenaireId))
            p.Add(New SqlParameter("@Search", If(search.Length = 0, CObj(DBNull.Value), search)))
            p.Add(New SqlParameter("@Limit", PageSize + 1))
            p.Add(New SqlParameter("@Offset", Offset))
            Dim t As DataTable = ExecuteSQLds("s0116ListAbonnesForPartner", p).Tables(0)

            Dim hasMore As Boolean = (t.Rows.Count > PageSize)
            If hasMore Then t.Rows.RemoveAt(t.Rows.Count - 1)

            rptList.DataSource = t
            rptList.DataBind()
            rptList.Visible = (t.Rows.Count > 0)
            pnlEmpty.Visible = (t.Rows.Count = 0)

            Dim first As Integer = If(t.Rows.Count = 0, 0, Offset + 1)
            Dim last As Integer = Offset + t.Rows.Count
            litRange.Text = first & "–" & last
            btnPrev.Enabled = (Offset > 0)
            btnNext.Enabled = hasMore
            pnlPager.Visible = (Offset > 0 OrElse hasMore)
        Catch ex As Exception
            pnlError.Visible = True
            litError.Text = "Impossible de charger les abonnés. Vérifiez que le script de base de données 42 a été exécuté."
            System.Diagnostics.Debug.WriteLine("PTN Abonnes Bind: " & ex.Message)
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
