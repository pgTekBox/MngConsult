using System.Collections.ObjectModel;
using System.Globalization;
using _60SecAI.Services;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace _60SecAI.ViewModels;

public record BilanLineItem(string Description, string AmountText);

public record ComptesClientItem(string Name, string AmountText, string BadgeText, Color BadgeBg, Color BadgeFg);

public record ComptesSupplierItem(string Name, string DueText, string AmountText);

public partial class FinancialReportViewModel : BaseViewModel
{
	private static readonly CultureInfo FrCulture = CultureInfo.GetCultureInfo("fr-CA");

	private readonly ReportService _reports;

	// ----- Bilan : lignes -----
	public ObservableCollection<BilanLineItem> ActifsCourantsLines { get; } = [];
	public ObservableCollection<BilanLineItem> ActifsLongTermeLines { get; } = [];
	public ObservableCollection<BilanLineItem> PassifsCourantsLines { get; } = [];
	public ObservableCollection<BilanLineItem> PassifsLongTermeLines { get; } = [];

	// ----- Bilan : totaux / équation -----
	[ObservableProperty] private string _sousTotalActifsCourantsText = "—";
	[ObservableProperty] private string _sousTotalActifsLongTermeText = "—";
	[ObservableProperty] private string _totalActifsText = "—";
	[ObservableProperty] private string _sousTotalPassifsCourantsText = "—";
	[ObservableProperty] private string _sousTotalPassifsLongTermeText = "—";
	[ObservableProperty] private string _totalPassifsText = "—";
	[ObservableProperty] private string _valeurNetteText = "—";
	[ObservableProperty] private string _totalPassifsPlusValeurNetteText = "—";
	[ObservableProperty] private string _passifsPctText = "—";
	[ObservableProperty] private string _valeurNettePctText = "—";

	// ----- Trésorerie -----
	public ObservableCollection<BilanLineItem> ExploitationLines { get; } = [];
	public ObservableCollection<BilanLineItem> InvestissementLines { get; } = [];
	public ObservableCollection<BilanLineItem> FinancementLines { get; } = [];

	[ObservableProperty] private string _totalExploitationText = "—";
	[ObservableProperty] private string _totalInvestissementText = "—";
	[ObservableProperty] private string _totalFinancementText = "—";
	[ObservableProperty] private string _fluxNetText = "—";

	// ----- Comptes -----
	public ObservableCollection<ComptesClientItem> ClientsLines { get; } = [];
	public ObservableCollection<ComptesSupplierItem> FournisseursLines { get; } = [];

	[ObservableProperty] private string _totalClientsText = "—";
	[ObservableProperty] private string _totalFournisseursText = "—";
	[ObservableProperty] private string _aging0Text = "—";
	[ObservableProperty] private string _aging1Text = "—";
	[ObservableProperty] private string _aging2Text = "—";
	[ObservableProperty] private string _overdueAmountText = "—";
	[ObservableProperty] private string _positionNetteText = "—";

	// ----- Taxes -----
	[ObservableProperty] private string _tpsPercueText = "—";
	[ObservableProperty] private string _tpsPayeeText = "—";
	[ObservableProperty] private string _tpsNetteText = "—";
	[ObservableProperty] private string _tvqPercueText = "—";
	[ObservableProperty] private string _tvqPayeeText = "—";
	[ObservableProperty] private string _tvqNetteText = "—";
	[ObservableProperty] private string _taxesCollecteText = "—";
	[ObservableProperty] private string _taxesPayeText = "—";
	[ObservableProperty] private string _taxesARemettreText = "—";

	[ObservableProperty] private string _revenusText = "—";
	[ObservableProperty] private string _depensesText = "—";
	[ObservableProperty] private string _beneficeNetText = "—";
	[ObservableProperty] private string _beneficeBrutText = "—";
	[ObservableProperty] private string _margeBrutePctText = "—";
	[ObservableProperty] private string _margeBrutePctOfRevenue = "—";
	[ObservableProperty] private string _tresorerieText = "—";
	[ObservableProperty] private string _aRecevoirText = "—";

	public FinancialReportViewModel(ReportService reports)
	{
		_reports = reports;
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
			var o = await _reports.GetOverviewAsync("month");
			if (o is not null)
			{
				RevenusText = Money(o.Revenus);
				DepensesText = Money(o.Depenses);
				BeneficeNetText = Money(o.BeneficeNet);
				BeneficeBrutText = Money(o.BeneficeBrut);
				MargeBrutePctText = Pct(o.MargeBrutePct);
				MargeBrutePctOfRevenue = Pct(o.MargeBrutePct) + " de vos revenus";
				TresorerieText = Money(o.Tresorerie);
				ARecevoirText = Money(o.ARecevoir);
			}

			var b = await _reports.GetBilanAsync();
			if (b is not null)
			{
				Fill(ActifsCourantsLines, b.ActifsCourants);
				Fill(ActifsLongTermeLines, b.ActifsLongTerme);
				Fill(PassifsCourantsLines, b.PassifsCourants);
				Fill(PassifsLongTermeLines, b.PassifsLongTerme);

				SousTotalActifsCourantsText = Money(b.ActifsCourants.Subtotal);
				SousTotalActifsLongTermeText = Money(b.ActifsLongTerme.Subtotal);
				TotalActifsText = Money(b.TotalActifs);
				SousTotalPassifsCourantsText = Money(b.PassifsCourants.Subtotal);
				SousTotalPassifsLongTermeText = Money(b.PassifsLongTerme.Subtotal);
				TotalPassifsText = Money(b.TotalPassifs);
				ValeurNetteText = Money(b.ValeurNette);
				TotalPassifsPlusValeurNetteText = Money(b.TotalPassifsPlusValeurNette);
				PassifsPctText = "Passifs " + b.PassifsPct.ToString("0", FrCulture) + " %";
				ValeurNettePctText = "Valeur nette " + b.ValeurNettePct.ToString("0", FrCulture) + " %";
			}

			var t = await _reports.GetTresorerieAsync("month");
			if (t is not null)
			{
				FillTreso(ExploitationLines, t.Exploitation);
				FillTreso(InvestissementLines, t.Investissement);
				FillTreso(FinancementLines, t.Financement);
				TotalExploitationText = Money(t.TotalExploitation);
				TotalInvestissementText = Money(t.TotalInvestissement);
				TotalFinancementText = Money(t.TotalFinancement);
				FluxNetText = Money(t.VariationNette);
			}

			var c = await _reports.GetComptesAsync();
			if (c is not null)
			{
				ClientsLines.Clear();
				foreach (var client in c.Clients)
				{
					var (bg, fg, text) = BadgeFor(client.Bucket);
					ClientsLines.Add(new ComptesClientItem(client.Name, Money(client.Amount), text, bg, fg));
				}

				FournisseursLines.Clear();
				foreach (var s in c.Fournisseurs)
				{
					var due = s.DueDate.HasValue
						? "Éch. " + s.DueDate.Value.ToDateTime(TimeOnly.MinValue).ToString("d MMMM yyyy", FrCulture)
						: string.Empty;
					FournisseursLines.Add(new ComptesSupplierItem(s.Name, due, Money(s.Amount)));
				}

				TotalClientsText = Money(c.TotalClients);
				TotalFournisseursText = Money(c.TotalFournisseurs);
				Aging0Text = Money(c.Aging0_30);
				Aging1Text = Money(c.Aging31_60);
				Aging2Text = Money(c.Aging90Plus);
				OverdueAmountText = Money(c.Aging90Plus);
				PositionNetteText = Money(c.TotalClients - c.TotalFournisseurs);
			}

			var tax = await _reports.GetTaxesAsync("month");
			if (tax is not null)
			{
				TpsPercueText = Money(tax.TpsPercue);
				TpsPayeeText = "− " + Money(tax.TpsPayee);
				TpsNetteText = Money(tax.TpsNette);
				TvqPercueText = Money(tax.TvqPercue);
				TvqPayeeText = "− " + Money(tax.TvqPayee);
				TvqNetteText = Money(tax.TvqNette);
				TaxesCollecteText = Money(tax.TotalCollecte);
				TaxesPayeText = Money(tax.TotalPaye);
				TaxesARemettreText = Money(tax.TotalARemettre);
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

	private static void Fill(ObservableCollection<BilanLineItem> target, BilanSectionDto section)
	{
		target.Clear();
		foreach (var line in section.Lines)
		{
			target.Add(new BilanLineItem(line.Description, Money(line.Amount)));
		}
	}

	private static void FillTreso(ObservableCollection<BilanLineItem> target, List<TresorerieLine> lines)
	{
		target.Clear();
		foreach (var line in lines)
		{
			target.Add(new BilanLineItem(line.Description, Money(line.Amount)));
		}
	}

	private static (Color Bg, Color Fg, string Text) BadgeFor(string bucket) => bucket switch
	{
		"31-60" => (Color.FromArgb("#FEF6E7"), Color.FromArgb("#B9770E"), "31-60 j."),
		"90+" => (Color.FromArgb("#FDECEC"), Color.FromArgb("#C0392B"), "+90 j."),
		_ => (Color.FromArgb("#E7F7EF"), Color.FromArgb("#1E8449"), "0-30 j."),
	};

	private static string Money(decimal value) => value.ToString("N2", FrCulture) + " $";

	private static string Pct(decimal value) => value.ToString("0.#", FrCulture) + " %";
}
