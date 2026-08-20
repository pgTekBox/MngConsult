using _60SecAI.Services;
using _60SecAI.ViewModels;

namespace _60SecAI;

[QueryProperty(nameof(InvoiceId), "id")]
[QueryProperty(nameof(Kind), "kind")]
public partial class InvoiceDetailPage : ContentPage
{
	private readonly InvoiceDetailViewModel _vm;

	public InvoiceDetailPage()
	{
		InitializeComponent();
		_vm = ServiceHelper.GetService<InvoiceDetailViewModel>();
		BindingContext = _vm;
	}

	public int InvoiceId { get; set; }

	/// <summary>"supplier" pour une facture fournisseur ; vide/"client" sinon.</summary>
	public string Kind
	{
		get => _vm.Kind;
		set
		{
			if (!string.IsNullOrEmpty(value))
			{
				_vm.Kind = value;
			}
		}
	}

	protected override async void OnAppearing()
	{
		base.OnAppearing();
		await _vm.LoadCommand.ExecuteAsync(InvoiceId);
	}

	private async void OnBackTapped(object? sender, TappedEventArgs e)
		=> await Shell.Current.GoToAsync("..");
}
