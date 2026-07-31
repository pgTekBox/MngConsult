Imports System.Data
Imports System.Data.SqlClient

Namespace Controls

    Public Class Header
        Inherits clsDataUC

        Private Sub Header_Load(sender As Object, e As EventArgs) Handles Me.Load
            LoadPlaidStatus()
            LoadStripeStatus()
        End Sub

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
