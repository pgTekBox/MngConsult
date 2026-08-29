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

	public InvoiceLineItem(string placeholder)
	{
		_productLabel = placeholder;
	}
}
