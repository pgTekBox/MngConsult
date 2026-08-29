using System.Collections.ObjectModel;
using _60SecAI.Localization;
using _60SecAI.Services;

namespace _60SecAI;

/// <summary>
/// Sélecteur de tiers (client ou fournisseur) : recherche dans la liste + bouton
/// « Nouveau client » (si un créateur est fourni). Présenté en modal ; renvoie
/// le tiers choisi (ou null si annulé) via PickAsync.
/// </summary>
public partial class ClientPickerPage : ContentPage
{
	private readonly TaskCompletionSource<ClientLookupDto?> _tcs;
	private readonly Func<CancellationToken, Task<IReadOnlyList<ClientLookupDto>>> _loader;
	private readonly Func<string, Task<ClientLookupDto?>>? _creator;

	private List<ClientLookupDto> _all = [];
	private bool _loaded;
	private bool _closing;

	public ObservableCollection<ClientLookupDto> Items { get; } = [];

	private ClientPickerPage(
		string title,
		Func<CancellationToken, Task<IReadOnlyList<ClientLookupDto>>> loader,
		Func<string, Task<ClientLookupDto?>>? creator,
		TaskCompletionSource<ClientLookupDto?> tcs)
	{
		InitializeComponent();
		_loader = loader;
		_creator = creator;
		_tcs = tcs;
		TitleLabel.Text = title;
		NewButton.IsVisible = creator is not null;
	}

	/// <summary>Ouvre le sélecteur en modal et renvoie le tiers choisi (ou null).</summary>
	public static Task<ClientLookupDto?> PickAsync(
		INavigation nav,
		string title,
		Func<CancellationToken, Task<IReadOnlyList<ClientLookupDto>>> loader,
		Func<string, Task<ClientLookupDto?>>? creator = null)
	{
		var tcs = new TaskCompletionSource<ClientLookupDto?>();
		var page = new ClientPickerPage(title, loader, creator, tcs);
		nav.PushModalAsync(page);
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
		IEnumerable<ClientLookupDto> source = _all;
		if (q.Length > 0)
		{
			source = _all.Where(c => (c.DisplayName ?? string.Empty).Contains(q, StringComparison.OrdinalIgnoreCase));
		}

		Items.Clear();
		foreach (var c in source)
		{
			Items.Add(c);
		}
	}

	private void OnSelectionChanged(object? sender, SelectionChangedEventArgs e)
	{
		if (e.CurrentSelection.FirstOrDefault() is ClientLookupDto selected)
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
		var name = await DisplayPromptAsync(loc["NewClientTitle"], loc["NewClientNameMsg"], "OK", loc["Cancel"]);
		if (string.IsNullOrWhiteSpace(name))
		{
			return;
		}

		try
		{
			var created = await _creator(name.Trim());
			if (created is not null)
			{
				Close(created);
			}
			else
			{
				await DisplayAlertAsync("Client", "Création du client échouée.", "OK");
			}
		}
		catch (Exception ex)
		{
			await DisplayAlertAsync("Client", ex.Message, "OK");
		}
	}

	private void OnCancel(object? sender, TappedEventArgs e) => Close(null);

	private async void Close(ClientLookupDto? result)
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
