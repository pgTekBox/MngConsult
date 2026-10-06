''' <summary>
''' Authentification avec les comptes de MngConsul : table dbo.T015User, identifiant = courriel,
''' mot de passe haché en BCrypt (même librairie et même vérification que wbfLogin.aspx de MngConsul).
''' Les mots de passe se créent et se changent dans MngConsul ; 60secPaie ne fait que les vérifier.
''' MngConsul n'a pas de verrouillage : 60secPaie tient le sien dans paie.TentativeConnexion.
''' </summary>
Public NotInheritable Class ServiceConnexion

    Public Const EchecsMaximum As Integer = 5
    Public Const MinutesVerrouillage As Integer = 15

    ' Hachage BCrypt factice (coût 11) : sert à dépenser le même temps de calcul quand le courriel n'existe pas,
    ' pour ne pas révéler quels courriels ont un compte.
    Private Const HachageFactice As String = "$2a$11$7EqJtq98hPqEX7fNZaFWoOa5pJ8y9Yk1Gd0nRr1xT6wQm3dYw0D2a"

    Private Sub New()
    End Sub

    Public Enum Issue
        Reussie
        Refusee
        Verrouillee
        AucuneCompagnie
    End Enum

    ''' <summary>Compte actif et non supprimé, ou Nothing.</summary>
    Public Shared Function CompteActif(courriel As String) As DataRow
        Return Db.Ligne("paie.spUtilisateur_CompteActif", Db.P("@c", courriel))
    End Function

    ''' <summary>Compagnies accessibles, selon la règle de MngConsul (procédure s0210GetUserCompanies, dont le paramètre @UserId est le courriel).</summary>
    Public Shared Function CompagniesDe(courriel As String) As DataTable
        Return Db.Table("dbo.s0210GetUserCompanies", Db.P("@UserId", courriel))
    End Function

    Public Shared Function Authentifier(courriel As String, motDePasse As String) As Issue
        courriel = If(courriel, "").Trim().ToLowerInvariant()
        If courriel.Length = 0 OrElse String.IsNullOrEmpty(motDePasse) Then Return Issue.Refusee

        Dim verrou = Db.Ligne("paie.spTentativeConnexion_Get", Db.P("@c", courriel))
        If verrou IsNot Nothing AndAlso verrou.DtN("VerrouilleJusqua").HasValue AndAlso verrou.DtN("VerrouilleJusqua").Value > Date.Now Then
            Return Issue.Verrouillee
        End If

        Dim u = Db.Ligne("paie.spUtilisateur_Hachage", Db.P("@c", courriel))
        Dim valide = MotDePasseValide(motDePasse, If(u Is Nothing, HachageFactice, u.Txt("PasswordHash"))) AndAlso u IsNot Nothing

        If Not valide Then
            Db.Exec("paie.spTentativeConnexion_Echec",
                    Db.P("@c", courriel), Db.P("@max", EchecsMaximum), Db.P("@min", MinutesVerrouillage))
            Return Issue.Refusee
        End If

        Db.Exec("paie.spTentativeConnexion_Effacer", Db.P("@c", courriel))
        If CompagniesDe(courriel).Rows.Count = 0 Then Return Issue.AucuneCompagnie
        Return Issue.Reussie
    End Function

    Private Shared Function MotDePasseValide(motDePasse As String, hachage As String) As Boolean
        Try
            Return BCrypt.Net.BCrypt.Verify(motDePasse, hachage)
        Catch ex As Exception
            ' Hachage mal formé dans la base : on refuse, comme MngConsul.
            Return False
        End Try
    End Function

End Class
