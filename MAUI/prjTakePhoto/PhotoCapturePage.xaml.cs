 

namespace prjTakePhoto;

public partial class PhotoCapturePage : ContentPage
{
    private byte[]? _finalBytes;
    private readonly ReceiptApiClient _api = new ReceiptApiClient(new HttpClient());
    public PhotoCapturePage()
    {
        InitializeComponent();
    }

    private async void OnScanClicked(object sender, EventArgs e)
    {
        lblStatus.Text = "Ouverture du scanner…";
        lblSize.Text = "";
        imgPreview.Source = null;
        _finalBytes = null;

        var service = Handler?.MauiContext?.Services.GetService<IDocumentScannerService>();
        if (service == null)
        {
            lblStatus.Text = "Scanner non disponible.";
            return;
        }

        var result = await service.OpenDocumentScannerAsync();
        if (result == null || result.Images.Count == 0)
        {
            lblStatus.Text = "Scan annulé ou aucun reçu détecté.";
            return;
        }

        // On prend la 1ère page (reçu)
        var path = result.Images[0].LocalPath;
        if (!File.Exists(path))
        {
            lblStatus.Text = "Fichier scanné introuvable.";
            return;
        }

        var originalBytes = File.ReadAllBytes(path);

      

        imgPreview.Source = ImageSource.FromStream(() => new MemoryStream(originalBytes));
        

        lblStatus.Text = "Scan OK v1 (cadrage automatique).";
        lblSize.Text = $"Taille finale: {FormatBytes(originalBytes.Length)}";

        try
        {
            lblStatus.Text = "Upload vers serveur...";

            // ⚠️ Android Emulator: "localhost" = le téléphone lui-même.
            // - Emulateur Android: utilise http://10.0.2.2:5000
            // - Device USB: utilise l'IP de ton PC (ex: http://192.168.1.25:5000)
            var url = "http://60sec.ai:7090/api/receipts/upload";

            var json = await _api.UploadReceiptAsync(
                url,
                originalBytes,
                fileName: Path.GetFileName(path),
                contentType: "image/jpeg"
            );

            lblStatus.Text = "Upload OK";
            lblSize.Text = json; // ou parse JSON
        }
        catch (Exception ex)
        {
            lblStatus.Text = "Erreur upload";
            lblSize.Text = ex.Message;
        }





    }

    private static string FormatBytes(int bytes)
    {
        double b = bytes;
        string[] u = { "B", "KB", "MB", "GB" };
        int i = 0;
        while (b >= 1024 && i < u.Length - 1) { b /= 1024; i++; }
        return $"{b:0.##} {u[i]}";
    }
}
