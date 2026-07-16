Imports QuestPDF.Fluent
Imports QuestPDF.Helpers
Imports QuestPDF.Infrastructure

Public Class InvoicePdfBuilder

    ' ============================================================
    ' Couleurs MngConsul
    ' ============================================================
    Private Const CLR_PRIMARY As String = "#2563eb"
    Private Const CLR_SECONDARY As String = "#06b6d4"
    Private Const CLR_TEXT As String = "#0f172a"
    Private Const CLR_TEXT_MUTED As String = "#64748b"
    Private Const CLR_TEXT_LIGHT As String = "#475569"
    Private Const CLR_BG_LIGHT As String = "#f8fafc"
    Private Const CLR_BG_ACCENT As String = "#eff6ff"
    Private Const CLR_LINE As String = "#e2e8f0"
    Private Const CLR_NOTE_BG As String = "#ecfeff"
    Private Const CLR_NOTE_TEXT As String = "#0e7490"
    Private Const CLR_LINE_DARK As String = "#cbd5e1"
    Private Const CLR_WHITE As String = "#ffffff"
    Private Const CLR_STAMP As String = "#dc2626"   ' Rouge tampon « PAYÉ »

    ' ============================================================
    ' Point d'entrée
    ' ============================================================
    Public Shared Function Build(invoice As InvoiceData) As Byte()
        Return Document.Create(
            Sub(container)
                container.Page(
                    Sub(page)
                        page.Size(PageSizes.Letter)
                        page.Margin(40)
                        page.PageColor(CLR_WHITE)
                        page.DefaultTextStyle(
                            Function(x) x.FontSize(10).FontFamily("Arial").FontColor(CLR_TEXT))

                        page.Content().Element(Sub(c) ComposeBody(c, invoice))
                        page.Footer().Element(Sub(c) ComposeFooter(c, invoice))
                    End Sub)
            End Sub).GeneratePdf()
    End Function

    '' ============================================================
    '' Corps — avec couche tampon en superposition si payée
    '' ============================================================
    'Private Shared Sub ComposeBody(container As IContainer, inv As InvoiceData)
    '    container.Layers(
    '        Sub(layers)
    '            ' Couche principale : le contenu normal de la facture
    '            layers.PrimaryLayer().Column(
    '                Sub(col)
    '                    col.Spacing(20)

    '                    ComposeHeader(col, inv)
    '                    ComposeMetaCards(col, inv)
    '                    ComposeClientCards(col, inv)
    '                    ComposeItemsTable(col, inv)
    '                    ComposeTotals(col, inv)

    '                    If Not String.IsNullOrEmpty(inv.PaymentTerms) Then
    '                        ComposeNotes(col, inv.PaymentTerms)
    '                    End If
    '                End Sub)

    '            ' Couche du tampon : seulement sur la 1ère page, seulement si payée
    '            If inv.IsPaid Then
    '                layers.Layer().ShowOnce().AlignCenter().AlignMiddle().
    '                    Element(Sub(c) ComposePaidStamp(c))
    '            End If
    '        End Sub)
    'End Sub
    Private Shared Sub ComposeBody(container As IContainer, inv As InvoiceData)
        container.Column(
        Sub(col)
            col.Spacing(20)

            ' Si payée, on injecte un élément zéro-hauteur qui dessine le tampon
            ' à la position absolue centre-haut de la page.
            If inv.IsPaid Then
                col.Item().Height(0).Element(
                    Sub(stampSlot)
                        stampSlot.TranslateX(120).TranslateY(280).
                            Element(Sub(c) ComposePaidStamp(c))
                    End Sub)
            End If

            ComposeHeader(col, inv)
            ComposeMetaCards(col, inv)
            ComposeClientCards(col, inv)
            ComposeItemsTable(col, inv)
            ComposeTotals(col, inv)

            If Not String.IsNullOrEmpty(inv.PaymentTerms) Then
                ComposeNotes(col, inv.PaymentTerms)
            End If
        End Sub)
    End Sub
    ' ============================================================
    ' En-tête
    ' ============================================================
    Private Shared Sub ComposeHeader(col As ColumnDescriptor, inv As InvoiceData)

        col.Item().BorderBottom(3).BorderColor(CLR_PRIMARY).PaddingBottom(15).Row(
            Sub(row)

                ' Côté gauche : logo + nom entreprise
                row.RelativeItem().Row(
                    Sub(brandRow)
                        If inv.LogoBytes IsNot Nothing AndAlso inv.LogoBytes.Length > 0 Then
                            ' Vrai logo de l'entreprise
                            brandRow.AutoItem().Width(50).Height(50).AlignCenter().AlignMiddle().
                                Image(inv.LogoBytes).FitArea()
                        Else
                            ' Repli : carré avec l'initiale
                            brandRow.AutoItem().Width(50).Height(50).Background(CLR_PRIMARY).AlignCenter().AlignMiddle().
                                Text(GetInitial(inv.CompanyName)).
                                    FontSize(24).FontColor(CLR_WHITE).Bold()
                        End If

                        brandRow.ConstantItem(12)

                        brandRow.RelativeItem().AlignMiddle().Column(
                            Sub(c)
                                c.Item().Text(inv.CompanyName).FontSize(16).Bold()
                                c.Item().Text(inv.CompanyTagline).FontSize(10).FontColor(CLR_TEXT_MUTED)
                            End Sub)
                    End Sub)

                ' Côté droit : titre FACTURE
                row.AutoItem().AlignRight().Column(
                    Sub(c)
                        c.Item().AlignRight().Text("FACTURE").FontSize(28).Bold().FontColor(CLR_PRIMARY)
                        c.Item().AlignRight().Text("N° " & inv.InvoiceNumber).FontSize(11).FontColor(CLR_TEXT_MUTED)
                    End Sub)
            End Sub)
    End Sub

    ' ============================================================
    ' 3 cartes meta
    ' ============================================================
    Private Shared Sub ComposeMetaCards(col As ColumnDescriptor, inv As InvoiceData)
        col.Item().Row(
            Sub(row)
                row.Spacing(10)

                row.RelativeItem().Element(
                    Sub(c) BuildMetaCard(c, "DATE D'ÉMISSION",
                                          inv.IssueDate.ToString("yyyy-MM-dd"),
                                          accent:=False))
                row.RelativeItem().Element(
                    Sub(c) BuildMetaCard(c, "DATE D'ÉCHÉANCE",
                                          inv.DueDate.ToString("yyyy-MM-dd"),
                                          accent:=False))
                row.RelativeItem().Element(
                    Sub(c) BuildMetaCard(c, "MONTANT DÛ",
                                          inv.Total.ToString("C"),
                                          accent:=True))
            End Sub)
    End Sub

    ''' <summary>
    ''' Carte meta : titre en haut + valeur en bas.
    ''' Utilise la syntaxe Text delegate pour éviter les conflits de chaînage.
    ''' </summary>
    Private Shared Sub BuildMetaCard(container As IContainer, label As String, value As String, accent As Boolean)
        Dim bg As String = If(accent, CLR_BG_ACCENT, CLR_WHITE)
        Dim valueColor As String = If(accent, CLR_PRIMARY, CLR_TEXT)

        container.Background(bg).Border(0.5F).BorderColor(CLR_LINE).
            Padding(12).Column(
            Sub(c)
                c.Item().Text(label).FontSize(9).FontColor(CLR_TEXT_MUTED).Bold()
                c.Item().PaddingTop(3).Text(value).FontSize(13).Bold().FontColor(valueColor)
            End Sub)
    End Sub

    ' ============================================================
    ' Cartes émetteur / client
    ' ============================================================
    Private Shared Sub ComposeClientCards(col As ColumnDescriptor, inv As InvoiceData)
        col.Item().Row(
            Sub(row)
                row.Spacing(15)

                ' Émetteur
                row.RelativeItem().Background(CLR_BG_LIGHT).Padding(14).Column(
                    Sub(c)
                        c.Item().Text("FACTURÉ PAR").FontSize(9).FontColor(CLR_TEXT_MUTED).Bold()
                        c.Item().PaddingTop(4).Text(inv.CompanyName).FontSize(13).Bold()
                        c.Item().Text(inv.CompanyAddressLine1).FontSize(10).FontColor(CLR_TEXT_LIGHT)
                        If Not String.IsNullOrEmpty(inv.CompanyAddressLine2) Then
                            c.Item().Text(inv.CompanyAddressLine2).FontSize(10).FontColor(CLR_TEXT_LIGHT)
                        End If
                        If Not String.IsNullOrEmpty(inv.CompanyPhone) Then
                            c.Item().Text(inv.CompanyPhone).FontSize(10).FontColor(CLR_TEXT_LIGHT)
                        End If

                        If Not String.IsNullOrEmpty(inv.CompanyTpsNumber) Then
                            c.Item().PaddingTop(6).Text("TPS : " & inv.CompanyTpsNumber).FontSize(9).FontColor(CLR_TEXT_MUTED)
                        End If
                        If Not String.IsNullOrEmpty(inv.CompanyTvqNumber) Then
                            c.Item().Text("TVQ : " & inv.CompanyTvqNumber).FontSize(9).FontColor(CLR_TEXT_MUTED)
                        End If
                    End Sub)

                ' Client
                row.RelativeItem().Background(CLR_BG_LIGHT).Padding(14).Column(
                    Sub(c)
                        c.Item().Text("FACTURÉ À").FontSize(9).FontColor(CLR_TEXT_MUTED).Bold()
                        c.Item().PaddingTop(4).Text(inv.CustomerName).FontSize(13).Bold()
                        If Not String.IsNullOrEmpty(inv.CustomerAddressLine1) Then
                            c.Item().Text(inv.CustomerAddressLine1).FontSize(10).FontColor(CLR_TEXT_LIGHT)
                        End If
                        If Not String.IsNullOrEmpty(inv.CustomerAddressLine2) Then
                            c.Item().Text(inv.CustomerAddressLine2).FontSize(10).FontColor(CLR_TEXT_LIGHT)
                        End If
                        If Not String.IsNullOrEmpty(inv.CustomerPhone) Then
                            c.Item().Text(inv.CustomerPhone).FontSize(10).FontColor(CLR_TEXT_LIGHT)
                        End If
                        If Not String.IsNullOrEmpty(inv.CustomerEmail) Then
                            c.Item().Text(inv.CustomerEmail).FontSize(10).FontColor(CLR_TEXT_LIGHT)
                        End If
                    End Sub)
            End Sub)
    End Sub

    ' ============================================================
    ' Tableau des lignes
    ' ============================================================
    Private Shared Sub ComposeItemsTable(col As ColumnDescriptor, inv As InvoiceData)
        col.Item().Table(
            Sub(table)
                table.ColumnsDefinition(
                    Sub(cols)
                        cols.RelativeColumn(5)    ' Description
                        cols.RelativeColumn(1)    ' Qté
                        cols.RelativeColumn(2)    ' Prix
                        cols.RelativeColumn(2)    ' Montant
                    End Sub)

                ' En-tête
                table.Header(
                    Sub(header)
                        header.Cell().Background(CLR_PRIMARY).Padding(10).
                            Text("DESCRIPTION").FontSize(10).Bold().FontColor(CLR_WHITE)
                        header.Cell().Background(CLR_PRIMARY).Padding(10).AlignCenter().
                            Text("QTÉ").FontSize(10).Bold().FontColor(CLR_WHITE)
                        header.Cell().Background(CLR_PRIMARY).Padding(10).AlignRight().
                            Text("PRIX").FontSize(10).Bold().FontColor(CLR_WHITE)
                        header.Cell().Background(CLR_PRIMARY).Padding(10).AlignRight().
                            Text("MONTANT").FontSize(10).Bold().FontColor(CLR_WHITE)
                    End Sub)

                ' Lignes
                For i As Integer = 0 To inv.Items.Count - 1
                    Dim line = inv.Items(i)
                    Dim bg As String = If(i Mod 2 = 0, CLR_WHITE, CLR_BG_LIGHT)

                    ' Description (avec sous-titre éventuel)
                    table.Cell().Background(bg).Padding(10).Column(
                        Sub(c)
                            c.Item().Text(line.Description).FontSize(11).Bold()
                            If Not String.IsNullOrEmpty(line.SubDescription) Then
                                c.Item().PaddingTop(2).Text(line.SubDescription).FontSize(9).FontColor(CLR_TEXT_MUTED)
                            End If
                        End Sub)

                    table.Cell().Background(bg).Padding(10).AlignCenter().AlignMiddle().
                        Text(line.Qty.ToString("0.##")).FontSize(11)

                    table.Cell().Background(bg).Padding(10).AlignRight().AlignMiddle().
                        Text(line.UnitPrice.ToString("C")).FontSize(11)

                    table.Cell().Background(bg).Padding(10).AlignRight().AlignMiddle().
                        Text(line.Amount.ToString("C")).FontSize(11).Bold()
                Next
            End Sub)
    End Sub

    ' ============================================================
    ' Totaux
    ' ============================================================
    Private Shared Sub ComposeTotals(col As ColumnDescriptor, inv As InvoiceData)
        col.Item().AlignRight().Width(280).Background(CLR_BG_LIGHT).Padding(14).Column(
            Sub(c)
                BuildTotalLine(c, "Sous-total", inv.SubTotal)

                If inv.Tps > 0 Then
                    BuildTotalLine(c, "TPS (" & inv.TpsRate.ToString("0.###") & " %)", inv.Tps)
                End If
                If inv.Tvq > 0 Then
                    BuildTotalLine(c, "TVQ (" & inv.TvqRate.ToString("0.###") & " %)", inv.Tvq)
                End If

                ' Séparateur
                c.Item().PaddingVertical(6).LineHorizontal(0.5F).LineColor(CLR_LINE_DARK)

                ' TOTAL
                c.Item().Background(CLR_PRIMARY).Padding(10).Row(
                    Sub(row)
                        row.RelativeItem().Text("TOTAL").FontSize(11).Bold().FontColor(CLR_WHITE)
                        row.AutoItem().Text(inv.Total.ToString("C")).FontSize(15).Bold().FontColor(CLR_WHITE)
                    End Sub)
            End Sub)
    End Sub

    Private Shared Sub BuildTotalLine(c As ColumnDescriptor, label As String, value As Decimal)
        c.Item().PaddingVertical(2).Row(
            Sub(row)
                row.RelativeItem().Text(label).FontSize(11).FontColor(CLR_TEXT_LIGHT)
                row.AutoItem().Text(value.ToString("C")).FontSize(11).Bold()
            End Sub)
    End Sub

    ' ============================================================
    ' Notes
    ' ============================================================
    Private Shared Sub ComposeNotes(col As ColumnDescriptor, notes As String)
        col.Item().BorderLeft(3).BorderColor(CLR_SECONDARY).
            Background(CLR_NOTE_BG).Padding(12).
            Text(notes).FontSize(10).FontColor(CLR_NOTE_TEXT)
    End Sub

    ' ============================================================
    ' Tampon « PAYÉ »
    '   Rouge, bold 90pt, encadré, incliné -22°.
    '   Centré sur la page (via AlignCenter/AlignMiddle de la couche appelante).
    ' ============================================================
    Private Shared Sub ComposePaidStamp(container As IContainer)
        container.Rotate(-22).Width(280).Height(120).
            Border(4).BorderColor(CLR_STAMP).
            Padding(10).
            AlignCenter().AlignMiddle().
            Text("PAYÉ").
                FontSize(90).Bold().FontColor(CLR_STAMP).LetterSpacing(0.05F)
    End Sub

    ' ============================================================
    ' Pied de page
    ' ============================================================
    Private Shared Sub ComposeFooter(container As IContainer, inv As InvoiceData)
        container.BorderTop(0.5F).BorderColor(CLR_LINE).PaddingTop(10).
            AlignCenter().Text(
            Sub(text)
                text.DefaultTextStyle(Function(x) x.FontSize(9).FontColor(CLR_TEXT_MUTED))
                text.Span(inv.CompanyName)
                If Not String.IsNullOrEmpty(inv.CompanyAddressLine1) Then
                    text.Span(" — " & inv.CompanyAddressLine1)
                End If
                If Not String.IsNullOrEmpty(inv.CompanyEmail) Then
                    text.Span(" — " & inv.CompanyEmail)
                End If
                text.Span(" — Page ")
                text.CurrentPageNumber()
                text.Span(" / ")
                text.TotalPages()
            End Sub)
    End Sub

    ' ============================================================
    ' Helpers
    ' ============================================================
    Private Shared Function GetInitial(s As String) As String
        If String.IsNullOrEmpty(s) Then Return "?"
        Return s.Substring(0, 1).ToUpper()
    End Function

End Class


' ============================================================
' Modèles de données
' ============================================================
Public Class InvoiceData

    Public Property CompanyName As String
    Public Property CompanyTagline As String = "Cabinet de massothérapie"
    ''' <summary>Octets du logo de l'entreprise (T010Company.Logo). Si présent, remplace le monogramme.</summary>
    Public Property LogoBytes As Byte()
    Public Property CompanyAddressLine1 As String
    Public Property CompanyAddressLine2 As String
    Public Property CompanyPhone As String
    Public Property CompanyEmail As String
    Public Property CompanyTpsNumber As String
    Public Property CompanyTvqNumber As String

    Public Property InvoiceNumber As String
    Public Property IssueDate As Date
    Public Property DueDate As Date

    Public Property CustomerName As String
    Public Property CustomerAddressLine1 As String
    Public Property CustomerAddressLine2 As String
    Public Property CustomerPhone As String
    Public Property CustomerEmail As String

    Public Property Items As New List(Of InvoiceLine)

    Public Property SubTotal As Decimal
    Public Property TpsRate As Decimal = 5D
    Public Property Tps As Decimal
    Public Property TvqRate As Decimal = 9.975D
    Public Property Tvq As Decimal
    Public Property Total As Decimal

    Public Property PaymentTerms As String = "Net 30 jours. Paiement par virement Interac. Merci de votre confiance!"

    ''' <summary>
    ''' Si True, un tampon « PAYÉ » est apposé sur la 1ère page du PDF.
    ''' Mis à True par LoadInvoiceForPdf quand ResteAPayer = 0 (ou IsPaid = 1).
    ''' </summary>
    Public Property IsPaid As Boolean = False

End Class

Public Class InvoiceLine
    Public Property Description As String
    Public Property SubDescription As String
    Public Property Qty As Decimal
    Public Property UnitPrice As Decimal
    Public Property Amount As Decimal
End Class
