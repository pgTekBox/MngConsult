Imports System
Imports System.Globalization
Imports System.IO
Imports System.Text.RegularExpressions
Imports System.Web

''' <summary>
''' Distribution de l'application mobile iOS (iPhone / iPad).
'''
''' Pendant Apple de clsAndroidApp, avec une différence de fond : iOS ne sait
''' pas installer un fichier téléchargé. Il faut deux fichiers déposés dans
''' ~/apple (voir apple/LISEZMOI.md) :
'''   - un .ipa signé en Ad Hoc ;
'''   - un manifest.plist qui décrit l'application à installer.
''' Le bouton de la page utilise ensuite un lien itms-services:// pointant sur
''' le manifeste, seul mécanisme d'installation « par le web » qu'Apple
''' autorise hors App Store.
'''
''' Rappel : iOS exige HTTPS avec certificat valide pour ce mécanisme.
''' </summary>
Public NotInheritable Class clsAppleApp

    ''' <summary>Répertoire virtuel où le paquet iOS est déposé.</summary>
    Public Const FolderVirtualPath As String = "~/apple"

    ''' <summary>Nom imposé du descripteur d'installation.</summary>
    Public Const ManifestFileName As String = "manifest.plist"

    ''' <summary>URL publique du handler (paquet, ou manifeste avec ?manifest=1).</summary>
    Public Const DownloadUrl As String = "AppApple.ashx"

    ''' <summary>
    ''' Type MIME du paquet. Apple ne définit pas de type propre pour un .ipa ;
    ''' octet-stream est ce que servent les outils de distribution.
    ''' </summary>
    Public Const IpaContentType As String = "application/octet-stream"

    Private Sub New()
    End Sub

    ''' <summary>
    ''' Chemin physique du .ipa à servir, ou "" si aucun n'est disponible.
    ''' Le nom du fichier n'a pas d'importance : on prend le plus récent.
    ''' </summary>
    Public Shared Function ResolveIpaPath() As String
        Try
            Dim folder As String = HttpContext.Current.Server.MapPath(FolderVirtualPath)
            If Not Directory.Exists(folder) Then Return ""

            Dim newest As String = ""
            Dim newestUtc As DateTime = DateTime.MinValue
            For Each f As String In Directory.GetFiles(folder, "*.ipa")
                Dim stamp As DateTime = File.GetLastWriteTimeUtc(f)
                If stamp > newestUtc Then
                    newestUtc = stamp
                    newest = f
                End If
            Next
            Return newest
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("clsAppleApp.ResolveIpaPath: " & ex.Message)
            Return ""
        End Try
    End Function

    ''' <summary>Chemin physique du manifeste, ou "" s'il est absent.</summary>
    Public Shared Function ResolveManifestPath() As String
        Try
            Dim p As String = HttpContext.Current.Server.MapPath(FolderVirtualPath & "/" & ManifestFileName)
            If File.Exists(p) Then Return p
            Return ""
        Catch ex As Exception
            Return ""
        End Try
    End Function

    ''' <summary>
    ''' Vrai seulement si les DEUX fichiers sont là : un .ipa seul ne
    ''' s'installe pas, autant ne pas afficher de bouton qui échouerait.
    ''' </summary>
    Public Shared Function IsAvailable() As Boolean
        Return ResolveIpaPath().Length > 0 AndAlso ResolveManifestPath().Length > 0
    End Function

    ''' <summary>Nom du .ipa réellement servi, nettoyé pour l'en-tête HTTP.</summary>
    Public Shared Function GetFileName() As String
        Dim p As String = ResolveIpaPath()
        If p.Length = 0 Then Return ""
        Dim name As String = Path.GetFileName(p)
        Return name.Replace("""", "").Replace(vbCr, "").Replace(vbLf, "")
    End Function

    ''' <summary>Numéro de version affiché, lu dans ~/apple/version.txt.</summary>
    Public Shared Function GetVersion() As String
        Try
            Dim p As String = HttpContext.Current.Server.MapPath(FolderVirtualPath & "/version.txt")
            If Not File.Exists(p) Then Return ""
            Dim txt As String = File.ReadAllText(p).Trim()
            If txt.Length > 24 Then txt = txt.Substring(0, 24)
            Return txt
        Catch ex As Exception
            Return ""
        End Try
    End Function

    ''' <summary>Taille du paquet en octets, 0 si absent.</summary>
    Public Shared Function GetSizeBytes() As Long
        Dim p As String = ResolveIpaPath()
        If p.Length = 0 Then Return 0
        Try
            Return New FileInfo(p).Length
        Catch ex As Exception
            Return 0
        End Try
    End Function

    ''' <summary>Date de publication = dernière écriture du paquet.</summary>
    Public Shared Function GetPublishedOn() As DateTime
        Dim p As String = ResolveIpaPath()
        If p.Length = 0 Then Return DateTime.MinValue
        Try
            Return File.GetLastWriteTime(p)
        Catch ex As Exception
            Return DateTime.MinValue
        End Try
    End Function

    ''' <summary>
    ''' Contenu du manifeste, avec l'URL du paquet réécrite vers l'adresse
    ''' réelle du site. Xcode fige cette URL au moment de l'export ; la
    ''' réécrire évite d'avoir à ré-exporter à chaque changement de domaine,
    ''' et évite surtout un manifeste qui pointe dans le vide.
    ''' </summary>
    Public Shared Function BuildManifest(ipaAbsoluteUrl As String) As String
        Dim p As String = ResolveManifestPath()
        If p.Length = 0 Then Return ""
        Try
            Dim xml As String = File.ReadAllText(p)
            ' Toute valeur <string> se terminant par .ipa est l'URL du paquet.
            Return Regex.Replace(xml,
                                 "<string>\s*[^<]*\.ipa\s*</string>",
                                 "<string>" & ipaAbsoluteUrl.Replace("&", "&amp;") & "</string>",
                                 RegexOptions.IgnoreCase)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("clsAppleApp.BuildManifest: " & ex.Message)
            Return ""
        End Try
    End Function

    ''' <summary>Taille lisible ("48,2 Mo" / "48.2 MB"), selon la langue.</summary>
    Public Shared Function FormatSize(bytes As Long, lang As String) As String
        Return clsAndroidApp.FormatSize(bytes, lang)
    End Function

    ''' <summary>Date lisible dans la langue courante.</summary>
    Public Shared Function FormatDate(value As DateTime, lang As String) As String
        Return clsAndroidApp.FormatDate(value, lang)
    End Function

End Class
