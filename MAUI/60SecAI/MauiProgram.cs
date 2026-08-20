using _60SecAI.Services;
using _60SecAI.ViewModels;
using Microsoft.Extensions.Logging;

namespace _60SecAI;

public static class MauiProgram
{
	public static MauiApp CreateMauiApp()
	{
		var builder = MauiApp.CreateBuilder();
		builder
			.UseMauiApp<App>()
			.ConfigureFonts(fonts =>
			{
				fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
				fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
			});

		// ----- Accès API -----
		var api = new ApiSettings();
		builder.Services.AddSingleton(api);
		builder.Services.AddSingleton<AuthTokenStore>();
		builder.Services.AddTransient<AuthHeaderHandler>();

		// AuthService : login (anonyme), pas d'en-tête Bearer.
		builder.Services.AddHttpClient<AuthService>(client =>
			client.BaseAddress = new Uri(api.BaseUrl));

		// Services protégés : ajoutent automatiquement le token Bearer.
		builder.Services.AddHttpClient<SalesService>(client =>
			client.BaseAddress = new Uri(api.BaseUrl))
			.AddHttpMessageHandler<AuthHeaderHandler>();

		builder.Services.AddHttpClient<PaymentService>(client =>
			client.BaseAddress = new Uri(api.BaseUrl))
			.AddHttpMessageHandler<AuthHeaderHandler>();

		builder.Services.AddHttpClient<SupplierService>(client =>
			client.BaseAddress = new Uri(api.BaseUrl))
			.AddHttpMessageHandler<AuthHeaderHandler>();

		builder.Services.AddHttpClient<ReportService>(client =>
			client.BaseAddress = new Uri(api.BaseUrl))
			.AddHttpMessageHandler<AuthHeaderHandler>();

		// ----- ViewModels (MVVM) -----
		builder.Services.AddTransient<LoginViewModel>();
		builder.Services.AddTransient<DashboardViewModel>();
		builder.Services.AddTransient<AiSalesDetailViewModel>();
		builder.Services.AddTransient<InvoiceDetailViewModel>();
		builder.Services.AddTransient<AiPaymentDetailViewModel>();
		builder.Services.AddTransient<SettingsViewModel>();
		builder.Services.AddTransient<FinancialReportViewModel>();

		// ----- Scanner de documents natif (reçus) -----
#if ANDROID
		builder.Services.AddSingleton<IDocumentScannerService, _60SecAI.Platforms.Android.DocumentScannerService>();
#elif IOS
		builder.Services.AddSingleton<IDocumentScannerService, _60SecAI.Platforms.iOS.DocumentScannerService>();
#endif

#if DEBUG
		builder.Logging.AddDebug();
#endif

		return builder.Build();
	}
}
