Imports System.Security.Cryptography
Imports System.Text
Imports System.Text.Json

''' <summary>
''' Les réglages de l'application, gardés d'une session à l'autre dans
''' %APPDATA%\60sec\QboExtraction\parametres.json.
'''
''' Le secret client et le jeton de renouvellement donnent accès à la
''' comptabilité : ils sont chiffrés pour l'utilisateur Windows courant (DPAPI)
''' et illisibles depuis un autre compte ou une autre machine.
''' </summary>
Public Class Parametres

    Public Property ClientId As String = ""
    Public Property ClientSecretProtege As String = ""
    Public Property RefreshTokenProtege As String = ""
    Public Property RealmId As String = ""
    Public Property Environnement As String = "Sandbox"
    Public Property RedirectUri As String = "http://localhost:8765/callback"

    Public Property DossierSortie As String = ""
    Public Property Separateur As String = ";"
    Public Property MethodeComptable As String = "Accrual"
    Public Property DateDebut As Date? = Nothing
    Public Property DateBascule As Date? = Nothing
    Public Property FiltrerTransactions As Boolean = False

    Private Shared ReadOnly Entropie As Byte() = Encoding.UTF8.GetBytes("60sec.QboExtraction")

    Private Shared ReadOnly Property Chemin As String
        Get
            Return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                                "60sec", "QboExtraction", "parametres.json")
        End Get
    End Property

    Public Shared Function Charger() As Parametres
        Try
            If File.Exists(Chemin) Then
                Dim p = JsonSerializer.Deserialize(Of Parametres)(File.ReadAllText(Chemin))
                If p IsNot Nothing Then Return p
            End If
        Catch
            ' Un fichier illisible ne doit pas empêcher l'application de s'ouvrir.
        End Try
        Return New Parametres()
    End Function

    Public Sub Enregistrer()
        Directory.CreateDirectory(Path.GetDirectoryName(Chemin))
        File.WriteAllText(Chemin, JsonSerializer.Serialize(Me, New JsonSerializerOptions With {.WriteIndented = True}))
    End Sub

    Public Shared Function Proteger(texte As String) As String
        If String.IsNullOrEmpty(texte) Then Return ""
        Dim octets = ProtectedData.Protect(Encoding.UTF8.GetBytes(texte), Entropie, DataProtectionScope.CurrentUser)
        Return Convert.ToBase64String(octets)
    End Function

    Public Shared Function Devoiler(protege As String) As String
        If String.IsNullOrEmpty(protege) Then Return ""
        Try
            Dim octets = ProtectedData.Unprotect(Convert.FromBase64String(protege), Entropie, DataProtectionScope.CurrentUser)
            Return Encoding.UTF8.GetString(octets)
        Catch
            Return ""
        End Try
    End Function

End Class
