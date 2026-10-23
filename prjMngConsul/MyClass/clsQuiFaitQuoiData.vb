Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Web.Caching
Imports System.Web.Script.Serialization

''' <summary>
''' Les métiers (T330Metier, T330MetierProfil ; gérés dans la console d'administration,
''' Abonnements › Métiers), pour la liste déroulante Paramètres › Entreprise › Métier et
''' pour la page « Qui fait quoi » (DATA.M). Lus par s0912 et gardés en cache deux minutes.
''' Si la base ne répond pas ou que la table est vide, l'inventaire du fichier
''' js/qui-fait-quoi-data.js (DATA.M) sert de secours.
''' </summary>
Public NotInheritable Class clsQuiFaitQuoiData

    Private Const Fichier As String = "~/js/qui-fait-quoi-data.js"
    Private Const CleCache As String = "clsQuiFaitQuoiData.Lignes"

    ''' <summary>Les profils, dans l'ordre d'affichage : (code, fr, en, es).</summary>
    Public Shared ReadOnly Profils As String()() = {
        New String() {"TA", "Travailleur autonome", "Self-employed", "Trabajador autónomo"},
        New String() {"Cie 0", "Société sans employé", "Corporation without employees", "Sociedad sin empleados"},
        New String() {"Cie 1-4", "Société avec employés", "Corporation with employees", "Sociedad con empleados"}
    }

    ''' <summary>Une ligne métier × profil, aux noms de champs de DATA.M (m, p, f, g, t).</summary>
    Public Class Ligne
        Public Property m As String
        Public Property p As String
        Public Property f As String
        Public Property g As String
        Public Property t As String
    End Class

    Private Sub New()
    End Sub

    ''' <summary>Métier → profils pour lesquels il existe (ex. « Barbier » → TA, Cie 0, Cie 1-4). Trié par nom.</summary>
    Public Shared Function Metiers() As SortedDictionary(Of String, List(Of String))
        Dim liste As New SortedDictionary(Of String, List(Of String))(StringComparer.Create(New System.Globalization.CultureInfo("fr-CA"), True))
        For Each l As Ligne In Lignes()
            If Not liste.ContainsKey(l.m) Then liste(l.m) = New List(Of String)
            If l.p <> "" AndAlso Not liste(l.m).Contains(l.p) Then liste(l.m).Add(l.p)
        Next
        Return liste
    End Function

    ''' <summary>Les lignes métier × profil des métiers actifs, comme DATA.M de « Qui fait quoi ».</summary>
    Public Shared Function Lignes() As List(Of Ligne)
        Dim cache As Cache = HttpRuntime.Cache
        Dim deja = TryCast(cache(CleCache), List(Of Ligne))
        If deja IsNot Nothing Then Return deja

        Dim liste As List(Of Ligne) = LireBase()
        If liste.Count = 0 Then liste = LireFichier()
        If liste.Count > 0 Then cache.Insert(CleCache, liste, Nothing, Date.UtcNow.AddMinutes(2), Cache.NoSlidingExpiration)
        Return liste
    End Function

    ''' <summary>Les lignes, en JSON, pour remplacer DATA.M dans la page « Qui fait quoi ».</summary>
    Public Shared Function LignesJson() As String
        Return New JavaScriptSerializer() With {.MaxJsonLength = Integer.MaxValue}.Serialize(Lignes())
    End Function

    ''' <summary>s0912 : les métiers actifs, une ligne par profil.</summary>
    Private Shared Function LireBase() As List(Of Ligne)
        Dim liste As New List(Of Ligne)
        Try
            Using cn As New SqlConnection(ConfigurationManager.AppSettings("ConnectionString"))
                Using cmd As New SqlCommand("s0912GetMetiers", cn) With {.CommandType = CommandType.StoredProcedure, .CommandTimeout = 30}
                    cn.Open()
                    Using r As SqlDataReader = cmd.ExecuteReader()
                        While r.Read()
                            liste.Add(New Ligne With {
                                .m = Convert.ToString(r("Nom")).Trim(),
                                .p = Convert.ToString(r("Profil")),
                                .f = Convert.ToString(r("Famille")),
                                .g = Convert.ToString(r("Groupe")),
                                .t = Convert.ToString(r("Taxes"))
                            })
                        End While
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("clsQuiFaitQuoiData (base) : " & ex.Message)
            liste.Clear()
        End Try
        Return liste
    End Function

    ''' <summary>Secours : DATA.M du fichier js/qui-fait-quoi-data.js (« var DATA = {…}; »).</summary>
    Private Shared Function LireFichier() As List(Of Ligne)
        Dim liste As New List(Of Ligne)
        Try
            Dim texte As String = System.IO.File.ReadAllText(HttpContext.Current.Server.MapPath(Fichier), System.Text.Encoding.UTF8)
            Dim debut As Integer = texte.IndexOf("{"c), fin As Integer = texte.LastIndexOf("}"c)
            If debut < 0 OrElse fin <= debut Then Return liste
            Dim js As New JavaScriptSerializer() With {.MaxJsonLength = Integer.MaxValue}
            Dim data = js.Deserialize(Of Dictionary(Of String, Object))(texte.Substring(debut, fin - debut + 1))
            Dim m = TryCast(If(data IsNot Nothing AndAlso data.ContainsKey("M"), data("M"), Nothing), ArrayList)
            If m Is Nothing Then Return liste
            For Each item In m
                Dim d = TryCast(item, Dictionary(Of String, Object))
                If d Is Nothing OrElse Not d.ContainsKey("m") Then Continue For
                Dim nom As String = Convert.ToString(d("m")).Trim()
                If nom = "" Then Continue For
                liste.Add(New Ligne With {
                    .m = nom,
                    .p = If(d.ContainsKey("p"), Convert.ToString(d("p")), ""),
                    .f = If(d.ContainsKey("f"), Convert.ToString(d("f")), ""),
                    .g = If(d.ContainsKey("g"), Convert.ToString(d("g")), ""),
                    .t = If(d.ContainsKey("t"), Convert.ToString(d("t")), "")
                })
            Next
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("clsQuiFaitQuoiData (fichier) : " & ex.Message)
        End Try
        Return liste
    End Function
End Class
