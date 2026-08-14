using System.Globalization;

namespace _60SecAI;

public partial class NewInvoicePage : ContentPage
{
	private const decimal TpsRate = 0.05m;      // TPS 5 %
	private const decimal TvqRate = 0.09975m;   // TVQ 9,975 %

	private static readonly CultureInfo FrCulture = CultureInfo.GetCultureInfo("fr-CA");

	public NewInvoicePage()
	{
		InitializeComponent();
		Recalculate();
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

	private async void OnViewClientClicked(object? sender, EventArgs e)
		=> await DisplayAlertAsync("Facture", "Sélectionner un client.", "OK");

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
		=> await DisplayAlertAsync("Facture", "Facture enregistrée.", "OK");
}
