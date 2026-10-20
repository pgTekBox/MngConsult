Imports System.Configuration
Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

Namespace Controls

    Public Class Header
        Inherits clsDataUC

        Private Sub Header_Load(sender As Object, e As EventArgs) Handles Me.Load
            LoadPortails()
            LoadPlaidStatus()
            LoadStripeStatus()
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

        ''' <summary>Pastille : nombre de fournisseurs connectés à Stripe Connect.</summary>
        Private Sub LoadStripeStatus()
            Dim comp As Guid = Guid.Empty
            Try
                comp = Company
            Catch
            End Try
            If comp = Guid.Empty Then
                litStripeStatus.Text = ""
                Return
            End If

            Dim count As Integer = 0
            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", comp))
                Dim ds As DataSet = ExecuteSQLds("s0699GetStripeSupplierCount", p)
                If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                    Dim v As Object = ds.Tables(0).Rows(0)("StripeSupplierCount")
                    count = If(IsDBNull(v), 0, CInt(v))
                End If
            Catch
            End Try

            Dim cls As String = If(count > 0, "on", "off")
            Dim lbl As String = StripeSuppliersLabel()
            litStripeStatus.Text =
                "<span class=""stripe-hdr-pill " & cls & """ title=""" & Server.HtmlEncode(count.ToString() & " " & lbl) & """>" &
                "<span class=""dot""></span>💳 <span class=""num"">" & count.ToString() & "</span> " &
                "<span class=""lbl"">" & Server.HtmlEncode(lbl) & "</span></span>"
        End Sub

        Private Function StripeSuppliersLabel() As String
            Select Case CurrentLang
                Case "en" : Return "Stripe suppliers"
                Case "es" : Return "proveedores Stripe"
                Case Else : Return "fournisseurs Stripe"
            End Select
        End Function

        ''' <summary>Affiche dans le header si Plaid est connecté et avec quelle(s) banque(s).</summary>
        Private Sub LoadPlaidStatus()

            ' Pas de compagnie en session (ex. page de connexion) → aucun indicateur.
            Dim comp As Guid = Guid.Empty
            Try
                comp = Company
            Catch
            End Try
            If comp = Guid.Empty Then
                litPlaidStatus.Text = ""
                Return
            End If

            Dim banks As String = ""
            Dim bankCount As Integer = 0

            Try
                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", comp))
                Dim ds As DataSet = ExecuteSQLds("s0698GetCompanyPlaidStatus", p)
                If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                    Dim r As DataRow = ds.Tables(0).Rows(0)
                    bankCount = If(IsDBNull(r("BankCount")), 0, CInt(r("BankCount")))
                    banks = If(IsDBNull(r("Banks")), "", r("Banks").ToString())
                End If
            Catch
            End Try

            If bankCount > 0 Then
                Dim full As String = Server.HtmlEncode(banks)
                litPlaidStatus.Text =
                    "<span class=""plaid-pill on"" title=""Plaid — " & full & """>" &
                    "<span class=""dot""></span>🏦 <span class=""lbl"">" & full & "</span></span>"
            Else
                Dim off As String = Server.HtmlEncode(PlaidOffLabel())
                litPlaidStatus.Text =
                    "<span class=""plaid-pill off"" title=""" & off & """>" &
                    "<span class=""dot""></span>🏦 <span class=""lbl"">" & off & "</span></span>"
            End If
        End Sub

        Private Function PlaidOffLabel() As String
            Select Case CurrentLang
                Case "en" : Return "Plaid not connected"
                Case "es" : Return "Plaid no conectado"
                Case Else : Return "Plaid non connecté"
            End Select
        End Function

    End Class

End Namespace
