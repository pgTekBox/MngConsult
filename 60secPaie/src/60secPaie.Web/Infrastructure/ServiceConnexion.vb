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

    Private Const ColonnesCompte As String =
        "u.Id, u.UserGUID, u.CompanyGUID, u.Email AS Courriel, LTRIM(RTRIM(ISNULL(u.FirstName, N'') + N' ' + ISNULL(u.LastName, N''))) AS NomComplet, " &
        "u.IsAdmin AS EstAdmin, CAST(ISNULL(u.isAccountant, 0) AS bit) AS EstComptable"

    ''' <summary>Compte actif et non supprimé, ou Nothing.</summary>
    Public Shared Function CompteActif(courriel As String) As DataRow
        Return Db.Ligne("SELECT " & ColonnesCompte & " FROM dbo.T015User u WHERE u.Email = @c AND u.IsDeleted = 0 AND u.IsActive = 1", Db.P("@c", courriel))
    End Function

    ''' <summary>Compagnies accessibles, selon la règle de MngConsul (procédure s0210GetUserCompanies, dont le paramètre @UserId est le courriel).</summary>
    Public Shared Function CompagniesDe(courriel As String) As DataTable
        Return Db.Table("EXEC dbo.s0210GetUserCompanies @UserId = @c", Db.P("@c", courriel))
    End Function

    Public Shared Function Authentifier(courriel As String, motDePasse As String) As Issue
        courriel = If(courriel, "").Trim().ToLowerInvariant()
        If courriel.Length = 0 OrElse String.IsNullOrEmpty(motDePasse) Then Return Issue.Refusee

        Dim verrou = Db.Ligne("SELECT VerrouilleJusqua FROM paie.TentativeConnexion WHERE Courriel = @c", Db.P("@c", courriel))
        If verrou IsNot Nothing AndAlso verrou.DtN("VerrouilleJusqua").HasValue AndAlso verrou.DtN("VerrouilleJusqua").Value > Date.Now Then
            Return Issue.Verrouillee
        End If

        Dim u = Db.Ligne("SELECT u.PasswordHash FROM dbo.T015User u WHERE u.Email = @c AND u.IsDeleted = 0 AND u.IsActive = 1", Db.P("@c", courriel))
        Dim valide = MotDePasseValide(motDePasse, If(u Is Nothing, HachageFactice, u.Txt("PasswordHash"))) AndAlso u IsNot Nothing

        If Not valide Then
            Db.Exec("MERGE paie.TentativeConnexion AS t USING (SELECT @c AS Courriel) AS s ON t.Courriel = s.Courriel " &
                    "WHEN MATCHED THEN UPDATE SET Echecs = t.Echecs + 1, DernierEchec = sysdatetime(), " &
                    "     VerrouilleJusqua = CASE WHEN t.Echecs + 1 >= @max THEN DATEADD(minute, @min, sysdatetime()) ELSE t.VerrouilleJusqua END " &
                    "WHEN NOT MATCHED THEN INSERT (Courriel, Echecs, DernierEchec) VALUES (@c, 1, sysdatetime());",
                    Db.P("@c", courriel), Db.P("@max", EchecsMaximum), Db.P("@min", MinutesVerrouillage))
            Return Issue.Refusee
        End If

        Db.Exec("DELETE FROM paie.TentativeConnexion WHERE Courriel = @c", Db.P("@c", courriel))
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
