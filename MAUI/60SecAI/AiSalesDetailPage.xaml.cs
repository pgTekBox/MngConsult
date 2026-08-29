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
