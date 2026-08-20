using System.Globalization;
using _60SecAI.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace _60SecAI.ViewModels;

public partial class DashboardViewModel : BaseViewModel
{
	private static readonly CultureInfo FrCulture = CultureInfo.GetCultureInfo("fr-CA");

	private readonly SalesService _sales;

	[ObservableProperty]
	private string _overdueText = "0 $";

	[ObservableProperty]
	private string _collectedText = "0 $";

	[ObservableProperty]
	private string _receivableText = "0 $";

	public DashboardViewModel(SalesService sales)
	{
		_sales = sales;
	}

	[RelayCommand]
	private async Task LoadAsync()
	{
		if (IsBusy)
		{
			return;
		}

		IsBusy = true;

		try
		{
			var summary = await _sales.GetSummaryAsync();
			if (summary is not null)
			{
				OverdueText = Money(summary.Overdue);
				CollectedText = Money(summary.Collected);
				ReceivableText = Money(summary.Receivable);
			}
		}
		catch (Exception)
		{
			// API injoignable : on conserve les valeurs affichées.
		}
		finally
		{
			IsBusy = false;
		}
	}

	private static string Money(decimal value) => value.ToString("N0", FrCulture) + " $";
}
