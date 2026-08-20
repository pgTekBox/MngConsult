using _60SecAI.Services;
using _60SecAI.ViewModels;

namespace _60SecAI;

public partial class AiPaymentDetailPage : ContentPage
{
	private readonly AiPaymentDetailViewModel _vm;

	public AiPaymentDetailPage()
	{
		InitializeComponent();
		_vm = ServiceHelper.GetService<AiPaymentDetailViewModel>();
		BindingContext = _vm;
	}

	protected override async void OnAppearing()
	{
		base.OnAppearing();
		await _vm.LoadCommand.ExecuteAsync(null);
	}

	private async void OnNewInvoiceClicked(object? sender, EventArgs e)
		=> await Shell.Current.GoToAsync($"{nameof(NewInvoicePage)}?kind=supplier");
}
