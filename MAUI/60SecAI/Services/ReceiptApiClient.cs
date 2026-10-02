using System.Net.Http.Headers;

namespace _60SecAI.Services;

/// <summary>
/// Envoi d'un reçu (JPEG brut) à l'API 60SecAI, en multipart/form-data, champ « file ».
/// Le HttpClient est fourni par MauiProgram : il porte l'adresse de l'API et joint
/// le jeton de connexion, qui désigne la compagnie où le reçu est rangé.
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
