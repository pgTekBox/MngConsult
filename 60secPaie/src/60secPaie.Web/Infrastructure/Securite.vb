Imports System.Security.Cryptography
Imports System.Text
Imports System.Web.Security

''' <summary>Hachage des mots de passe : PBKDF2-HMAC-SHA256 avec sel aléatoire.</summary>
Public NotInheritable Class MotsDePasse

    Private Const Iterations As Integer = 120000
    ''' <summary>
    ''' Longueur minimale d'un mot de passe : 10 par défaut. Le paramètre « MotDePasse:LongueurMinimale » de Web.config
    ''' permet de l'abaisser sur un poste de développement ; Web.Release.config le retire pour la production.
    ''' </summary>
    Public Shared ReadOnly Property LongueurMinimale As Integer
        Get
            Dim v As Integer
            If Integer.TryParse(System.Configuration.ConfigurationManager.AppSettings("MotDePasse:LongueurMinimale"), v) AndAlso v >= 4 Then Return v
            Return 10
        End Get
    End Property

    Private Sub New()
    End Sub

    Public Shared Function Hacher(motDePasse As String) As String
        Dim sel(15) As Byte
        Using rng = RandomNumberGenerator.Create()
            rng.GetBytes(sel)
        End Using
        Using kdf As New Rfc2898DeriveBytes(motDePasse, sel, Iterations, HashAlgorithmName.SHA256)
            Return Iterations.ToString() & ":" & Convert.ToBase64String(sel) & ":" & Convert.ToBase64String(kdf.GetBytes(32))
        End Using
    End Function

    Public Shared Function Verifier(motDePasse As String, stocke As String) As Boolean
        If String.IsNullOrEmpty(motDePasse) OrElse String.IsNullOrEmpty(stocke) Then Return False
        Dim parties = stocke.Split(":"c)
        If parties.Length <> 3 Then Return False
        Dim iterations As Integer
        If Not Integer.TryParse(parties(0), iterations) Then Return False

        Dim sel = Convert.FromBase64String(parties(1))
        Dim attendu = Convert.FromBase64String(parties(2))
        Using kdf As New Rfc2898DeriveBytes(motDePasse, sel, iterations, HashAlgorithmName.SHA256)
            Dim obtenu = kdf.GetBytes(attendu.Length)
            ' Comparaison en temps constant
            Dim difference = 0
            For i = 0 To attendu.Length - 1
                difference = difference Or (attendu(i) Xor obtenu(i))
            Next
            Return difference = 0
        End Using
    End Function

End Class

''' <summary>
''' Chiffrement des données sensibles (NAS, compte bancaire) avant leur écriture en base.
''' Utilise la clé machine d'ASP.NET : en production, définir une machineKey fixe dans Web.config,
''' sinon les données ne pourront plus être déchiffrées après un changement de serveur.
''' </summary>
Public NotInheritable Class Secret

    Private Shared ReadOnly Usages As String() = {"60secPaie", "donnees-sensibles"}

    Private Sub New()
    End Sub

    Public Shared Function Proteger(texte As String) As String
        If String.IsNullOrEmpty(texte) Then Return Nothing
        Return Convert.ToBase64String(MachineKey.Protect(Encoding.UTF8.GetBytes(texte), Usages))
    End Function

    Public Shared Function Reveler(chiffre As String) As String
        If String.IsNullOrEmpty(chiffre) Then Return ""
        Try
            Return Encoding.UTF8.GetString(MachineKey.Unprotect(Convert.FromBase64String(chiffre), Usages))
        Catch ex As CryptographicException
            Return ""
        End Try
    End Function

    ''' <summary>Affiche seulement les 3 derniers caractères : ••• ••• 123.</summary>
    Public Shared Function Masquer(texte As String) As String
        If String.IsNullOrEmpty(texte) Then Return ""
        If texte.Length <= 3 Then Return New String("•"c, texte.Length)
        Return New String("•"c, texte.Length - 3) & texte.Substring(texte.Length - 3)
    End Function

End Class
