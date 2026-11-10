Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Web
Imports System.Web.SessionState
Imports System.Web.Script.Serialization

''' <summary>
''' Le rapprochement d'une ligne du relevé bancaire (wbfReleve.aspx), script T367.
''' L'usager doit être authentifié (Session UserId) et avoir une compagnie en session
''' (Session Company) ; chaque procédure est bornée à cette compagnie.
'''
''' POST application/json { action, id, reglementId, docId, ignorer } :
'''   candidats → { ok, ligne, reglements[], factures[] }   (s0978)
'''   lier      → relie la ligne au règlement reglementId     (s0979)
'''   regler    → règle la facture docId depuis la ligne, puis relie (s0980)
'''   delier    → la ligne redevient « Importé »               (s0981)
'''   ignorer   → « Ignoré » (ignorer = true) ou rétablit       (s0982)
''' En cas d'erreur : { ok:false, erreur } (le message de la procédure).
''' </summary>
Public Class ReleveRapprochementHandler
    Implements IHttpHandler, IRequiresSessionState

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

        Dim company As Guid = Guid.Empty
        Try
            If context.Session("Company") IsNot Nothing Then company = CType(context.Session("Company"), Guid)
        Catch
        End Try
        If company = Guid.Empty Then
            Repondre(context, js, 400, New With {.ok = False, .erreur = T("Aucune compagnie sélectionnée.", "No company selected.", "Ninguna empresa seleccionada.")})
            Return
        End If

        Dim action As String = "", id As Integer = 0, reglementId As Integer = 0, docId As Integer = 0, ignorer As Boolean = True
        Dim compteId As Integer = 0, lienId As Integer = 0, montant As Decimal = 0D, libelle As String = ""
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
                If d.ContainsKey("action") AndAlso d("action") IsNot Nothing Then action = Convert.ToString(d("action")).Trim().ToLowerInvariant()
                If d.ContainsKey("id") AndAlso d("id") IsNot Nothing Then Integer.TryParse(Convert.ToString(d("id")), id)
                If d.ContainsKey("reglementId") AndAlso d("reglementId") IsNot Nothing Then Integer.TryParse(Convert.ToString(d("reglementId")), reglementId)
                If d.ContainsKey("docId") AndAlso d("docId") IsNot Nothing Then Integer.TryParse(Convert.ToString(d("docId")), docId)
                If d.ContainsKey("ignorer") AndAlso d("ignorer") IsNot Nothing Then Boolean.TryParse(Convert.ToString(d("ignorer")), ignorer)
                If d.ContainsKey("compteId") AndAlso d("compteId") IsNot Nothing Then Integer.TryParse(Convert.ToString(d("compteId")), compteId)
                If d.ContainsKey("lienId") AndAlso d("lienId") IsNot Nothing Then Integer.TryParse(Convert.ToString(d("lienId")), lienId)
                If d.ContainsKey("montant") AndAlso d("montant") IsNot Nothing Then
                    Decimal.TryParse(Convert.ToString(d("montant"), System.Globalization.CultureInfo.InvariantCulture).Replace(",", "."),
                                     System.Globalization.NumberStyles.Number, System.Globalization.CultureInfo.InvariantCulture, montant)
                End If
                If d.ContainsKey("libelle") AndAlso d("libelle") IsNot Nothing Then libelle = Convert.ToString(d("libelle")).Trim()
            End If
        Catch
        End Try

        If id <= 0 AndAlso action <> "retirer" Then
            Repondre(context, js, 400, New With {.ok = False, .erreur = T("Ligne invalide.", "Invalid line.", "Línea no válida.")})
            Return
        End If

        Try
            Select Case action
                Case "candidats"
                    Dim ds As DataSet = Executer("s0978GetReleveCandidats", company, id)
                    Dim l As DataRow = ds.Tables(0).Rows(0)
                    Dim liens As New List(Of Object)
                    For Each r As DataRow In ds.Tables(1).Rows
                        liens.Add(New With {
                            .id = CInt(r("LienId")), .montant = Dec(r("Montant")), .genre = Txt(r("Genre")),
                            .libelle = Txt(r("Libelle")), .detail = Txt(r("Detail"))})
                    Next
                    Dim regs As New List(Of Object)
                    For Each r As DataRow In ds.Tables(2).Rows
                        regs.Add(New With {
                            .id = CInt(r("Id")), .date = Jour(r("DateReglement")), .montant = Dec(r("Montant")),
                            .tiers = Txt(r("Tiers")), .numeros = Txt(r("Numeros")), .reference = Txt(r("Reference")),
                            .type = Txt(r("TypeReglement")), .probable = CInt(r("Probable")) = 1, .possible = CInt(r("Possible")) = 1})
                    Next
                    Dim facts As New List(Of Object)
                    For Each r As DataRow In ds.Tables(3).Rows
                        facts.Add(New With {
                            .id = CInt(r("Id")), .numero = Txt(r("DocumentNumber")), .echeance = Jour(r("DueDate")),
                            .tiers = Txt(r("Tiers")), .reste = Dec(r("Reste")),
                            .probable = CInt(r("MontantExact")) = 1 OrElse CInt(r("NomTrouve")) = 1})
                    Next
                    Dim comptes As New List(Of Object)
                    For Each r As DataRow In ds.Tables(4).Rows
                        comptes.Add(New With {.id = CInt(r("Id")), .compte = Txt(r("Compte")), .nom = Txt(r("Nom")), .suggere = CInt(r("Suggere")) = 1})
                    Next
                    Repondre(context, js, 200, New With {
                        .ok = True,
                        .ligne = New With {.id = id, .date = Jour(l("DateMouvement")), .description = Txt(l("Description")),
                                           .montant = Dec(l("Montant")), .entree = CBool(l("Entree")),
                                           .relie = Dec(l("Relie")), .reste = Dec(l("Reste")), .verrouillee = CInt(l("Verrouillee")) = 1},
                        .liens = liens, .reglements = regs, .factures = facts, .comptes = comptes})

                Case "lier"
                    If reglementId <= 0 Then Throw New ArgumentException(T("Règlement invalide.", "Invalid payment.", "Pago no válido."))
                    Dim ds As DataSet = Executer("s0979LierReleveReglement", company, id,
                                                 New SqlParameter("@ReglementId", reglementId), New SqlParameter("@UserId", userId))
                    Repondre(context, js, 200, New With {.ok = True, .reste = Dec(ds.Tables(ds.Tables.Count - 1).Rows(0)("Reste"))})

                Case "regler"
                    If docId <= 0 Then Throw New ArgumentException(T("Facture invalide.", "Invalid invoice.", "Factura no válida."))
                    Dim ds As DataSet = Executer("s0980ReglerFactureDepuisReleve", company, id,
                                                 New SqlParameter("@DocumentId", docId), New SqlParameter("@UserId", userId))
                    ' La procédure de règlement renvoie aussi son propre résultat : le nôtre est le dernier.
                    Dim r As DataRow = ds.Tables(ds.Tables.Count - 1).Rows(0)
                    Repondre(context, js, 200, New With {.ok = True, .montant = Dec(r("MontantRegle")),
                                                         .resteFacture = Dec(r("ResteFacture")), .reste = Dec(r("Reste"))})

                Case "inscrire"
                    If compteId <= 0 Then Throw New ArgumentException(T("Choisissez un compte.", "Choose an account.", "Elija una cuenta."))
                    Dim ds As DataSet = Executer("s0989InscrireReleveEcriture", company, id,
                                                 New SqlParameter("@CompteId", compteId),
                                                 New SqlParameter("@Montant", If(montant > 0D, CObj(montant), DBNull.Value)),
                                                 New SqlParameter("@Libelle", If(libelle = "", CObj(DBNull.Value), libelle)),
                                                 New SqlParameter("@UserId", userId))
                    Dim r As DataRow = ds.Tables(ds.Tables.Count - 1).Rows(0)
                    Repondre(context, js, 200, New With {.ok = True, .piece = Txt(r("NumeroPiece")), .montant = Dec(r("Montant")), .reste = Dec(r("Reste"))})

                Case "retirer"
                    If lienId <= 0 Then Throw New ArgumentException(T("Lien invalide.", "Invalid link.", "Vínculo no válido."))
                    Dim ds As DataSet = ExecuterSans("s0990RetirerLienReleve", company, New SqlParameter("@LienId", lienId))
                    Repondre(context, js, 200, New With {.ok = True, .reste = Dec(ds.Tables(ds.Tables.Count - 1).Rows(0)("Reste"))})

                Case "delier"
                    Executer("s0981DelierReleve", company, id)
                    Repondre(context, js, 200, New With {.ok = True})

                Case "ignorer"
                    Executer("s0982IgnorerReleve", company, id, New SqlParameter("@Ignorer", ignorer))
                    Repondre(context, js, 200, New With {.ok = True})

                Case Else
                    Repondre(context, js, 400, New With {.ok = False, .erreur = T("Action inconnue.", "Unknown action.", "Acción desconocida.")})
            End Select
        Catch ex As SqlException
            Repondre(context, js, 200, New With {.ok = False, .erreur = ex.Message})
        Catch ex As ArgumentException
            Repondre(context, js, 200, New With {.ok = False, .erreur = ex.Message})
        Catch ex As Exception
            Repondre(context, js, 500, New With {.ok = False, .erreur = T("Erreur : ", "Error: ", "Error: ") & ex.Message})
        End Try
    End Sub

    Private Shared Function Executer(proc As String, company As Guid, id As Integer, ParamArray autres As SqlParameter()) As DataSet
        Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
            Using cmd As New SqlCommand(proc, conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = 120
                cmd.Parameters.Add(New SqlParameter("@CompanyGUID", company))
                cmd.Parameters.Add(New SqlParameter("@ReleveId", id))
                For Each p As SqlParameter In autres
                    cmd.Parameters.Add(p)
                Next
                Dim ds As New DataSet()
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(ds)
                End Using
                Return ds
            End Using
        End Using
    End Function

    ''' <summary>Une procédure sans @ReleveId (retirer un lien).</summary>
    Private Shared Function ExecuterSans(proc As String, company As Guid, ParamArray autres As SqlParameter()) As DataSet
        Using conn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
            Using cmd As New SqlCommand(proc, conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = 120
                cmd.Parameters.Add(New SqlParameter("@CompanyGUID", company))
                For Each p As SqlParameter In autres
                    cmd.Parameters.Add(p)
                Next
                Dim ds As New DataSet()
                Using da As New SqlDataAdapter(cmd)
                    da.Fill(ds)
                End Using
                Return ds
            End Using
        End Using
    End Function

    Private Shared Function Txt(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return Convert.ToString(o)
    End Function

    Private Shared Function Dec(o As Object) As Decimal
        If o Is Nothing OrElse IsDBNull(o) Then Return 0D
        Return Convert.ToDecimal(o)
    End Function

    Private Shared Function Jour(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return Convert.ToDateTime(o).ToString("yyyy-MM-dd")
    End Function

    Private Function T(fr As String, en As String, es As String) As String
        Select Case _lang
            Case "en" : Return en
            Case "es" : Return es
            Case Else : Return fr
        End Select
    End Function

    Private Shared Sub Repondre(context As HttpContext, js As JavaScriptSerializer, statut As Integer, corps As Object)
        context.Response.StatusCode = statut
        context.Response.Write(js.Serialize(corps))
    End Sub
End Class
