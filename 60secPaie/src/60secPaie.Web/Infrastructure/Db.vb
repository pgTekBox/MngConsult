Imports System.Configuration
Imports System.Data.SqlClient

''' <summary>
''' Accès SQL Server minimal (ADO.NET). Seules des procédures stockées s'exécutent : aucune requête
''' n'est écrite dans l'application. Les procédures vivent dans Database\07_procedures.sql
''' (schéma paie, nom paie.sp&lt;Entité&gt;_&lt;Action&gt;) ; chaque appel passe un nom de procédure
''' et ses paramètres (Db.P), rien d'autre — un texte qui n'est pas un nom de procédure est refusé.
''' </summary>
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

    ''' <summary>Un nom de procédure (schéma.nom), et rien d'autre : ni espace, ni point-virgule, ni parenthèse.</summary>
    Private Shared Function Commande(procedure As String, cn As SqlConnection, prms As SqlParameter()) As SqlCommand
        Dim nom = If(procedure, "").Trim()
        If nom.Length = 0 OrElse nom.IndexOfAny({" "c, ControlChars.Tab, ControlChars.Cr, ControlChars.Lf, ";"c, "("c, "'"c}) >= 0 Then
            Throw New ArgumentException("Db n'exécute que des procédures stockées (ex. paie.spCompagnie_Get), jamais une requête : " & nom)
        End If
        Dim cmd As New SqlCommand(nom, cn) With {.CommandType = CommandType.StoredProcedure}
        cmd.Parameters.AddRange(prms)
        Return cmd
    End Function

    Public Shared Function Table(procedure As String, ParamArray prms As SqlParameter()) As DataTable
        Using cn As New SqlConnection(ChaineConnexion), cmd = Commande(procedure, cn, prms)
            Using da As New SqlDataAdapter(cmd)
                Dim t As New DataTable()
                da.Fill(t)
                Return t
            End Using
        End Using
    End Function

    ''' <summary>Première ligne du résultat, ou Nothing.</summary>
    Public Shared Function Ligne(procedure As String, ParamArray prms As SqlParameter()) As DataRow
        Dim t = Table(procedure, prms)
        Return If(t.Rows.Count = 0, Nothing, t.Rows(0))
    End Function

    ''' <summary>Exécute la procédure et rend le nombre de lignes touchées.</summary>
    Public Shared Function Exec(procedure As String, ParamArray prms As SqlParameter()) As Integer
        Using cn As New SqlConnection(ChaineConnexion), cmd = Commande(procedure, cn, prms)
            cn.Open()
            Return cmd.ExecuteNonQuery()
        End Using
    End Function

    Public Shared Function Scalaire(procedure As String, ParamArray prms As SqlParameter()) As Object
        Using cn As New SqlConnection(ChaineConnexion), cmd = Commande(procedure, cn, prms)
            cn.Open()
            Dim v = cmd.ExecuteScalar()
            Return If(v Is DBNull.Value, Nothing, v)
        End Using
    End Function

    Public Shared Function ScalaireEntier(procedure As String, ParamArray prms As SqlParameter()) As Integer
        Dim v = Scalaire(procedure, prms)
        Return If(v Is Nothing, 0, Convert.ToInt32(v))
    End Function

    ''' <summary>Exécute une procédure qui crée une ligne et se termine par SELECT CAST(SCOPE_IDENTITY() AS int) ; rend cet identifiant.</summary>
    Public Shared Function Inserer(procedure As String, ParamArray prms As SqlParameter()) As Integer
        Return ScalaireEntier(procedure, prms)
    End Function

End Class
