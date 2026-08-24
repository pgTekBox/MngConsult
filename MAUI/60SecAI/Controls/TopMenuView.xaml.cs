using System.ComponentModel;
using System.Globalization;
using _60SecAI.Localization;

namespace _60SecAI.Controls;

public partial class TopMenuView : ContentView
{
	private static readonly CultureInfo FrCulture = CultureInfo.GetCultureInfo("fr-CA");

	public static readonly BindableProperty PageTitleProperty =
		BindableProperty.Create(
			nameof(PageTitle),
			typeof(string),
			typeof(TopMenuView),
			"Dashboard 60SecAi",
			propertyChanged: OnPageTitleChanged);

	public static readonly BindableProperty SubtitleProperty =
		BindableProperty.Create(
			nameof(Subtitle),
			typeof(string),
			typeof(TopMenuView),
			null,
			propertyChanged: OnSubtitleChanged);

	public static readonly BindableProperty BalanceProperty =
		BindableProperty.Create(
			nameof(Balance),
			typeof(decimal),
			typeof(TopMenuView),
			0m,
			propertyChanged: OnBalanceChanged);

	public static readonly BindableProperty ShowHomeProperty =
		BindableProperty.Create(
			nameof(ShowHome),
			typeof(bool),
			typeof(TopMenuView),
			false,
			propertyChanged: OnShowHomeChanged);

	public string PageTitle
	{
		get => (string)GetValue(PageTitleProperty);
		set => SetValue(PageTitleProperty, value);
	}

	/// <summary>Ligne sous le titre. Si vide, la date du jour est affichée.</summary>
	public string? Subtitle
	{
		get => (string?)GetValue(SubtitleProperty);
		set => SetValue(SubtitleProperty, value);
	}

	public decimal Balance
	{
		get => (decimal)GetValue(BalanceProperty);
		set => SetValue(BalanceProperty, value);
	}

	/// <summary>Affiche le bouton accueil (retour au dashboard). Faux par défaut.</summary>
	public bool ShowHome
	{
		get => (bool)GetValue(ShowHomeProperty);
		set => SetValue(ShowHomeProperty, value);
	}

	public event EventHandler? FinancialReportClicked;
	public event EventHandler? BlackBoxClicked;

	public TopMenuView()
	{
		InitializeComponent();

		Loaded += OnLoaded;
		Unloaded += OnUnloaded;

		UpdateTitleLabel();
		UpdateSubtitleLabel();
		UpdateBalanceLabel();
	}

	private void OnLoaded(object? sender, EventArgs e)
	{
		LocalizationResourceManager.Instance.PropertyChanged += OnLanguageChanged;
		UpdateSubtitleLabel();
	}

	private void OnUnloaded(object? sender, EventArgs e)
	{
		LocalizationResourceManager.Instance.PropertyChanged -= OnLanguageChanged;
	}

	private void OnLanguageChanged(object? sender, PropertyChangedEventArgs e)
		=> UpdateSubtitleLabel();

	private static void OnPageTitleChanged(BindableObject bindable, object oldValue, object newValue)
	{
		if (bindable is TopMenuView view)
		{
			view.UpdateTitleLabel();
		}
	}

	private static void OnSubtitleChanged(BindableObject bindable, object oldValue, object newValue)
	{
		if (bindable is TopMenuView view)
		{
			view.UpdateSubtitleLabel();
		}
	}

	private void UpdateTitleLabel()
	{
		TitleLabel.Text = string.IsNullOrWhiteSpace(PageTitle) ? "60SecAi" : PageTitle;
	}

	private void UpdateSubtitleLabel()
	{
		DateLabel.Text = string.IsNullOrWhiteSpace(Subtitle)
			? FormatToday()
			: Subtitle;
	}

	/// <summary>Date du jour formatée selon la langue courante.</summary>
	private static string FormatToday()
	{
		var (culture, pattern) = LocalizationResourceManager.Instance.CurrentLanguage switch
		{
			"en" => (CultureInfo.GetCultureInfo("en-CA"), "dddd, MMMM d, yyyy"),
			"es" => (CultureInfo.GetCultureInfo("es-ES"), "dddd d 'de' MMMM 'de' yyyy"),
			_ => (FrCulture, "dddd d MMMM yyyy"),
		};

		return DateTime.Now.ToString(pattern, culture);
	}

	private static void OnBalanceChanged(BindableObject bindable, object oldValue, object newValue)
	{
		if (bindable is TopMenuView view)
		{
			view.UpdateBalanceLabel();
		}
	}

	private void UpdateBalanceLabel()
	{
		BalanceLabel.Text = Balance.ToString("N2", FrCulture) + " $";
	}

	private async void OnFinancialReportTapped(object? sender, TappedEventArgs e)
	{
		FinancialReportClicked?.Invoke(this, EventArgs.Empty);

		if (Shell.Current is not null)
		{
			await Shell.Current.GoToAsync("FinancialReportPage");
		}
	}

	private async void OnBlackBoxTapped(object? sender, TappedEventArgs e)
	{
		BlackBoxClicked?.Invoke(this, EventArgs.Empty);

		if (Shell.Current is not null)
		{
			await Shell.Current.GoToAsync("BlackBoxPage");
		}
	}

	private async void OnSettingsTapped(object? sender, TappedEventArgs e)
	{
		if (Shell.Current is not null)
		{
			await Shell.Current.GoToAsync("SettingsPage");
		}
	}

	private static void OnShowHomeChanged(BindableObject bindable, object oldValue, object newValue)
	{
		if (bindable is TopMenuView view)
		{
			view.HomeButton.IsVisible = view.ShowHome;
		}
	}

	private async void OnHomeTapped(object? sender, TappedEventArgs e)
	{
		var shell = Shell.Current;
		if (shell is null)
		{
			return;
		}

		// Remonter jusqu'au Dashboard, quelle que soit la profondeur.
		var stack = shell.Navigation.NavigationStack;
		var dashIndex = -1;
		for (var i = 0; i < stack.Count; i++)
		{
			if (stack[i] is _60SecAI.DashboardPage)
			{
				dashIndex = i;
				break;
			}
		}

		if (dashIndex < 0)
		{
			await shell.GoToAsync(nameof(_60SecAI.DashboardPage));
			return;
		}

		var popCount = stack.Count - 1 - dashIndex;
		if (popCount <= 0)
		{
			return; // déjà sur le Dashboard
		}

		var route = string.Empty;
		for (var i = 0; i < popCount; i++)
		{
			route += "../";
		}

		await shell.GoToAsync(route);
	}
}
