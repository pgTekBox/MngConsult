Imports System.Security.Cryptography
Imports System.Text
Imports System.Web.Security

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
