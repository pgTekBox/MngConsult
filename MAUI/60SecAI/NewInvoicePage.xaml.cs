using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Globalization;
using _60SecAI.Localization;
using _60SecAI.Services;
using _60SecAI.ViewModels;

namespace _60SecAI;

[QueryProperty(nameof(Kind), "kind")]
public partial class NewInvoicePage : ContentPage
{
	private const decimal TpsRate = 0.05m;      // TPS 5 %
	private const decimal TvqRate = 0.09975m;   // TVQ 9,975 %

	private static readonly CultureInfo FrCulture = CultureInfo.GetCultureInfo("fr-CA");

	private bool _saving;
	private ClientLookupDto? _selectedParty;
	private AccountInfoDto? _defaultAccount;

	/// <summary>Lignes de la facture (produit + quantité + prix).</summary>
	public ObservableCollection<InvoiceLineItem> Lines { get; } = [];

	/// <summary>"supplier" = facture fournisseur, sinon facture client.</summary>
	public string Kind { get; set; } = "client";

	private bool IsSupplier => Kind == "supplier";

	public NewInvoicePage()
	{
		InitializeComponent();

		// Dates vides au depart : l'utilisateur doit les choisir (obligatoires).
		BillDatePicker.Date = null;
		DueDatePicker.Date = null;

		AddLine();
		Recalculate();
	}

	protected override async void OnAppearing()
	{
		base.OnAppearing();
		ApplyKindLabels();
		await EnsureDefaultAccountAsync();
	}

	/// <summary>Charge le compte par défaut et l'associe aux lignes qui n'en ont pas encore.</summary>
	private async Task EnsureDefaultAccountAsync()
	{
		// Le compte par défaut (« VP ») ne s'applique qu'aux factures client.
		if (IsSupplier || _defaultAccount is not null)
		{
			return;
		}

		try
		{
			_defaultAccount = await ServiceHelper.GetService<SalesService>().GetDefaultAccountAsync();
		}
		catch (Exception)
		{
			_defaultAccount = null;
		}

		if (_defaultAccount is { } d && !string.IsNullOrWhiteSpace(d.Number))
		{
			foreach (var line in Lines)
			{
				if (!line.HasAccount)
				{
					line.AccountNumber = d.Number;
					line.AccountName = d.Name;
				}
			}
		}
	}

	/// <summary>Ajuste le titre et les libellés selon client / fournisseur.</summary>
	private void ApplyKindLabels()
	{
		var loc = LocalizationResourceManager.Instance;
		HeaderTitle.Text = IsSupplier ? loc["NewSupplierInvoice"] : loc["NewInvoice"];
		PartyLabel.Text = IsSupplier ? loc["SupplierLabel"] : loc["ClientLabel"];
		if (_selectedParty is null)
		{
			ClientValueLabel.Text = IsSupplier ? loc["ChooseSupplier"] : loc["ChooseClient"];
		}
	}

	/// <summary>Ouvre le sélecteur de client/fournisseur (recherche + « Nouveau client »).</summary>
	private async void OnPickPartyTapped(object? sender, TappedEventArgs e)
	{
		var loc = LocalizationResourceManager.Instance;
		ClientLookupDto? picked;

		if (IsSupplier)
		{
			var supplier = ServiceHelper.GetService<SupplierService>();
			picked = await ClientPickerPage.PickAsync(
				Navigation,
				loc["ChooseSupplier"],
				ct => supplier.GetSuppliersAsync(ct));
		}
		else
		{
			var sales = ServiceHelper.GetService<SalesService>();
			picked = await ClientPickerPage.PickAsync(
				Navigation,
				loc["ChooseClient"],
				ct => sales.GetClientsAsync(ct),
				name => sales.CreateClientAsync(name));
		}

		if (picked is not null)
		{
			_selectedParty = picked;
			ClientValueLabel.Text = picked.DisplayName;
		}
	}

	// ---------- Lignes ----------

	/// <summary>Ajoute une ligne et ouvre le catalogue (dont l'item « Ligne libre »).</summary>
	private async void OnAddLineClicked(object? sender, EventArgs e)
	{
		var item = AddLine();
		await PickProductForLine(item);
	}

	private InvoiceLineItem AddLine()
	{
		var item = new InvoiceLineItem(LocalizationResourceManager.Instance["ChooseProduct"]);

		// Chaque ligne est associée à un compte : par défaut le compte de ventes.
		if (_defaultAccount is { } d && !string.IsNullOrWhiteSpace(d.Number))
		{
			item.AccountNumber = d.Number;
			item.AccountName = d.Name;
		}

		item.PropertyChanged += OnLinePropertyChanged;
		Lines.Add(item);
		return item;
	}

	private void OnLineDeleteTapped(object? sender, TappedEventArgs e)
	{
		if (LineFrom(sender) is not { } item)
		{
			return;
		}

		item.PropertyChanged -= OnLinePropertyChanged;
		Lines.Remove(item);

		if (Lines.Count == 0)
		{
			AddLine();
		}

		Recalculate();
	}

	private async void OnLineProductTapped(object? sender, TappedEventArgs e)
	{
		if (LineFrom(sender) is { } item)
		{
			await PickProductForLine(item);
		}
	}

	/// <summary>Affiche le nom du compte comptable de la ligne dans une petite fenêtre.</summary>
	private async void OnLineAccountTapped(object? sender, TappedEventArgs e)
	{
		if (LineFrom(sender) is not { } item || string.IsNullOrWhiteSpace(item.AccountNumber))
		{
			return;
		}

		var loc = LocalizationResourceManager.Instance;
		var name = string.IsNullOrWhiteSpace(item.AccountName)
			? await ServiceHelper.GetService<SalesService>().GetAccountNameAsync(item.AccountNumber)
			: item.AccountName;
		await DisplayAlertAsync(item.AccountNumber, string.IsNullOrWhiteSpace(name) ? loc["AccountNameUnavailable"] : name, "OK");
	}

	private async Task PickProductForLine(InvoiceLineItem item)
	{
		var sales = ServiceHelper.GetService<SalesService>();
		var product = await ProductPickerPage.PickAsync(
			Navigation,
			ct => sales.GetProductsAsync(ct),
			(name, price) => sales.CreateProductAsync(name, price));

		if (product is null)
		{
			return;
		}

		// « Ligne libre » : description à saisir, mais on associe le compte par défaut (facture client).
		if (ProductPickerPage.IsCustomLine(product))
		{
			if (!IsSupplier)
			{
				await ApplyAccountAsync(item, _defaultAccount?.Number);
			}

			return;
		}

		item.Description = product.Name;
		item.ProductLabel = product.Name;
		item.PriceText = product.Price.ToString("0.##", CultureInfo.InvariantCulture);
		if (!IsSupplier)
		{
			await ApplyAccountAsync(item, product.AccountNumber);
		}
		if (ParseAmount(item.QtyText) <= 0m)
		{
			item.QtyText = "1";
		}

		UpdateLineAmount(item);
		Recalculate();
	}

	/// <summary>Associe un compte à la ligne (celui fourni, sinon le compte par défaut) et résout son nom.</summary>
	private async Task ApplyAccountAsync(InvoiceLineItem item, string? number)
	{
		var acct = string.IsNullOrWhiteSpace(number) ? _defaultAccount?.Number : number;
		if (string.IsNullOrWhiteSpace(acct))
		{
			return; // aucun compte disponible
		}

		item.AccountNumber = acct;
		item.AccountName = await ResolveAccountNameAsync(acct);
	}

	/// <summary>Nom du compte : depuis le cache du compte par défaut, sinon via l'API.</summary>
	private async Task<string> ResolveAccountNameAsync(string number)
	{
		if (_defaultAccount is { } d && string.Equals(d.Number, number, StringComparison.OrdinalIgnoreCase))
		{
			return d.Name;
		}

		return await ServiceHelper.GetService<SalesService>().GetAccountNameAsync(number);
	}

	private void OnLinePropertyChanged(object? sender, PropertyChangedEventArgs e)
	{
		if (sender is not InvoiceLineItem item)
		{
			return;
		}

		if (e.PropertyName is nameof(InvoiceLineItem.QtyText) or nameof(InvoiceLineItem.PriceText))
		{
			UpdateLineAmount(item);
			Recalculate();
		}
	}

	private static void UpdateLineAmount(InvoiceLineItem item)
	{
		var amount = ParseAmount(item.QtyText) * ParseAmount(item.PriceText);
		item.AmountText = Money(amount);
	}

	private InvoiceLineItem? LineFrom(object? sender) => (sender as BindableObject)?.BindingContext as InvoiceLineItem;

	// ---------- Totaux ----------

	private void OnPaidChanged(object? sender, CheckedChangedEventArgs e) => Recalculate();

	private void Recalculate()
	{
		var subTotal = 0m;
		foreach (var item in Lines)
		{
			subTotal += ParseAmount(item.QtyText) * ParseAmount(item.PriceText);
		}

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

	private static string Money(decimal value) => value.ToString("N2", FrCulture) + " $";

	// ---------- Navigation / actions ----------

	private async void OnBackTapped(object? sender, TappedEventArgs e)
		=> await Shell.Current.GoToAsync("..");

	private async void OnCreatePaymentTapped(object? sender, TappedEventArgs e)
		=> await DisplayAlertAsync("Facture", "Créer un nouveau paiement.", "OK");

	/// <summary>Récupère la position GPS (best-effort) pour l'enregistrer avec la facture.</summary>
	private static async Task<(double? Latitude, double? Longitude)> TryGetLocationAsync()
	{
		try
		{
			var status = await Permissions.RequestAsync<Permissions.LocationWhenInUse>();
			if (status != PermissionStatus.Granted)
			{
				return (null, null);
			}

			var location = await Geolocation.Default.GetLocationAsync(
				new GeolocationRequest(GeolocationAccuracy.Medium, TimeSpan.FromSeconds(10)));

			location ??= await Geolocation.Default.GetLastKnownLocationAsync();

			return location is null ? (null, null) : (location.Latitude, location.Longitude);
		}
		catch (Exception)
		{
			// Permission refusée, GPS off, ou timeout : on enregistre sans position.
			return (null, null);
		}
	}

	private async void OnSaveInvoiceClicked(object? sender, EventArgs e)
	{
		if (_saving)
		{
			return;
		}

		var loc = LocalizationResourceManager.Instance;

		if (_selectedParty is not { } client)
		{
			await DisplayAlertAsync("Facture", loc[IsSupplier ? "SupplierRequiredMsg" : "ClientRequiredMsg"], "OK");
			return;
		}

		if (BillDatePicker.Date is null)
		{
			await DisplayAlertAsync("Facture", loc["BillDateRequired"], "OK");
			return;
		}

		if (DueDatePicker.Date is null)
		{
			await DisplayAlertAsync("Facture", loc["DueDateRequired"], "OK");
			return;
		}

		var lines = new List<CreateInvoiceLine>();
		foreach (var item in Lines)
		{
			var qty = ParseAmount(item.QtyText);
			var price = ParseAmount(item.PriceText);
			if (qty > 0m && price > 0m && !string.IsNullOrWhiteSpace(item.Description))
			{
				lines.Add(new CreateInvoiceLine(
					item.Description.Trim(), qty, price,
					AccountNumber: string.IsNullOrWhiteSpace(item.AccountNumber) ? null : item.AccountNumber.Trim()));
			}
		}

		if (lines.Count == 0)
		{
			await DisplayAlertAsync("Facture", "Ajoutez au moins une ligne (produit, quantité et prix).", "OK");
			return;
		}

		var (lat, lng) = await TryGetLocationAsync();

		var request = new CreateInvoiceRequest(
			client.PartyGUID,
			DateOnly.FromDateTime(BillDatePicker.Date.Value),
			DateOnly.FromDateTime(DueDatePicker.Date.Value),
			lines,
			lat,
			lng);

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
