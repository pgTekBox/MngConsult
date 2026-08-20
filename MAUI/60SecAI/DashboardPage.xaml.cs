using _60SecAI.Services;
using _60SecAI.ViewModels;

namespace _60SecAI;

public partial class DashboardPage : ContentPage
{
	private readonly DashboardViewModel _vm;

	public DashboardPage()
	{
		InitializeComponent();
		_vm = ServiceHelper.GetService<DashboardViewModel>();
		BindingContext = _vm;
	}

	protected override async void OnAppearing()
	{
		base.OnAppearing();
		await _vm.LoadCommand.ExecuteAsync(null);
	}

	// ===== AI Sales =====
	private async void OnNewInvoiceTapped(object? sender, TappedEventArgs e)
		=> await Shell.Current.GoToAsync(nameof(NewInvoicePage));

	private async void OnCollectTapped(object? sender, TappedEventArgs e)
		=> await DisplayAlertAsync("AI Sales", "Collecter les montants en retard.", "OK");

	private async void OnSalesStatusTapped(object? sender, TappedEventArgs e)
	{
		var status = e.Parameter as string ?? "collected";
		await Shell.Current.GoToAsync($"{nameof(AiSalesDetailPage)}?status={status}");
	}

	// ===== AI Payment =====
	private async void OnReceiptTapped(object? sender, TappedEventArgs e)
		=> await Shell.Current.GoToAsync(nameof(ReceiptScanPage));

	private async void OnPaymentCategoryTapped(object? sender, TappedEventArgs e)
		=> await Shell.Current.GoToAsync(nameof(AiPaymentDetailPage));

	// ===== Agenda =====
	private async void OnAddAppointmentTapped(object? sender, TappedEventArgs e)
		=> await Shell.Current.GoToAsync(nameof(NewAppointmentPage));

	private async void OnAgendaTapped(object? sender, TappedEventArgs e)
		=> await Shell.Current.GoToAsync(nameof(AgendaDetailPage));
}
