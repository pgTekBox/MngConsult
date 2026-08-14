using System.Globalization;

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

	public event EventHandler? FinancialReportClicked;
	public event EventHandler? BlackBoxClicked;

	public TopMenuView()
	{
		InitializeComponent();

		UpdateTitleLabel();
		UpdateSubtitleLabel();
		UpdateBalanceLabel();
	}

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
			? DateTime.Now.ToString("dddd d MMMM yyyy", FrCulture)
			: Subtitle;
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
}
