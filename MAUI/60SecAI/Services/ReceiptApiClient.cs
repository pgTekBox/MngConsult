using System.Net.Http.Headers;

namespace _60SecAI.Services;

/// <summary>
/// Envoi d'un reçu (JPEG brut) au serveur de traitement, en multipart/form-data.
/// Répliqué à l'identique depuis prjTakePhoto : champ « file », sans authentification.
/// Le serveur (60sec.ai:7090) fait l'OCR et renvoie le JSON.
/// </summary>
public sealed class ReceiptApiClient
{
	private readonly HttpClient _http;

	public ReceiptApiClient(HttpClient http)
	{
		_http = http;
		_http.Timeout = TimeSpan.FromSeconds(60);
	}

	public async Task<string> UploadReceiptAsync(string url, byte[] imageBytes, string fileName = "receipt.jpg", string contentType = "image/jpeg")
	{
		using var form = new MultipartFormDataContent();

		using var fileContent = new ByteArrayContent(imageBytes);
		fileContent.Headers.ContentType = new MediaTypeHeaderValue(contentType);

		// « file » DOIT correspondre au paramètre [FromForm] IFormFile file de l'API serveur.
		form.Add(fileContent, "file", fileName);

		using var resp = await _http.PostAsync(url, form);
		var body = await resp.Content.ReadAsStringAsync();

		if (!resp.IsSuccessStatusCode)
		{
			throw new HttpRequestException($"Upload failed: {(int)resp.StatusCode} {resp.ReasonPhrase}\n{body}");
		}

		return body; // JSON renvoyé par le serveur
	}
}
