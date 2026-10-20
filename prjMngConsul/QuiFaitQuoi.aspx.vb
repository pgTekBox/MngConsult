Imports System.Data.SqlClient
Imports System.IO
Imports System.Text
Imports System.Web.Script.Serialization

''' <summary>
''' « Qui fait quoi » : la répartition des actions entre l'entreprise, son cabinet
''' et 60secondes (modèle 60secondes-qui-fait-quoi.html). Affichée dans l'onglet
''' « Qui fait quoi » de la fenêtre Mon cabinet comptable.
'''
'''   GET  : la page, avec son contexte (window.QFQ_CONTEXTE) : nom de l'entreprise,
'''          cabinet choisi (T323MonCabinet), choix enregistrés, lecture seule.
'''   POST : (JSON, même origine, administrateurs seulement) enregistre les choix
'''          dans le paramètre de compagnie QFQ_CHOIX (s0150 / s0151).
'''
''' Profil et métier ne sont pas encore des données de l'entreprise : en
''' attendant, ceux de la démonstration du modèle.
''' </summary>
Public Class QuiFaitQuoi
    Inherits clsData

    ' À remplacer quand le profil et le métier de l'entreprise seront enregistrés.
    Private Const ProfilDemo As String = "TA"
    Private Const MetierDemo As String = "Massothérapeute"

    Private Const Categorie As String = "QUIFAITQUOI"
    Private Const Cle As String = "QFQ_CHOIX"
    Private Const TailleMax As Integer = 8000      ' T101ParamValues.sVal

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
        Dim param As DataRow = LireParam()
        Dim ctx As New Dictionary(Of String, Object) From {
            {"entreprise", CompanyName},
            {"profil", ProfilDemo},
            {"metier", MetierDemo},
            {"cabinet", LireCabinet(js)},
            {"choix", ChoixEnregistres(js, param)},
            {"urlEnregistrer", ResolveUrl("~/QuiFaitQuoi")},
            {"lectureSeule", Not EstAdmin()}
        }
        ' Inséré dans un <script> : « </ » ne doit pas fermer la balise.
        ContexteJson = js.Serialize(ctx).Replace("</", "<\/")
    End Sub

    ' ---------------------------------------------------------------------
    '  Lecture
    ' ---------------------------------------------------------------------

    ''' <summary>Le paramètre QFQ_CHOIX de la compagnie (s0150 le crée au besoin à partir du modèle).</summary>
    Private Function LireParam() As DataRow
        Dim p As New Collection
        p.Add(New SqlParameter("@CompanyGUID", Company))
        p.Add(New SqlParameter("@Categorie", Categorie))
        Dim ds As DataSet = ExecuteSQLds("s0150GetParamsForCompany", p)
        If ds Is Nothing OrElse ds.Tables.Count = 0 Then Return Nothing
        For Each r As DataRow In ds.Tables(0).Rows
            If String.Equals(Convert.ToString(r("ShortName")), Cle, StringComparison.OrdinalIgnoreCase) Then Return r
        Next
        Return Nothing
    End Function

    ''' <summary>Les choix enregistrés, au format attendu par la page : [{ id, moi, cabinet }].</summary>
    Private Shared Function ChoixEnregistres(js As JavaScriptSerializer, param As DataRow) As List(Of Object)
        Dim liste As New List(Of Object)
        If param Is Nothing OrElse IsDBNull(param("sVal")) Then Return liste
        Try
            Dim doc = js.Deserialize(Of Dictionary(Of String, Object))(Convert.ToString(param("sVal")))
            Dim c = TryCast(If(doc IsNot Nothing AndAlso doc.ContainsKey("c"), doc("c"), Nothing), Dictionary(Of String, Object))
            If c Is Nothing Then Return liste
            For Each kv In c
                Dim v As String = Convert.ToString(kv.Value)
                liste.Add(New Dictionary(Of String, Object) From {{"id", kv.Key}, {"moi", v.Contains("m")}, {"cabinet", v.Contains("c")}})
            Next
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("QuiFaitQuoi (lecture) : " & ex.Message)
        End Try
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

        ' Forme compacte : seules les actions où l'entreprise ou le cabinet a un rôle (pas celles de 60, ni Phase 2 / Hors 60secondes).
        Dim c As New SortedDictionary(Of String, String)(StringComparer.Ordinal)
        For Each item In activites
            Dim a = TryCast(item, Dictionary(Of String, Object))
            If a Is Nothing OrElse Not a.ContainsKey("id") Then Continue For
            Dim id As String = Convert.ToString(a("id"))
            If String.IsNullOrWhiteSpace(id) OrElse id.Length > 40 Then Continue For
            Dim moi As Boolean = a.ContainsKey("moi") AndAlso Convert.ToBoolean(a("moi"))
            Dim cab As Boolean = a.ContainsKey("cabinet") AndAlso Convert.ToBoolean(a("cabinet"))
            If Not moi AndAlso Not cab Then Continue For
            c(id) = If(moi, "m", "") & If(cab, "c", "")
        Next

        Dim valeur As String = js.Serialize(New Dictionary(Of String, Object) From {
            {"v", 1},
            {"profil", If(doc.ContainsKey("profil"), Convert.ToString(doc("profil")), "")},
            {"metier", If(doc.ContainsKey("metier"), Convert.ToString(doc("metier")), "")},
            {"c", c}
        })
        ' sVal est un VARCHAR : le texte doit tenir dans 8000 octets, sans caractère hors Windows-1252.
        If Encoding.GetEncoding(1252).GetByteCount(valeur) > TailleMax Then
            RepondreJson(413, New With {.erreur = "Trop de choix à enregistrer."})
            Return
        End If

        Dim param As DataRow = LireParam()
        If param Is Nothing Then
            RepondreJson(500, New With {.erreur = "Paramètre QFQ_CHOIX introuvable."})
            Return
        End If

        Dim p As New Collection
        p.Add(New SqlParameter("@ParamId", Convert.ToInt32(param("ParamId"))))
        p.Add(New SqlParameter("@sVal", SqlDbType.VarChar, TailleMax) With {.Value = valeur})
        ExecuteSQL("s0151UpdateParamValue", p)

        RepondreJson(200, New With {.ok = True, .nb = c.Count})
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
