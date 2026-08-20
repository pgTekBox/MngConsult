using System.Collections.ObjectModel;
using System.Globalization;
using _60SecAI.Localization;
using _60SecAI.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace _60SecAI.ViewModels;

/// <summary>
/// Liste des factures fournisseur — même présentation que les factures client
/// (AiSalesDetailViewModel), branchée sur SupplierService (s0023GetSuppliersInvoices).
/// Buckets : Collected = Payée, Receivable = À payer, Overdue = En retard.
/// </summary>
public partial class AiPaymentDetailViewModel : BaseViewModel
{
	private static readonly CultureInfo FrCulture = CultureInfo.GetCultureInfo("fr-CA");

	private readonly SupplierService _suppliers;
	private List<InvoiceDto> _all = [];

	public ObservableCollection<InvoiceListItem> Invoices { get; } = [];

	[ObservableProperty] private string _selectedStatus = "all";
	[ObservableProperty] private int _allCount;
	[ObservableProperty] private int _paidCount;
	[ObservableProperty] private int _toPayCount;
	[ObservableProperty] private int _overdueCount;
	[ObservableProperty] private string _emptyText = "Aucune facture.";
	[ObservableProperty] private Color _allTabBg = Color.FromArgb("#EAF1FB");
	[ObservableProperty] private Color _paidTabBg = Colors.Transparent;
	[ObservableProperty] private Color _toPayTabBg = Colors.Transparent;
	[ObservableProperty] private Color _overdueTabBg = Colors.Transparent;

	public AiPaymentDetailViewModel(SupplierService suppliers)
	{
		_suppliers = suppliers;
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
			_all = [.. await _suppliers.GetInvoicesAsync()];
			AllCount = _all.Count;
			PaidCount = _all.Count(i => i.Status == "Collected");
			ToPayCount = _all.Count(i => i.Status == "Receivable");
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

	private void ApplyTab(string status)
	{
		AllTabBg = status == "all" ? Color.FromArgb("#EAF1FB") : Colors.Transparent;
		PaidTabBg = status == "paid" ? Color.FromArgb("#E7F7EF") : Colors.Transparent;
		ToPayTabBg = status == "topay" ? Color.FromArgb("#FEF6E7") : Colors.Transparent;
		OverdueTabBg = status == "overdue" ? Color.FromArgb("#FDECEC") : Colors.Transparent;

		EmptyText = LocalizationResourceManager.Instance[status switch
		{
			"overdue" => "EmptyOverdue",
			"topay" => "EmptyReceivable",
			"paid" => "EmptyCollected",
			_ => "EmptyInvoices",
		}];

		var enumName = status switch
		{
			"overdue" => "Overdue",
			"topay" => "Receivable",
			"paid" => "Collected",
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
				inv.Amount.ToString("N2", FrCulture) + " $",
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
			await Shell.Current.GoToAsync($"InvoiceDetailPage?id={id}&kind=supplier");
		}
	}

	/// <summary>Couleurs et icône propres au statut d'une facture fournisseur.</summary>
	private static (Color Color, Color Background, string Icon) StyleFor(string enumName) => enumName switch
	{
		"Overdue" => (Color.FromArgb("#C0392B"), Color.FromArgb("#FDF1F1"), "⚠"),
		"Receivable" => (Color.FromArgb("#B9770E"), Color.FromArgb("#FEF9E7"), "↗"),
		_ => (Color.FromArgb("#1E8449"), Color.FromArgb("#F1FBF5"), "✓"),
	};
}
