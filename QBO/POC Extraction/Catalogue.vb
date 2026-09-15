Imports System.Globalization

''' <summary>Une colonne du CSV : un chemin dans l'objet QuickBooks, ou un calcul.</summary>
Public Class Colonne
    Public ReadOnly Property Titre As String
    Private ReadOnly _chemin As String
    Private ReadOnly _calcul As Func(Of JsonNode, String)

    Public Sub New(titre As String, chemin As String)
        Me.Titre = titre
        _chemin = chemin
    End Sub

    Public Sub New(titre As String, calcul As Func(Of JsonNode, String))
        Me.Titre = titre
        _calcul = calcul
    End Sub

    Public Function Lire(noeud As JsonNode) As String
        If _calcul IsNot Nothing Then Return _calcul(noeud)
        Return JsonChemin.Valeur(noeud, _chemin)
    End Function
End Class

''' <summary>
''' Une extraction = un bouton. Elle vise une entité de l'API (requête) ou un
''' rapport, et produit un fichier — deux quand l'entité a des lignes : l'entête
''' (Factures.csv) et le détail (Factures_Lignes.csv).
''' </summary>
Public Class Extraction
    Public Property Categorie As String
    Public Property Libelle As String
    Public Property Fichier As String

    ''' <summary>Nom de l'entité à interroger (Invoice, Customer…). Vide pour un rapport.</summary>
    Public Property Entite As String = ""

    ''' <summary>Inclure les éléments inactifs (listes : clients, comptes, produits…).</summary>
    Public Property ActifsEtInactifs As Boolean

    ''' <summary>Transaction datée : filtrable par la date de début.</summary>
    Public Property Datee As Boolean

    Public Property Colonnes As List(Of Colonne)

    ''' <summary>Les colonnes du fichier de lignes ; Nothing si l'entité n'en a pas.</summary>
    Public Property ColonnesLignes As List(Of Colonne)

    ''' <summary>Nom du rapport (TrialBalance…) ; vide pour une entité.</summary>
    Public Property Rapport As String = ""
    Public Property ParametresRapport As Func(Of OptionsExtraction, Dictionary(Of String, String))

    Public ReadOnly Property Fichiers As String
        Get
            If Rapport <> "" Then Return Fichier & "_<date>.csv"
            Return Fichier & ".csv" & If(ColonnesLignes IsNot Nothing, " + " & Fichier & "_Lignes.csv", "")
        End Get
    End Property
End Class

''' <summary>
''' Tout ce que l'application sait extraire, et comment chaque fichier est fait.
'''
''' Les en-têtes de colonnes sont les chemins de l'API QuickBooks (BillAddr.City,
''' CustomerRef.name) : ils ne dépendent ni de la langue de QuickBooks ni de
''' celle du poste, et se retrouvent tels quels dans la documentation d'Intuit.
''' Les numéros d'assurance sociale des employés ne sont volontairement pas extraits.
''' </summary>
Public Module Catalogue

    Public Const CatReferentiels As String = "Référentiels"
    Public Const CatVentes As String = "Ventes"
    Public Const CatAchats As String = "Achats"
    Public Const CatBanque As String = "Banque et journal"
    Public Const CatRapports As String = "Rapports"

    Public ReadOnly Property Categories As String() = {CatReferentiels, CatVentes, CatAchats, CatBanque, CatRapports}

#Region "Outils de définition"

    ''' <summary>
    ''' Bâtit une liste de colonnes à partir de chemins. Jetons spéciaux :
    '''   @Chemin     une adresse complète (Line1 à Country)
    '''   =Taxes      le détail des taxes de la transaction
    '''   =Liens      les transactions liées (TxnType:TxnId)
    '''   =ChampsPerso les champs personnalisés (Nom=Valeur)
    ''' </summary>
    Private Function Cols(ParamArray chemins As String()) As List(Of Colonne)
        Dim l As New List(Of Colonne)
        For Each c In chemins
            If c.StartsWith("@") Then
                Dim p = c.Substring(1)
                For Each champ In {"Line1", "Line2", "Line3", "Line4", "City", "CountrySubDivisionCode", "PostalCode", "Country"}
                    l.Add(New Colonne(p & "." & champ, p & "." & champ))
                Next
            ElseIf c = "=Taxes" Then
                l.Add(New Colonne("TxnTaxDetail.TaxLine", AddressOf DetailTaxes))
            ElseIf c = "=Liens" Then
                l.Add(New Colonne("LinkedTxn", Function(n) Paires(JsonChemin.Enfant(n, "LinkedTxn"), "TxnType", "TxnId")))
            ElseIf c = "=ChampsPerso" Then
                l.Add(New Colonne("CustomField", Function(n) Paires(JsonChemin.Enfant(n, "CustomField"), "Name", "StringValue")))
            Else
                l.Add(New Colonne(c, c))
            End If
        Next
        Return l
    End Function

    Private Function Plus(a As List(Of Colonne), b As List(Of Colonne)) As List(Of Colonne)
        Return a.Concat(b).ToList()
    End Function

    Private Function Paires(tableau As JsonNode, cle As String, valeur As String) As String
        Dim t = TryCast(tableau, JsonArray)
        If t Is Nothing Then Return ""
        Return String.Join(" | ", t.Select(Function(e) JsonChemin.Valeur(e, cle) & ":" & JsonChemin.Valeur(e, valeur)) _
                                   .Where(Function(s) s <> ":"))
    End Function

    ''' <summary>« TaxRateRef=3 Pct=5 Base=100.00 Montant=5.00 | … » — une entrée par taux.</summary>
    Private Function DetailTaxes(n As JsonNode) As String
        Dim lignes = TryCast(JsonChemin.Enfant(JsonChemin.Enfant(n, "TxnTaxDetail"), "TaxLine"), JsonArray)
        If lignes Is Nothing Then Return ""
        Return String.Join(" | ", lignes.Select(Function(t)
                                                     Return "TaxRateRef=" & JsonChemin.Valeur(t, "TaxLineDetail.TaxRateRef.value") &
                                                            " Pct=" & JsonChemin.Valeur(t, "TaxLineDetail.TaxPercent") &
                                                            " Base=" & JsonChemin.Valeur(t, "TaxLineDetail.NetAmountTaxable") &
                                                            " Montant=" & JsonChemin.Valeur(t, "Amount")
                                                 End Function))
    End Function

    Private Function Iso(d As Date) As String
        Return d.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
    End Function

    Private Function Periode(o As OptionsExtraction) As Dictionary(Of String, String)
        Return New Dictionary(Of String, String) From {
            {"start_date", Iso(o.DateDebut)}, {"end_date", Iso(o.DateBascule)}, {"accounting_method", o.MethodeComptable}}
    End Function

    Private Function Echeancier(o As OptionsExtraction) As Dictionary(Of String, String)
        Return New Dictionary(Of String, String) From {
            {"report_date", Iso(o.DateBascule)}, {"aging_method", "Report_Date"}, {"accounting_method", o.MethodeComptable}}
    End Function

#End Region

#Region "Colonnes communes"

    ''' <summary>L'entête commune à toute transaction.</summary>
    Private Function EnteteTxn() As List(Of Colonne)
        Return Cols("Id", "DocNumber", "TxnDate", "CurrencyRef.value", "ExchangeRate", "PrivateNote",
                    "DepartmentRef.value", "DepartmentRef.name", "ClassRef.value", "ClassRef.name")
    End Function

    Private Function Suivi() As List(Of Colonne)
        Return Cols("MetaData.CreateTime", "MetaData.LastUpdatedTime")
    End Function

    ''' <summary>Les lignes des documents de vente : factures, notes de crédit, reçus, soumissions.</summary>
    Private Function LignesVente() As List(Of Colonne)
        Return Cols("Id", "LineNum", "DetailType", "Description", "Amount",
                    "SalesItemLineDetail.ItemRef.value", "SalesItemLineDetail.ItemRef.name",
                    "SalesItemLineDetail.Qty", "SalesItemLineDetail.UnitPrice",
                    "SalesItemLineDetail.TaxCodeRef.value", "SalesItemLineDetail.ServiceDate",
                    "SalesItemLineDetail.ItemAccountRef.value", "SalesItemLineDetail.ItemAccountRef.name",
                    "SalesItemLineDetail.ClassRef.name", "SalesItemLineDetail.DiscountRate", "SalesItemLineDetail.DiscountAmt",
                    "DiscountLineDetail.PercentBased", "DiscountLineDetail.DiscountPercent",
                    "DiscountLineDetail.DiscountAccountRef.value", "DiscountLineDetail.DiscountAccountRef.name",
                    "GroupLineDetail.GroupItemRef.value", "GroupLineDetail.GroupItemRef.name", "GroupLineDetail.Quantity")
    End Function

    ''' <summary>Les lignes des documents d'achat : factures fournisseurs, dépenses, crédits, bons de commande.</summary>
    Private Function LignesAchat() As List(Of Colonne)
        Return Cols("Id", "LineNum", "DetailType", "Description", "Amount",
                    "AccountBasedExpenseLineDetail.AccountRef.value", "AccountBasedExpenseLineDetail.AccountRef.name",
                    "AccountBasedExpenseLineDetail.TaxCodeRef.value", "AccountBasedExpenseLineDetail.TaxAmount",
                    "AccountBasedExpenseLineDetail.BillableStatus",
                    "AccountBasedExpenseLineDetail.CustomerRef.value", "AccountBasedExpenseLineDetail.CustomerRef.name",
                    "AccountBasedExpenseLineDetail.ClassRef.name",
                    "ItemBasedExpenseLineDetail.ItemRef.value", "ItemBasedExpenseLineDetail.ItemRef.name",
                    "ItemBasedExpenseLineDetail.Qty", "ItemBasedExpenseLineDetail.UnitPrice",
                    "ItemBasedExpenseLineDetail.TaxCodeRef.value", "ItemBasedExpenseLineDetail.BillableStatus",
                    "ItemBasedExpenseLineDetail.CustomerRef.value", "ItemBasedExpenseLineDetail.CustomerRef.name",
                    "ItemBasedExpenseLineDetail.ClassRef.name")
    End Function

    ''' <summary>Les lignes d'un paiement : la transaction réglée et le montant qui lui est appliqué.</summary>
    Private Function LignesReglement() As List(Of Colonne)
        Return Plus(Cols("Amount", "LinkedTxn.TxnType", "LinkedTxn.TxnId"), Cols("=Liens"))
    End Function

#End Region

#Region "Le catalogue"

    Public Function Toutes() As List(Of Extraction)
        Return New List(Of Extraction) From {
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Entreprise", .Fichier = "Entreprise", .Entite = "CompanyInfo",
                .Colonnes = Plus(Cols("Id", "CompanyName", "LegalName", "@CompanyAddr", "@LegalAddr", "Email.Address",
                                      "PrimaryPhone.FreeFormNumber", "WebAddr.URI", "Country", "FiscalYearStartMonth",
                                      "CompanyStartDate", "SupportedLanguages"),
                                 {New Colonne("NameValue", Function(n) Paires(JsonChemin.Enfant(n, "NameValue"), "Name", "Value"))}.ToList())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Plan comptable", .Fichier = "PlanComptable", .Entite = "Account",
                .ActifsEtInactifs = True,
                .Colonnes = Cols("Id", "AcctNum", "Name", "FullyQualifiedName", "SubAccount", "ParentRef.value",
                                 "AccountType", "AccountSubType", "Classification", "Description",
                                 "CurrentBalance", "CurrentBalanceWithSubAccounts", "CurrencyRef.value",
                                 "TaxCodeRef.value", "Active", "MetaData.CreateTime")
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Clients", .Fichier = "Clients", .Entite = "Customer",
                .ActifsEtInactifs = True,
                .Colonnes = Plus(Cols("Id", "DisplayName", "CompanyName", "Title", "GivenName", "MiddleName", "FamilyName",
                                      "PrintOnCheckName", "PrimaryEmailAddr.Address", "PrimaryPhone.FreeFormNumber",
                                      "Mobile.FreeFormNumber", "AlternatePhone.FreeFormNumber", "Fax.FreeFormNumber",
                                      "WebAddr.URI", "@BillAddr", "@ShipAddr",
                                      "Job", "ParentRef.value", "ParentRef.name", "Level",
                                      "SalesTermRef.value", "PaymentMethodRef.value", "PreferredDeliveryMethod",
                                      "Taxable", "DefaultTaxCodeRef.value", "TaxExemptionReasonId", "ResaleNum",
                                      "BusinessNumber", "GSTRegistrationType", "PrimaryTaxIdentifier",
                                      "Balance", "BalanceWithJobs", "OpenBalanceDate", "CurrencyRef.value",
                                      "Notes", "Active"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Fournisseurs", .Fichier = "Fournisseurs", .Entite = "Vendor",
                .ActifsEtInactifs = True,
                .Colonnes = Plus(Cols("Id", "DisplayName", "CompanyName", "Title", "GivenName", "FamilyName",
                                      "PrintOnCheckName", "PrimaryEmailAddr.Address", "PrimaryPhone.FreeFormNumber",
                                      "Mobile.FreeFormNumber", "Fax.FreeFormNumber", "WebAddr.URI", "@BillAddr",
                                      "AcctNum", "BusinessNumber", "GSTRegistrationType", "TaxIdentifier",
                                      "TermRef.value", "APAccountRef.value", "Vendor1099", "T4AEligible", "T5018Eligible",
                                      "BillRate", "Balance", "CurrencyRef.value", "Active"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Produits et services", .Fichier = "ProduitsServices", .Entite = "Item",
                .ActifsEtInactifs = True,
                .Colonnes = Plus(Cols("Id", "Name", "FullyQualifiedName", "Sku", "Type", "Description", "PurchaseDesc",
                                      "UnitPrice", "PurchaseCost",
                                      "IncomeAccountRef.value", "IncomeAccountRef.name",
                                      "ExpenseAccountRef.value", "ExpenseAccountRef.name",
                                      "AssetAccountRef.value", "AssetAccountRef.name",
                                      "Taxable", "SalesTaxIncluded", "PurchaseTaxIncluded",
                                      "SalesTaxCodeRef.value", "PurchaseTaxCodeRef.value",
                                      "TrackQtyOnHand", "QtyOnHand", "ReorderPoint", "InvStartDate",
                                      "SubItem", "ParentRef.value", "ParentRef.name", "Level",
                                      "PrefVendorRef.value", "PrefVendorRef.name", "Active"), Suivi())
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Employés", .Fichier = "Employes", .Entite = "Employee",
                .ActifsEtInactifs = True,
                .Colonnes = Cols("Id", "DisplayName", "Title", "GivenName", "FamilyName", "PrimaryEmailAddr.Address",
                                 "PrimaryPhone.FreeFormNumber", "Mobile.FreeFormNumber", "@PrimaryAddr",
                                 "EmployeeNumber", "HiredDate", "ReleasedDate", "BillableTime", "BillRate", "CostRate", "Active")
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Codes de taxe", .Fichier = "CodesTaxe", .Entite = "TaxCode",
                .Colonnes = Cols("Id", "Name", "Description", "Taxable", "TaxGroup", "Active",
                                 "SalesTaxRateList.TaxRateDetail.TaxRateRef.value", "SalesTaxRateList.TaxRateDetail.TaxRateRef.name",
                                 "PurchaseTaxRateList.TaxRateDetail.TaxRateRef.value", "PurchaseTaxRateList.TaxRateDetail.TaxRateRef.name")
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Taux de taxe", .Fichier = "TauxTaxe", .Entite = "TaxRate",
                .Colonnes = Cols("Id", "Name", "Description", "RateValue", "AgencyRef.value", "SpecialTaxType",
                                 "DisplayType", "EffectiveTaxRate.RateValue", "EffectiveTaxRate.EffectiveDate",
                                 "EffectiveTaxRate.EndDate", "Active")
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Modalités de paiement", .Fichier = "Modalites", .Entite = "Term",
                .ActifsEtInactifs = True,
                .Colonnes = Cols("Id", "Name", "Type", "DueDays", "DiscountDays", "DiscountPercent", "DayOfMonthDue", "Active")
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Modes de paiement", .Fichier = "ModesPaiement", .Entite = "PaymentMethod",
                .ActifsEtInactifs = True,
                .Colonnes = Cols("Id", "Name", "Type", "Active")
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Classes", .Fichier = "Classes", .Entite = "Class",
                .ActifsEtInactifs = True,
                .Colonnes = Cols("Id", "Name", "FullyQualifiedName", "SubClass", "ParentRef.value", "Active")
            },
            New Extraction With {
                .Categorie = CatReferentiels, .Libelle = "Emplacements", .Fichier = "Emplacements", .Entite = "Department",
                .ActifsEtInactifs = True,
                .Colonnes = Cols("Id", "Name", "FullyQualifiedName", "SubDepartment", "ParentRef.value", "Active")
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Factures clients", .Fichier = "Factures", .Entite = "Invoice", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("CustomerRef.value", "CustomerRef.name", "DueDate", "SalesTermRef.value",
                                                        "BillEmail.Address", "TotalAmt", "TxnTaxDetail.TotalTax", "=Taxes",
                                                        "Balance", "Deposit", "GlobalTaxCalculation", "ApplyTaxAfterDiscount",
                                                        "CustomerMemo.value", "@BillAddr", "@ShipAddr", "ShipDate",
                                                        "=Liens", "EmailStatus", "PrintStatus", "=ChampsPerso"), Suivi())),
                .ColonnesLignes = LignesVente()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Notes de crédit", .Fichier = "NotesCredit", .Entite = "CreditMemo", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("CustomerRef.value", "CustomerRef.name", "TotalAmt", "TxnTaxDetail.TotalTax",
                                                        "=Taxes", "Balance", "RemainingCredit", "GlobalTaxCalculation",
                                                        "CustomerMemo.value", "@BillAddr", "=ChampsPerso"), Suivi())),
                .ColonnesLignes = LignesVente()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Reçus de vente", .Fichier = "RecusVente", .Entite = "SalesReceipt", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("CustomerRef.value", "CustomerRef.name", "TotalAmt", "TxnTaxDetail.TotalTax",
                                                        "=Taxes", "Balance", "DepositToAccountRef.value", "DepositToAccountRef.name",
                                                        "PaymentMethodRef.value", "PaymentRefNum", "GlobalTaxCalculation",
                                                        "CustomerMemo.value", "@BillAddr", "=ChampsPerso"), Suivi())),
                .ColonnesLignes = LignesVente()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Paiements clients", .Fichier = "PaiementsClients", .Entite = "Payment", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("CustomerRef.value", "CustomerRef.name", "TotalAmt", "UnappliedAmt",
                                                        "DepositToAccountRef.value", "DepositToAccountRef.name",
                                                        "ARAccountRef.value", "PaymentMethodRef.value", "PaymentRefNum"), Suivi())),
                .ColonnesLignes = LignesReglement()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Remboursements", .Fichier = "Remboursements", .Entite = "RefundReceipt", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("CustomerRef.value", "CustomerRef.name", "TotalAmt", "TxnTaxDetail.TotalTax",
                                                        "=Taxes", "DepositToAccountRef.value", "DepositToAccountRef.name",
                                                        "PaymentMethodRef.value", "PaymentRefNum", "@BillAddr"), Suivi())),
                .ColonnesLignes = LignesVente()
            },
            New Extraction With {
                .Categorie = CatVentes, .Libelle = "Soumissions", .Fichier = "Soumissions", .Entite = "Estimate", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("CustomerRef.value", "CustomerRef.name", "TxnStatus", "ExpirationDate",
                                                        "AcceptedBy", "AcceptedDate", "TotalAmt", "TxnTaxDetail.TotalTax", "=Taxes",
                                                        "CustomerMemo.value", "@BillAddr", "=Liens"), Suivi())),
                .ColonnesLignes = LignesVente()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Factures fournisseurs", .Fichier = "FacturesFournisseurs", .Entite = "Bill", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("VendorRef.value", "VendorRef.name", "APAccountRef.value", "APAccountRef.name",
                                                        "SalesTermRef.value", "DueDate", "TotalAmt", "TxnTaxDetail.TotalTax", "=Taxes",
                                                        "Balance", "GlobalTaxCalculation", "@VendorAddr", "=Liens"), Suivi())),
                .ColonnesLignes = LignesAchat()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Crédits fournisseurs", .Fichier = "CreditsFournisseurs", .Entite = "VendorCredit", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("VendorRef.value", "VendorRef.name", "APAccountRef.value", "APAccountRef.name",
                                                        "TotalAmt", "TxnTaxDetail.TotalTax", "=Taxes", "Balance",
                                                        "GlobalTaxCalculation", "=Liens"), Suivi())),
                .ColonnesLignes = LignesAchat()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Paiements fournisseurs", .Fichier = "PaiementsFournisseurs", .Entite = "BillPayment", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("VendorRef.value", "VendorRef.name", "PayType", "TotalAmt",
                                                        "CheckPayment.BankAccountRef.value", "CheckPayment.BankAccountRef.name",
                                                        "CheckPayment.PrintStatus",
                                                        "CreditCardPayment.CCAccountRef.value", "CreditCardPayment.CCAccountRef.name",
                                                        "APAccountRef.value", "APAccountRef.name"), Suivi())),
                .ColonnesLignes = LignesReglement()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Dépenses et chèques", .Fichier = "Depenses", .Entite = "Purchase", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("PaymentType", "AccountRef.value", "AccountRef.name",
                                                        "EntityRef.type", "EntityRef.value", "EntityRef.name",
                                                        "Credit", "TotalAmt", "TxnTaxDetail.TotalTax", "=Taxes",
                                                        "PaymentMethodRef.value", "PrintStatus", "GlobalTaxCalculation",
                                                        "@RemitToAddr", "=Liens"), Suivi())),
                .ColonnesLignes = LignesAchat()
            },
            New Extraction With {
                .Categorie = CatAchats, .Libelle = "Bons de commande", .Fichier = "BonsCommande", .Entite = "PurchaseOrder", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("VendorRef.value", "VendorRef.name", "APAccountRef.value", "POStatus",
                                                        "DueDate", "TotalAmt", "TxnTaxDetail.TotalTax", "=Taxes",
                                                        "@VendorAddr", "@ShipAddr", "Memo", "=Liens"), Suivi())),
                .ColonnesLignes = LignesAchat()
            },
            New Extraction With {
                .Categorie = CatBanque, .Libelle = "Écritures de journal", .Fichier = "EcrituresJournal", .Entite = "JournalEntry", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("Adjustment", "TotalAmt", "TxnTaxDetail.TotalTax", "=Taxes"), Suivi())),
                .ColonnesLignes = Cols("Id", "LineNum", "DetailType", "Description", "Amount",
                                       "JournalEntryLineDetail.PostingType",
                                       "JournalEntryLineDetail.AccountRef.value", "JournalEntryLineDetail.AccountRef.name",
                                       "JournalEntryLineDetail.Entity.Type",
                                       "JournalEntryLineDetail.Entity.EntityRef.value", "JournalEntryLineDetail.Entity.EntityRef.name",
                                       "JournalEntryLineDetail.ClassRef.name", "JournalEntryLineDetail.DepartmentRef.name",
                                       "JournalEntryLineDetail.TaxCodeRef.value", "JournalEntryLineDetail.TaxApplicableOn",
                                       "JournalEntryLineDetail.TaxAmount")
            },
            New Extraction With {
                .Categorie = CatBanque, .Libelle = "Dépôts", .Fichier = "Depots", .Entite = "Deposit", .Datee = True,
                .Colonnes = Plus(EnteteTxn(), Plus(Cols("DepositToAccountRef.value", "DepositToAccountRef.name", "TotalAmt",
                                                        "CashBack.AccountRef.name", "CashBack.Amount", "CashBack.Memo"), Suivi())),
                .ColonnesLignes = Cols("Id", "LineNum", "DetailType", "Description", "Amount",
                                       "DepositLineDetail.AccountRef.value", "DepositLineDetail.AccountRef.name",
                                       "DepositLineDetail.Entity.type", "DepositLineDetail.Entity.value", "DepositLineDetail.Entity.name",
                                       "DepositLineDetail.PaymentMethodRef.value", "DepositLineDetail.CheckNum",
                                       "DepositLineDetail.ClassRef.name", "DepositLineDetail.TaxCodeRef.value",
                                       "LinkedTxn.TxnType", "LinkedTxn.TxnId")
            },
            New Extraction With {
                .Categorie = CatBanque, .Libelle = "Virements", .Fichier = "Virements", .Entite = "Transfer", .Datee = True,
                .Colonnes = Plus(Cols("Id", "TxnDate", "FromAccountRef.value", "FromAccountRef.name",
                                      "ToAccountRef.value", "ToAccountRef.name", "Amount", "CurrencyRef.value", "PrivateNote"), Suivi())
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "Balance de vérification", .Fichier = "BalanceVerification",
                .Rapport = "TrialBalance", .ParametresRapport = AddressOf Periode
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "Balance âgée clients (détail)", .Fichier = "BalanceAgeeClients",
                .Rapport = "AgedReceivableDetail", .ParametresRapport = AddressOf Echeancier
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "Balance âgée fournisseurs (détail)", .Fichier = "BalanceAgeeFournisseurs",
                .Rapport = "AgedPayableDetail", .ParametresRapport = AddressOf Echeancier
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "Bilan", .Fichier = "Bilan",
                .Rapport = "BalanceSheet", .ParametresRapport = AddressOf Periode
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "État des résultats", .Fichier = "EtatResultats",
                .Rapport = "ProfitAndLoss", .ParametresRapport = AddressOf Periode
            },
            New Extraction With {
                .Categorie = CatRapports, .Libelle = "Grand livre", .Fichier = "GrandLivre",
                .Rapport = "GeneralLedger", .ParametresRapport = AddressOf Periode
            }
        }
    End Function

#End Region

End Module
