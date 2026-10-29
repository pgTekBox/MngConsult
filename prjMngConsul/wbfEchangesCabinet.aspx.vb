Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

''' <summary>
''' Messages du cabinet — côté client (ERP de l'entreprise). Fil à deux sens avec
''' le cabinet comptable du dossier. Scopé sur la compagnie de session. Lecture
''' s0951 ; réponse s0953 ; marque lu s0954 ('client').
''' </summary>
Public Class wbfEchangesCabinet
    Inherits clsData

    Protected WithEvents litTitre As System.Web.UI.WebControls.Literal
    Protected WithEvents litSous As System.Web.UI.WebControls.Literal
    Protected WithEvents litFil As System.Web.UI.WebControls.Literal
    Protected WithEvents pnlEnvoi As System.Web.UI.WebControls.Panel
    Protected WithEvents txtRep As System.Web.UI.WebControls.TextBox
    Protected WithEvents btnRep As System.Web.UI.WebControls.Button
    Protected WithEvents litMsg As System.Web.UI.WebControls.Literal

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("~/wbfLogin.aspx") : Return
        End If
        DirectCast(Master, SiteMaster).FondDePage = True

        Textes()
        If Not IsPostBack Then
            BindFil()
            MarkLu()
        End If
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case CurrentLang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Sub Textes()
        litTitre.Text = Server.HtmlEncode(T("Messages du cabinet", "Firm messages", "Mensajes del despacho"))
        litSous.Text = Server.HtmlEncode(T("Échangez directement avec votre cabinet comptable.",
                                           "Communicate directly with your accounting firm.",
                                           "Comuníquese directamente con su despacho contable."))
        btnRep.Text = T("Envoyer", "Send", "Enviar")
    End Sub

    Private Sub BindFil()
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        Dim ds As DataSet = ExecuteSQLds("s0951ListEchanges", p)
        Dim sb As New StringBuilder()
        If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
            For Each r As DataRow In ds.Tables(0).Rows
                ' Côté client : ses propres messages (client) à droite, le cabinet à gauche.
                Dim estMoi As Boolean = (Convert.ToString(r("Expediteur")) = "client")
                Dim cls As String = If(estMoi, "moi", "cab")
                Dim quand As String = Convert.ToDateTime(r("Utc")).ToLocalTime().ToString("yyyy-MM-dd HH:mm")
                Dim qui As String = If(estMoi, T("Vous", "You", "Usted"),
                                       If(IsDBNull(r("ExpNom")) OrElse Convert.ToString(r("ExpNom")).Trim() = "",
                                          T("Votre cabinet", "Your firm", "Su despacho"), Convert.ToString(r("ExpNom"))))
                sb.Append("<div class=""bulle ").Append(cls).Append(""">")
                sb.Append("<div class=""meta"">").Append(Server.HtmlEncode(qui & " · " & quand)).Append("</div>")
                sb.Append(Server.HtmlEncode(Convert.ToString(r("Texte"))).Replace(vbCrLf, "<br/>").Replace(vbLf, "<br/>"))
                sb.Append("</div>")
            Next
        Else
            sb.Append("<div class=""vide"">").Append(Server.HtmlEncode(T("Aucun message pour l'instant.", "No message yet.", "Ningún mensaje aún."))).Append("</div>")
        End If
        litFil.Text = sb.ToString()
    End Sub

    Private Sub MarkLu()
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Cote", "client"))
            ExecuteSQL("s0954MarkEchangesLus", p)
        Catch
        End Try
    End Sub

    Protected Sub btnRep_Click(sender As Object, e As EventArgs) Handles btnRep.Click
        Dim texte As String = If(txtRep.Text, "").Trim()
        If texte = "" Then BindFil() : Return

        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@UserId", UserId))
        p.Add(New SqlParameter("@Texte", texte))
        Dim outErr As New SqlParameter("@ErrorCode", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
        p.Add(outErr)
        ExecuteSQL("s0953AddEchangeClient", p)

        Dim err As Integer = If(outErr.Value Is Nothing OrElse IsDBNull(outErr.Value), -1, CInt(outErr.Value))
        txtRep.Text = ""
        BindFil()
        If err = 6 Then
            litMsg.Text = "<div class=""msg"" style=""background:#FDECEA;color:#A3261C"">" & Server.HtmlEncode(T("Aucun cabinet n'est rattaché à votre entreprise.", "No firm is linked to your company.", "Ningún despacho está vinculado a su empresa.")) & "</div>"
        Else
            litMsg.Text = "<div class=""msg"">" & Server.HtmlEncode(T("Message envoyé.", "Message sent.", "Mensaje enviado.")) & "</div>"
        End If
    End Sub

End Class
