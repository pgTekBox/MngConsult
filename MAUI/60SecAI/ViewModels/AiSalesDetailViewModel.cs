using System.Collections.ObjectModel;
using System.Globalization;
using _60SecAI.Localization;
using _60SecAI.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace _60SecAI.ViewModels;

/// <summary>Élément de liste prêt à afficher (données déjà formatées + couleurs).</summary>
public record InvoiceListItem(
	int Id,
	string Number,
	string ClientName,
	string DateText,
	string AmountText,
	Color AmountColor,
	string Icon,
	Color RowBackground);

public partial class AiSalesDetailViewModel : BaseViewModel
{
	private static readonly CultureInfo FrCulture = CultureInfo.GetCultureInfo("fr-CA");

	private readonly SalesService _sales;
	private List<InvoiceDto> _all = [];

	public ObservableCollection<InvoiceListItem> Invoices { get; } = [];

	[ObservableProperty] private string _selectedStatus = "all";
	[ObservableProperty] private string _periodText = "Today";
	[ObservableProperty] private int _allCount;
	[ObservableProperty] private int _collectedCount;
	[ObservableProperty] private int _receivableCount;
	[ObservableProperty] private int _overdueCount;
	[ObservableProperty] private string _emptyText = "Aucune facture.";
	[ObservableProperty] private Color _allTabBg = Color.FromArgb("#EAF1FB");
	[ObservableProperty] private Color _collectedTabBg = Colors.Transparent;
	[ObservableProperty] private Color _receivableTabBg = Colors.Transparent;
	[ObservableProperty] private Color _overdueTabBg = Colors.Transparent;

	public AiSalesDetailViewModel(SalesService sales)
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
			_all = [.. await _sales.GetInvoicesAsync()];
			AllCount = _all.Count;
			CollectedCount = _all.Count(i => i.Status == "Collected");
			ReceivableCount = _all.Count(i => i.Status == "Receivable");
			OverdueCount = _all.Count(i => i.Status == "Overdue");
		}
		catch (Exception)
		{
			_all = [];
		}
		finally
		{
			IsBusy = false;
		}

		ApplyTab(SelectedStatus);
	}

	[RelayCommand]
	private void SelectTab(string status)
	{
		SelectedStatus = status;
		ApplyTab(status);
	}

	[RelayCommand]
	private void SelectPeriod(string period) => PeriodText = period;

	private void ApplyTab(string status)
	{
		AllTabBg = status == "all" ? Color.FromArgb("#EAF1FB") : Colors.Transparent;
		CollectedTabBg = status == "collected" ? Color.FromArgb("#E7F7EF") : Colors.Transparent;
		ReceivableTabBg = status == "receivable" ? Color.FromArgb("#FEF6E7") : Colors.Transparent;
		OverdueTabBg = status == "overdue" ? Color.FromArgb("#FDECEC") : Colors.Transparent;

		EmptyText = LocalizationResourceManager.Instance[status switch
		{
			"overdue" => "EmptyOverdue",
			"receivable" => "EmptyReceivable",
			"collected" => "EmptyCollected",
			_ => "EmptyInvoices",
		}];

		var enumName = status switch
		{
			"overdue" => "Overdue",
			"receivable" => "Receivable",
			"collected" => "Collected",
			_ => null, // "all"
		};

		var source = enumName is null ? _all : _all.Where(i => i.Status == enumName);

		Invoices.Clear();
		foreach (var inv in source)
		{
			var (color, background, icon) = StyleFor(inv.Status);
			Invoices.Add(new InvoiceListItem(
				inv.Id,
				string.IsNullOrWhiteSpace(inv.Number) ? $"#{inv.Id}" : inv.Number,
				inv.ClientName,
				inv.IssuedOn.ToString("yyyy-MM-dd", FrCulture),
				inv.Amount.ToString("N0", FrCulture) + " $",
				color,
				icon,
				background));
		}
	}

	[RelayCommand]
	private async Task OpenInvoice(int id)
	{
		if (id > 0)
		{
			await Shell.Current.GoToAsync($"InvoiceDetailPage?id={id}");
		}
	}

	/// <summary>Couleurs et icône propres au statut d'une facture.</summary>
	private static (Color Color, Color Background, string Icon) StyleFor(string enumName) => enumName switch
	{
		"Overdue" => (Color.FromArgb("#C0392B"), Color.FromArgb("#FDF1F1"), "⚠"),
		"Receivable" => (Color.FromArgb("#B9770E"), Color.FromArgb("#FEF9E7"), "↗"),
		_ => (Color.FromArgb("#1E8449"), Color.FromArgb("#F1FBF5"), "✓"),
	};
}
