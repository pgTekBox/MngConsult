Imports System.Data
Imports System.Globalization
Imports System.Linq
Imports QuestPDF.Fluent
Imports QuestPDF.Helpers
Imports QuestPDF.Infrastructure

''' <summary>
''' Le reçu PDF d'un encaissement (Ventes › Encaissements › Imprimer), script T369.
''' Même allure que la facture (InvoicePdfBuilder) : en-tête avec logo, trois
''' cartes (date, mode, montant reçu), « reçu par » / « reçu de », puis le
''' détail des factures payées (total, montant appliqué, solde restant).
''' Les données viennent de s0988GetEncaissementPdf ; textes en fr/en/es.
''' </summary>
Public Class EncaissementPdfBuilder

    Private Const CLR_PRIMARY As String = "#2563eb"
    Private Const CLR_TEXT As String = "#0f172a"
    Private Const CLR_TEXT_MUTED As String = "#64748b"
    Private Const CLR_TEXT_LIGHT As String = "#475569"
    Private Const CLR_BG_LIGHT As String = "#f8fafc"
    Private Const CLR_BG_ACCENT As String = "#eff6ff"
    Private Const CLR_LINE As String = "#e2e8f0"
    Private Const CLR_LINE_DARK As String = "#cbd5e1"
    Private Const CLR_NOTE_BG As String = "#ecfeff"
    Private Const CLR_NOTE_TEXT As String = "#0e7490"
    Private Const CLR_WHITE As String = "#ffffff"

    Private ReadOnly _h As DataRow
    Private ReadOnly _lignes As DataTable
    Private ReadOnly _lang As String
    Private ReadOnly _ci As CultureInfo

    Private Sub New(h As DataRow, lignes As DataTable, lang As String)
        _h = h
        _lignes = lignes
        _lang = If(lang = "en" OrElse lang = "es", lang, "fr")
        _ci = CultureInfo.GetCultureInfo(If(_lang = "en", "en-CA", If(_lang = "es", "es-ES", "fr-CA")))
    End Sub

    ''' <summary>Le PDF du reçu, à partir des deux jeux de s0988.</summary>
    Public Shared Function Build(ds As DataSet, lang As String) As Byte()
        Dim b As New EncaissementPdfBuilder(ds.Tables(0).Rows(0), If(ds.Tables.Count > 1, ds.Tables(1), Nothing), lang)
        Return b.Generer()
    End Function

    ''' <summary>Le numéro affiché du reçu : ENC-000053 (DEC- pour un paiement fournisseur).</summary>
    Public Shared Function Numero(h As DataRow) As String
        Dim prefixe As String = If(Convert.ToString(h("Sens")) = "ENCAISSEMENT", "ENC-", "DEC-")
        Return prefixe & Convert.ToInt32(h("Id")).ToString("000000")
    End Function

    Private Function Generer() As Byte()
        Return Document.Create(
            Sub(container)
                container.Page(
                    Sub(page)
                        page.Size(PageSizes.Letter)
                        page.Margin(40)
                        page.PageColor(CLR_WHITE)
                        page.DefaultTextStyle(Function(x) x.FontSize(10).FontFamily("Arial").FontColor(CLR_TEXT))
                        page.Content().Element(AddressOf Corps)
                        page.Footer().Element(AddressOf Pied)
                    End Sub)
            End Sub).GeneratePdf()
    End Function

    ' ------------------------------------------------------------------
    Private Function S(col As String) As String
        If _h Is Nothing OrElse Not _h.Table.Columns.Contains(col) OrElse IsDBNull(_h(col)) Then Return ""
        Return Convert.ToString(_h(col)).Trim()
    End Function

    Private Function Argent(v As Decimal) As String
        Return v.ToString("C", _ci)
    End Function

    Private Function Jour(o As Object) As String
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return Convert.ToDateTime(o).ToString("d MMMM yyyy", _ci)
    End Function

    Private Function T(fr As String, en As String, es As String) As String
        Return If(_lang = "en", en, If(_lang = "es", es, fr))
    End Function

    Private ReadOnly Property EstEncaissement As Boolean
        Get
            Return S("Sens") = "ENCAISSEMENT"
        End Get
    End Property

    Private Function TypeLibelle() As String
        Select Case S("TypeReglement").ToUpperInvariant()
            Case "CHEQUE" : Return T("Chèque", "Cheque", "Cheque")
            Case "COMPTANT", "CASH" : Return T("Comptant", "Cash", "Efectivo")
            Case "VIREMENT" : Return T("Virement", "Transfer", "Transferencia")
            Case "INTERAC" : Return T("Virement Interac", "Interac transfer", "Transferencia Interac")
            Case "CARTE", "CARD" : Return T("Carte", "Card", "Tarjeta")
            Case "" : Return T("Paiement", "Payment", "Pago")
            Case Else : Return S("TypeReglement")
        End Select
    End Function

    ' ------------------------------------------------------------------
    Private Sub Corps(container As IContainer)
        container.Column(
            Sub(col)
                col.Spacing(14)
                Entete(col)
                Cartes(col)
                Parties(col)
                Detail(col)
                Totaux(col)
                Banque(col)
            End Sub)
    End Sub

    Private Sub Entete(col As ColumnDescriptor)
        Dim logo As Byte() = If(_h.Table.Columns.Contains("CoLogo") AndAlso Not IsDBNull(_h("CoLogo")), CType(_h("CoLogo"), Byte()), Nothing)
        Dim nom As String = S("CoName")
        Dim commercial As String = S("CoTradeName")
        col.Item().BorderBottom(3).BorderColor(CLR_PRIMARY).PaddingBottom(15).Row(
            Sub(row)
                row.RelativeItem().Row(
                    Sub(marque)
                        If logo IsNot Nothing AndAlso logo.Length > 0 Then
                            marque.AutoItem().Width(50).Height(50).AlignCenter().AlignMiddle().Image(logo).FitArea()
                        Else
                            marque.AutoItem().Width(50).Height(50).Background(CLR_PRIMARY).AlignCenter().AlignMiddle().
                                Text(If(nom = "", "?", nom.Substring(0, 1).ToUpper())).FontSize(24).FontColor(CLR_WHITE).Bold()
                        End If
                        marque.ConstantItem(12)
                        marque.RelativeItem().AlignMiddle().Column(
                            Sub(c)
                                c.Item().Text(nom).FontSize(16).Bold()
                                If commercial <> "" AndAlso Not commercial.Equals(nom, StringComparison.OrdinalIgnoreCase) Then
                                    c.Item().Text(commercial).FontSize(10).FontColor(CLR_TEXT_MUTED)
                                End If
                            End Sub)
                    End Sub)
                row.AutoItem().AlignRight().Column(
                    Sub(c)
                        c.Item().AlignRight().Text(If(EstEncaissement, T("REÇU DE PAIEMENT", "PAYMENT RECEIPT", "RECIBO DE PAGO"),
                                                                     T("AVIS DE PAIEMENT", "PAYMENT ADVICE", "AVISO DE PAGO"))).
                            FontSize(24).Bold().FontColor(CLR_PRIMARY)
                        c.Item().AlignRight().Text(T("N° ", "No. ", "N.º ") & Numero(_h)).FontSize(11).FontColor(CLR_TEXT_MUTED)
                        ' Un paiement annulé (s0992) : le reçu le dit, en rouge.
                        If S("Statut") = "ANNULE" Then
                            c.Item().AlignRight().PaddingTop(4).Border(1.5F).BorderColor("#dc2626").PaddingVertical(2).PaddingHorizontal(8).
                                Text(T("ANNULÉ", "CANCELLED", "ANULADO")).FontSize(12).Bold().FontColor("#dc2626")
                        End If
                    End Sub)
            End Sub)
    End Sub

    Private Sub Cartes(col As ColumnDescriptor)
        Dim mode As String = TypeLibelle() & If(S("Reference") <> "", " · " & S("Reference"), "")
        col.Item().Row(
            Sub(row)
                row.Spacing(10)
                row.RelativeItem().Element(Sub(c) Carte(c, T("DATE DU PAIEMENT", "PAYMENT DATE", "FECHA DEL PAGO"), Jour(_h("DateReglement")), False))
                row.RelativeItem().Element(Sub(c) Carte(c, T("MODE ET RÉFÉRENCE", "METHOD AND REFERENCE", "MÉTODO Y REFERENCIA"), mode, False))
                row.RelativeItem().Element(Sub(c) Carte(c, If(EstEncaissement, T("MONTANT REÇU", "AMOUNT RECEIVED", "IMPORTE RECIBIDO"),
                                                                                T("MONTANT PAYÉ", "AMOUNT PAID", "IMPORTE PAGADO")),
                                                         Argent(Convert.ToDecimal(_h("Montant"))), True))
            End Sub)
    End Sub

    Private Shared Sub Carte(container As IContainer, label As String, valeur As String, accent As Boolean)
        container.Background(If(accent, CLR_BG_ACCENT, CLR_WHITE)).Border(0.5F).BorderColor(CLR_LINE).Padding(12).Column(
            Sub(c)
                c.Item().Text(label).FontSize(9).FontColor(CLR_TEXT_MUTED).Bold()
                c.Item().PaddingTop(3).Text(valeur).FontSize(13).Bold().FontColor(If(accent, CLR_PRIMARY, CLR_TEXT))
            End Sub)
    End Sub

    Private Sub Parties(col As ColumnDescriptor)
        Dim coL2 As String = String.Join(" ", {String.Join(", ", {S("CoCity"), S("CoProvince")}.Where(Function(x) x <> "")), S("CoPostal")}.Where(Function(x) x <> ""))
        Dim clL2 As String = String.Join(" ", {S("ClientCity"), S("ClientPostal")}.Where(Function(x) x <> ""))
        Dim compagnie As String() = {S("CoName"), String.Join(", ", {S("CoAddr1"), S("CoAddr2")}.Where(Function(x) x <> "")), coL2, S("CoPhone"), S("CoEmail")}
        Dim client As String() = {If(S("ClientNom") = "", T("(sans client)", "(no customer)", "(sin cliente)"), S("ClientNom")),
                                  String.Join(", ", {S("ClientAddr1"), S("ClientAddr2")}.Where(Function(x) x <> "")), clL2, S("ClientPhone"), S("ClientEmail")}
        Dim titreCo As String = If(EstEncaissement, T("REÇU PAR", "RECEIVED BY", "RECIBIDO POR"), T("PAYÉ PAR", "PAID BY", "PAGADO POR"))
        Dim titreCl As String = If(EstEncaissement, T("REÇU DE", "RECEIVED FROM", "RECIBIDO DE"), T("PAYÉ À", "PAID TO", "PAGADO A"))
        col.Item().Row(
            Sub(row)
                row.Spacing(15)
                row.RelativeItem().Element(Sub(c) Bloc(c, titreCo, compagnie))
                row.RelativeItem().Element(Sub(c) Bloc(c, titreCl, client))
            End Sub)
    End Sub

    Private Shared Sub Bloc(container As IContainer, titre As String, lignes As String())
        container.Background(CLR_BG_LIGHT).Padding(14).Column(
            Sub(c)
                c.Item().Text(titre).FontSize(9).FontColor(CLR_TEXT_MUTED).Bold()
                c.Item().PaddingTop(4).Text(lignes(0)).FontSize(13).Bold()
                For i As Integer = 1 To lignes.Length - 1
                    If Not String.IsNullOrWhiteSpace(lignes(i)) Then c.Item().Text(lignes(i)).FontSize(10).FontColor(CLR_TEXT_LIGHT)
                Next
            End Sub)
    End Sub

    Private Sub Detail(col As ColumnDescriptor)
        col.Item().Text(T("Détail des factures payées", "Details of the invoices paid", "Detalle de las facturas pagadas")).FontSize(12).Bold()
        If _lignes Is Nothing OrElse _lignes.Rows.Count = 0 Then
            col.Item().Text(T("Ce paiement n'est appliqué à aucune facture.", "This payment is not applied to any invoice.", "Este pago no se aplica a ninguna factura.")).FontColor(CLR_TEXT_MUTED)
            Return
        End If
        col.Item().Table(
            Sub(table)
                table.ColumnsDefinition(
                    Sub(cols)
                        cols.RelativeColumn(2.2F)   ' Facture
                        cols.RelativeColumn(2)      ' Date
                        cols.RelativeColumn(2)      ' Total
                        cols.RelativeColumn(2)      ' Appliqué
                        cols.RelativeColumn(2)      ' Solde
                    End Sub)
                table.Header(
                    Sub(hd)
                        TeteCellule(hd.Cell(), T("FACTURE", "INVOICE", "FACTURA"), False)
                        TeteCellule(hd.Cell(), T("DATE", "DATE", "FECHA"), False)
                        TeteCellule(hd.Cell(), T("TOTAL", "TOTAL", "TOTAL"), True)
                        TeteCellule(hd.Cell(), T("APPLIQUÉ", "APPLIED", "APLICADO"), True)
                        TeteCellule(hd.Cell(), T("SOLDE RESTANT", "BALANCE DUE", "SALDO PENDIENTE"), True)
                    End Sub)
                Dim i As Integer = 0
                For Each r As DataRow In _lignes.Rows
                    Dim bg As String = If(i Mod 2 = 0, CLR_WHITE, CLR_BG_LIGHT)
                    Dim solde As Decimal = Convert.ToDecimal(r("SoldeActuel"))
                    table.Cell().Background(bg).Padding(9).Text(Convert.ToString(r("DocumentNumber"))).Bold()
                    table.Cell().Background(bg).Padding(9).Text(Jour(r("DocumentDate")))
                    table.Cell().Background(bg).Padding(9).AlignRight().Text(Argent(Convert.ToDecimal(r("Total"))))
                    table.Cell().Background(bg).Padding(9).AlignRight().Text(Argent(Convert.ToDecimal(r("MontantImpute")))).Bold()
                    table.Cell().Background(bg).Padding(9).AlignRight().Text(
                        If(solde <= 0.005D, T("Payée", "Paid", "Pagada"), Argent(solde)))
                    i += 1
                Next
            End Sub)
    End Sub

    Private Shared Sub TeteCellule(cell As IContainer, texte As String, droite As Boolean)
        Dim c As IContainer = cell.Background(CLR_PRIMARY).Padding(9)
        If droite Then c = c.AlignRight()
        c.Text(texte).FontSize(9).Bold().FontColor(CLR_WHITE)
    End Sub

    Private Sub Totaux(col As ColumnDescriptor)
        Dim montant As Decimal = Convert.ToDecimal(_h("Montant"))
        Dim applique As Decimal = 0D
        If _lignes IsNot Nothing Then
            For Each r As DataRow In _lignes.Rows
                applique += Convert.ToDecimal(r("MontantImpute"))
            Next
        End If
        Dim nonApplique As Decimal = montant - applique
        col.Item().AlignRight().Width(290).Background(CLR_BG_LIGHT).Padding(14).Column(
            Sub(c)
                LigneTotal(c, T("Appliqué aux factures", "Applied to invoices", "Aplicado a las facturas"), applique)
                If Math.Abs(nonApplique) >= 0.005D Then
                    LigneTotal(c, T("Non appliqué", "Unapplied", "No aplicado"), nonApplique)
                End If
                c.Item().PaddingVertical(6).LineHorizontal(0.5F).LineColor(CLR_LINE_DARK)
                c.Item().Background(CLR_PRIMARY).Padding(10).Row(
                    Sub(row)
                        row.RelativeItem().Text(If(EstEncaissement, T("TOTAL REÇU", "TOTAL RECEIVED", "TOTAL RECIBIDO"),
                                                                    T("TOTAL PAYÉ", "TOTAL PAID", "TOTAL PAGADO"))).FontSize(11).Bold().FontColor(CLR_WHITE)
                        row.AutoItem().Text(Argent(montant)).FontSize(15).Bold().FontColor(CLR_WHITE)
                    End Sub)
            End Sub)
    End Sub

    Private Sub LigneTotal(c As ColumnDescriptor, libelle As String, valeur As Decimal)
        c.Item().PaddingVertical(2).Row(
            Sub(row)
                row.RelativeItem().Text(libelle).FontSize(11).FontColor(CLR_TEXT_LIGHT)
                row.AutoItem().Text(Argent(valeur)).FontSize(11).Bold()
            End Sub)
    End Sub

    Private Sub Banque(col As ColumnDescriptor)
        Dim compte As String = Trim(S("CompteBanque") & " " & S("NomCompteBanque"))
        Dim texte As String = ""
        If compte <> "" Then texte = If(EstEncaissement, T("Déposé au compte : ", "Deposited to account: ", "Depositado en la cuenta: "),
                                                         T("Payé du compte : ", "Paid from account: ", "Pagado desde la cuenta: ")) & compte
        If S("ReleveDescription") <> "" Then
            texte &= If(texte <> "", vbLf, "") & T("Rapproché avec le relevé bancaire du ", "Matched with the bank statement of ", "Conciliado con el extracto bancario del ") &
                     Jour(_h("ReleveDate")) & " — " & S("ReleveDescription")
        End If
        If texte = "" Then Return
        col.Item().BorderLeft(3).BorderColor("#06b6d4").Background(CLR_NOTE_BG).Padding(10).
            Text(texte).FontSize(10).FontColor(CLR_NOTE_TEXT)
    End Sub

    Private Sub Pied(container As IContainer)
        Dim nom As String = S("CoName")
        Dim courriel As String = S("CoEmail")
        Dim emis As String = T("Émis le ", "Issued on ", "Emitido el ") & Date.Today.ToString("d MMMM yyyy", _ci)
        container.BorderTop(0.5F).BorderColor(CLR_LINE).PaddingTop(10).AlignCenter().Text(
            Sub(text)
                text.DefaultTextStyle(Function(x) x.FontSize(9).FontColor(CLR_TEXT_MUTED))
                text.Span(nom)
                If courriel <> "" Then text.Span(" — " & courriel)
                text.Span(" — " & emis & " — Page ")
                text.CurrentPageNumber()
                text.Span(" / ")
                text.TotalPages()
            End Sub)
    End Sub

End Class
