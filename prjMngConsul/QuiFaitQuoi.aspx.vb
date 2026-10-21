Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Web.Script.Serialization

''' <summary>
''' « Qui fait quoi » : la répartition des actions entre l'entreprise, son cabinet
''' et 60secondes (modèle 60secondes-qui-fait-quoi.html). Affichée dans l'onglet
''' « Qui fait quoi » de l'écran Mon cabinet comptable.
'''
''' Chaque action est un paramètre de compagnie (T326, catégorie QUIFAITQUOI) :
''' ShortName « QFQ:<id> », sVal = moi | cabinet | moi+cabinet ; la valeur par
''' défaut (compagnie modèle) est la proposition de 60.
'''
'''   GET  : la page, avec son contexte (window.QFQ_CONTEXTE) : nom de l'entreprise,
'''          cabinet choisi (T323MonCabinet), choix (paramètres QFQ:*), lecture seule.
'''   POST : (JSON, même origine, administrateurs seulement) met à jour les
'''          paramètres QFQ:* des actions modifiées (s0150 / s0151).
'''
''' Profil et métier : paramètres PROFIL et METIER de Paramètres › Entreprise. S'ils
''' manquent, la page invite à les choisir.
''' </summary>
Public Class QuiFaitQuoi
    Inherits clsData


    Private Const Categorie As String = "QUIFAITQUOI"
    Private Const Prefixe As String = "QFQ:"

    Protected ContexteJson As String = "null"

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            If Request.HttpMethod = "POST" Then
                RepondreJson(401, New With {.erreur = "Session expirée : reconnectez-vous."})
            Else
                Response.Redirect("~/Default.aspx")
            End If
            Return
        End If

        If Request.HttpMethod = "POST" Then
            Enregistrer()
            Return
        End If

        Dim js As New JavaScriptSerializer()
        Dim params = LireParams()
        Dim ctx As New Dictionary(Of String, Object) From {
            {"entreprise", CompanyName},
            {"profil", ParamEntreprise("PROFIL")},
            {"metier", ParamEntreprise("METIER")},
            {"cabinet", LireCabinet(js)},
            {"choix", ChoixEnregistres(params)},
            {"urlEnregistrer", ResolveUrl("~/QuiFaitQuoi")},
            {"lectureSeule", Not EstAdmin()}
        }
        ' Inséré dans un <script> : « </ » ne doit pas fermer la balise.
        ContexteJson = js.Serialize(ctx).Replace("</", "<\/")
    End Sub

    ' ---------------------------------------------------------------------
    '  Lecture
    ' ---------------------------------------------------------------------

    ''' <summary>
    ''' Les paramètres QFQ:* de la compagnie : id de l'action → (ParamId, valeur).
    ''' s0150 crée au besoin ceux qui manquent, avec la valeur par défaut du modèle.
    ''' </summary>
    Private Function LireParams() As Dictionary(Of String, KeyValuePair(Of Integer, String))
        Dim res As New Dictionary(Of String, KeyValuePair(Of Integer, String))(StringComparer.Ordinal)
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Categorie", Categorie))
        Dim ds As DataSet = ExecuteSQLds("s0150GetParamsForCompany", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return res
        For Each r As DataRow In ds.Tables(0).Rows
            Dim cle As String = Convert.ToString(r("ShortName"))
            If Not cle.StartsWith(Prefixe, StringComparison.Ordinal) Then Continue For
            res(cle.Substring(Prefixe.Length)) = New KeyValuePair(Of Integer, String)(
                Convert.ToInt32(r("ParamId")), If(IsDBNull(r("sVal")), "", Convert.ToString(r("sVal"))))
        Next
        Return res
    End Function

    ''' <summary>moi | cabinet | moi+cabinet (au moins un responsable).</summary>
    Private Shared Function Valeur(moi As Boolean, cab As Boolean) As String
        If moi AndAlso cab Then Return "moi+cabinet"
        If cab Then Return "cabinet"
        Return "moi"
    End Function
    ''' <summary>Valeur texte d'un paramètre de Paramètres › Entreprise (Nothing si vide).</summary>
    Private _entreprise As DataTable
    Private Function ParamEntreprise(cle As String) As String
        If _entreprise Is Nothing Then
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            p.Add(New SqlParameter("@Categorie", "ENTREPRISE"))
            Dim ds As DataSet = ExecuteSQLds("s0150GetParamsForCompany", p)
            _entreprise = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
        End If
        For Each r As DataRow In _entreprise.Rows
            If String.Equals(Convert.ToString(r("ShortName")), cle, StringComparison.OrdinalIgnoreCase) Then
                Dim v As String = If(IsDBNull(r("sVal")), "", Convert.ToString(r("sVal")).Trim())
                Return If(v = "", Nothing, v)
            End If
        Next
        Return Nothing
    End Function

    ''' <summary>Les choix, au format attendu par la page : [{ id, moi, cabinet }].</summary>
    Private Shared Function ChoixEnregistres(params As Dictionary(Of String, KeyValuePair(Of Integer, String))) As List(Of Object)
        Dim liste As New List(Of Object)
        For Each kv In params
            Dim v As String = kv.Value.Value.ToLowerInvariant()
            Dim moi As Boolean = v.Contains("moi"), cab As Boolean = v.Contains("cabinet")
            If Not moi AndAlso Not cab Then Continue For     ' valeur vide ou inconnue : la page part de la proposition de 60
            liste.Add(New Dictionary(Of String, Object) From {{"id", kv.Key}, {"moi", moi}, {"cabinet", cab}})
        Next
        Return liste
    End Function
    ''' <summary>Le cabinet choisi dans Mon cabinet comptable, ou Nothing s'il n'y en a pas.</summary>
    Private Function LireCabinet(js As JavaScriptSerializer) As Object
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0908GetMonCabinet", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return Nothing

            Dim etat = js.Deserialize(Of Dictionary(Of String, Object))(Convert.ToString(ds.Tables(0).Rows(0)("Etat")))
            Dim cab = TryCast(If(etat IsNot Nothing AndAlso etat.ContainsKey("cabinet"), etat("cabinet"), Nothing), Dictionary(Of String, Object))
            If cab Is Nothing Then Return Nothing

            Dim nom As String = If(cab.ContainsKey("nom"), Convert.ToString(cab("nom")), "")
            If String.IsNullOrWhiteSpace(nom) Then Return Nothing
            ' Un cabinet de l'annuaire porte sa certification (« Certifié · 2026 ») ; un comptable invité, non.
            Dim cert As String = If(cab.ContainsKey("cert"), Convert.ToString(cab("cert")), "")
            Return New Dictionary(Of String, Object) From {{"nom", nom}, {"certifie", Not String.IsNullOrWhiteSpace(cert)}}
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("QuiFaitQuoi : " & ex.Message)
            Return Nothing
        End Try
    End Function

    ''' <summary>Administrateur actif, lu en base à chaque appel (comme MonCabinet.ashx).</summary>
    Private Function EstAdmin() As Boolean
        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@Id", UserId))
            Dim ds As DataSet = ExecuteSQLds("s0314GetUserByUserId", p)
            If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return False
            Dim r As DataRow = ds.Tables(0).Rows(0)
            Return r IsNot Nothing AndAlso
                   Not IsDBNull(r("IsAdmin")) AndAlso CBool(r("IsAdmin")) AndAlso
                   Not IsDBNull(r("IsActive")) AndAlso CBool(r("IsActive"))
        Catch
            Return False
        End Try
    End Function

    ' ---------------------------------------------------------------------
    '  Enregistrement (POST JSON de js/qui-fait-quoi.js)
    '  Corps : { profil, metier, cabinet, activites: [{ id, statut, moi, cabinet, … }] }
    ' ---------------------------------------------------------------------
    Private Sub Enregistrer()
        If Not EstAdmin() Then
            RepondreJson(403, New With {.erreur = "Seul un administrateur peut modifier la répartition."})
            Return
        End If

        ' Même origine seulement.
        Dim origine As String = Request.Headers("Origin")
        If Not String.IsNullOrEmpty(origine) Then
            Dim o As Uri = Nothing
            If Not Uri.TryCreate(origine, UriKind.Absolute, o) OrElse
               Not String.Equals(o.Authority, Request.Url.Authority, StringComparison.OrdinalIgnoreCase) Then
                RepondreJson(403, New With {.erreur = "Origine refusée."})
                Return
            End If
        End If
        If Not If(Request.ContentType, "").StartsWith("application/json", StringComparison.OrdinalIgnoreCase) Then
            RepondreJson(415, New With {.erreur = "JSON attendu."})
            Return
        End If
        If Request.ContentLength > 512 * 1024 Then
            RepondreJson(413, New With {.erreur = "Contenu trop volumineux."})
            Return
        End If

        Dim corps As String
        Using lecteur As New StreamReader(Request.InputStream, Encoding.UTF8)
            corps = lecteur.ReadToEnd()
        End Using

        Dim js As New JavaScriptSerializer() With {.MaxJsonLength = 1024 * 1024}
        Dim doc As Dictionary(Of String, Object) = Nothing
        Try
            doc = js.Deserialize(Of Dictionary(Of String, Object))(corps)
        Catch
        End Try
        Dim activites = TryCast(If(doc IsNot Nothing AndAlso doc.ContainsKey("activites"), doc("activites"), Nothing), ArrayList)
        If activites Is Nothing Then
            RepondreJson(400, New With {.erreur = "Contenu invalide."})
            Return
        End If


        ' Une mise à jour par action dont la valeur change (actions de la compagnie seulement :
        ' un id inconnu des paramètres QFQ:* est ignoré).
        Dim params = LireParams()
        Dim nb As Integer = 0
        For Each item In activites
            Dim a = TryCast(item, Dictionary(Of String, Object))
            If a Is Nothing OrElse Not a.ContainsKey("id") Then Continue For
            Dim id As String = Convert.ToString(a("id"))
            If Not params.ContainsKey(id) Then Continue For
            Dim moi As Boolean = a.ContainsKey("moi") AndAlso Convert.ToBoolean(a("moi"))
            Dim cab As Boolean = a.ContainsKey("cabinet") AndAlso Convert.ToBoolean(a("cabinet"))
            If Not moi AndAlso Not cab Then Continue For      ' action de 60, Phase 2, Hors 60secondes
            Dim v As String = Valeur(moi, cab)
            If String.Equals(params(id).Value, v, StringComparison.OrdinalIgnoreCase) Then Continue For

            Dim p As New Collection
            p.Add(New SqlParameter("@ParamId", params(id).Key))
            p.Add(New SqlParameter("@sVal", SqlDbType.VarChar, 8000) With {.Value = v})
            ExecuteSQL("s0151UpdateParamValue", p)
            nb += 1
        Next
        RepondreJson(200, New With {.ok = True, .nb = nb})
    End Sub

    Private Sub RepondreJson(statut As Integer, contenu As Object)
        Response.Clear()
        Response.StatusCode = statut
        Response.ContentType = "application/json; charset=utf-8"
        Response.Cache.SetCacheability(HttpCacheability.NoCache)
        Response.Write(New JavaScriptSerializer().Serialize(contenu))
        Context.ApplicationInstance.CompleteRequest()
        SuppressContent = True
    End Sub

    ' Après RepondreJson, la page ne doit rien rendre d'autre.
    Private SuppressContent As Boolean = False
    Protected Overrides Sub Render(writer As HtmlTextWriter)
        If Not SuppressContent Then MyBase.Render(writer)
    End Sub
End Class
