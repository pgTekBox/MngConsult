Imports System.Data
Imports System.Globalization

''' <summary>
''' Tableau de bord du Portail Maître (page protégée via Site.Master).
''' </summary>
Public Class [Default]
    Inherits clsData

    Private Shared ReadOnly Cult As CultureInfo = New CultureInfo("fr-CA")

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Dim prenom As String = AdminName.Split(" "c)(0)
            If Not String.IsNullOrEmpty(prenom) Then
                litHello.Text = ", " & Server.HtmlEncode(prenom)
            End If
            LoadTreasury()
        End If
    End Sub

    ''' <summary>Résumé de trésorerie plateforme + contrôle de l'invariant comptable.</summary>
    Private Sub LoadTreasury()
        Try
            Dim r As DataRow = ExecuteSQLds("s0018GetPlatformSummary", New Collection).Tables(0).Rows(0)
            Dim trust As Long = ToLong(r("TrustCents"))
            Dim owed As Long = ToLong(r("TotalSoldeCents")) + ToLong(r("TotalReserveCents"))
            Dim fees As Long = ToLong(r("FeesCents"))
            litTrust.Text = Money(trust)
            litOwed.Text = Money(owed)
            litFees.Text = Money(fees)
            If Not IsDBNull(r("InvariantOK")) AndAlso CBool(r("InvariantOK")) Then
                litInvariant.Text = "<span class=""inv-ok"">✓ Équilibré</span>"
            Else
                litInvariant.Text = "<span class=""inv-bad"">⚠ Déséquilibre</span>"
            End If
        Catch ex As Exception
            Dim na As String = "—"
            litTrust.Text = na : litOwed.Text = na : litFees.Text = na
            litInvariant.Text = "<span class=""muted"">n/d</span>"
            System.Diagnostics.Debug.WriteLine("Treasury: " & ex.Message)
        End Try
    End Sub

    Private Function ToLong(o As Object) As Long
        If o Is Nothing OrElse IsDBNull(o) Then Return 0
        Return Convert.ToInt64(o)
    End Function

    Private Function Money(cents As Long) As String
        Return (cents / 100D).ToString("N2", Cult) & " $"
    End Function

End Class
