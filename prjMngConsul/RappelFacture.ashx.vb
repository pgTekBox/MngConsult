Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.IO
Imports System.Text
Imports System.Web
Imports System.Web.SessionState
Imports System.Web.Script.Serialization

''' <summary>
''' Les boutons d'une activité « Facture en retard » du tableau de bord (Default.aspx).
''' L'usager doit être authentifié (Session UserId) et avoir une compagnie en session
''' (Session Company) ; la facture est toujours lue bornée à cette compagnie (s0976).
'''
''' POST application/json { docId, canal } :
'''   canal = "texto"    → inscrit le rappel (T206, s0975) et renvoie { ok, tel, message } :
'''                        la page ouvre l'application de messagerie (lien sms:) avec le
'''                        texte prêt à envoyer ; aucun fournisseur SMS n'est branché.
'''   canal = "courriel" → dépose un courriel de rappel dans MailService (s0610, Reply-To =
'''                        courriel vérifié de la compagnie), inscrit le rappel et renvoie
'''                        { ok, email }.
'''   canal = "sync"     → relance tout de suite l'inscription des activités de la compagnie
'''                        (s0973), par exemple après l'enregistrement d'un paiement.
''' En cas d'erreur : { ok:false, erreur }.
''' </summary>
Public Class RappelFactureHandler
    Implements IHttpHandler, IReadOnlySessionState

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Private _lang As String = "fr"

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json; charset=utf-8"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Dim js As New JavaScriptSerializer()

        Try
            Dim l As String = Convert.ToString(context.Session("Lang"))
            If l = "en" OrElse l = "es" Then _lang = l
        Catch
        End Try

        ' Authentification : UserId en session (posé à la connexion).
        Dim userId As Integer = 0
        Try
            If context.Session IsNot Nothing AndAlso context.Session("UserId") IsNot Nothing Then
                userId = Convert.ToInt32(context.Session("UserId"))
            End If
        Catch
        End Try
        If userId = 0 Then
            Repondre(context, js, 403, New With {.ok = False, .erreur = T("Non authentifié.", "Not signed in.", "No autenticado.")})
            Return
        End If

        If context.Request.HttpMethod.ToUpperInvariant() <> "POST" Then
            Repondre(context, js, 405, New With {.ok = False, .erreur = "POST"})
            Return
        End If

        ' Compagnie de session : obligatoire (isolation par compagnie).
        Dim company As Guid = Guid.Empty
        Try
            If context.Session("Company") IsNot Nothing Then company = CType(context.Session("Company"), Guid)
        Catch
        End Try
        If company = Guid.Empty Then
            Repondre(context, js, 400, New With {.ok = False, .erreur = T("Aucune compagnie sélectionnée.", "No company selected.", "Ninguna empresa seleccionada.")})
            Return
        End If

        ' Corps JSON : { docId, canal }
        Dim docId As Integer = 0
        Dim canal As String = ""
        Try
            If context.Request.ContentLength > 10000 Then
                Repondre(context, js, 413, New With {.ok = False, .erreur = "413"})
                Return
            End If
            Dim brut As String
            Using lecteur As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                brut = lecteur.ReadToEnd()
            End Using
            Dim d As Dictionary(Of String, Object) = TryCast(js.DeserializeObject(brut), Dictionary(Of String, Object))
            If d IsNot Nothing Then
                If d.ContainsKey("docId") AndAlso d("docId") IsNot Nothing Then Integer.TryParse(Convert.ToString(d("docId")), docId)
                If d.ContainsKey("canal") AndAlso d("canal") IsNot Nothing Then canal = Convert.ToString(d("canal")).Trim().ToLowerInvariant()
            End If
        Catch
        End Try

        Try
            Select Case canal
                Case "sync"
                    Synchroniser(company)
                    Repondre(context, js, 200, New With {.ok = True})

                Case "texto", "courriel"
                    If docId <= 0 Then
                        Repondre(context, js, 400, New With {.ok = False, .erreur = T("Facture invalide.", "Invalid invoice.", "Factura no válida.")})
                        Return
                    End If
                    Dim f As DataRow = LireFacture(company, docId)
                    If f Is Nothing Then
                        Repondre(context, js, 404, New With {.ok = False, .erreur = T("Facture introuvable.", "Invoice not found.", "Factura no encontrada.")})
                        Return
                    End If
                    If Dec(f("ResteAPayer")) <= 0.005D Then
                        Repondre(context, js, 200, New With {.ok = False, .erreur = T("Cette facture est déjà payée.", "This invoice is already paid.", "Esta factura ya está pagada.")})
                        Return
                    End If
                    If canal = "texto" Then
                        Texto(context, js, company, userId, docId, f)
                    Else
                        Courriel(context, js, company, userId, docId, f)
                    End If

                Case Else
                    Repondre(context, js, 400, New With {.ok = False, .erreur = T("Action inconnue.", "Unknown action.", "Acción desconocida.")})
            End Select
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("RappelFacture : " & ex.Message)
            Repondre(context, js, 500, New With {.ok = False, .erreur = T("Le rappel n'a pas pu être envoyé.", "The reminder could not be sent.", "No se pudo enviar el recordatorio.")})
        End Try
    End Sub

    ' ---------------------------------------------------------------------
    ' Les canaux
    ' ---------------------------------------------------------------------

    ''' <summary>Texto : le message prêt à envoyer depuis l'application de messagerie.</summary>
    Private Sub Texto(context As HttpContext, js As JavaScriptSerializer, company As Guid, userId As Integer, docId As Integer, f As DataRow)
        Dim tel As String = NormaliserTel(Txt(f("Telephone")))
        If tel = "" Then
            Repondre(context, js, 200, New With {.ok = False, .erreur = T(
                "Aucun numéro de téléphone pour ce client. Ajoutez-le dans sa fiche ou sur la facture.",
                "No phone number for this customer. Add it to their record or to the invoice.",
                "No hay número de teléfono para este cliente. Agréguelo en su ficha o en la factura.")})
            Return
        End If

        Dim message As String = String.Format(T(
            "Bonjour {0}, petit rappel : la facture {1} de {2} est échue depuis le {3}. Merci de votre paiement !",
            "Hello {0}, a friendly reminder: invoice {1} for {2} was due on {3}. Thank you for your payment!",
            "Hola {0}, un recordatorio: la factura {1} de {2} venció el {3}. ¡Gracias por su pago!"),
            Txt(f("Client")), LireNumero(f), Montant(Dec(f("ResteAPayer"))), DateLongue(f("DueDate")))
        If Txt(f("CompanyName")) <> "" Then message &= " — " & Txt(f("CompanyName"))

        Inscrire(company, docId, "TEXTO", tel, userId, Nothing)
        Repondre(context, js, 200, New With {.ok = True, .tel = tel, .message = message})
    End Sub

    ''' <summary>Courriel : déposé dans la file MailService, envoyé par SrvAI au prochain cycle.</summary>
    Private Sub Courriel(context As HttpContext, js As JavaScriptSerializer, company As Guid, userId As Integer, docId As Integer, f As DataRow)
        Dim email As String = Txt(f("Email"))
        If email = "" OrElse Not email.Contains("@") Then
            Repondre(context, js, 200, New With {.ok = False, .erreur = T(
                "Aucune adresse courriel pour ce client. Ajoutez-la dans sa fiche ou sur la facture.",
                "No email address for this customer. Add it to their record or to the invoice.",
                "No hay correo electrónico para este cliente. Agréguelo en su ficha o en la factura.")})
            Return
        End If

        Dim numero As String = LireNumero(f)
        Dim compagnie As String = Txt(f("CompanyName"))
        Dim enc = Function(s As String) HttpUtility.HtmlEncode(s)

        Dim sujet As String = String.Format(T("Rappel : facture {0}", "Reminder: invoice {0}", "Recordatorio: factura {0}"), numero) &
                              If(compagnie <> "", " — " & compagnie, "")
        Dim corps As New StringBuilder()
        corps.Append("<div style=""font-family:Segoe UI,Arial,sans-serif;font-size:14px;color:#1f2937;"">")
        corps.Append("<p>").Append(enc(String.Format(T("Bonjour {0},", "Hello {0},", "Hola {0}:"), Txt(f("Client"))))).Append("</p>")
        corps.Append("<p>").Append(enc(String.Format(T(
            "Notre facture {0}, échue le {1}, n'est pas encore réglée.",
            "Our invoice {0}, due on {1}, has not been paid yet.",
            "Nuestra factura {0}, vencida el {1}, aún no ha sido pagada."), numero, DateLongue(f("DueDate"))))).Append("</p>")
        corps.Append("<p>").Append(enc(T("Solde dû : ", "Balance due: ", "Saldo pendiente: "))).Append("<strong>").Append(enc(Montant(Dec(f("ResteAPayer"))))).Append("</strong></p>")
        corps.Append("<p>").Append(enc(T(
            "Si le paiement est déjà parti, merci d'ignorer ce message.",
            "If the payment has already been sent, please disregard this message.",
            "Si el pago ya fue enviado, ignore este mensaje."))).Append("</p>")
        If compagnie <> "" Then corps.Append("<p>").Append(enc(compagnie)).Append("</p>")
        corps.Append("</div>")

        Dim pm As New Collection
        pm.Add(New SqlParameter("@To", email))
        pm.Add(New SqlParameter("@Subject", sujet))
        pm.Add(New SqlParameter("@HTMLBody", corps.ToString()))
        ' Reply-To = courriel vérifié de la compagnie (jamais en From : SPF)
        CompanyMail.AddReplyToParam(pm, ConnectionString, company)

        Dim mailId As Integer? = Nothing
        Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionStringMail"))
            Using cmd As New SqlCommand("s0610InsertOutboundMail", conn) With {.CommandType = CommandType.StoredProcedure}
                For Each p As SqlParameter In pm : cmd.Parameters.Add(p) : Next
                conn.Open()
                Dim v As Object = cmd.ExecuteScalar()
                If v IsNot Nothing AndAlso Not IsDBNull(v) Then mailId = Convert.ToInt32(v)
            End Using
        End Using

        Inscrire(company, docId, "COURRIEL", email, userId, mailId)
        Repondre(context, js, 200, New With {.ok = True, .email = email})
    End Sub

    ' ---------------------------------------------------------------------
    ' Base de données
    ' ---------------------------------------------------------------------

    Private Shared ReadOnly Property ConnectionString As String
        Get
            Return ConfigurationManager.AppSettings("ConnectionString")
        End Get
    End Property

    Private Shared Function LireFacture(company As Guid, docId As Integer) As DataRow
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand("s0976GetFactureRappel", conn) With {.CommandType = CommandType.StoredProcedure}
                cmd.Parameters.Add(New SqlParameter("@CompanyGUID", company))
                cmd.Parameters.Add(New SqlParameter("@DocumentId", docId))
                Dim dt As New DataTable()
                Using da As New SqlDataAdapter(cmd) : da.Fill(dt) : End Using
                Return If(dt.Rows.Count > 0, dt.Rows(0), Nothing)
            End Using
        End Using
    End Function

    Private Shared Sub Inscrire(company As Guid, docId As Integer, canal As String, destinataire As String, userId As Integer, mailId As Integer?)
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand("s0975InsertRappelFacture", conn) With {.CommandType = CommandType.StoredProcedure}
                cmd.Parameters.Add(New SqlParameter("@CompanyGUID", company))
                cmd.Parameters.Add(New SqlParameter("@DocumentId", docId))
                cmd.Parameters.Add(New SqlParameter("@Canal", canal))
                cmd.Parameters.Add(New SqlParameter("@Destinataire", If(destinataire, CObj(DBNull.Value))))
                cmd.Parameters.Add(New SqlParameter("@UserId", userId))
                cmd.Parameters.Add(New SqlParameter("@MailId", If(mailId.HasValue, CObj(mailId.Value), DBNull.Value)))
                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    ''' <summary>Réinscrit tout de suite les activités de la compagnie (s0973).</summary>
    Private Shared Sub Synchroniser(company As Guid)
        Using conn As New SqlConnection(ConnectionString)
            Using cmd As New SqlCommand("s0973SyncActivitesAFaire", conn) With {.CommandType = CommandType.StoredProcedure, .CommandTimeout = 120}
                cmd.Parameters.Add(New SqlParameter("@CompanyGUID", company))
                conn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    ' ---------------------------------------------------------------------
    ' Petits outils
    ' ---------------------------------------------------------------------

    Private Sub Repondre(context As HttpContext, js As JavaScriptSerializer, statut As Integer, o As Object)
        context.Response.StatusCode = statut
        context.Response.Write(js.Serialize(o))
    End Sub

    Private Function T(fr As String, en As String, es As String) As String
        Select Case _lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Function Cult() As CultureInfo
        Select Case _lang
            Case "en" : Return New CultureInfo("en-CA")
            Case "es" : Return New CultureInfo("es-ES")
            Case Else : Return New CultureInfo("fr-CA")
        End Select
    End Function

    Private Function Montant(v As Decimal) As String
        If _lang = "en" Then Return v.ToString("C2", New CultureInfo("en-CA"))
        Return v.ToString("N2", Cult()) & " $"
    End Function

    Private Function DateLongue(v As Object) As String
        If v Is Nothing OrElse IsDBNull(v) Then Return ""
        Dim d As Date = Convert.ToDateTime(v)
        If _lang = "en" Then Return d.ToString("MMMM d, yyyy", Cult())
        Return d.ToString("d MMMM yyyy", Cult())
    End Function

    ''' <summary>« #1040 » pour un numéro, le numéro tel quel sinon.</summary>
    Private Shared Function LireNumero(f As DataRow) As String
        Dim n As String = Txt(f("DocumentNumber"))
        If n = "" Then Return "#" & Txt(f("Id"))
        Return If(Char.IsDigit(n(0)), "#" & n, n)
    End Function

    ''' <summary>Garde les chiffres (et un + initial) ; 10 chiffres nord-américains → +1.</summary>
    Private Shared Function NormaliserTel(s As String) As String
        If String.IsNullOrWhiteSpace(s) Then Return ""
        Dim plus As Boolean = s.Trim().StartsWith("+")
        Dim chiffres As New StringBuilder()
        For Each c As Char In s
            If Char.IsDigit(c) Then chiffres.Append(c)
        Next
        Dim n As String = chiffres.ToString()
        If n.Length < 7 Then Return ""
        If plus Then Return "+" & n
        If n.Length = 10 Then Return "+1" & n
        If n.Length = 11 AndAlso n.StartsWith("1") Then Return "+" & n
        Return n
    End Function

    Private Shared Function Txt(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return Convert.ToString(o).Trim()
    End Function

    Private Shared Function Dec(o As Object) As Decimal
        If o Is Nothing OrElse IsDBNull(o) Then Return 0D
        Return Convert.ToDecimal(o)
    End Function

End Class
