Imports System.Data
Imports System.Data.SqlClient

''' <summary>
''' Demandes de clients (Portail comptable, admin/solo) : les entreprises qui ont
''' demandé ce cabinet dans l'annuaire. Accepter → la compagnie devient un dossier
''' (ComptableGUID posé) ; Refuser → écartée. Procs s0939/s0940.
''' </summary>
Public Class wbfCabDemandes
    Inherits clsData

    Protected WithEvents litTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litMsg As System.Web.UI.WebControls.Literal
    Protected WithEvents rptDemandes As System.Web.UI.WebControls.Repeater
    Protected WithEvents litVide As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated OrElse Not IsAccountant Then
            Response.Redirect("~/Default.aspx") : Return
        End If
        Dim role As String = RoleCabinet()
        If role <> "admin" AndAlso role <> "solo" Then
            Response.Redirect("~/wbfCabTableauBord.aspx") : Return
        End If

        EnPortailComptable = True
        DirectCast(Master, SiteMaster).FondDePage = True

        If Not IsPostBack Then
            Textes()
            BindDemandes()
        End If
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Function RoleCabinet() As String
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@UserId", UserEmail))
            Dim ds As DataSet = ExecuteSQLds("s0919GetUserCabinet", p)
            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Return Convert.ToString(ds.Tables(0).Rows(0)("Role")).Trim().ToLowerInvariant()
            End If
        Catch
        End Try
        Return ""
    End Function

    Private Sub Textes()
        litTitre.Text = Server.HtmlEncode(T("Demandes de clients", "Client requests", "Solicitudes de clientes"))
        litSous.Text = Server.HtmlEncode(T("Des entreprises ont choisi votre cabinet. Acceptez-les pour les ajouter à vos dossiers.",
                                           "Businesses chose your firm. Accept them to add them to your files.",
                                           "Empresas eligieron su despacho. Acéptelas para añadirlas a sus expedientes."))
    End Sub

    Private Sub BindDemandes()
        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        Dim ds As DataSet = ExecuteSQLds("s0939ListDemandesCabinet", p)
        Dim dt As DataTable = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
        rptDemandes.DataSource = dt
        rptDemandes.DataBind()
        litVide.Text = If(dt.Rows.Count = 0, "<div class=""vide"">" & Server.HtmlEncode(T("Aucune demande en attente.", "No pending request.", "Ninguna solicitud pendiente.")) & "</div>", "")
    End Sub

    Protected Sub rptDemandes_ItemCommand(source As Object, e As RepeaterCommandEventArgs) Handles rptDemandes.ItemCommand
        Dim id As Integer = CInt(e.CommandArgument)
        Dim decision As String = If(e.CommandName = "accepter", "accepter", "refuser")

        Dim p As New Collection
        p.Add(New SqlParameter("@UserId", UserEmail))
        p.Add(New SqlParameter("@Id", id))
        p.Add(New SqlParameter("@Decision", decision))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s0940TraiterDemandeCabinet", p)

        BindDemandes()
        If e.CommandName = "accepter" Then
            litMsg.Text = "<div class=""msg"">" & Server.HtmlEncode(T("Demande acceptée. La compagnie est maintenant un dossier (à confier dans « Clients non associés »).",
                "Request accepted. The company is now a file (to assign under « Unassigned clients »).",
                "Solicitud aceptada. La empresa ahora es un expediente (a asignar en « Clientes sin asignar »).")) & "</div>"
        Else
            litMsg.Text = "<div class=""msg"">" & Server.HtmlEncode(T("Demande refusée.", "Request declined.", "Solicitud rechazada.")) & "</div>"
        End If
    End Sub

    ' ---- Helpers de rendu ----
    Protected Function MsgText(m As Object) As String
        If m Is Nothing OrElse IsDBNull(m) OrElse Convert.ToString(m).Trim() = "" Then
            Return Server.HtmlEncode(T("(sans message)", "(no message)", "(sin mensaje)"))
        End If
        Return Server.HtmlEncode(Convert.ToString(m))
    End Function

    Protected Function DateText(d As Object) As String
        If d Is Nothing OrElse IsDBNull(d) Then Return ""
        Return Server.HtmlEncode(Convert.ToDateTime(d).ToLocalTime().ToString("yyyy-MM-dd"))
    End Function

    Protected Function ConfirmJs() As String
        Dim msg As String = T("Refuser cette demande ?", "Decline this request?", "¿Rechazar esta solicitud?")
        Return "if(!confirm('" & HttpUtility.JavaScriptStringEncode(msg) & "')){return false;}"
    End Function

    Protected ReadOnly Property LblAccepter As String
        Get
            Return T("Accepter", "Accept", "Aceptar")
        End Get
    End Property
    Protected ReadOnly Property LblRefuser As String
        Get
            Return T("Refuser", "Decline", "Rechazar")
        End Get
    End Property

End Class
