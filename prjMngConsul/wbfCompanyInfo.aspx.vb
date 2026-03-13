Imports System.Data.SqlClient



Public Class wbfCompanyInfo
        Inherits System.Web.UI.Page

#Region "Propriétés"

        ''' <summary>
        ''' Chaîne de connexion — à adapter selon ton web.config
        ''' </summary>
        Private ReadOnly Property ConnStr As String
            Get
                Return ConfigurationManager.ConnectionStrings("MngConsulDB").ConnectionString
            End Get
        End Property

#End Region

#Region "Événements de page"

        Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
            If Not IsPostBack Then
                'LoadCompanyInfo()
            End If
        End Sub

#End Region

#Region "Chargement"

        ''' <summary>
        ''' Charge les informations de la compagnie depuis la base de données
        ''' et les affiche dans les champs du formulaire.
        ''' </summary>
        Private Sub LoadCompanyInfo()
            Try
                Using conn As New SqlConnection(ConnStr)
                    conn.Open()

                    Dim sql As String = "
                        SELECT 
                            NomCommercial, RaisonSociale, DateIncorporation, Industrie,
                            Adresse, Ville, Province, CodePostal, Telephone, Courriel, SiteWeb,
                            NEQ, NumeroTPS, NumeroTVQ, AnneeFiscaleDebut,
                            Banque, NumeroTransit, NumeroInstitution, NumeroCompte,
                            NomActionnaire, PourcentageParticipation, TypeActions, NombreActions,
                            ChiffreAffaires, BeneficeNet, TotalActif, TotalPassif
                        FROM CompagnieInfo
                        WHERE Id = 1"

                    Using cmd As New SqlCommand(sql, conn)
                        Using dr As SqlDataReader = cmd.ExecuteReader()
                            If dr.Read() Then
                            ' --- Onglet Générale ---
                            'tbNomCommercial.Text    = NullToString(dr("NomCommercial"))
                            'tbRaisonSociale.Text    = NullToString(dr("RaisonSociale"))
                            'tbIndustrie.Text        = NullToString(dr("Industrie"))
                            'tbAdresse.Text          = NullToString(dr("Adresse"))
                            'tbVille.Text            = NullToString(dr("Ville"))
                            'tbCodePostal.Text       = NullToString(dr("CodePostal"))
                            'tbTelephone.Text        = NullToString(dr("Telephone"))
                            'tbCourriel.Text         = NullToString(dr("Courriel"))
                            'tbSiteWeb.Text          = NullToString(dr("SiteWeb"))

                            'If Not IsDBNull(dr("DateIncorporation")) Then
                            '    tbDateIncorporation.Text = CDate(dr("DateIncorporation")).ToString("yyyy-MM-dd")
                            'End If

                            'SetDropDown(ddlProvince, NullToString(dr("Province")))

                            '' --- Onglet Gouvernementale ---
                            'tbNEQ.Text          = NullToString(dr("NEQ"))
                            'tbTPS.Text          = NullToString(dr("NumeroTPS"))
                            'tbTVQ.Text          = NullToString(dr("NumeroTVQ"))

                            'If Not IsDBNull(dr("AnneeFiscaleDebut")) Then
                            '    tbAnneeFiscale.Text = CDate(dr("AnneeFiscaleDebut")).ToString("yyyy-MM-dd")
                            'End If

                            '' --- Onglet Bancaire ---
                            'tbBanque.Text       = NullToString(dr("Banque"))
                            'tbTransit.Text      = NullToString(dr("NumeroTransit"))
                            'tbInstitution.Text  = NullToString(dr("NumeroInstitution"))
                            'tbCompte.Text       = NullToString(dr("NumeroCompte"))

                            '' --- Onglet Actionnariale ---
                            'tbActionnaire.Text  = NullToString(dr("NomActionnaire"))
                            'tbParticipation.Text = NullToString(dr("PourcentageParticipation"))
                            'tbNbActions.Text    = NullToString(dr("NombreActions"))
                            'SetDropDown(ddlTypeActions, NullToString(dr("TypeActions")))

                            '' --- Onglet État-financier ---
                            'tbCA.Text           = NullToString(dr("ChiffreAffaires"))
                            'tbBenefice.Text     = NullToString(dr("BeneficeNet"))
                            'tbActif.Text        = NullToString(dr("TotalActif"))
                            'tbPassif.Text       = NullToString(dr("TotalPassif"))
                        End If
                        End Using
                    End Using
                End Using

            Catch ex As Exception
                ' Journaliser l'erreur selon ton système de log
                ' Log.Error("LoadCompanyInfo", ex)
                ShowError("Erreur lors du chargement : " & ex.Message)
            End Try
        End Sub

#End Region

#Region "Sauvegarde"

    'Protected Sub btnEnregistrer_Click(sender As Object, e As EventArgs) Handles btnEnregistrer.Click
    '    If Not ValidateForm() Then Exit Sub

    '    Try
    '        Using conn As New SqlConnection(ConnStr)
    '            conn.Open()

    '            ' Vérifie si un enregistrement existe déjà
    '            Dim exists As Boolean = False
    '            Using cmdCheck As New SqlCommand("SELECT COUNT(*) FROM CompagnieInfo WHERE Id = 1", conn)
    '                exists = CInt(cmdCheck.ExecuteScalar()) > 0
    '            End Using

    '            Dim sql As String
    '            If exists Then
    '                sql = "
    '                    UPDATE CompagnieInfo SET
    '                        NomCommercial           = @NomCommercial,
    '                        RaisonSociale           = @RaisonSociale,
    '                        DateIncorporation       = @DateIncorporation,
    '                        Industrie               = @Industrie,
    '                        Adresse                 = @Adresse,
    '                        Ville                   = @Ville,
    '                        Province                = @Province,
    '                        CodePostal              = @CodePostal,
    '                        Telephone               = @Telephone,
    '                        Courriel                = @Courriel,
    '                        SiteWeb                 = @SiteWeb,
    '                        NEQ                     = @NEQ,
    '                        NumeroTPS               = @NumeroTPS,
    '                        NumeroTVQ               = @NumeroTVQ,
    '                        AnneeFiscaleDebut       = @AnneeFiscaleDebut,
    '                        Banque                  = @Banque,
    '                        NumeroTransit           = @NumeroTransit,
    '                        NumeroInstitution       = @NumeroInstitution,
    '                        NumeroCompte            = @NumeroCompte,
    '                        NomActionnaire          = @NomActionnaire,
    '                        PourcentageParticipation= @PourcentageParticipation,
    '                        TypeActions             = @TypeActions,
    '                        NombreActions           = @NombreActions,
    '                        ChiffreAffaires         = @ChiffreAffaires,
    '                        BeneficeNet             = @BeneficeNet,
    '                        TotalActif              = @TotalActif,
    '                        TotalPassif             = @TotalPassif,
    '                        DateModification        = GETDATE()
    '                    WHERE Id = 1"
    '            Else
    '                sql = "
    '                    INSERT INTO CompagnieInfo (
    '                        NomCommercial, RaisonSociale, DateIncorporation, Industrie,
    '                        Adresse, Ville, Province, CodePostal, Telephone, Courriel, SiteWeb,
    '                        NEQ, NumeroTPS, NumeroTVQ, AnneeFiscaleDebut,
    '                        Banque, NumeroTransit, NumeroInstitution, NumeroCompte,
    '                        NomActionnaire, PourcentageParticipation, TypeActions, NombreActions,
    '                        ChiffreAffaires, BeneficeNet, TotalActif, TotalPassif,
    '                        DateCreation, DateModification
    '                    ) VALUES (
    '                        @NomCommercial, @RaisonSociale, @DateIncorporation, @Industrie,
    '                        @Adresse, @Ville, @Province, @CodePostal, @Telephone, @Courriel, @SiteWeb,
    '                        @NEQ, @NumeroTPS, @NumeroTVQ, @AnneeFiscaleDebut,
    '                        @Banque, @NumeroTransit, @NumeroInstitution, @NumeroCompte,
    '                        @NomActionnaire, @PourcentageParticipation, @TypeActions, @NombreActions,
    '                        @ChiffreAffaires, @BeneficeNet, @TotalActif, @TotalPassif,
    '                        GETDATE(), GETDATE()
    '                    )"
    '            End If

    '            Using cmd As New SqlCommand(sql, conn)
    '                AddParameters(cmd)
    '                cmd.ExecuteNonQuery()
    '            End Using
    '        End Using

    '        ShowSuccess("Informations enregistrées avec succès.")

    '    Catch ex As Exception
    '        ShowError("Erreur lors de la sauvegarde : " & ex.Message)
    '    End Try
    'End Sub

#End Region

#Region "Annuler"

    'Protected Sub btnAnnuler_Click(sender As Object, e As EventArgs) Handles btnAnnuler.Click
    '        LoadCompanyInfo()
    '    End Sub

#End Region

#Region "Paramètres SQL"

    ''' <summary>
    ''' Ajoute tous les paramètres SQL à la commande.
    ''' Centralisé ici pour éviter la duplication entre INSERT et UPDATE.
    ''' </summary>
    Private Sub AddParameters(cmd As SqlCommand)
        ' --- Générale ---
        'cmd.Parameters.AddWithValue("@NomCommercial",   StringToNull(tbNomCommercial.Text))
        'cmd.Parameters.AddWithValue("@RaisonSociale",   StringToNull(tbRaisonSociale.Text))
        'cmd.Parameters.AddWithValue("@Industrie",       StringToNull(tbIndustrie.Text))
        'cmd.Parameters.AddWithValue("@Adresse",         StringToNull(tbAdresse.Text))
        'cmd.Parameters.AddWithValue("@Ville",           StringToNull(tbVille.Text))
        'cmd.Parameters.AddWithValue("@Province",        StringToNull(ddlProvince.SelectedValue))
        'cmd.Parameters.AddWithValue("@CodePostal",      StringToNull(tbCodePostal.Text))
        'cmd.Parameters.AddWithValue("@Telephone",       StringToNull(tbTelephone.Text))
        'cmd.Parameters.AddWithValue("@Courriel",        StringToNull(tbCourriel.Text))
        'cmd.Parameters.AddWithValue("@SiteWeb",         StringToNull(tbSiteWeb.Text))

        '' Date d'incorporation
        'If String.IsNullOrWhiteSpace(tbDateIncorporation.Text) Then
        '    cmd.Parameters.AddWithValue("@DateIncorporation", DBNull.Value)
        'Else
        '    cmd.Parameters.AddWithValue("@DateIncorporation", CDate(tbDateIncorporation.Text))
        'End If

        '' --- Gouvernementale ---
        'cmd.Parameters.AddWithValue("@NEQ",         StringToNull(tbNEQ.Text))
        'cmd.Parameters.AddWithValue("@NumeroTPS",   StringToNull(tbTPS.Text))
        'cmd.Parameters.AddWithValue("@NumeroTVQ",   StringToNull(tbTVQ.Text))

        'If String.IsNullOrWhiteSpace(tbAnneeFiscale.Text) Then
        '    cmd.Parameters.AddWithValue("@AnneeFiscaleDebut", DBNull.Value)
        'Else
        '    cmd.Parameters.AddWithValue("@AnneeFiscaleDebut", CDate(tbAnneeFiscale.Text))
        'End If

        '' --- Bancaire ---
        'cmd.Parameters.AddWithValue("@Banque",              StringToNull(tbBanque.Text))
        'cmd.Parameters.AddWithValue("@NumeroTransit",       StringToNull(tbTransit.Text))
        'cmd.Parameters.AddWithValue("@NumeroInstitution",   StringToNull(tbInstitution.Text))
        'cmd.Parameters.AddWithValue("@NumeroCompte",        StringToNull(tbCompte.Text))

        '' --- Actionnariale ---
        'cmd.Parameters.AddWithValue("@NomActionnaire",          StringToNull(tbActionnaire.Text))
        'cmd.Parameters.AddWithValue("@TypeActions",             StringToNull(ddlTypeActions.SelectedValue))

        'Dim participation As Decimal
        'If Decimal.TryParse(tbParticipation.Text, participation) Then
        '    cmd.Parameters.AddWithValue("@PourcentageParticipation", participation)
        'Else
        '    cmd.Parameters.AddWithValue("@PourcentageParticipation", DBNull.Value)
        'End If

        'Dim nbActions As Integer
        'If Integer.TryParse(tbNbActions.Text, nbActions) Then
        '    cmd.Parameters.AddWithValue("@NombreActions", nbActions)
        'Else
        '    cmd.Parameters.AddWithValue("@NombreActions", DBNull.Value)
        'End If

        '' --- État-financier ---
        'cmd.Parameters.AddWithValue("@ChiffreAffaires", ParseDecimalOrNull(tbCA.Text))
        'cmd.Parameters.AddWithValue("@BeneficeNet",     ParseDecimalOrNull(tbBenefice.Text))
        'cmd.Parameters.AddWithValue("@TotalActif",      ParseDecimalOrNull(tbActif.Text))
        'cmd.Parameters.AddWithValue("@TotalPassif",     ParseDecimalOrNull(tbPassif.Text))
    End Sub

#End Region

#Region "Validation"

        ''' <summary>
        ''' Valide les champs obligatoires avant la sauvegarde.
        ''' </summary>
        Private Function ValidateForm() As Boolean
            Dim isValid As Boolean = True

        'If String.IsNullOrWhiteSpace(tbNomCommercial.Text) Then
        '    ShowError("Le nom commercial est obligatoire.")
        '    isValid = False
        'End If

        'If Not String.IsNullOrWhiteSpace(tbCourriel.Text) Then
        '    If Not IsValidEmail(tbCourriel.Text) Then
        '        ShowError("Le format du courriel est invalide.")
        '        isValid = False
        '    End If
        'End If

        Return isValid
        End Function

        Private Function IsValidEmail(email As String) As Boolean
            Try
                Dim addr As New System.Net.Mail.MailAddress(email)
                Return addr.Address = email
            Catch
                Return False
            End Try
        End Function

#End Region

#Region "Utilitaires"

        ''' <summary>Convertit DBNull en String vide.</summary>
        Private Function NullToString(value As Object) As String
            If IsDBNull(value) OrElse value Is Nothing Then Return String.Empty
            Return value.ToString()
        End Function

        ''' <summary>Convertit une String vide en DBNull pour SQL.</summary>
        Private Function StringToNull(value As String) As Object
            If String.IsNullOrWhiteSpace(value) Then Return DBNull.Value
            Return value.Trim()
        End Function

        ''' <summary>Parse un Decimal ou retourne DBNull.</summary>
        Private Function ParseDecimalOrNull(value As String) As Object
            Dim result As Decimal
            If Decimal.TryParse(value, result) Then Return result
            Return DBNull.Value
        End Function

        ''' <summary>Sélectionne une valeur dans un DropDownList.</summary>
        Private Sub SetDropDown(ddl As DropDownList, value As String)
            Dim item As ListItem = ddl.Items.FindByValue(value)
            If item IsNot Nothing Then
                ddl.SelectedValue = value
            End If
        End Sub

        ''' <summary>Affiche un message d'erreur — à adapter selon ton système de notification.</summary>
        Private Sub ShowError(message As String)
            ' Exemple avec ScriptManager :
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "error",
                $"alert('❌ {message.Replace("'", "\\'")}');", True)
        End Sub

        ''' <summary>Affiche un message de succès — à adapter selon ton système de notification.</summary>
        Private Sub ShowSuccess(message As String)
            ScriptManager.RegisterStartupScript(Me, Me.GetType(), "success",
                $"alert('✅ {message.Replace("'", "\\'")}');", True)
        End Sub

#End Region

    End Class


