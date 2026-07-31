Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization

Public Class _Default
    Inherits clsData

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not isAuthenticated Then
            Response.Redirect("wbfLogin.aspx?lang=" & CurrentLang)
        End If
        Page.Title = L("pageTitle")

        If Not IsPostBack Then
            LoadWelcomeInfo()
            LoadKPIs()
        End If
    End Sub

    ''' <summary>
    ''' Alimente les 4 cartes KPI (Clients, Factures fournisseur, Produits, Revenu du mois)
    ''' avec les vraies valeurs de la compagnie via s0697GetDashboardKPIs.
    ''' </summary>
    Private Sub LoadKPIs()
        Dim custCount As Long = 0
        Dim supInvCount As Long = 0
        Dim prodCount As Long = 0
        Dim revenue As Decimal = 0D

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0697GetDashboardKPIs", p)

            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                custCount = If(IsDBNull(r("CustomerCount")), 0L, Convert.ToInt64(r("CustomerCount")))
                supInvCount = If(IsDBNull(r("SupplierInvoiceCount")), 0L, Convert.ToInt64(r("SupplierInvoiceCount")))
                prodCount = If(IsDBNull(r("ProductCount")), 0L, Convert.ToInt64(r("ProductCount")))
                revenue = If(IsDBNull(r("RevenueMonth")), 0D, Convert.ToDecimal(r("RevenueMonth")))
            End If
        Catch
            ' En cas d'erreur, on laisse les valeurs à 0.
        End Try

        Dim c As CultureInfo = Cult()
        litKpiCustomers.Text = custCount.ToString("N0", c)
        litKpiSupplierInvoices.Text = supInvCount.ToString("N0", c)
        litKpiProducts.Text = prodCount.ToString("N0", c)
        litKpiRevenue.Text = revenue.ToString("N0", c) & " $"
    End Sub

    ''' <summary>Culture pour le format des dates selon la langue courante.</summary>
    Private Function Cult() As CultureInfo
        Select Case CurrentLang
            Case "en" : Return New CultureInfo("en-CA")
            Case "es" : Return New CultureInfo("es-ES")
            Case Else : Return New CultureInfo("fr-CA")
        End Select
    End Function

    ''' <summary>
    ''' Alimente la boîte de bienvenue dépliable (prénom, forfait, fin d'essai).
    ''' L'onboarding vit directement dans le tableau de bord (plus de page séparée).
    ''' </summary>
    Private Sub LoadWelcomeInfo()

        Dim firstName As String = UserFirstName
        If String.IsNullOrEmpty(firstName) Then firstName = L("aboard")
        litFirstName.Text = firstName

        Dim planName As String = "Solo"
        Dim trialEnd As Date = Date.Now.AddDays(30)

        Try
            Dim p As New Collection
            p.Add(New SqlParameter("@CompanyGUID", Company))
            Dim ds As DataSet = ExecuteSQLds("s0301GetActiveSubscription", p)

            If ds IsNot Nothing AndAlso ds.Tables.Count > 0 AndAlso ds.Tables(0).Rows.Count > 0 Then
                Dim r As DataRow = ds.Tables(0).Rows(0)
                planName = If(r("PlanName") Is DBNull.Value, "Solo", r("PlanName").ToString())
                If Not r("NextBillingDate") Is DBNull.Value Then
                    trialEnd = CDate(r("NextBillingDate"))
                End If
            End If
        Catch
            ' On garde les valeurs par défaut en cas d'erreur
        End Try

        litPlanName.Text = planName
        litTrialEnd.Text = trialEnd.ToString("d MMMM yyyy", Cult())
    End Sub

    ''' <summary>Traductions du tableau de bord (fr/en/es).</summary>
    Protected Function L(key As String) As String
        Dim lang As String = CurrentLang
        Select Case key
            Case "pageTitle" : Return Choose3(lang, "Tableau de bord — 60Sec-AI", "Dashboard — 60Sec-AI", "Panel — 60Sec-AI")
            Case "heroBadge" : Return Choose3(lang, "✨ Tableau de bord principal", "✨ Main dashboard", "✨ Panel principal")
            Case "heroTitle" : Return Choose3(lang, "Bienvenue dans 60Sec-AI", "Welcome to 60Sec-AI", "Bienvenido a 60Sec-AI")
            Case "heroSub" : Return Choose3(lang, "Gérez vos clients, vos factures, vos produits et vos opérations quotidiennes depuis une seule interface claire, rapide et adaptée au mobile.", "Manage your customers, invoices, products and daily operations from a single interface that's clear, fast and mobile-ready.", "Gestione sus clientes, facturas, productos y operaciones diarias desde una sola interfaz clara, rápida y adaptada al móvil.")
            Case "btnNewInvoice" : Return Choose3(lang, "Nouvelle facture", "New invoice", "Nueva factura")
            Case "winAddInvoice" : Return Choose3(lang, "Nouvelle facture", "New invoice", "Nueva factura")
            Case "winEditInvoice" : Return Choose3(lang, "Modifier la facture", "Edit invoice", "Editar factura")
            Case "btnViewCustomers" : Return Choose3(lang, "Voir les clients", "View customers", "Ver clientes")
            Case "btnSettings" : Return Choose3(lang, "Paramètres", "Settings", "Ajustes")
            Case "msSalesLabel" : Return Choose3(lang, "Ventes du mois", "Monthly sales", "Ventas del mes")
            Case "msSalesNote" : Return Choose3(lang, "+12.4% vs mois dernier", "+12.4% vs last month", "+12,4 % vs mes anterior")
            Case "msOpenInvLabel" : Return Choose3(lang, "Factures ouvertes", "Open invoices", "Facturas abiertas")
            Case "msOpenInvNote" : Return Choose3(lang, "5 à relancer cette semaine", "5 to follow up this week", "5 por reclamar esta semana")
            Case "msActiveCustLabel" : Return Choose3(lang, "Clients actifs", "Active customers", "Clientes activos")
            Case "msActiveCustNote" : Return Choose3(lang, "Nouveaux ce mois-ci : 14", "New this month: 14", "Nuevos este mes: 14")
            Case "msProductsLabel" : Return Choose3(lang, "Produits", "Products", "Productos")
            Case "msProductsNote" : Return Choose3(lang, "Catalogue synchronisé", "Catalog synced", "Catálogo sincronizado")
            Case "kpiCustomers" : Return Choose3(lang, "Clients", "Customers", "Clientes")
            Case "kpiCustomersFoot" : Return Choose3(lang, "Total des clients enregistrés", "Total registered customers", "Total de clientes registrados")
            Case "kpiSupplierInvoices" : Return Choose3(lang, "Factures fournisseur", "Supplier invoices", "Facturas de proveedor")
            Case "kpiSupplierInvoicesFoot" : Return Choose3(lang, "Total des factures fournisseurs", "Total supplier invoices", "Total de facturas de proveedores")
            Case "kpiProducts" : Return Choose3(lang, "Produits", "Products", "Productos")
            Case "kpiProductsFoot" : Return Choose3(lang, "Catalogue prêt pour la vente", "Catalog ready to sell", "Catálogo listo para vender")
            Case "kpiRevenue" : Return Choose3(lang, "Revenus", "Revenue", "Ingresos")
            Case "kpiRevenueFoot" : Return Choose3(lang, "Performance du mois courant", "Current month performance", "Rendimiento del mes actual")
            Case "modulesTitle" : Return Choose3(lang, "Modules", "Modules", "Módulos")
            Case "modulesSub" : Return Choose3(lang, "Accès rapide aux sections principales", "Quick access to main sections", "Acceso rápido a las secciones principales")
            Case "modClients" : Return Choose3(lang, "Clients", "Customers", "Clientes")
            Case "modClientsDesc" : Return Choose3(lang, "Consultez, ajoutez et modifiez vos clients.", "View, add and edit your customers.", "Consulte, añada y edite sus clientes.")
            Case "modInvoices" : Return Choose3(lang, "Factures", "Invoices", "Facturas")
            Case "modInvoicesDesc" : Return Choose3(lang, "Gérez vos factures, paiements et suivis.", "Manage your invoices, payments and follow-ups.", "Gestione sus facturas, pagos y seguimientos.")
            Case "modProducts" : Return Choose3(lang, "Produits", "Products", "Productos")
            Case "modProductsDesc" : Return Choose3(lang, "Maintenez votre catalogue et vos prix.", "Maintain your catalog and prices.", "Mantenga su catálogo y precios.")
            Case "modSuppliers" : Return Choose3(lang, "Fournisseurs", "Suppliers", "Proveedores")
            Case "modSuppliersDesc" : Return Choose3(lang, "Suivi des partenaires et des approvisionnements.", "Track partners and supplies.", "Seguimiento de socios y suministros.")
            Case "modReceipts" : Return Choose3(lang, "Reçus", "Receipts", "Recibos")
            Case "modReceiptsDesc" : Return Choose3(lang, "Consultez les reçus et les encaissements.", "View receipts and cash-ins.", "Consulte los recibos y cobros.")
            Case "modSettings" : Return Choose3(lang, "Paramètres", "Settings", "Ajustes")
            Case "modSettingsDesc" : Return Choose3(lang, "Configurez l'entreprise, les taxes et l'email.", "Configure company, taxes and email.", "Configure la empresa, los impuestos y el correo.")
            Case "recentInvTitle" : Return Choose3(lang, "Factures récentes", "Recent invoices", "Facturas recientes")
            Case "recentInvSub" : Return Choose3(lang, "Aperçu rapide des dernières opérations", "Quick overview of the latest transactions", "Vista rápida de las últimas operaciones")
            Case "viewAll" : Return Choose3(lang, "Voir tout", "View all", "Ver todo")
            Case "thNo" : Return Choose3(lang, "No", "No.", "N.º")
            Case "thClient" : Return Choose3(lang, "Client", "Customer", "Cliente")
            Case "thDate" : Return Choose3(lang, "Date", "Date", "Fecha")
            Case "thAmount" : Return Choose3(lang, "Montant", "Amount", "Importe")
            Case "thStatus" : Return Choose3(lang, "Statut", "Status", "Estado")
            Case "stOpen" : Return Choose3(lang, "Ouverte", "Open", "Abierta")
            Case "stPaid" : Return Choose3(lang, "Payée", "Paid", "Pagada")
            Case "stOverdue" : Return Choose3(lang, "En retard", "Overdue", "Vencida")
            Case "d1" : Return Choose3(lang, "11 mars 2026", "March 11, 2026", "11 de marzo de 2026")
            Case "d2" : Return Choose3(lang, "10 mars 2026", "March 10, 2026", "10 de marzo de 2026")
            Case "d3" : Return Choose3(lang, "9 mars 2026", "March 9, 2026", "9 de marzo de 2026")
            Case "d4" : Return Choose3(lang, "8 mars 2026", "March 8, 2026", "8 de marzo de 2026")
            Case "quickTitle" : Return Choose3(lang, "Actions rapides", "Quick actions", "Acciones rápidas")
            Case "quickSub" : Return Choose3(lang, "Les opérations les plus utilisées", "The most used operations", "Las operaciones más usadas")
            Case "qaCreateInvoice" : Return Choose3(lang, "Créer une facture", "Create an invoice", "Crear una factura")
            Case "qaAddCustomer" : Return Choose3(lang, "Ajouter un client", "Add a customer", "Añadir un cliente")
            Case "qaAddProduct" : Return Choose3(lang, "Ajouter un produit", "Add a product", "Añadir un producto")
            Case "qaViewReceipts" : Return Choose3(lang, "Voir les reçus", "View receipts", "Ver recibos")
            Case "activityTitle" : Return Choose3(lang, "Activité récente", "Recent activity", "Actividad reciente")
            Case "activitySub" : Return Choose3(lang, "Derniers événements du système", "Latest system events", "Últimos eventos del sistema")
            Case "act1" : Return Choose3(lang, "La facture #1048 a été créée.", "Invoice #1048 was created.", "La factura n.º 1048 fue creada.")
            Case "act1Time" : Return Choose3(lang, "Aujourd'hui à 08:42", "Today at 08:42", "Hoy a las 08:42")
            Case "act2" : Return Choose3(lang, "Paiement reçu pour la facture #1047.", "Payment received for invoice #1047.", "Pago recibido para la factura n.º 1047.")
            Case "act2Time" : Return Choose3(lang, "Aujourd'hui à 07:58", "Today at 07:58", "Hoy a las 07:58")
            Case "act3" : Return Choose3(lang, "Un nouveau client a été ajouté au système.", "A new customer was added to the system.", "Se añadió un nuevo cliente al sistema.")
            Case "act3Time" : Return Choose3(lang, "Hier à 16:21", "Yesterday at 16:21", "Ayer a las 16:21")
            Case "act4" : Return Choose3(lang, "La facture #1045 est maintenant en retard.", "Invoice #1045 is now overdue.", "La factura n.º 1045 está ahora vencida.")
            Case "act4Time" : Return Choose3(lang, "Hier à 09:14", "Yesterday at 09:14", "Ayer a las 09:14")
            Case "summaryTitle" : Return Choose3(lang, "Résumé", "Summary", "Resumen")
            Case "summarySub" : Return Choose3(lang, "État général de votre environnement", "General status of your environment", "Estado general de su entorno")
            Case "sumCustomers" : Return Choose3(lang, "Base clients", "Customer base", "Base de clientes")
            Case "sumCustomersVal" : Return Choose3(lang, "À jour", "Up to date", "Actualizada")
            Case "sumTaxes" : Return Choose3(lang, "Taxes", "Taxes", "Impuestos")
            Case "sumTaxesVal" : Return Choose3(lang, "Configurées", "Configured", "Configurados")
            Case "sumEmails" : Return Choose3(lang, "Emails", "Emails", "Correos")
            Case "sumEmailsVal" : Return Choose3(lang, "Actifs", "Active", "Activos")
            Case "sumPdf" : Return Choose3(lang, "PDF / Modèles", "PDF / Templates", "PDF / Plantillas")
            Case "sumPdfVal" : Return Choose3(lang, "Disponibles", "Available", "Disponibles")

            ' === Boîte de bienvenue dépliable (onboarding intégré au tableau de bord) ===
            Case "aboard" : Return Choose3(lang, "à bord", "aboard", "a bordo")
            Case "wbGreetBefore" : Return Choose3(lang, "Bienvenue, ", "Welcome, ", "Bienvenido, ")
            Case "wbGreetAfter" : Return Choose3(lang, " ! 👋", "! 👋", "! 👋")
            Case "wbToggle" : Return Choose3(lang, "Voir vos prochaines étapes", "See your next steps", "Vea sus próximos pasos")
            Case "wbTrialBefore" : Return Choose3(lang, "Forfait ", "Plan ", "Plan ")
            Case "wbTrialMiddle" : Return Choose3(lang, " · Essai gratuit jusqu'au ", " · Free trial until ", " · Prueba gratuita hasta el ")
            Case "nextSteps" : Return Choose3(lang, "🚀 Vos prochaines étapes", "🚀 Your next steps", "🚀 Sus próximos pasos")
            Case "step" : Return Choose3(lang, "Étape", "Step", "Paso")
            Case "step1Title" : Return Choose3(lang, "Compléter votre profil", "Complete your profile", "Complete su perfil")
            Case "step1Desc" : Return Choose3(lang, "Ajoutez vos informations fiscales (NEQ, TPS, TVQ) pour débloquer la facturation.", "Add your tax information (NEQ, GST, QST) to unlock invoicing.", "Añada su información fiscal (NEQ, GST, QST) para desbloquear la facturación.")
            Case "step2Title" : Return Choose3(lang, "Ajouter vos clients", "Add your customers", "Añada sus clientes")
            Case "step2Desc" : Return Choose3(lang, "Créez votre carnet de clients pour commencer à émettre vos premières factures.", "Build your customer list to start issuing your first invoices.", "Cree su lista de clientes para empezar a emitir sus primeras facturas.")
            Case "step3Title" : Return Choose3(lang, "Configurer vos services", "Set up your services", "Configure sus servicios")
            Case "step3Desc" : Return Choose3(lang, "Définissez votre liste de services avec leurs tarifs et durées.", "Define your list of services with their prices and durations.", "Defina su lista de servicios con sus precios y duraciones.")
            Case "step4Title" : Return Choose3(lang, "Planifier votre agenda", "Plan your schedule", "Planifique su agenda")
            Case "step4Desc" : Return Choose3(lang, "Prenez votre premier rendez-vous et organisez votre semaine en quelques clics.", "Book your first appointment and organize your week in a few clicks.", "Reserve su primera cita y organice su semana en unos clics.")
            Case "tipsTitle" : Return Choose3(lang, "💡 Quelques conseils pour bien démarrer", "💡 A few tips to get started", "💡 Algunos consejos para empezar")
            Case "tipsHead" : Return Choose3(lang, "À savoir avant de commencer", "Good to know before you start", "Qué saber antes de empezar")
            Case "tip1" : Return Choose3(lang, "<strong>Vos données sont en sécurité.</strong> Toutes les sauvegardes sont automatiques et chiffrées.", "<strong>Your data is safe.</strong> All backups are automatic and encrypted.", "<strong>Sus datos están seguros.</strong> Todas las copias de seguridad son automáticas y cifradas.")
            Case "tip2" : Return Choose3(lang, "<strong>Aucune carte de crédit requise pendant l'essai.</strong> Vous serez informé 7 jours avant la fin de votre période d'essai.", "<strong>No credit card required during the trial.</strong> You'll be notified 7 days before your trial ends.", "<strong>No se requiere tarjeta de crédito durante la prueba.</strong> Se le avisará 7 días antes de que termine su prueba.")
            Case "tip3" : Return Choose3(lang, "<strong>Conformité fiscale Québec.</strong> 60Sec-AI calcule automatiquement la TPS (5 %) et la TVQ (9,975 %) sur vos factures.", "<strong>Quebec tax compliance.</strong> 60Sec-AI automatically calculates GST (5%) and QST (9.975%) on your invoices.", "<strong>Cumplimiento fiscal de Quebec.</strong> 60Sec-AI calcula automáticamente el GST (5 %) y el QST (9,975 %) en sus facturas.")
            Case "tip4" : Return Choose3(lang, "<strong>Vous n'êtes pas seul·e.</strong> Notre équipe de support est disponible par courriel à <a href=""mailto:support@60sec.ca"" style=""color:#92400e; font-weight:800;"">support@60sec.ca</a>.", "<strong>You're not alone.</strong> Our support team is available by email at <a href=""mailto:support@60sec.ca"" style=""color:#92400e; font-weight:800;"">support@60sec.ca</a>.", "<strong>No está solo.</strong> Nuestro equipo de soporte está disponible por correo en <a href=""mailto:support@60sec.ca"" style=""color:#92400e; font-weight:800;"">support@60sec.ca</a>.")
            Case "resourcesTitle" : Return Choose3(lang, "📚 Ressources utiles", "📚 Useful resources", "📚 Recursos útiles")
            Case "helpCenter" : Return Choose3(lang, "Centre d'aide", "Help center", "Centro de ayuda")
            Case "videoTutorials" : Return Choose3(lang, "Tutoriels vidéo", "Video tutorials", "Tutoriales en video")
            Case "contactSupport" : Return Choose3(lang, "Contacter le support", "Contact support", "Contactar con soporte")

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
