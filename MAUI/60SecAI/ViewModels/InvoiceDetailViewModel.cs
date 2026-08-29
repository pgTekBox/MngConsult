using System.Collections.ObjectModel;
using System.Globalization;
using _60SecAI.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace _60SecAI.ViewModels;

public record InvoiceLineRow(string Description, string Qty, string UnitPrice, string Amount);

public partial class InvoiceDetailViewModel : BaseViewModel
{
	private static readonly CultureInfo FrCulture = CultureInfo.GetCultureInfo("fr-CA");

	private readonly SalesService _sales;
	private readonly SupplierService _suppliers;

	/// <summary>"supplier" = facture fournisseur, sinon facture client.</summary>
	public string Kind { get; set; } = "client";

	public ObservableCollection<InvoiceLineRow> Lines { get; } = [];

	[ObservableProperty] private string _number = "—";
	[ObservableProperty] private string _clientName = "—";
	[ObservableProperty] private string _clientAddress = string.Empty;
	[ObservableProperty] private string _issuedText = "—";
	[ObservableProperty] private string _dueText = "—";
	[ObservableProperty] private string _subTotalText = "—";
	[ObservableProperty] private string _tpsText = "—";
	[ObservableProperty] private string _tvqText = "—";
	[ObservableProperty] private string _totalText = "—";
	[ObservableProperty] private string _paidText = "—";
	[ObservableProperty] private string _balanceText = "—";
	[ObservableProperty] private string _note = string.Empty;
	[ObservableProperty] private bool _hasNote;
	[ObservableProperty] private bool _hasLocation;

	private double _latitude;
	private double _longitude;

	public InvoiceDetailViewModel(SalesService sales, SupplierService suppliers)
	{
		_sales = sales;
		_suppliers = suppliers;
	}

	[RelayCommand]
	public async Task LoadAsync(int id)
	{
		if (IsBusy || id <= 0)
		{
			return;
		}

		IsBusy = true;
		try
		{
			var inv = Kind == "supplier"
				? await _suppliers.GetInvoiceAsync(id)
				: await _sales.GetInvoiceAsync(id);
			if (inv is not null)
			{
				Number = string.IsNullOrWhiteSpace(inv.Number) ? $"#{inv.Id}" : inv.Number;
				ClientName = inv.ClientName;
				ClientAddress = inv.ClientAddress;
				IssuedText = inv.IssuedOn.ToString("yyyy-MM-dd", FrCulture);
				DueText = inv.DueOn.ToString("yyyy-MM-dd", FrCulture);
				SubTotalText = Money(inv.SubTotal);
				TpsText = Money(inv.Tps);
				TvqText = Money(inv.Tvq);
				TotalText = Money(inv.Total);
				PaidText = Money(inv.Paid);
				BalanceText = Money(inv.Balance);
				Note = inv.Note;
				HasNote = !string.IsNullOrWhiteSpace(inv.Note);

				HasLocation = inv.Latitude.HasValue && inv.Longitude.HasValue;
				_latitude = inv.Latitude ?? 0;
				_longitude = inv.Longitude ?? 0;

				Lines.Clear();
				foreach (var l in inv.Lines)
				{
					Lines.Add(new InvoiceLineRow(
						l.Description,
						l.Qty.ToString("0.##", FrCulture),
						Money(l.UnitPrice),
						Money(l.Amount)));
				}
			}
		}
		catch (Exception)
		{
			// API injoignable : on laisse les tirets.
		}
		finally
		{
			IsBusy = false;
		}
	}

	[RelayCommand]
	private async Task OpenMap()
	{
		if (!HasLocation)
		{
			return;
		}

		try
		{
			await Microsoft.Maui.ApplicationModel.Map.Default.OpenAsync(
				_latitude, _longitude,
				new Microsoft.Maui.ApplicationModel.MapLaunchOptions { Name = Number });
		}
		catch (Exception)
		{
			// Aucune app de carte disponible.
		}
	}

	private static string Money(decimal value) => value.ToString("N2", FrCulture) + " $";
}
