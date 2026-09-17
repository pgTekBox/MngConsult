''' <summary>
''' Contexte de la requête. Les utilisateurs et les compagnies sont ceux de MngConsul :
'''   - utilisateur : dbo.T015User, identifié par son courriel (nom du témoin d'authentification) ;
'''   - compagnies accessibles : procédure s0210GetUserCompanies de MngConsul (un utilisateur normal a sa compagnie,
'''     un comptable a toutes celles dont il est le ComptableGUID) ;
'''   - compagnie courante : Session("Company"), même clé que dans MngConsul.
''' 60secPaie lit ces objets et n'y écrit jamais.
''' </summary>
Public NotInheritable Class Contexte

    Private Sub New()
    End Sub

    Private Shared ReadOnly Property Ctx As HttpContext
        Get
            Return HttpContext.Current
        End Get
    End Property

    Public Shared ReadOnly Property Utilisateur As String
        Get
            Dim u = Ctx.User
            Return If(u Is Nothing OrElse Not u.Identity.IsAuthenticated, "", u.Identity.Name)
        End Get
    End Property

    ''' <summary>Compte MngConsul de l'utilisateur connecté, relu à chaque requête : une désactivation prend effet immédiatement.</summary>
    Public Shared ReadOnly Property Compte As DataRow
        Get
            If Not Ctx.Items.Contains("Compte") Then
                Ctx.Items("Compte") = If(Utilisateur.Length = 0, Nothing, ServiceConnexion.CompteActif(Utilisateur))
            End If
            Return DirectCast(Ctx.Items("Compte"), DataRow)
        End Get
    End Property

    Public Shared ReadOnly Property EstAdmin As Boolean
        Get
            Return Compte IsNot Nothing AndAlso Compte.Bln("EstAdmin")
        End Get
    End Property

    ''' <summary>Compagnies de MngConsul auxquelles l'utilisateur a accès (colonnes CompanyGUID, Name).</summary>
    Public Shared ReadOnly Property Compagnies As DataTable
        Get
            If Not Ctx.Items.Contains("Compagnies") Then
                Ctx.Items("Compagnies") = If(Utilisateur.Length = 0, New DataTable(), ServiceConnexion.CompagniesDe(Utilisateur))
            End If
            Return DirectCast(Ctx.Items("Compagnies"), DataTable)
        End Get
    End Property

    ''' <summary>Compagnie courante (T010Company.CompanyGUID). Toujours revalidée contre les compagnies accessibles.</summary>
    Public Shared ReadOnly Property CompanyGuid As Guid
        Get
            If Ctx.Items.Contains("CompanyGuid") Then Return DirectCast(Ctx.Items("CompanyGuid"), Guid)

            Dim choisie As Guid = Guid.Empty
            If Ctx.Session IsNot Nothing AndAlso TypeOf Ctx.Session("Company") Is Guid Then choisie = DirectCast(Ctx.Session("Company"), Guid)

            Dim resultat As Guid = Guid.Empty
            For Each c As DataRow In Compagnies.Rows
                Dim g = DirectCast(c("CompanyGUID"), Guid)
                If resultat = Guid.Empty Then resultat = g          ' par défaut : la première
                If g = choisie Then resultat = g : Exit For
            Next
            Ctx.Items("CompanyGuid") = resultat
            If Ctx.Session IsNot Nothing Then Ctx.Session("Company") = resultat
            Return resultat
        End Get
    End Property

    ''' <summary>Change de compagnie ; refusé si l'utilisateur n'y a pas accès.</summary>
    Public Shared Function ChangerCompagnie(nouvelle As Guid) As Boolean
        If Not Compagnies.Rows.Cast(Of DataRow)().Any(Function(c) DirectCast(c("CompanyGUID"), Guid) = nouvelle) Then Return False
        Ctx.Session("Company") = nouvelle
        Ctx.Items.Remove("CompanyGuid")
        Ctx.Items.Remove("CompagnieId")
        Return True
    End Function

    Public Shared ReadOnly Property NomCompagnie As String
        Get
            Dim g = CompanyGuid
            For Each c As DataRow In Compagnies.Rows
                If DirectCast(c("CompanyGUID"), Guid) = g Then Return c.Txt("Name")
            Next
            Return ""
        End Get
    End Property

    ''' <summary>Identifiant des paramètres de paie (paie.Compagnie) de la compagnie courante ; 0 tant que la paie n'y est pas configurée.</summary>
    Public Shared ReadOnly Property CompagnieId As Integer
        Get
            If Ctx.Items("CompagnieId") Is Nothing Then
                Dim g = CompanyGuid
                Ctx.Items("CompagnieId") = If(g = Guid.Empty, 0, Db.ScalaireEntier("SELECT Id FROM paie.Compagnie WHERE CompanyGUID = @g", Db.P("@g", g)))
            End If
            Return CInt(Ctx.Items("CompagnieId"))
        End Get
    End Property

    Public Shared Sub OublierCompagnie()
        Ctx.Items.Remove("CompagnieId")
    End Sub

    ''' <summary>Nom et coordonnées de la compagnie courante, tels que définis dans MngConsul (paramètres LEGAL_NAME, ADDR1...).</summary>
    Public Shared Function IdentiteCompagnie() As DataRow
        Return Db.Ligne(
            "SELECT ISNULL(dbo.fCompanyName(@g), N'') AS Nom, dbo.fParamS(@g, 'ADDR1') AS Adresse1, dbo.fParamS(@g, 'ADDR2') AS Adresse2, " &
            "dbo.fParamS(@g, 'CITY') AS Ville, dbo.fParamS(@g, 'POSTAL') AS CodePostal, dbo.fParamS(@g, 'PHONE') AS Telephone, " &
            "dbo.fParamS(@g, 'MAIL_FROM_EMAIL') AS Courriel, dbo.fParamS(@g, 'FED_BN') AS NumeroEntreprise", Db.P("@g", CompanyGuid))
    End Function

    ''' <summary>Recopie le nom et l'adresse de MngConsul dans paie.Compagnie (utilisés par les talons, rapports et fichiers).</summary>
    Public Shared Sub SynchroniserCompagnie()
        If CompagnieId = 0 Then Return
        Dim i = IdentiteCompagnie()
        Db.Exec("UPDATE paie.Compagnie SET Nom = @n, Adresse1 = @a1, Adresse2 = @a2, Ville = @v, CodePostal = @cp, Telephone = @t, " &
                "Courriel = COALESCE(@c, Courriel) WHERE Id = @id",
                Db.P("@n", If(i.Txt("Nom").Length = 0, "(sans nom)", i.Txt("Nom"))), Db.P("@a1", i.Txt("Adresse1")), Db.P("@a2", i.Txt("Adresse2")),
                Db.P("@v", i.Txt("Ville")), Db.P("@cp", Gauche(i.Txt("CodePostal"), 10)), Db.P("@t", Gauche(i.Txt("Telephone"), 30)),
                Db.P("@c", i.Txt("Courriel")), Db.P("@id", CompagnieId))
    End Sub

    Private Shared Function Gauche(texte As String, longueur As Integer) As String
        Return If(texte.Length > longueur, texte.Substring(0, longueur), texte)
    End Function

    Public Shared Sub Journaliser(description As String, Optional lien As String = Nothing)
        Db.Exec("INSERT INTO paie.JournalActivite (Utilisateur, Description, Lien, CompagnieId) VALUES (@u, @d, @l, @c)",
                Db.P("@u", If(Utilisateur.Length = 0, "système", Utilisateur)), Db.P("@d", description), Db.P("@l", lien),
                Db.P("@c", If(CompagnieId = 0, Nothing, CObj(CompagnieId))))
    End Sub

End Class
