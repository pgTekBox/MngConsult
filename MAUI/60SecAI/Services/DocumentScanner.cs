namespace _60SecAI.Services;

/// <summary>
/// Scanner de documents natif (Google ML Kit sur Android, VisionKit sur iOS).
/// Répliqué depuis prjTakePhoto — capture + recadrage automatique, renvoie un JPEG.
/// </summary>
public interface IDocumentScannerService
{
	Task<DocumentScanResult?> OpenDocumentScannerAsync();
}

public sealed class DocumentScanResult
{
	public List<Uri> Images { get; set; } = new();
}
