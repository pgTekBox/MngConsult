Public Class clsGenerateInvoicePDF

    Private m_ConnectionString As String = ""
    Public Property ConnectionString() As String
        Get
            Try

                If m_ConnectionString.Length = 0 Then
                    Dim sConnect As String = System.Configuration.ConfigurationManager.AppSettings("ConnectionString")
                    m_ConnectionString = sConnect
                End If
                Return m_ConnectionString
            Catch ex As Exception
                Return ""
            End Try

        End Get
        Set(ByVal Value As String)
            m_ConnectionString = Value
        End Set
    End Property

    Public Sub ExecuteSQL(ByVal SQLStatement As String)
        Dim oCom As New SqlClient.SqlCommand
        oCom.CommandText = SQLStatement
        oCom.Connection = New SqlClient.SqlConnection(ConnectionString)
        oCom.CommandType = CommandType.StoredProcedure
        oCom.Connection.Open()
        oCom.ExecuteNonQuery()
        oCom.Connection.Close()
    End Sub
    Public Sub ExecuteSQL(ByVal SQLStatement As String, AllParameters As Collection)
        Dim DRconn As SqlClient.SqlConnection
        DRconn = New SqlClient.SqlConnection(ConnectionString)


        Dim oCom As New SqlClient.SqlCommand
        oCom.CommandText = SQLStatement
        oCom.Connection = DRconn
        oCom.CommandType = CommandType.StoredProcedure


        For Each oParam As Data.SqlClient.SqlParameter In AllParameters
            oCom.Parameters.Add(oParam)
        Next

        oCom.Connection.Open()
        oCom.ExecuteNonQuery()
        oCom.Connection.Close()

    End Sub
    Public Function ExecuteSQLds(ByVal SQLStatement As String) As DataSet
        Dim oDa As New SqlClient.SqlDataAdapter(SQLStatement, ConnectionString)
        Dim oDs As New DataSet
        oDa.Fill(oDs)
        Return oDs
    End Function

    Public Function ExecuteSQLds(ByVal SQLStatement As String, AllParameters As Collection) As DataSet
        Dim DRconn As SqlClient.SqlConnection
        DRconn = New SqlClient.SqlConnection(ConnectionString)
        Dim MyDA As New SqlClient.SqlDataAdapter

        Dim oCom As New SqlClient.SqlCommand
        oCom.CommandText = SQLStatement
        oCom.Connection = DRconn
        oCom.CommandType = CommandType.StoredProcedure
        MyDA.SelectCommand = oCom

        For Each oParam As Data.SqlClient.SqlParameter In AllParameters
            oCom.Parameters.Add(oParam)
        Next

        Dim oDs As New DataSet
        MyDA.Fill(oDs)
        Return oDs

    End Function

    ''' <summary>Lit une colonne texte de façon sûre (colonne absente ou NULL → "").</summary>
    Private Shared Function ColStr(r As DataRow, col As String) As String
        If r Is Nothing OrElse Not r.Table.Columns.Contains(col) OrElse r.IsNull(col) Then Return ""
        Return r(col).ToString().Trim()
    End Function

    Public Sub GenerateAndDownloadPdf(invoiceId As Integer)

        ' 1. Charger les données de la facture
        Dim inv As InvoiceData = LoadInvoiceForPdf(invoiceId)
        If inv Is Nothing Then Exit Sub

        ' 2. Générer le PDF en mémoire
        Dim pdfBytes As Byte() = InvoicePdfBuilder.Build(inv)

        ' 3. Stocker dans T060Document
        Dim fileName As String = "Invoice_" & inv.InvoiceNumber & ".pdf"

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@InvoiceId", invoiceId))
        p.Add(New SqlClient.SqlParameter("@PdfData", pdfBytes))
        p.Add(New SqlClient.SqlParameter("@FileName", fileName))
        ExecuteSQL("s0116SaveInvoicePdf", p)


    End Sub
    ''' <summary>
    ''' Charge l'objet InvoiceData (entête + lignes) depuis la BD via s0115.
    ''' </summary>
    Private Function LoadInvoiceForPdf(invoiceId As Integer) As InvoiceData

        Dim p As New Collection
        p.Add(New SqlClient.SqlParameter("@InvoiceId", invoiceId))
        Dim ds As DataSet = ExecuteSQLds("s0115GetInvoiceForPdf", p)

        If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then
            Return Nothing
        End If

        Dim r As DataRow = ds.Tables(0).Rows(0)
        Dim inv As New InvoiceData()

        ' === Émetteur : infos réelles de la compagnie (paramètres T101 + logo) ===
        '   Fournies par s0115GetInvoiceForPdf (colonnes Co*). Plus rien codé en dur.
        inv.CompanyName = ColStr(r, "CoName")

        ' Nom commercial en sous-titre s'il diffère du nom légal.
        Dim coTrade As String = ColStr(r, "CoTradeName")
        inv.CompanyTagline = If(coTrade <> "" AndAlso Not coTrade.Equals(inv.CompanyName, StringComparison.OrdinalIgnoreCase), coTrade, "")

        ' Adresse : ligne 1 = rue (+ complément), ligne 2 = ville, province, code postal.
        Dim coAddr1 As String = ColStr(r, "CoAddr1")
        Dim coAddr2 As String = ColStr(r, "CoAddr2")
        inv.CompanyAddressLine1 = If(coAddr2 <> "", (coAddr1 & If(coAddr1 <> "", ", ", "") & coAddr2), coAddr1)

        Dim coL2 As New System.Text.StringBuilder()
        Dim coCity As String = ColStr(r, "CoCity")
        Dim coProv As String = ColStr(r, "CoProvince")
        Dim coPostal As String = ColStr(r, "CoPostal")
        If coCity <> "" Then coL2.Append(coCity)
        If coProv <> "" Then coL2.Append(If(coL2.Length > 0, ", ", "")).Append(coProv)
        If coPostal <> "" Then coL2.Append(If(coL2.Length > 0, " ", "")).Append(coPostal)
        inv.CompanyAddressLine2 = coL2.ToString()

        inv.CompanyPhone = ColStr(r, "CoPhone")
        inv.CompanyEmail = ColStr(r, "CoEmail")

        ' Numéros de taxe : TPS (ou TVH si pas de TPS) et TVQ.
        Dim coGst As String = ColStr(r, "CoGstNo")
        Dim coHst As String = ColStr(r, "CoHstNo")
        inv.CompanyTpsNumber = If(coGst <> "", coGst, coHst)
        inv.CompanyTvqNumber = ColStr(r, "CoQstNo")

        ' Bas de facture : conditions de paiement + notes (paramètres PDF).
        inv.PaymentTerms = ColStr(r, "CoPaymentTerms")
        inv.Notes = ColStr(r, "CoNotes")

        ' Logo de la compagnie (T010Company.Logo).
        If r.Table.Columns.Contains("CoLogo") AndAlso Not r.IsNull("CoLogo") Then
            inv.LogoBytes = CType(r("CoLogo"), Byte())
        End If

        ' === Facture ===
        inv.InvoiceNumber = If(r("DocumentNumber") Is DBNull.Value, invoiceId.ToString(), r("DocumentNumber").ToString())
        inv.IssueDate = If(r("DocumentDate") Is DBNull.Value, Date.Now.Date, CDate(r("DocumentDate")))
        inv.DueDate = If(r("DueDate") Is DBNull.Value, inv.IssueDate.AddDays(30), CDate(r("DueDate")))

        ' === Client (depuis les colonnes copiées dans T060Document) ===
        inv.CustomerName = If(r("Name") Is DBNull.Value, "", r("Name").ToString())
        inv.CustomerAddressLine1 = If(r("Address1") Is DBNull.Value, "", r("Address1").ToString())

        Dim line2 As New System.Text.StringBuilder()
        If Not (r("City") Is DBNull.Value) Then line2.Append(r("City").ToString())
        If Not (r("State") Is DBNull.Value) Then line2.Append(", ").Append(r("State").ToString())
        If Not (r("PostalCode") Is DBNull.Value) Then line2.Append(" ").Append(r("PostalCode").ToString())
        inv.CustomerAddressLine2 = line2.ToString()

        inv.CustomerPhone = If(r("Phone") Is DBNull.Value, "", r("Phone").ToString())
        inv.CustomerEmail = If(r("Email") Is DBNull.Value, "", r("Email").ToString())

        ' === Totaux ===
        inv.SubTotal = If(r("SubTotal") Is DBNull.Value, 0D, CDec(r("SubTotal")))
        inv.Tps = If(r("TPS") Is DBNull.Value, 0D, CDec(r("TPS")))
        inv.Tvq = If(r("TVQ") Is DBNull.Value, 0D, CDec(r("TVQ")))
        inv.Total = If(r("Total") Is DBNull.Value, 0D, CDec(r("Total")))

        ' === État de paiement ===
        '   Apposera le tampon « PAYÉ » sur le PDF si la facture est totalement réglée.
        '   Rétrocompatible : si la proc s0115 ne retourne ni ResteAPayer ni IsPaid,
        '   IsPaid reste False et aucun tampon n'est dessiné.
        If ds.Tables(0).Columns.Contains("ResteAPayer") Then
            Dim reste As Decimal = If(r("ResteAPayer") Is DBNull.Value, inv.Total, CDec(r("ResteAPayer")))
            inv.IsPaid = (reste <= 0D AndAlso inv.Total > 0D)
        ElseIf ds.Tables(0).Columns.Contains("IsPaid") Then
            inv.IsPaid = If(r("IsPaid") Is DBNull.Value, False, CBool(r("IsPaid")))
        End If

        ' === Lignes (table 2 du DataSet) ===
        If ds.Tables.Count >= 2 Then
            For Each rl As DataRow In ds.Tables(1).Rows
                inv.Items.Add(New InvoiceLine With {
                    .Description = If(rl("ProductName") Is DBNull.Value OrElse rl("ProductName").ToString() = "",
                                       If(rl("Description") Is DBNull.Value, "", rl("Description").ToString()),
                                       rl("ProductName").ToString()),
                    .SubDescription = If(rl("Description") Is DBNull.Value, "", rl("Description").ToString()),
                    .Qty = If(rl("Qty") Is DBNull.Value, 1D, CDec(rl("Qty"))),
                    .UnitPrice = If(rl("UnitPrice") Is DBNull.Value, 0D, CDec(rl("UnitPrice"))),
                    .Amount = If(rl("Amount") Is DBNull.Value, 0D, CDec(rl("Amount")))
                })
            Next
        End If

        Return inv
    End Function


End Class
