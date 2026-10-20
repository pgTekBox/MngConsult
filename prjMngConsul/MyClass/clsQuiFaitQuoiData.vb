Imports System.Web
Imports System.Web.Caching
Imports System.Web.Script.Serialization

''' <summary>
''' Les métiers de l'inventaire « Qui fait quoi » (js/qui-fait-quoi-data.js, DATA.M),
''' pour la liste déroulante Paramètres › Entreprise › Métier. Le fichier est lu une
''' fois puis gardé en cache tant qu'il ne change pas.
''' </summary>
Public NotInheritable Class clsQuiFaitQuoiData

    Private Const Fichier As String = "~/js/qui-fait-quoi-data.js"
    Private Const CleCache As String = "clsQuiFaitQuoiData.Metiers"

    ''' <summary>Les profils, dans l'ordre d'affichage : (code, fr, en, es).</summary>
    Public Shared ReadOnly Profils As String()() = {
        New String() {"TA", "Travailleur autonome", "Self-employed", "Trabajador autónomo"},
        New String() {"Cie 0", "Société sans employé", "Corporation without employees", "Sociedad sin empleados"},
        New String() {"Cie 1-4", "Société avec employés", "Corporation with employees", "Sociedad con empleados"}
    }

    Private Sub New()
    End Sub

    ''' <summary>Métier → profils pour lesquels l'inventaire le prévoit (ex. « Barbier » → TA, Cie 0, Cie 1-4). Trié par nom.</summary>
    Public Shared Function Metiers() As SortedDictionary(Of String, List(Of String))
        Dim cache As Cache = HttpRuntime.Cache
        Dim deja = TryCast(cache(CleCache), SortedDictionary(Of String, List(Of String)))
        If deja IsNot Nothing Then Return deja

        Dim liste As New SortedDictionary(Of String, List(Of String))(StringComparer.Create(New System.Globalization.CultureInfo("fr-CA"), True))
        Dim chemin As String = HttpContext.Current.Server.MapPath(Fichier)
        Try
            ' Le fichier est « var DATA = {…}; » : on garde l'objet JSON.
            Dim texte As String = System.IO.File.ReadAllText(chemin, System.Text.Encoding.UTF8)
            Dim debut As Integer = texte.IndexOf("{"c), fin As Integer = texte.LastIndexOf("}"c)
            If debut >= 0 AndAlso fin > debut Then
                Dim js As New JavaScriptSerializer() With {.MaxJsonLength = Integer.MaxValue}
                Dim data = js.Deserialize(Of Dictionary(Of String, Object))(texte.Substring(debut, fin - debut + 1))
                Dim m = TryCast(If(data IsNot Nothing AndAlso data.ContainsKey("M"), data("M"), Nothing), ArrayList)
                If m IsNot Nothing Then
                    For Each item In m
                        Dim d = TryCast(item, Dictionary(Of String, Object))
                        If d Is Nothing OrElse Not d.ContainsKey("m") Then Continue For
                        Dim nom As String = Convert.ToString(d("m")).Trim()
                        Dim profil As String = If(d.ContainsKey("p"), Convert.ToString(d("p")), "")
                        If nom = "" Then Continue For
                        If Not liste.ContainsKey(nom) Then liste(nom) = New List(Of String)
                        If profil <> "" AndAlso Not liste(nom).Contains(profil) Then liste(nom).Add(profil)
                    Next
                End If
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("clsQuiFaitQuoiData : " & ex.Message)
        End Try

        If liste.Count > 0 Then cache.Insert(CleCache, liste, New CacheDependency(chemin))
        Return liste
    End Function
End Class
