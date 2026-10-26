Imports System.Data
Imports System.Data.SqlClient
Imports System.Text

Namespace Controls

    Public Class LeftMenu
        Inherits clsDataUC

        Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
            litMenu.Text = BuildMenu()
        End Sub

        Private ReadOnly CHEV As String =
            "<span class=""chev"" aria-hidden=""true"">" &
            "<svg width=""18"" height=""18"" viewBox=""0 0 24 24"" fill=""none"">" &
            "<path d=""M9 18l6-6-6-6"" stroke=""currentColor"" stroke-width=""2"" stroke-linecap=""round"" stroke-linejoin=""round"" />" &
            "</svg></span>"

        Private Function Item(url As String, icon As String, labelKey As String,
                              Optional cls As String = "nav-item",
                              Optional badge As Integer = 0,
                              Optional ton As String = "y") As String

            ' Une pastille à zéro ne se dessine pas : elle ferait du bruit sur
            ' chaque ligne du menu sans rien signaler. Ton : y = à faire (jaune),
            ' r = en retard (rouge), "" = information (bleu pâle).
            Dim meta As String = ""
            If badge > 0 Then
                meta = "<span class=""nav-badge " & ton & """>" & badge.ToString() & "</span>"
            End If

            ' La page où l'on est : la classe « ici » (fond bleu pâle, icône sur rond
            ' bleu marine) et aria-current, pour le lecteur d'écran.
            Dim ici As String = If(EstPageCourante(url), " ici"" aria-current=""page", "")
            Return "<a class=""" & cls & ici & """ href=""" & ResolveUrl(url) & """ data-navlink>" &
                   "<span class=""nav-ico"" aria-hidden=""true"">" & icon & "</span>" &
                   "<span class=""nav-txt"">" & L(labelKey) & "</span>" & meta & "</a>"
        End Function

        ''' <summary>
        ''' Nombre de tâches en attente de décision pour la compagnie courante.
        ''' Le menu se dessine sur chaque page : une erreur ici ne doit jamais
        ''' faire tomber la navigation, on rend simplement zéro.
        ''' </summary>
        Private Function CountApprobations() As Integer
            Try
                If Company = Guid.Empty Then Return 0

                Dim p As New Collection
                p.Add(New SqlParameter("@CompanyGUID", Company))

                Dim ds As DataSet = ExecuteSQLds("s0745GetApprobationsCount", p)
                If ds Is Nothing OrElse ds.Tables.Count = 0 OrElse ds.Tables(0).Rows.Count = 0 Then Return 0

                Return Convert.ToInt32(ds.Tables(0).Rows(0)("AApprouver"))
            Catch
                Return 0
            End Try
        End Function

        ''' <summary>
        ''' Le lien mène-t-il à la page courante ? Par le nom du fichier, sans
        ''' l'extension ni les paramètres : ~/wbfX.aspx?mode=1 et /wbfX se valent.
        ''' </summary>
        Private Function EstPageCourante(url As String) As Boolean
            Try
                Dim cible As String = url
                Dim q As Integer = cible.IndexOf("?"c)
                If q >= 0 Then cible = cible.Substring(0, q)
                cible = IO.Path.GetFileNameWithoutExtension(cible)
                Dim ici As String = IO.Path.GetFileNameWithoutExtension(Request.AppRelativeCurrentExecutionFilePath)
                Return cible <> "" AndAlso String.Equals(cible, ici, StringComparison.OrdinalIgnoreCase)
            Catch
                Return False
            End Try
        End Function

        ''' <summary>Titre de section du menu (Mon argent, Mon entreprise…), en petites capitales.</summary>
        Private Function Section(labelKey As String) As String
            Return "<div class=""nav-sec"">" & L(labelKey) & "</div>"
        End Function


        Private Function Child(url As String, labelKey As String) As String
            Dim ici As String = If(EstPageCourante(url), " ici"" aria-current=""page", "")
            Return "<a class=""nav-child" & ici & """ href=""" & ResolveUrl(url) & """ data-navlink>" &
                   L(labelKey) & "</a>"
        End Function

        Private Function GroupStart(icon As String, labelKey As String) As String
            Return "<div class=""nav-group"" data-accordion>" &
                   "<button type=""button"" class=""nav-parent"" aria-expanded=""false"">" &
                   "<span class=""nav-ico"" aria-hidden=""true"">" & icon & "</span>" &
                   "<span class=""nav-txt"">" & L(labelKey) & "</span>" & CHEV & "</button>" &
                   "<div class=""nav-children"">"
        End Function

        Private Const GroupEnd As String = "</div></div>"

        ''' <summary>
        ''' Les icônes du menu, au trait, dans le style du gabarit « Doux bleu
        ''' marine » : 24 × 24, trait 2.2 arrondi, couleur du texte (currentColor —
        ''' bleu sur le rond clair, blanc sur le rond bleu marine de la page courante).
        ''' Un nom inconnu rend un rond vide plutôt qu'une erreur.
        ''' </summary>
        Private Shared ReadOnly Traits As New Dictionary(Of String, String)(StringComparer.OrdinalIgnoreCase) From {
            {"home", "<path d=""M3 11l9-8 9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z""/>"},
            {"receipt", "<path d=""M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1z""/><path d=""M8 8h8M8 12h8M8 16h5""/>"},
            {"package", "<path d=""M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z""/><path d=""M3.3 7l8.7 5 8.7-5M12 22V12""/>"},
            {"tag", "<path d=""M20.6 13.4l-7.2 7.2a2 2 0 0 1-2.8 0L3 13V3h10l7.6 7.6a2 2 0 0 1 0 2.8z""/><circle cx=""7.5"" cy=""7.5"" r=""1.5""/>"},
            {"book", "<path d=""M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z""/><path d=""M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z""/>"},
            {"calendar", "<rect x=""3"" y=""4"" width=""18"" height=""18"" rx=""2""/><path d=""M8 2v4M16 2v4M3 10h18""/>"},
            {"users", "<path d=""M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2""/><circle cx=""9"" cy=""7"" r=""4""/><path d=""M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75""/>"},
            {"mail", "<rect x=""2"" y=""4"" width=""20"" height=""16"" rx=""2""/><path d=""M22 7l-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7""/>"},
            {"inbox", "<path d=""M22 12h-6l-2 3h-4l-2-3H2""/><path d=""M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z""/>"},
            {"chart", "<path d=""M3 3v18h18""/><path d=""M18 17V9M13 17V5M8 17v-3""/>"},
            {"import", "<path d=""M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4""/><path d=""M7 10l5 5 5-5M12 15V3""/>"},
            {"building", "<path d=""M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18z""/><path d=""M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2M10 6h4M10 10h4M10 14h4M10 18h4""/>"},
            {"user-cog", "<circle cx=""10"" cy=""7"" r=""4""/><path d=""M2 21v-2a4 4 0 0 1 4-4h5""/><circle cx=""18"" cy=""17"" r=""3""/><path d=""M18 12.5v1.5M18 20v1.5M22.5 17H21M15 17h-1.5M21.2 13.8l-1.1 1.1M15.9 19.1l-1.1 1.1M21.2 20.2l-1.1-1.1M15.9 14.9l-1.1-1.1""/>"},
            {"settings", "<circle cx=""12"" cy=""12"" r=""3""/><path d=""M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09a1.65 1.65 0 0 0-1.08-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09a1.65 1.65 0 0 0 1.51-1.08 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z""/>"},
            {"firm", "<path d=""M4 21V5l8-3 8 3v16M9 21v-5h6v5""/>"},
            {"payments", "<path d=""M3 7h18v10H3zM3 11h18M7 15h3""/>"},
            {"card", "<rect x=""2"" y=""5"" width=""20"" height=""14"" rx=""2""/><path d=""M2 10h20""/>"},
            {"bot", "<path d=""M12 8V4H8""/><rect x=""4"" y=""8"" width=""16"" height=""12"" rx=""2""/><path d=""M2 14h2M20 14h2M15 13v2M9 13v2""/>"},
            {"logout", "<path d=""M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4""/><path d=""M16 17l5-5-5-5M21 12H9""/>"}
        }

        Private Shared Function Ico(nom As String) As String
            Dim trait As String = ""
            Traits.TryGetValue(nom, trait)
            Return "<svg aria-hidden=""true"" width=""16"" height=""16"" viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" " &
                   "stroke-width=""2.2"" stroke-linecap=""round"" stroke-linejoin=""round"">" & trait & "</svg>"
        End Function

        ''' <summary>
        ''' Le menu, rangé comme l'accueil 60secondes : Tableau de bord, puis
        ''' Mon argent, Mon entreprise, Mon accompagnement et Administration.
        ''' Les éléments qui regroupent plusieurs écrans se déplient.
        ''' </summary>
        Private Function BuildMenu() As String
            Dim sb As New StringBuilder()

            sb.Append(Item("~/default.aspx", Ico("home"), "dashboard"))

            ' ---------- Mon argent ----------
            sb.Append(Section("secMoney"))

            sb.Append(GroupStart(Ico("receipt"), "sales"))
            sb.Append(Child("~/wbfCustomers.aspx", "customers"))
            sb.Append(Child("~/wbfCustomersInvoices.aspx", "customerInvoices"))
            sb.Append(Child("~/wbfEncaissements.aspx", "cashIns"))
            sb.Append(GroupEnd)

            sb.Append(GroupStart(Ico("package"), "purchases"))
            sb.Append(Child("~/wbfSuppliers.aspx", "suppliers"))
            sb.Append(Child("~/wbfSuppliersInvoices.aspx", "supplierInvoices"))
            sb.Append(Child("~/wbfReceipt.aspx", "receipts"))
            sb.Append(GroupEnd)

            sb.Append(GroupStart(Ico("payments"), "payments"))
            sb.Append(Child("~/wbfPaymentProcessors.aspx", "paymentProcessors"))
            sb.Append(Child("~/wbfAutoPayAuthorizations.aspx", "autoPay"))
            sb.Append(GroupEnd)

            sb.Append(GroupStart(Ico("chart"), "reports"))
            sb.Append(Child("~/wbfRapportPlanComptable.aspx", "chartOfAccounts"))
            sb.Append(Child("~/wbfEtatResultats.aspx", "incomeStatement"))
            sb.Append(Child("~/wbfBilan.aspx", "balanceSheet"))
            sb.Append(Child("~/wbfFluxTresorerie.aspx", "cashFlow"))
            sb.Append(Child("~/wbfBeneficesNonRepartis.aspx", "retainedEarnings"))
            sb.Append(Child("~/wbfBalanceVerification.aspx", "trialBalance"))
            sb.Append(Child("~/wbfAIPaiement.aspx", "aiPayment"))
            sb.Append(Child("~/wbfAISale.aspx", "aiSales"))
            sb.Append(GroupEnd)

            ' ---------- Mon entreprise ----------
            sb.Append(Section("secBusiness"))

            sb.Append(Item("~/wbfAgenda.aspx", Ico("calendar"), "agenda"))
            ' Employés (ressources de l'agenda)
            sb.Append(Item("~/wbfEmployees.aspx", Ico("users"), "employees"))
            sb.Append(Item("~/wbfMailbox.aspx", Ico("mail"), "mailbox"))

            sb.Append(GroupStart(Ico("book"), "accounting"))
            sb.Append(Child("~/wbfJournal.aspx", "journals"))
            sb.Append(Child("~/wbfTemplate.aspx", "journalTemplates"))
            sb.Append(Child("~/PlaidAccounts.aspx", "bankAccounts"))
            sb.Append(Child("~/wbfReleve.aspx", "bankStatement"))
            sb.Append(Child("~/wbfRapportTaxe.aspx", "taxReport"))
            sb.Append(Child("~/wbfFermetureAnnee.aspx", "yearEnd"))
            sb.Append(Child("~/wbfPlanComptable.aspx", "chartOfAccounts"))
            sb.Append(GroupEnd)

            sb.Append(GroupStart(Ico("tag"), "productsServices"))
            sb.Append(Child("~/wbfProducts.aspx", "products"))
            sb.Append(Child("~/wbfProductCategory.aspx", "productCategory"))
            sb.Append(Child("~/wbfLieux.aspx", "lieux"))
            sb.Append(GroupEnd)

            ' La boîte de messages : les tâches que l'exécuteur ne lancera pas sans
            ' l'accord de l'utilisateur ; la pastille jaune porte le nombre en attente.
            ' (Les tâches planifiées vivent dans la console d'administration, prjSec60Admin.)
            sb.Append(Item("~/wbfApprobations.aspx", Ico("inbox"), "approvals", "nav-item", CountApprobations(), "y"))

            ' ---------- Mon accompagnement ----------
            sb.Append(Section("secSupport"))
            sb.Append(Item("~/CabinetsCertifies.aspx", Ico("firm"), "myFirm"))

            ' ---------- Administration ----------
            sb.Append(Section("secAdmin"))
            sb.Append(Item("~/wbfsetting.aspx", Ico("settings"), "settings"))
            sb.Append(Item("~/wbfUsers.aspx", Ico("user-cog"), "users"))
            ' Une seule porte pour l'importation : la page d'accueil des importations,
            ' qui dit aussi où chacun en est.
            sb.Append(Item("~/Importations.aspx", Ico("import"), "importations"))
            sb.Append(Item("~/wbfLogout.aspx", Ico("logout"), "logout"))

            Return sb.ToString()
        End Function

        ''' <summary>Traductions du menu (fr/en/es).</summary>
        Protected Function L(key As String) As String
            Dim lang As String = CurrentLang
            Select Case key
                Case "menu" : Return Choose3(lang, "Menu", "Menu", "Menú")
                Case "menuShow" : Return Choose3(lang, "Afficher le menu", "Show menu", "Mostrar el menú")
                Case "menuHide" : Return Choose3(lang, "Masquer le menu", "Hide menu", "Ocultar el menú")
                Case "secMoney" : Return Choose3(lang, "Mon argent", "My money", "Mi dinero")
                Case "secBusiness" : Return Choose3(lang, "Mon entreprise", "My business", "Mi empresa")
                Case "secSupport" : Return Choose3(lang, "Mon accompagnement", "My support", "Mi acompañamiento")
                Case "secAdmin" : Return Choose3(lang, "Administration", "Administration", "Administración")
                Case "payments" : Return Choose3(lang, "Paiements", "Payments", "Pagos")
                Case "myFirm" : Return Choose3(lang, "Mon cabinet comptable", "My accounting firm", "Mi despacho contable")
                Case "welcome" : Return Choose3(lang, "Bienvenue", "Welcome", "Bienvenida")
                Case "dashboard" : Return Choose3(lang, "Tableau de bord", "Dashboard", "Panel de control")
                Case "agenda" : Return Choose3(lang, "Agenda", "Agenda", "Agenda")
                Case "employees" : Return Choose3(lang, "Employés", "Employees", "Empleados")
                Case "mailbox" : Return Choose3(lang, "Courriel", "Mail", "Correo")
                Case "approvals" : Return Choose3(lang, "Tâches à approuver", "Tasks to approve", "Tareas por aprobar")
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
                Case "lieux" : Return Choose3(lang, "Lieux", "Locations", "Lugares")
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
                Case "importations" : Return Choose3(lang, "Importation des données", "Data import", "Importación de datos")
                Case "importPlanComptable" : Return Choose3(lang, "Reprise — plan comptable", "Migration — chart of accounts", "Migración — plan contable")
                Case "appliquerPlanComptable" : Return Choose3(lang, "Reprise — créer les comptes", "Migration — create accounts", "Migración — crear las cuentas")
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
