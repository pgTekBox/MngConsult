Imports System.Configuration
Imports System.Data.SqlClient

''' <summary>
''' Accès à la base MailService, celle du service d'envoi de la plateforme.
'''
''' C'est une AUTRE base que celle de la paie, sur le même serveur : 60secPaie y
''' dépose un courriel, et le service Windows SrvAI le remet lui-même aux
''' serveurs de destination. 60secPaie ne parle donc à aucun serveur SMTP, et
''' n'a pas à connaître de mot de passe de messagerie.
'''
''' L'accès se fait par les procédures de MailService (s0610, s1579) : la forme
''' de T400Mails appartient au service de courriel, pas à la paie.
''' </summary>
Public NotInheritable Class DbMail

    Private Sub New()
    End Sub

    Public Const NomConnexion As String = "Mail"

    ''' <summary>Vrai si la connexion au service d'envoi est configurée.</summary>
    Public Shared ReadOnly Property EstConfigure As Boolean
        Get
            Dim c = ConfigurationManager.ConnectionStrings(NomConnexion)
            Return c IsNot Nothing AndAlso Not String.IsNullOrWhiteSpace(c.ConnectionString)
        End Get
    End Property

    Private Shared ReadOnly Property ChaineConnexion As String
        Get
            If Not EstConfigure Then
                Throw New SaisieInvalideException(
                    "La connexion « " & NomConnexion & " » vers la base MailService n'est pas configurée : " &
                    "les courriels ne peuvent pas être remis au service d'envoi.")
            End If
            Return ConfigurationManager.ConnectionStrings(NomConnexion).ConnectionString
        End Get
    End Property

    ''' <summary>Exécute une procédure de MailService et retourne sa première valeur (l'identifiant créé).</summary>
    Public Shared Function Procedure(nom As String, ParamArray prms As SqlParameter()) As Object
        Using cn As New SqlConnection(ChaineConnexion), cmd As New SqlCommand(nom, cn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddRange(prms)
            cn.Open()
            Dim v = cmd.ExecuteScalar()
            Return If(v Is DBNull.Value, Nothing, v)
        End Using
    End Function

End Class
