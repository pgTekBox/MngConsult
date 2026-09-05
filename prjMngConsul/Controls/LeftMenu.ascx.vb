Imports System.Text

Namespace Controls

    Public Class LeftMenu
        Inherits clsDataUC

        Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
            litMenu.Text = BuildMenu()
        End Sub

        Private ReadOnly CHEV As String =
            "<span class=""nav-meta""><span class=""chev"" aria-hidden=""true"">" &
            "<svg width=""18"" height=""18"" viewBox=""0 0 24 24"" fill=""none"">" &
            "<path d=""M9 18l6-6-6-6"" stroke=""currentColor"" stroke-width=""2"" stroke-linecap=""round"" stroke-linejoin=""round"" />" &
            "</svg></span></span>"

        Private Function Item(url As String, icon As String, labelKey As String, Optional cls As String = "nav-item") As String
            Return "<a class=""" & cls & """ href=""" & ResolveUrl(url) & """ data-navlink>" &
                   "<span class=""nav-ico"" aria-hidden=""true"">" & icon & "</span>" &
                   "<span class=""nav-txt"">" & L(labelKey) & "</span></a>"
        End Function

        Private Function Child(url As String, labelKey As String) As String
            Return "<a class=""nav-child"" href=""" & ResolveUrl(url) & """ data-navlink>" &
                   "<span class=""dot"" aria-hidden=""true""></span>" & L(labelKey) & "</a>"
        End Function

        Private Function GroupStart(icon As String, labelKey As String) As String
            Return "<div class=""nav-group"" data-accordion>" &
                   "<button type=""button"" class=""nav-parent"" aria-expanded=""false"">" &
                   "<span class=""nav-ico"" aria-hidden=""true"">" & icon & "</span>" &
                   "<span class=""nav-txt"">" & L(labelKey) & "</span>" & CHEV & "</button>" &
                   "<div class=""nav-children"">"
        End Function

        Private Const GroupEnd As String = "</div></div>"

        Private Function BuildMenu() As String
            Dim sb As New StringBuilder()

            sb.Append(Item("~/default.aspx", "🏠", "dashboard"))

            ' Ventes
            sb.Append(GroupStart("🧾", "sales"))
            sb.Append(Child("~/wbfCustomers.aspx", "customers"))
            sb.Append(Child("~/wbfCustomersInvoices.aspx", "customerInvoices"))
            sb.Append(GroupEnd)

            ' Achats
            sb.Append(GroupStart("📦", "purchases"))
            sb.Append(Child("~/wbfSuppliers.aspx", "suppliers"))
            sb.Append(Child("~/wbfSuppliersInvoices.aspx", "supplierInvoices"))
            sb.Append(Child("~/wbfReceipt.aspx", "receipts"))
            sb.Append(GroupEnd)

            ' Produits et services
            sb.Append(GroupStart("🏷️", "productsServices"))
            sb.Append(Child("~/wbfProducts.aspx", "products"))
            sb.Append(Child("~/wbfProductCategory.aspx", "productCategory"))
            sb.Append(GroupEnd)

            ' Comptabilité
            sb.Append(GroupStart("📒", "accounting"))
            sb.Append(Child("~/wbfJournal.aspx", "journals"))
            sb.Append(Child("~/wbfTemplate.aspx", "journalTemplates"))
            sb.Append(Child("~/PlaidAccounts.aspx", "bankAccounts"))
            sb.Append(Child("~/wbfReleve.aspx", "bankStatement"))
            sb.Append(Child("~/wbfRapportTaxe.aspx", "taxReport"))
            sb.Append(Child("~/wbfFermetureAnnee.aspx", "yearEnd"))
            sb.Append(Child("~/wbfPlanComptable.aspx", "chartOfAccounts"))
            sb.Append(GroupEnd)

            ' Agenda
            sb.Append(Item("~/wbfAgenda.aspx", "📅", "agenda"))

            ' Employés (ressources de l'agenda)
            sb.Append(Item("~/wbfEmployees.aspx", "👥", "employees"))

            ' Courriel
            sb.Append(Item("~/wbfMailbox.aspx", "✉️", "mailbox"))

            ' Les tâches planifiées ont été déplacées dans la console
            ' d'administration (prjSec60Admin) : elles pilotent des traitements
            ' de fond, pas le travail quotidien d'un utilisateur.

            ' Rapports
            sb.Append(GroupStart("📒", "reports"))
            sb.Append(Child("~/wbfRapportPlanComptable.aspx", "chartOfAccounts"))
            sb.Append(Child("~/wbfEtatResultats.aspx", "incomeStatement"))
            sb.Append(Child("~/wbfBilan.aspx", "balanceSheet"))
            sb.Append(Child("~/wbfFluxTresorerie.aspx", "cashFlow"))
            sb.Append(Child("~/wbfBeneficesNonRepartis.aspx", "retainedEarnings"))
            sb.Append(Child("~/wbfBalanceVerification.aspx", "trialBalance"))
            sb.Append(Child("~/wbfAIPaiement.aspx", "aiPayment"))
            sb.Append(Child("~/wbfAISale.aspx", "aiSales"))
            sb.Append(GroupEnd)

            ' Importation
            sb.Append(GroupStart("📒", "import"))
            sb.Append(Child("~/wbfImport.aspx", "importAll"))
            sb.Append(GroupEnd)

            ' Footer
            sb.Append("<div class=""sidebar-footer"">")
            sb.Append(Item("~/wbfNewUser.aspx", "🏢", "companyProfile", "nav-item subtle"))
            sb.Append(Item("~/wbfUsers.aspx", "⚙️", "users", "nav-item subtle"))
            sb.Append(Item("~/wbfsetting.aspx", "⚙️", "settings", "nav-item subtle"))
            sb.Append(Item("~/wbfPaymentProcessors.aspx", "💳", "paymentProcessors", "nav-item subtle"))
            sb.Append(Item("~/wbfAutoPayAuthorizations.aspx", "🤖", "autoPay", "nav-item subtle"))
            sb.Append(Item("~/wbfLogout.aspx", "🚪", "logout", "nav-item subtle"))
            sb.Append("</div>")

            Return sb.ToString()
        End Function

        ''' <summary>Traductions du menu (fr/en/es).</summary>
        Private Function L(key As String) As String
            Dim lang As String = CurrentLang
            Select Case key
                Case "welcome" : Return Choose3(lang, "Bienvenue", "Welcome", "Bienvenida")
                Case "dashboard" : Return Choose3(lang, "Tableau de bord", "Dashboard", "Panel de control")
                Case "agenda" : Return Choose3(lang, "Agenda", "Agenda", "Agenda")
                Case "employees" : Return Choose3(lang, "Employés", "Employees", "Empleados")
                Case "mailbox" : Return Choose3(lang, "Courriel", "Mail", "Correo")
                Case "sales" : Return Choose3(lang, "Ventes", "Sales", "Ventas")
                Case "customers" : Return Choose3(lang, "Clients", "Customers", "Clientes")
                Case "customerInvoices" : Return Choose3(lang, "Factures clients", "Customer invoices", "Facturas de clientes")
                Case "scannedDocs" : Return Choose3(lang, "Documents scannés", "Scanned documents", "Documentos escaneados")
                Case "cashIns" : Return Choose3(lang, "Encaissements", "Cash receipts", "Cobros")
                Case "purchases" : Return Choose3(lang, "Achats", "Purchases", "Compras")
                Case "suppliers" : Return Choose3(lang, "Fournisseurs", "Suppliers", "Proveedores")
                Case "supplierInvoices" : Return Choose3(lang, "Factures fournisseurs", "Supplier invoices", "Facturas de proveedores")
                Case "receipts" : Return Choose3(lang, "Reçus", "Receipts", "Recibos")
                Case "productsServices" : Return Choose3(lang, "Produits et services", "Products and services", "Productos y servicios")
                Case "accounting" : Return Choose3(lang, "Comptabilité", "Accounting", "Contabilidad")
                Case "journals" : Return Choose3(lang, "Journaux", "Journals", "Diarios")
                Case "journalTemplates" : Return Choose3(lang, "Modèles de journaux", "Journal templates", "Plantillas de diarios")
                Case "bankAccounts" : Return Choose3(lang, "Comptes bancaires", "Bank accounts", "Cuentas bancarias")
                Case "bankStatement" : Return Choose3(lang, "Relevé bancaire", "Bank statement", "Extracto bancario")
                Case "taxReport" : Return Choose3(lang, "Rapport de taxes", "Tax report", "Informe de impuestos")
                Case "yearEnd" : Return Choose3(lang, "Fermeture d'année fiscale", "Fiscal year-end close", "Cierre del ejercicio fiscal")
                Case "chartOfAccounts" : Return Choose3(lang, "Plan comptable", "Chart of accounts", "Plan contable")
                Case "productCategory" : Return Choose3(lang, "Catégorie de produit", "Product category", "Categoría de producto")
                Case "products" : Return Choose3(lang, "Produits", "Products", "Productos")
                Case "reports" : Return Choose3(lang, "Rapports", "Reports", "Informes")
                Case "incomeStatement" : Return Choose3(lang, "État des résultats", "Income statement", "Estado de resultados")
                Case "balanceSheet" : Return Choose3(lang, "Bilan", "Balance sheet", "Balance general")
                Case "cashFlow" : Return Choose3(lang, "État des flux de trésorerie", "Cash flow statement", "Estado de flujos de efectivo")
                Case "retainedEarnings" : Return Choose3(lang, "État des bénéfices non répartis", "Retained earnings statement", "Estado de resultados acumulados")
                Case "trialBalance" : Return Choose3(lang, "Balance de vérification", "Trial balance", "Balance de comprobación")
                Case "aiPayment" : Return Choose3(lang, "IA Paiement", "AI Payment", "Pago con IA")
                Case "aiSales" : Return Choose3(lang, "IA Ventes", "AI Sales", "Ventas con IA")
                Case "import" : Return Choose3(lang, "Importation", "Import", "Importación")
                Case "importAll" : Return Choose3(lang, "Import (clients / fournisseurs / produits)", "Import (customers / suppliers / products)", "Importar (clientes / proveedores / productos)")
                Case "companyProfile" : Return Choose3(lang, "Profil de l'entreprise", "Company profile", "Perfil de la empresa")
                Case "users" : Return Choose3(lang, "Utilisateurs", "Users", "Usuarios")
                Case "settings" : Return Choose3(lang, "Paramètres", "Settings", "Ajustes")
                Case "settingsOpenAI" : Return Choose3(lang, "Paramètres OpenAI", "OpenAI settings", "Ajustes de OpenAI")
                Case "paymentProcessors" : Return Choose3(lang, "Processeur de paiement", "Payment processor", "Procesador de pago")
                Case "stripeDiag" : Return Choose3(lang, "Diagnostic Stripe", "Stripe diagnostics", "Diagnóstico de Stripe")
                Case "autoPay" : Return Choose3(lang, "Paiements automatiques", "Automatic payments", "Pagos automáticos")
                Case "logout" : Return Choose3(lang, "Déconnexion", "Log out", "Cerrar sesión")
                Case Else : Return ""
            End Select
        End Function

        Private Shared Function Choose3(lang As String, fr As String, en As String, es As String) As String
            Select Case lang
                Case "en" : Return en
                Case "es" : Return es
                Case Else : Return fr
            End Select
        End Function

    End Class
End Namespace
