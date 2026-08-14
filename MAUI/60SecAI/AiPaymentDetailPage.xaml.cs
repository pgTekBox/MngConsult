using _60SecAI.Services;
using _60SecAI.ViewModels;

namespace _60SecAI;

[QueryProperty(nameof(Filter), "filter")]
public partial class AiPaymentDetailPage : ContentPage
{
	private readonly AiPaymentDetailViewModel _vm;

	public AiPaymentDetailPage()
	{
		InitializeComponent();
		_vm = ServiceHelper.GetService<AiPaymentDetailViewModel>();
		BindingContext = _vm;
	}

	/// <summary>Catégorie passée lors de la navigation (Général / Institution / Gouvernement / Paie).</summary>
	public string Filter
	{
		get => _vm.SelectedCategory;
		set
		{
			if (!string.IsNullOrEmpty(value))
			{
				_vm.SelectedCategory = value;
			}
		}
	}

	protected override async void OnAppearing()
	{
		base.OnAppearing();
		await _vm.LoadCommand.ExecuteAsync(null);
	}
}
