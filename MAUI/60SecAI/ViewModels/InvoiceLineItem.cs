using CommunityToolkit.Mvvm.ComponentModel;

namespace _60SecAI.ViewModels;

/// <summary>Une ligne de facture éditable (produit + quantité + prix).</summary>
public partial class InvoiceLineItem : ObservableObject
{
	[ObservableProperty] private string _productLabel;
	[ObservableProperty] private string _description = string.Empty;
	[ObservableProperty] private string _qtyText = "1";
	[ObservableProperty] private string _priceText = "0";
	[ObservableProperty] private string _amountText = "0,00 $";
	[ObservableProperty] private string _accountNumber = string.Empty;
	[ObservableProperty] private string _accountName = string.Empty;

	/// <summary>Vrai si un numéro de compte est associé (contrôle l'affichage).</summary>
	public bool HasAccount => !string.IsNullOrWhiteSpace(AccountNumber);

	/// <summary>« numéro · nom » affiché sous la description (numéro seul si nom inconnu).</summary>
	public string AccountLabel => !HasAccount
		? string.Empty
		: string.IsNullOrWhiteSpace(AccountName) ? AccountNumber : $"{AccountNumber} · {AccountName}";

	public InvoiceLineItem(string placeholder)
	{
		_productLabel = placeholder;
	}

	partial void OnAccountNumberChanged(string value)
	{
		OnPropertyChanged(nameof(HasAccount));
		OnPropertyChanged(nameof(AccountLabel));
	}

	partial void OnAccountNameChanged(string value) => OnPropertyChanged(nameof(AccountLabel));
}
