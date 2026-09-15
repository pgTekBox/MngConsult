Imports System.Security.Cryptography
Imports System.Text
Imports System.Text.Json

''' <summary>
''' Les réglages de l'application, gardés d'une session à l'autre dans
''' %APPDATA%\60sec\ApideckExtraction\parametres.json.
'''
''' La clé d'API Apideck ouvre les données de tous les consommateurs de
''' l'application : elle est chiffrée pour l'utilisateur Windows courant (DPAPI).
''' </summary>
Public Class Parametres

    Public Property CleApiProtegee As String = ""
    Public Property AppId As String = ""
    Public Property ConsumerId As String = ""
    Public Property NomSociete As String = ""
    Public Property ServiceId As String = "quickbooks"

    Public Property DossierSortie As String = ""
    Public Property Separateur As String = ";"
    Public Property MethodeComptable As String = "accrual"
    Public Property DateDebut As Date? = Nothing
    Public Property DateBascule As Date? = Nothing
    Public Property FiltrerTransactions As Boolean = False

    Private Shared ReadOnly Entropie As Byte() = Encoding.UTF8.GetBytes("60sec.ApideckExtraction")

    Private Shared ReadOnly Property Chemin As String
        Get
            Return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                                "60sec", "ApideckExtraction", "parametres.json")
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
        Return Convert.ToBase64String(ProtectedData.Protect(Encoding.UTF8.GetBytes(texte), Entropie, DataProtectionScope.CurrentUser))
    End Function

    Public Shared Function Devoiler(protege As String) As String
        If String.IsNullOrEmpty(protege) Then Return ""
        Try
            Return Encoding.UTF8.GetString(ProtectedData.Unprotect(Convert.FromBase64String(protege), Entropie, DataProtectionScope.CurrentUser))
        Catch
            Return ""
        End Try
    End Function

End Class
