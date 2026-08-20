using _60SecAI.Services;

namespace _60SecAI;

public partial class ReceiptScanPage : ContentPage
{
	// Serveur de traitement OCR (identique à prjTakePhoto).
	private const string UploadUrl = "http://60sec.ai:7090/api/receipts/upload";

	private readonly ReceiptApiClient _api = new(new HttpClient());

	public ReceiptScanPage()
	{
		InitializeComponent();
	}

	private async void OnScanClicked(object? sender, EventArgs e)
	{
		lblStatus.Text = "Ouverture du scanner…";
		lblSize.Text = string.Empty;
		imgPreview.Source = null;

		var service = Handler?.MauiContext?.Services.GetService<IDocumentScannerService>();
		if (service is null)
		{
			lblStatus.Text = "Scanner non disponible sur cet appareil.";
			return;
		}

		var result = await service.OpenDocumentScannerAsync();
		if (result is null || result.Images.Count == 0)
		{
			lblStatus.Text = "Scan annulé ou aucun reçu détecté.";
			return;
		}

		// On prend la 1ère page (le reçu).
		var path = result.Images[0].LocalPath;
		if (!File.Exists(path))
		{
			lblStatus.Text = "Fichier scanné introuvable.";
			return;
		}

		var originalBytes = File.ReadAllBytes(path);
		imgPreview.Source = ImageSource.FromStream(() => new MemoryStream(originalBytes));

		lblStatus.Text = "Scan OK (cadrage automatique).";
		lblSize.Text = $"Taille : {FormatBytes(originalBytes.Length)}";

		try
		{
			lblStatus.Text = "Envoi au serveur…";

			var json = await _api.UploadReceiptAsync(
				UploadUrl,
				originalBytes,
				fileName: Path.GetFileName(path),
				contentType: "image/jpeg");

			lblStatus.Text = "Traitement terminé.";
			lblSize.Text = json; // réponse brute du serveur (JSON)
		}
		catch (Exception ex)
		{
			lblStatus.Text = "Erreur d'envoi.";
			lblSize.Text = ex.Message;
		}
	}

	private async void OnBackTapped(object? sender, TappedEventArgs e)
		=> await Shell.Current.GoToAsync("..");

	private static string FormatBytes(int bytes)
	{
		double b = bytes;
		string[] u = { "B", "KB", "MB", "GB" };
		int i = 0;
		while (b >= 1024 && i < u.Length - 1)
		{
			b /= 1024;
			i++;
		}

		return $"{b:0.##} {u[i]}";
	}
}
