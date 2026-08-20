using System.Globalization;
using _60SecAI.Localization;
using _60SecAI.Services;

namespace _60SecAI;

[QueryProperty(nameof(Kind), "kind")]
public partial class NewInvoicePage : ContentPage
{
	private const decimal TpsRate = 0.05m;      // TPS 5 %
	private const decimal TvqRate = 0.09975m;   // TVQ 9,975 %

	private static readonly CultureInfo FrCulture = CultureInfo.GetCultureInfo("fr-CA");

	private bool _saving;
	private bool _partiesLoaded;

	/// <summary>"supplier" = facture fournisseur, sinon facture client.</summary>
	public string Kind { get; set; } = "client";

	private bool IsSupplier => Kind == "supplier";

	public NewInvoicePage()
	{
		InitializeComponent();
		Recalculate();
	}

	protected override async void OnAppearing()
	{
		base.OnAppearing();

		ApplyKindLabels();

		if (_partiesLoaded)
		{
			return;
		}

		try
		{
			var parties = IsSupplier
				? await ServiceHelper.GetService<SupplierService>().GetSuppliersAsync()
				: await ServiceHelper.GetService<SalesService>().GetClientsAsync();
			ClientPicker.ItemsSource = parties.ToList();
			_partiesLoaded = true;
		}
		catch (Exception)
		{
			// API injoignable : le sélecteur reste vide.
		}
	}

	/// <summary>Ajuste le titre, le libellé et le sélecteur selon client / fournisseur.</summary>
	private void ApplyKindLabels()
	{
		var loc = LocalizationResourceManager.Instance;
		HeaderTitle.Text = IsSupplier ? loc["NewSupplierInvoice"] : loc["NewInvoice"];
		PartyLabel.Text = IsSupplier ? loc["SupplierLabel"] : loc["ClientLabel"];
		ClientPicker.Title = IsSupplier ? loc["ChooseSupplier"] : loc["ChooseClient"];
	}

	private static decimal ParseAmount(string? text)
	{
		if (string.IsNullOrWhiteSpace(text))
		{
			return 0m;
		}

		var normalized = text.Replace(',', '.');
		return decimal.TryParse(normalized, NumberStyles.Any, CultureInfo.InvariantCulture, out var value)
			? value
			: 0m;
	}

	private static string Money(decimal value)
		=> value.ToString("N2", FrCulture) + " $";

	private void OnAmountChanged(object? sender, TextChangedEventArgs e) => Recalculate();

	private void OnPaidChanged(object? sender, CheckedChangedEventArgs e) => Recalculate();

	private void Recalculate()
	{
		var qty = ParseAmount(QtyEntry.Text);
		var price = ParseAmount(PriceEntry.Text);

		var subTotal = qty * price;
		var tps = subTotal * TpsRate;
		var tvq = subTotal * TvqRate;
		var total = subTotal + tps + tvq;
		var paid = PaidCheck.IsChecked ? total : 0m;
		var due = total - paid;

		SubTotalLabel.Text = Money(subTotal);
		TpsLabel.Text = Money(tps);
		TvqLabel.Text = Money(tvq);
		TotalLabel.Text = Money(total);
		PaidLabel.Text = Money(paid);
		TotalDueLabel.Text = Money(due);
	}

	private async void OnBackTapped(object? sender, TappedEventArgs e)
		=> await Shell.Current.GoToAsync("..");

	private async void OnLineActionTapped(object? sender, TappedEventArgs e)
	{
		var action = e.Parameter as string ?? "";
		var message = action switch
		{
			"up" => "Monter la ligne.",
			"down" => "Descendre la ligne.",
			"discount" => "Ajouter un rabais.",
			"delete" => "Supprimer la ligne.",
			_ => "Action.",
		};
		await DisplayAlertAsync("Ligne", message, "OK");
	}

	private async void OnCreatePaymentTapped(object? sender, TappedEventArgs e)
		=> await DisplayAlertAsync("Facture", "Créer un nouveau paiement.", "OK");

	private async void OnSaveInvoiceClicked(object? sender, EventArgs e)
	{
		if (_saving)
		{
			return;
		}

		if (ClientPicker.SelectedItem is not ClientLookupDto client)
		{
			await DisplayAlertAsync("Facture", "Veuillez choisir un client.", "OK");
			return;
		}

		var qty = ParseAmount(QtyEntry.Text);
		var price = ParseAmount(PriceEntry.Text);
		if (qty <= 0m || price <= 0m)
		{
			await DisplayAlertAsync("Facture", "Veuillez saisir une quantité et un prix.", "OK");
			return;
		}

		var description = string.IsNullOrWhiteSpace(DescriptionEditor.Text)
			? "Facture"
			: DescriptionEditor.Text.Trim();

		var request = new CreateInvoiceRequest(
			client.PartyGUID,
			DateOnly.FromDateTime(BillDatePicker.Date ?? DateTime.Today),
			DateOnly.FromDateTime(DueDatePicker.Date ?? DateTime.Today),
			new List<CreateInvoiceLine>
			{
				new(description, qty, price)
			});

		_saving = true;
		try
		{
			var id = IsSupplier
				? await ServiceHelper.GetService<SupplierService>().CreateInvoiceAsync(request)
				: await ServiceHelper.GetService<SalesService>().CreateInvoiceAsync(request);
			if (id > 0)
			{
				await DisplayAlertAsync("Facture", $"Facture créée (n° {id}).", "OK");
				await Shell.Current.GoToAsync("..");
			}
			else
			{
				await DisplayAlertAsync("Facture", "La facture n'a pas pu être créée.", "OK");
			}
		}
		catch (Exception ex)
		{
			await DisplayAlertAsync("Facture", $"Erreur : {ex.Message}", "OK");
		}
		finally
		{
			_saving = false;
		}
	}
}
