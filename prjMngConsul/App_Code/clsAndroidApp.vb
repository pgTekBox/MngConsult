Imports System
Imports System.Globalization
Imports System.IO
Imports System.Web

''' <summary>
''' Distribution de l'application mobile Android (APK).
'''
''' L'APK n'est pas versionné dans Git : il est déposé manuellement dans le
''' répertoire ~/android (voir android/LISEZMOI.md). Cette classe centralise
''' la localisation du fichier et ses métadonnées pour que le handler de
''' téléchargement (AppAndroid.ashx) et la page publique (LandingPage) voient
''' exactement la même chose.
''' </summary>
Public NotInheritable Class clsAndroidApp

    ''' <summary>Répertoire virtuel où l'APK est déposé.</summary>
    Public Const FolderVirtualPath As String = "~/android"

    ''' <summary>Nom de fichier attendu ; sert aussi de nom proposé au navigateur.</summary>
    Public Const PreferredFileName As String = "60secai.apk"

    ''' <summary>URL publique de téléchargement (handler, pas de fichier statique).</summary>
    Public Const DownloadUrl As String = "AppAndroid.ashx"

    ''' <summary>Type MIME officiel d'un paquet Android.</summary>
    Public Const ContentType As String = "application/vnd.android.package-archive"

    Private Sub New()
    End Sub

    ''' <summary>
    ''' Chemin physique de l'APK à servir, ou "" si aucun n'est disponible.
    ''' On privilégie 60secai.apk ; à défaut on prend le *.apk le plus récent
    ''' du répertoire (pratique quand on y dépose un build daté).
    ''' </summary>
    Public Shared Function ResolveApkPath() As String
        Try
            Dim folder As String = HttpContext.Current.Server.MapPath(FolderVirtualPath)
            If Not Directory.Exists(folder) Then Return ""

            Dim preferred As String = Path.Combine(folder, PreferredFileName)
            If File.Exists(preferred) Then Return preferred

            Dim newest As String = ""
            Dim newestUtc As DateTime = DateTime.MinValue
            For Each f As String In Directory.GetFiles(folder, "*.apk")
                Dim stamp As DateTime = File.GetLastWriteTimeUtc(f)
                If stamp > newestUtc Then
                    newestUtc = stamp
                    newest = f
                End If
            Next
            Return newest
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("clsAndroidApp.ResolveApkPath: " & ex.Message)
            Return ""
        End Try
    End Function

    ''' <summary>Vrai si un APK est disponible au téléchargement.</summary>
    Public Shared Function IsAvailable() As Boolean
        Return ResolveApkPath().Length > 0
    End Function

    ''' <summary>
    ''' Numéro de version affiché, lu dans ~/android/version.txt (1 ligne).
    ''' Retourne "" si le fichier est absent : la page n'affiche alors pas de version.
    ''' </summary>
    Public Shared Function GetVersion() As String
        Try
            Dim p As String = HttpContext.Current.Server.MapPath(FolderVirtualPath & "/version.txt")
            If Not File.Exists(p) Then Return ""
            Dim txt As String = File.ReadAllText(p).Trim()
            ' Garde-fou : on n'affiche qu'un numéro court, jamais du contenu arbitraire.
            If txt.Length > 24 Then txt = txt.Substring(0, 24)
            Return txt
        Catch ex As Exception
            Return ""
        End Try
    End Function

    ''' <summary>Taille du fichier en octets, 0 si absent.</summary>
    Public Shared Function GetSizeBytes() As Long
        Dim p As String = ResolveApkPath()
        If p.Length = 0 Then Return 0
        Try
            Return New FileInfo(p).Length
        Catch ex As Exception
            Return 0
        End Try
    End Function

    ''' <summary>Date de publication = date de dernière écriture du fichier.</summary>
    Public Shared Function GetPublishedOn() As DateTime
        Dim p As String = ResolveApkPath()
        If p.Length = 0 Then Return DateTime.MinValue
        Try
            Return File.GetLastWriteTime(p)
        Catch ex As Exception
            Return DateTime.MinValue
        End Try
    End Function

    ''' <summary>
    ''' Taille lisible ("48,2 Mo" / "48.2 MB" / "48,2 MB") selon la langue.
    ''' </summary>
    Public Shared Function FormatSize(bytes As Long, lang As String) As String
        If bytes <= 0 Then Return ""
        Dim mb As Double = bytes / 1048576.0R
        Select Case lang
            Case "en"
                Return mb.ToString("N1", CultureInfo.GetCultureInfo("en-CA")) & " MB"
            Case "es"
                Return mb.ToString("N1", CultureInfo.GetCultureInfo("fr-CA")) & " MB"
            Case Else
                Return mb.ToString("N1", CultureInfo.GetCultureInfo("fr-CA")) & " Mo"
        End Select
    End Function

    ''' <summary>Date lisible dans la langue courante (ex. « 21 août 2026 »).</summary>
    Public Shared Function FormatDate(value As DateTime, lang As String) As String
        If value = DateTime.MinValue Then Return ""
        Dim ci As CultureInfo
        Select Case lang
            Case "en" : ci = CultureInfo.GetCultureInfo("en-CA")
            Case "es" : ci = CultureInfo.GetCultureInfo("es-ES")
            Case Else : ci = CultureInfo.GetCultureInfo("fr-CA")
        End Select
        Return value.ToString("d MMMM yyyy", ci)
    End Function

End Class
