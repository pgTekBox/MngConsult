using _60SecAI.Localization;
using _60SecAI.Services;

namespace _60SecAI;

public partial class ReceiptScanPage : ContentPage
{
	// Serveur de traitement OCR (identique à prjTakePhoto).
	private const string UploadUrl = "http://60sec.ai:7090/api/receipts/upload";

	private readonly ReceiptApiClient _api = new(new HttpClient());

	private static string L(string key) => LocalizationResourceManager.Instance[key];

	public ReceiptScanPage()
	{
		InitializeComponent();
	}

	private async void OnScanClicked(object? sender, EventArgs e)
	{
		lblStatus.TextColor = Color.FromArgb("#6B7280");
		lblStatus.Text = L("ScanOpening");
		lblSize.Text = string.Empty;
		imgPreview.Source = null;

		var service = Handler?.MauiContext?.Services.GetService<IDocumentScannerService>();
		if (service is null)
		{
			lblStatus.Text = L("ScanUnavailable");
			return;
		}

		var result = await service.OpenDocumentScannerAsync();
		if (result is null || result.Images.Count == 0)
		{
			lblStatus.Text = L("ScanCancelled");
			return;
		}

		// Aperçu de la 1re page.
		var firstPath = result.Images[0].LocalPath;
		if (File.Exists(firstPath))
		{
			var firstBytes = File.ReadAllBytes(firstPath);
			imgPreview.Source = ImageSource.FromStream(() => new MemoryStream(firstBytes));
		}

		try
		{
			lblStatus.Text = L("ScanUploading");

			// On envoie TOUS les reçus scannés (toutes les pages).
			var count = 0;
			foreach (var image in result.Images)
			{
				var p = image.LocalPath;
				if (!File.Exists(p))
				{
					continue;
				}

				var bytes = File.ReadAllBytes(p);
				await _api.UploadReceiptAsync(
					UploadUrl,
					bytes,
					fileName: Path.GetFileName(p),
					contentType: "image/jpeg");
				count++;
			}

			// Succès : message clair (pas le JSON brut) + bouton pour recommencer.
			lblStatus.Text = count > 1 ? string.Format(L("ReceiptsSavedCount"), count) : L("ReceiptSaved");
			lblStatus.TextColor = Color.FromArgb("#1E8449");
			lblSize.Text = string.Empty;
			ScanButton.Text = L("ScanAnotherReceipt");
		}
		catch (Exception ex)
		{
			lblStatus.Text = L("ScanUploadError");
			lblStatus.TextColor = Color.FromArgb("#C0392B");
			lblSize.Text = ex.Message;
		}
	}

	private async void OnBackTapped(object? sender, TappedEventArgs e)
		=> await Shell.Current.GoToAsync("..");
}
