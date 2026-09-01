using _60SecAI.Localization;
using _60SecAI.Services;
using _60SecAI.ViewModels;

namespace _60SecAI;

[QueryProperty(nameof(Status), "status")]
public partial class AiSalesDetailPage : ContentPage
{
	private readonly AiSalesDetailViewModel _vm;

	public AiSalesDetailPage()
	{
		InitializeComponent();
		_vm = ServiceHelper.GetService<AiSalesDetailViewModel>();
		BindingContext = _vm;
	}

	/// <summary>Statut passé lors de la navigation (collected / receivable / overdue).</summary>
	public string Status
	{
		get => _vm.SelectedStatus;
		set
		{
			if (!string.IsNullOrEmpty(value))
			{
				_vm.SelectedStatus = value;
			}
		}
	}

	protected override async void OnAppearing()
	{
		base.OnAppearing();
		await _vm.LoadCommand.ExecuteAsync(null);
	}

	private async void OnNewInvoiceClicked(object? sender, EventArgs e)
		=> await Shell.Current.GoToAsync(nameof(NewInvoicePage));

	/// <summary>Envoie la facture au client par courriel (PDF + lien Square optionnel).</summary>
	private async void OnSendInvoiceTapped(object? sender, TappedEventArgs e)
	{
		if ((sender as BindableObject)?.BindingContext is not InvoiceListItem invoice || invoice.Id <= 0)
		{
			return;
		}

		var loc = LocalizationResourceManager.Instance;
		var choice = await DisplayActionSheetAsync(loc["SendTitle"], loc["Cancel"], null,
			loc["SendWithout"], loc["SendWithSquare"], loc["GenLink"], loc["SendSms"]);

		if (choice == loc["SendWithout"])
		{
			await SendInvoiceEmailAsync(invoice.Id, false, loc);
		}
		else if (choice == loc["SendWithSquare"])
		{
			await SendInvoiceEmailAsync(invoice.Id, true, loc);
		}
		else if (choice == loc["GenLink"])
		{
			await GeneratePaymentLinkAsync(invoice.Id, sendSms: false, loc);
		}
		else if (choice == loc["SendSms"])
		{
			await GeneratePaymentLinkAsync(invoice.Id, sendSms: true, loc);
		}
	}

	/// <summary>Envoie la facture par courriel (avec ou sans lien Square).</summary>
	private async Task SendInvoiceEmailAsync(int invoiceId, bool includeSquare, LocalizationResourceManager loc)
	{
		try
		{
			var result = await ServiceHelper.GetService<SalesService>().SendInvoiceAsync(invoiceId, includeSquare);
			await DisplayAlertAsync(loc["SendTitle"], BuildSendMessage(result, loc), "OK");
		}
		catch (Exception ex)
		{
			await DisplayAlertAsync(loc["SendTitle"], ex.Message, "OK");
		}
	}

	/// <summary>Génère le lien de paiement Square, puis le copie (ou l'envoie par SMS).</summary>
	private async Task GeneratePaymentLinkAsync(int invoiceId, bool sendSms, LocalizationResourceManager loc)
	{
		try
		{
			var result = await ServiceHelper.GetService<SalesService>().CreatePaymentLinkAsync(invoiceId);
			if (result is null)
			{
				await DisplayAlertAsync(loc["SendTitle"], loc["SendFailed"], "OK");
				return;
			}

			if (result.Status != "Created" || string.IsNullOrWhiteSpace(result.Url))
			{
				var reason = result.Status switch
				{
					"AlreadyPaid" => loc["LinkAlreadyPaid"],
					"NotConnected" => loc["LinkNotConnected"],
					"NotFound" => loc["SendNotFound"],
					_ => loc["LinkFailed"],
				};
				await DisplayAlertAsync(loc["SendTitle"], reason, "OK");
				return;
			}

			if (sendSms)
			{
				var body = string.Format(loc["SmsBody"], result.DocNumber, result.Url);
				var message = string.IsNullOrWhiteSpace(result.Phone)
					? new SmsMessage(body, Array.Empty<string>())
					: new SmsMessage(body, new[] { result.Phone });
				await Sms.Default.ComposeAsync(message);
			}
			else
			{
				await Clipboard.Default.SetTextAsync(result.Url);
				await DisplayAlertAsync(loc["SendTitle"], string.Format(loc["LinkCopied"], result.Url), "OK");
			}
		}
		catch (FeatureNotSupportedException)
		{
			await DisplayAlertAsync(loc["SendTitle"], loc["SmsNotSupported"], "OK");
		}
		catch (Exception ex)
		{
			await DisplayAlertAsync(loc["SendTitle"], ex.Message, "OK");
		}
	}

	/// <summary>Construit le message localisé à partir du statut d'envoi renvoyé par l'API.</summary>
	private static string BuildSendMessage(SendInvoiceResult? result, LocalizationResourceManager loc)
	{
		if (result is null)
		{
			return loc["SendFailed"];
		}

		switch (result.Status)
		{
			case "Sent":
				var msg = string.Format(loc["SendSent"], result.DocNumber, result.Email);
				var note = result.SquareStatus switch
				{
					"AlreadyPaid" => loc["SqAlreadyPaid"],
					"NotConnected" => loc["SqNotConnected"],
					"NotGenerated" => loc["SqNotGenerated"],
					"Error" => loc["SqError"],
					_ => string.Empty,
				};
				return msg + note;
			case "NoEmail":
				return loc["SendNoEmail"];
			case "PdfFail":
				return loc["SendPdfFail"];
			default:
				return loc["SendNotFound"];
		}
	}

	/// <summary>Ouvre la liste des photos de la facture.</summary>
	private async void OnViewPhotosTapped(object? sender, TappedEventArgs e)
	{
		if ((sender as BindableObject)?.BindingContext is not InvoiceListItem invoice || invoice.Id <= 0)
		{
			return;
		}

		await InvoicePhotosPage.ShowAsync(Navigation, invoice.Id, invoice.Number);
	}

	/// <summary>Ajoute une photo (appareil photo ou galerie) à la facture.</summary>
	private async void OnAddPhotoTapped(object? sender, TappedEventArgs e)
	{
		if ((sender as BindableObject)?.BindingContext is not InvoiceListItem invoice || invoice.Id <= 0)
		{
			return;
		}

		var loc = LocalizationResourceManager.Instance;
		var choice = await DisplayActionSheetAsync(loc["PhotoTitle"], loc["Cancel"], null, loc["TakePhoto"], loc["FromGallery"]);

		var photos = new List<FileResult>();
		try
		{
			if (choice == loc["TakePhoto"])
			{
				if (!MediaPicker.Default.IsCaptureSupported)
				{
					await DisplayAlertAsync(loc["PhotoTitle"], "Appareil photo non disponible.", "OK");
					return;
				}

				var captured = await MediaPicker.Default.CapturePhotoAsync();
				if (captured is not null)
				{
					photos.Add(captured);
				}
			}
			else if (choice == loc["FromGallery"])
			{
				// Sélection multiple : plusieurs photos par facture.
				var picked = await MediaPicker.Default.PickPhotosAsync();
				if (picked is not null)
				{
					photos.AddRange(picked);
				}
			}
			else
			{
				return; // annulé
			}
		}
		catch (Exception ex)
		{
			await DisplayAlertAsync(loc["PhotoTitle"], ex.Message, "OK");
			return;
		}

		if (photos.Count == 0)
		{
			return;
		}

		try
		{
			var service = ServiceHelper.GetService<SalesService>();
			var uploaded = 0;
			foreach (var photo in photos)
			{
				using var stream = await photo.OpenReadAsync();
				using var ms = new MemoryStream();
				await stream.CopyToAsync(ms);
				var bytes = ms.ToArray();

				if (await service.UploadInvoicePhotoAsync(invoice.Id, bytes, photo.FileName, photo.ContentType ?? "image/jpeg"))
				{
					uploaded++;
				}
			}

			await DisplayAlertAsync(loc["PhotoTitle"], uploaded > 0 ? loc["PhotoAdded"] : loc["PhotoFailed"], "OK");
		}
		catch (Exception ex)
		{
			await DisplayAlertAsync(loc["PhotoTitle"], ex.Message, "OK");
		}
	}
}
