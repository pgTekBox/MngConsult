using _60SecAI.Services;
using _60SecAI.ViewModels;

namespace _60SecAI;

[QueryProperty(nameof(Status), "status")]
public partial class AiSalesDetailPage : ContentPage
{
	private readonly AiSalesDetailViewModel _vm;

	public AiSalesDetailPage()
	{
		InitializeComponent();
		_vm = ServiceHelper.GetService<AiSalesDetailViewModel>();
		BindingContext = _vm;
	}

	/// <summary>Statut passé lors de la navigation (collected / receivable / overdue).</summary>
	public string Status
	{
		get => _vm.SelectedStatus;
		set
		{
			if (!string.IsNullOrEmpty(value))
			{
				_vm.SelectedStatus = value;
			}
		}
	}

	protected override async void OnAppearing()
	{
		base.OnAppearing();
		await _vm.LoadCommand.ExecuteAsync(null);
	}

	private async void OnNewInvoiceClicked(object? sender, EventArgs e)
		=> await Shell.Current.GoToAsync(nameof(NewInvoicePage));
}
