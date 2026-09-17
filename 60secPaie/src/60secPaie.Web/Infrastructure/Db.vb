Imports System.Configuration
Imports System.Data.SqlClient

''' <summary>Accès SQL Server minimal (ADO.NET). Toutes les requêtes sont paramétrées.</summary>
Public NotInheritable Class Db

    Private Sub New()
    End Sub

    Private Shared ReadOnly Property ChaineConnexion As String
        Get
            Return ConfigurationManager.ConnectionStrings("Paie").ConnectionString
        End Get
    End Property

    Public Shared Function P(nom As String, valeur As Object) As SqlParameter
        If valeur Is Nothing Then Return New SqlParameter(nom, DBNull.Value)
        Dim texte = TryCast(valeur, String)
        If texte IsNot Nothing AndAlso texte.Trim().Length = 0 Then Return New SqlParameter(nom, DBNull.Value)
        Return New SqlParameter(nom, valeur)
    End Function

    Public Shared Function Table(sql As String, ParamArray prms As SqlParameter()) As DataTable
        Using cn As New SqlConnection(ChaineConnexion), cmd As New SqlCommand(sql, cn)
            cmd.Parameters.AddRange(prms)
            Using da As New SqlDataAdapter(cmd)
                Dim t As New DataTable()
                da.Fill(t)
                Return t
            End Using
        End Using
    End Function

    ''' <summary>Première ligne du résultat, ou Nothing.</summary>
    Public Shared Function Ligne(sql As String, ParamArray prms As SqlParameter()) As DataRow
        Dim t = Table(sql, prms)
        Return If(t.Rows.Count = 0, Nothing, t.Rows(0))
    End Function

    Public Shared Function Exec(sql As String, ParamArray prms As SqlParameter()) As Integer
        Using cn As New SqlConnection(ChaineConnexion), cmd As New SqlCommand(sql, cn)
            cmd.Parameters.AddRange(prms)
            cn.Open()
            Return cmd.ExecuteNonQuery()
        End Using
    End Function

    Public Shared Function Scalaire(sql As String, ParamArray prms As SqlParameter()) As Object
        Using cn As New SqlConnection(ChaineConnexion), cmd As New SqlCommand(sql, cn)
            cmd.Parameters.AddRange(prms)
            cn.Open()
            Dim v = cmd.ExecuteScalar()
            Return If(v Is DBNull.Value, Nothing, v)
        End Using
    End Function

    Public Shared Function ScalaireEntier(sql As String, ParamArray prms As SqlParameter()) As Integer
        Dim v = Scalaire(sql, prms)
        Return If(v Is Nothing, 0, Convert.ToInt32(v))
    End Function

    ''' <summary>Exécute un INSERT et retourne l'identité générée.</summary>
    Public Shared Function Inserer(sql As String, ParamArray prms As SqlParameter()) As Integer
        Return ScalaireEntier(sql & "; SELECT CAST(SCOPE_IDENTITY() AS int);", prms)
    End Function

End Class
