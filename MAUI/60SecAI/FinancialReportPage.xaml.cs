using _60SecAI.Services;
using _60SecAI.ViewModels;

namespace _60SecAI;

public partial class FinancialReportPage : ContentPage
{
	private readonly FinancialReportViewModel _vm;

	public FinancialReportPage()
	{
		InitializeComponent();
		_vm = ServiceHelper.GetService<FinancialReportViewModel>();
		BindingContext = _vm;
		SelectTab("Aperçu");
	}

	protected override async void OnAppearing()
	{
		base.OnAppearing();
		await _vm.LoadCommand.ExecuteAsync(null);
	}

	private void OnTabTapped(object? sender, TappedEventArgs e)
	{
		if (e.Parameter is string tab)
		{
			SelectTab(tab);
		}
	}

	private void SelectTab(string tab)
	{
		SetTab(TabApercu, TabApercuLabel, tab == "Aperçu");
		SetTab(TabResultats, TabResultatsLabel, tab == "Résultats");
		SetTab(TabBilan, TabBilanLabel, tab == "Bilan");
		SetTab(TabTresorerie, TabTresorerieLabel, tab == "Trésorerie");
		SetTab(TabTaxes, TabTaxesLabel, tab == "Taxes");
		SetTab(TabComptes, TabComptesLabel, tab == "Comptes");

		ApercuSection.IsVisible = tab == "Aperçu";
		ResultatsSection.IsVisible = tab == "Résultats";
		BilanSection.IsVisible = tab == "Bilan";
		TresorerieSection.IsVisible = tab == "Trésorerie";
		TaxesSection.IsVisible = tab == "Taxes";
		ComptesSection.IsVisible = tab == "Comptes";

		var isOther = tab is not ("Aperçu" or "Résultats" or "Bilan" or "Trésorerie" or "Taxes" or "Comptes");
		OtherSection.IsVisible = isOther;
		if (isOther)
		{
			OtherSectionLabel.Text = $"Section « {tab} » en construction.";
		}
	}

	private static void SetTab(Border border, Label label, bool selected)
	{
		border.BackgroundColor = selected ? Color.FromArgb("#3B5BDB") : Colors.Transparent;
		label.TextColor = selected ? Colors.White : Color.FromArgb("#6E6E6E");
		label.FontAttributes = selected ? FontAttributes.Bold : FontAttributes.None;
	}

	private void OnPeriodTapped(object? sender, TappedEventArgs e)
	{
		var period = e.Parameter as string ?? "Ce mois";

		SetPeriod(PeriodMois, PeriodMoisLabel, period == "Ce mois");
		SetPeriod(PeriodTrim, PeriodTrimLabel, period == "Trimestre");
		SetPeriod(PeriodAnnee, PeriodAnneeLabel, period == "Année");
	}

	private static void SetPeriod(Border border, Label label, bool selected)
	{
		if (selected)
		{
			border.BackgroundColor = Application.Current?.RequestedTheme == AppTheme.Dark
				? Color.FromArgb("#262138")
				: Color.FromArgb("#EEF0F4");
			label.TextColor = Application.Current?.RequestedTheme == AppTheme.Dark
				? Colors.White
				: Color.FromArgb("#1F1F1F");
			label.FontAttributes = FontAttributes.Bold;
		}
		else
		{
			border.BackgroundColor = Colors.Transparent;
			label.TextColor = Color.FromArgb("#6E6E6E");
			label.FontAttributes = FontAttributes.None;
		}
	}

	private async void OnExportTapped(object? sender, TappedEventArgs e)
		=> await DisplayAlertAsync("Rapports financiers", "Exporter le rapport.", "OK");
}
