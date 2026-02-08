 

namespace prjTakePhoto;

public partial class PhotoCapturePage : ContentPage
{
    private byte[]? _finalBytes;

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

        // ✅ Option: réduire taille avec SkiaSharp (recommandé)
        // Si tu ne veux pas, commente les 2 lignes suivantes et utilise originalBytes.
        _finalBytes = ImageCompress.ResizeAndCompressJpeg(originalBytes, maxWidth: 1200, quality: 80);

        imgPreview.Source = ImageSource.FromStream(() => new MemoryStream(_finalBytes));
        lblStatus.Text = "Scan OK (cadrage automatique).";
        lblSize.Text = $"Taille finale: {FormatBytes(_finalBytes.Length)}";
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
