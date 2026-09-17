''' <summary>Contexte de la requête : compagnie courante, utilisateur, journal d'activités.</summary>
Public NotInheritable Class Contexte

    Private Sub New()
    End Sub

    ''' <summary>Identifiant de la compagnie (0 tant qu'elle n'est pas configurée). Une seule compagnie dans cette version.</summary>
    Public Shared ReadOnly Property CompagnieId As Integer
        Get
            Dim ctx = HttpContext.Current
            If ctx.Items("CompagnieId") Is Nothing Then
                ctx.Items("CompagnieId") = Db.ScalaireEntier("SELECT TOP 1 Id FROM dbo.Compagnie ORDER BY Id")
            End If
            Return CInt(ctx.Items("CompagnieId"))
        End Get
    End Property

    Public Shared Sub OublierCompagnie()
        HttpContext.Current.Items.Remove("CompagnieId")
    End Sub

    Public Shared ReadOnly Property Utilisateur As String
        Get
            Dim u = HttpContext.Current.User
            Return If(u Is Nothing OrElse Not u.Identity.IsAuthenticated, "", u.Identity.Name)
        End Get
    End Property

    ''' <summary>Compte de l'utilisateur connecté, relu à chaque requête : une désactivation prend effet immédiatement. Nothing si introuvable ou inactif.</summary>
    Public Shared ReadOnly Property Compte As DataRow
        Get
            Dim ctx = HttpContext.Current
            If Not ctx.Items.Contains("Compte") Then
                ctx.Items("Compte") = Db.Ligne(
                    "SELECT Id, Courriel, NomComplet, EstAdmin, DoitChangerMotDePasse FROM dbo.Utilisateur WHERE Courriel = @c AND Actif = 1",
                    Db.P("@c", Utilisateur))
            End If
            Return DirectCast(ctx.Items("Compte"), DataRow)
        End Get
    End Property

    Public Shared ReadOnly Property EstAdmin As Boolean
        Get
            Return Compte IsNot Nothing AndAlso Compte.Bln("EstAdmin")
        End Get
    End Property

    Public Shared Sub Journaliser(description As String, Optional lien As String = Nothing)
        Db.Exec("INSERT INTO dbo.JournalActivite (Utilisateur, Description, Lien) VALUES (@u, @d, @l)",
                Db.P("@u", If(Utilisateur.Length = 0, "système", Utilisateur)), Db.P("@d", description), Db.P("@l", lien))
    End Sub

End Class
