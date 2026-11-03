Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

Namespace Controls

    Public Class Header
        Inherits clsDataUC

        Private Sub Header_Load(sender As Object, e As EventArgs) Handles Me.Load
            LoadPortails()
            LoadProfilEssai()      ' à côté du logo : profil (TA/Cie) · métier + état de l'essai
            LoadFournisseurs()     ' à droite : « Fournisseurs connectés » (banque, Stripe, Square)
        End Sub

        ''' <summary>
        ''' La barre des portails, comme sur la page publique : Entreprise (ici, la
        ''' pastille blanche), puis le bouton Cabinets certifiés (l'annuaire, en fenêtre),
        ''' puis Paie et Paiements — seulement ceux dont Web.config donne l'adresse
        ''' (Portail.Paie.Url, Portail.Paiements.Url). Sans adresse, le portail n'est pas montré : un lien
        ''' qui ne mène nulle part vaut moins que pas de lien.
        ''' </summary>
        Private Sub LoadPortails()
            Dim lang As String = CurrentLang
            Dim sb As New StringBuilder()
            ' « Entreprise » et « Cabinets certifiés » retirés de l'en-tête (l'annuaire des
            ' cabinets reste accessible par le menu : Mon cabinet comptable).
            AjouterPortail(sb, "Portail.Paie.Url", Mot(lang, "Paie", "Payroll", "Nómina"))
            AjouterPortail(sb, "Portail.Paiements.Url", Mot(lang, "Paiements", "Payments", "Pagos"))
            litPortails.Text = sb.ToString()
        End Sub

        ''' <summary>
        ''' « Cabinets certifiés » : un bouton, pas un lien — il ouvre dans une fenêtre
        ''' par-dessus la page (ouvrirFenetreApp du master) l'annuaire des cabinets
        ''' comptables certifiés (CabinetsCertifies.aspx?popup=1). Toujours montré : cette
        ''' liste vit dans la base, pas dans Web.config.
        ''' </summary>
        Private Sub AjouterBoutonCabinets(sb As StringBuilder, libelle As String)
            Dim url As String = ResolveUrl("~/CabinetsCertifies.aspx?popup=1")
            sb.Append("<button type=""button"" onclick=""ouvrirFenetreApp('").Append(url).Append("', this.textContent)"">").Append(Server.HtmlEncode(libelle)).Append("</button>")
        End Sub

        Private Sub AjouterPortail(sb As StringBuilder, cle As String, libelle As String)
            Dim url As String = ConfigurationManager.AppSettings(cle)
            If String.IsNullOrWhiteSpace(url) Then Return
            sb.Append("<a href=""").Append(Server.HtmlEncode(url.Trim())).Append(""">").Append(Server.HtmlEncode(libelle)).Append("</a>")
        End Sub

        ''' <summary>Libellé du bouton ☰ : « Masquer le menu » (fermer = True) ou « Afficher le menu ».</summary>
        Protected Function MenuLbl(fermer As Boolean) As String
            If fermer Then Return Mot(CurrentLang, "Masquer le menu", "Hide menu", "Ocultar el menú")
            Return Mot(CurrentLang, "Afficher le menu", "Show menu", "Mostrar el menú")
        End Function

        Private Shared Function Mot(lang As String, fr As String, en As String, es As String) As String
            Select Case lang
                Case "en" : Return en
                Case "es" : Return es
                Case Else : Return fr
            End Select
        End Function

        ' =====================================================================
        ' À côté du logo : profil (TA / Cie + nb d'employés) · métier, et l'essai
        ' (maquette « page première » du 21 octobre). Lu des paramètres Entreprise
        ' (PROFIL, METIER, mêmes valeurs que « Qui fait quoi ») et de l'essai (s0687).
        ' =====================================================================
        Private Sub LoadProfilEssai()
            Dim comp As Guid = CompagnieCourante()
            If comp = Guid.Empty Then litProfilMetier.Text = "" : Return

            Dim profil As String = ParamEntreprise("PROFIL")
            Dim metier As String = ParamEntreprise("METIER")
            Dim essai As String = EssaiLigne()

            If profil = "" AndAlso metier = "" AndAlso essai = "" Then
                litProfilMetier.Text = ""
                Return
            End If

            Dim sb As New StringBuilder()
            sb.Append("<div class=""hdr-ctx"">")
            If profil <> "" OrElse metier <> "" Then
                sb.Append("<div class=""hdr-pm"">")
                If profil <> "" Then
                    sb.Append("<b class=""hdr-prof"">").Append(Server.HtmlEncode(profil))
                    ' « Cie 1-4 » : le nombre réel d'employés dans un cercle.
                    If profil.StartsWith("Cie 1", StringComparison.OrdinalIgnoreCase) Then
                        Dim nEmp As Integer = CompterEmployes()
                        If nEmp > 0 Then
                            sb.Append("<span class=""hdr-nemp"" title=""").Append(Server.HtmlEncode(NbEmpTitre(nEmp))).Append(""" aria-label=""").Append(Server.HtmlEncode(NbEmpTitre(nEmp))).Append(""">").Append(nEmp).Append("</span>")
                        End If
                    End If
                    sb.Append("</b>")
                End If
                If metier <> "" Then
                    If profil <> "" Then sb.Append("<span class=""hdr-sep"" aria-hidden=""true"">·</span>")
                    sb.Append("<b class=""hdr-met"">").Append(Server.HtmlEncode(metier)).Append("</b>")
                End If
                sb.Append("</div>")
            End If
            If essai <> "" Then sb.Append("<span class=""hdr-essai").Append(If(_essaiJours <= 3, " urg", "")).Append(""">").Append(Server.HtmlEncode(essai)).Append("</span>")
            sb.Append("</div>")
            litProfilMetier.Text = sb.ToString()
        End Sub

        ''' <summary>« Essai gratuit · N jours restants » (s0687) ; vide si pas en essai.
        ''' Pose aussi _essaiJours (pour la couleur d'urgence).</summary>
        Private _essaiJours As Integer = 999
        Private Function EssaiLigne() As String
            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", Company))
                Dim ds As DataSet = ExecuteSQLds("s0687GetCompanyTrialStatus", p)
                If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return ""
                Dim r As DataRow = ds.Tables(0).Rows(0)
                If IsDBNull(r("IsTrial")) OrElse Not Convert.ToBoolean(r("IsTrial")) OrElse IsDBNull(r("DaysRemaining")) Then Return ""
                Dim jours As Integer = Convert.ToInt32(r("DaysRemaining"))
                If jours < 0 Then jours = 0
                _essaiJours = jours
                Return Mot(CurrentLang,
                           "Essai gratuit · " & jours & " jours restants",
                           "Free trial · " & jours & " days left",
                           "Prueba gratuita · quedan " & jours & " días")
            Catch
                Return ""
            End Try
        End Function

        Private Function NbEmpTitre(n As Integer) As String
            Return Mot(CurrentLang, n & " employé(s)", n & " employee(s)", n & " empleado(s)")
        End Function

        ''' <summary>Nombre d'employés (ressources d'agenda) de la compagnie, s0106.</summary>
        Private Function CompterEmployes() As Integer
            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", Company))
                Dim ds As DataSet = ExecuteSQLds("s0106GetEmployeesForAgenda", p)
                If ds IsNot Nothing AndAlso ds.Tables.Count > 0 Then Return ds.Tables(0).Rows.Count
            Catch
            End Try
            Return 0
        End Function

        ''' <summary>Valeur texte d'un paramètre de Paramètres › Entreprise (vide si absent).</summary>
        Private _entreprise As DataTable
        Private Function ParamEntreprise(cle As String) As String
            Try
                If _entreprise Is Nothing Then
                    Dim p As New Collection
                    p.Add(New SqlParameter("@CompanyGUID", Company))
                    p.Add(New SqlParameter("@Categorie", "ENTREPRISE"))
                    Dim ds As DataSet = ExecuteSQLds("s0150GetParamsForCompany", p)
                    _entreprise = If(ds IsNot Nothing AndAlso ds.Tables.Count > 0, ds.Tables(0), New DataTable())
                End If
                For Each r As DataRow In _entreprise.Rows
                    If String.Equals(Convert.ToString(r("ShortName")), cle, StringComparison.OrdinalIgnoreCase) Then
                        Return If(IsDBNull(r("sVal")), "", Convert.ToString(r("sVal")).Trim())
                    End If
                Next
            Catch
            End Try
            Return ""
        End Function

        ' =====================================================================
        ' À droite : « Fournisseurs connectés » — un bouton vert (nombre) qui ouvre
        ' la liste des branchements : banque (Plaid), Stripe, Square. Remplace les
        ' deux pastilles d'état séparées, comme la maquette.
        ' =====================================================================
        Private Sub LoadFournisseurs()
            Dim comp As Guid = CompagnieCourante()
            If comp = Guid.Empty Then litFournisseurs.Text = "" : Return

            Dim lignes As New List(Of String)
            Dim nConnectes As Integer = 0

            ' --- Banque (Plaid) ---
            Dim bankCount As Integer = 0, banks As String = ""
            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", comp))
                Dim ds As DataSet = ExecuteSQLds("s0698GetCompanyPlaidStatus", p)
                If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                    Dim r As DataRow = ds.Tables(0).Rows(0)
                    bankCount = If(IsDBNull(r("BankCount")), 0, CInt(r("BankCount")))
                    banks = If(IsDBNull(r("Banks")), "", Convert.ToString(r("Banks")))
                End If
            Catch
            End Try
            Dim labBanque As String = Mot(CurrentLang, "Banque", "Bank", "Banco")
            If bankCount > 0 Then
                nConnectes += 1
                lignes.Add(LigneFournisseur(labBanque, banks, True))
            Else
                lignes.Add(LigneFournisseur(labBanque, Mot(CurrentLang, "non branchée", "not connected", "no conectado"), False))
            End If

            ' --- Stripe ---
            Dim stripeCount As Integer = 0
            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", comp))
                Dim ds As DataSet = ExecuteSQLds("s0699GetStripeSupplierCount", p)
                If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                    Dim v As Object = ds.Tables(0).Rows(0)("StripeSupplierCount")
                    stripeCount = If(IsDBNull(v), 0, CInt(v))
                End If
            Catch
            End Try
            If stripeCount > 0 Then
                nConnectes += 1
                lignes.Add(LigneFournisseur("Stripe", String.Format(Mot(CurrentLang, "{0} fournisseur(s)", "{0} supplier(s)", "{0} proveedor(es)"), stripeCount), True))
            Else
                lignes.Add(LigneFournisseur("Stripe", Mot(CurrentLang, "non branché", "not connected", "no conectado"), False))
            End If

            ' --- Square ---
            Dim square As Boolean = False
            Try : square = IsSquareConnected() : Catch : End Try
            If square Then
                nConnectes += 1
                lignes.Add(LigneFournisseur("Square", Mot(CurrentLang, "branché", "connected", "conectado"), True))
            Else
                lignes.Add(LigneFournisseur("Square", Mot(CurrentLang, "non branché", "not connected", "no conectado"), False))
            End If

            Dim libelle As String = Mot(CurrentLang, "Fournisseurs connectés", "Connected providers", "Proveedores conectados")
            Dim sb As New StringBuilder()
            sb.Append("<div class=""fourn-wrap"">")
            sb.Append("<button type=""button"" class=""fourn-btn"" data-fourn-btn aria-expanded=""false"" aria-controls=""fournListe"" title=""").Append(Server.HtmlEncode(libelle)).Append(""">")
            sb.Append("<span class=""fourn-n"">").Append(nConnectes).Append("</span>")
            sb.Append("<span class=""fourn-lbl"">").Append(Server.HtmlEncode(libelle)).Append("</span>")
            sb.Append("<svg class=""fourn-chv"" aria-hidden=""true"" width=""14"" height=""14"" viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""2.6"" stroke-linecap=""round"" stroke-linejoin=""round""><path d=""M6 9l6 6 6-6""></path></svg>")
            sb.Append("</button>")
            sb.Append("<div class=""fourn-liste"" id=""fournListe"" data-fourn-liste hidden><b>").Append(Server.HtmlEncode(libelle)).Append("</b>")
            For Each l As String In lignes : sb.Append(l) : Next
            sb.Append("</div></div>")
            litFournisseurs.Text = sb.ToString()
        End Sub

        Private Function LigneFournisseur(nom As String, detail As String, connecte As Boolean) As String
            Dim cls As String = If(connecte, "on", "off")
            Return "<div class=""fourn-it " & cls & """><span class=""fourn-nom"">" & Server.HtmlEncode(nom) & "</span>" &
                   "<span class=""fourn-det"">" & Server.HtmlEncode(detail) & "</span>" &
                   "<span class=""fourn-dot"" aria-hidden=""true""></span></div>"
        End Function

        Private Function CompagnieCourante() As Guid
            Try
                Return Company
            Catch
                Return Guid.Empty
            End Try
        End Function

    End Class

End Namespace
