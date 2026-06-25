Imports System
Imports System.Configuration
Imports System.IO
Imports System.Security.Cryptography
Imports System.Text

''' <summary>
''' Chiffrement symetrique (AES-256) pour stocker des secrets en base
''' (ex. jetons OAuth Square). La cle est derivee (SHA-256) du secret
''' Web.config "Square.TokenKey". L'IV aleatoire est prefixe au texte chiffre.
''' Format retourne : Base64( IV(16) + ciphertext ).
''' </summary>
Public Class clsCrypto

    Private Shared Function GetKey() As Byte()
        Dim secret As String = ConfigurationManager.AppSettings("Square.TokenKey")
        If String.IsNullOrEmpty(secret) Then
            Throw New InvalidOperationException("Square.TokenKey n'est pas configure dans Web.config.")
        End If
        Using sha As SHA256 = SHA256.Create()
            Return sha.ComputeHash(Encoding.UTF8.GetBytes(secret))
        End Using
    End Function

    Public Shared Function Encrypt(plainText As String) As String
        If String.IsNullOrEmpty(plainText) Then Return ""

        Using aes As Aes = Aes.Create()
            aes.Key = GetKey()
            aes.Mode = CipherMode.CBC
            aes.Padding = PaddingMode.PKCS7
            aes.GenerateIV()

            Dim iv As Byte() = aes.IV
            Using enc As ICryptoTransform = aes.CreateEncryptor()
                Dim plain As Byte() = Encoding.UTF8.GetBytes(plainText)
                Dim cipher As Byte() = enc.TransformFinalBlock(plain, 0, plain.Length)

                Dim result As Byte() = New Byte(iv.Length + cipher.Length - 1) {}
                Buffer.BlockCopy(iv, 0, result, 0, iv.Length)
                Buffer.BlockCopy(cipher, 0, result, iv.Length, cipher.Length)
                Return Convert.ToBase64String(result)
            End Using
        End Using
    End Function

    Public Shared Function Decrypt(cipherText As String) As String
        If String.IsNullOrEmpty(cipherText) Then Return ""

        Dim all As Byte() = Convert.FromBase64String(cipherText)
        Using aes As Aes = Aes.Create()
            aes.Key = GetKey()
            aes.Mode = CipherMode.CBC
            aes.Padding = PaddingMode.PKCS7

            Dim iv As Byte() = New Byte(15) {}
            Buffer.BlockCopy(all, 0, iv, 0, 16)
            aes.IV = iv

            Using dec As ICryptoTransform = aes.CreateDecryptor()
                Dim plain As Byte() = dec.TransformFinalBlock(all, 16, all.Length - 16)
                Return Encoding.UTF8.GetString(plain)
            End Using
        End Using
    End Function

End Class
