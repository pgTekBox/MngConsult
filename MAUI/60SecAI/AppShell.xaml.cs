namespace _60SecAI;

public partial class AppShell : Shell
{
	public AppShell()
	{
		InitializeComponent();

		Routing.RegisterRoute(nameof(DashboardPage), typeof(DashboardPage));
		Routing.RegisterRoute(nameof(AiSalesDetailPage), typeof(AiSalesDetailPage));
		Routing.RegisterRoute(nameof(InvoiceDetailPage), typeof(InvoiceDetailPage));
		Routing.RegisterRoute(nameof(AiPaymentDetailPage), typeof(AiPaymentDetailPage));
		Routing.RegisterRoute(nameof(AgendaDetailPage), typeof(AgendaDetailPage));
		Routing.RegisterRoute(nameof(FinancialReportPage), typeof(FinancialReportPage));
		Routing.RegisterRoute(nameof(NewInvoicePage), typeof(NewInvoicePage));
		Routing.RegisterRoute(nameof(NewAppointmentPage), typeof(NewAppointmentPage));
		Routing.RegisterRoute(nameof(BlackBoxPage), typeof(BlackBoxPage));
		Routing.RegisterRoute(nameof(ReceiptScanPage), typeof(ReceiptScanPage));
		Routing.RegisterRoute(nameof(SettingsPage), typeof(SettingsPage));
	}
}
