using System.Collections.ObjectModel;
using System.Globalization;
using _60SecAI.Localization;
using _60SecAI.Services;

namespace _60SecAI;

/// <summary>
/// Sélecteur de produit/service : recherche + création (nom + prix). Présenté en
/// modal ; renvoie le produit choisi (ou null si annulé) via PickAsync.
/// </summary>
public partial class ProductPickerPage : ContentPage
{
	/// <summary>Id sentinelle de l'item « Ligne libre » (saisie manuelle, hors catalogue).</summary>
	private const int CustomLineId = -1;

	/// <summary>Vrai si le produit renvoyé est l'item « Ligne libre ».</summary>
	public static bool IsCustomLine(ProductLookupDto? product) => product is { Id: CustomLineId };

	private readonly TaskCompletionSource<ProductLookupDto?> _tcs;
	private readonly Func<CancellationToken, Task<IReadOnlyList<ProductLookupDto>>> _loader;
	private readonly Func<string, decimal, Task<ProductLookupDto?>>? _creator;

	private List<ProductLookupDto> _all = [];
	private bool _loaded;
	private bool _closing;

	public ObservableCollection<ProductLookupDto> Items { get; } = [];

	private ProductPickerPage(
		Func<CancellationToken, Task<IReadOnlyList<ProductLookupDto>>> loader,
		Func<string, decimal, Task<ProductLookupDto?>>? creator,
		TaskCompletionSource<ProductLookupDto?> tcs)
	{
		InitializeComponent();
		_loader = loader;
		_creator = creator;
		_tcs = tcs;
		NewButton.IsVisible = creator is not null;
	}

	public static Task<ProductLookupDto?> PickAsync(
		INavigation nav,
		Func<CancellationToken, Task<IReadOnlyList<ProductLookupDto>>> loader,
		Func<string, decimal, Task<ProductLookupDto?>>? creator = null)
	{
		var tcs = new TaskCompletionSource<ProductLookupDto?>();
		nav.PushModalAsync(new ProductPickerPage(loader, creator, tcs));
		return tcs.Task;
	}

	protected override async void OnAppearing()
	{
		base.OnAppearing();
		if (_loaded)
		{
			return;
		}

		_loaded = true;
		try
		{
			_all = [.. await _loader(CancellationToken.None)];
		}
		catch (Exception)
		{
			_all = [];
		}

		ApplyFilter(Search.Text);
	}

	private void OnSearchChanged(object? sender, TextChangedEventArgs e) => ApplyFilter(e.NewTextValue);

	private void ApplyFilter(string? query)
	{
		var q = (query ?? string.Empty).Trim();
		IEnumerable<ProductLookupDto> source = _all;
		if (q.Length > 0)
		{
			source = _all.Where(p => (p.Name ?? string.Empty).Contains(q, StringComparison.OrdinalIgnoreCase));
		}

		Items.Clear();

		// « Ligne libre » toujours en tête : insère une ligne vide à remplir soi-même.
		Items.Add(new ProductLookupDto(CustomLineId, LocalizationResourceManager.Instance["CustomLine"], 0m));

		foreach (var p in source)
		{
			Items.Add(p);
		}
	}

	private void OnSelectionChanged(object? sender, SelectionChangedEventArgs e)
	{
		if (e.CurrentSelection.FirstOrDefault() is ProductLookupDto selected)
		{
			Close(selected);
		}
	}

	private async void OnNewClicked(object? sender, EventArgs e)
	{
		if (_creator is null)
		{
			return;
		}

		var loc = LocalizationResourceManager.Instance;

		var name = await DisplayPromptAsync(loc["NewProductTitle"], loc["NewProductNameMsg"], "OK", loc["Cancel"]);
		if (string.IsNullOrWhiteSpace(name))
		{
			return;
		}

		var priceText = await DisplayPromptAsync(loc["NewProductTitle"], loc["NewProductPriceMsg"], "OK", loc["Cancel"],
			initialValue: "0", keyboard: Keyboard.Numeric);
		if (priceText is null)
		{
			return;
		}

		var price = ParsePrice(priceText);

		try
		{
			var created = await _creator(name.Trim(), price);
			if (created is not null)
			{
				Close(created);
			}
			else
			{
				await DisplayAlertAsync("Produit", "Création du produit échouée.", "OK");
			}
		}
		catch (Exception ex)
		{
			await DisplayAlertAsync("Produit", ex.Message, "OK");
		}
	}

	private void OnCancel(object? sender, TappedEventArgs e) => Close(null);

	private static decimal ParsePrice(string? text)
	{
		if (string.IsNullOrWhiteSpace(text))
		{
			return 0m;
		}

		var normalized = text.Replace(',', '.');
		return decimal.TryParse(normalized, NumberStyles.Any, CultureInfo.InvariantCulture, out var value) ? value : 0m;
	}

	private async void Close(ProductLookupDto? result)
	{
		if (_closing)
		{
			return;
		}

		_closing = true;
		_tcs.TrySetResult(result);
		await Navigation.PopModalAsync();
	}
}
