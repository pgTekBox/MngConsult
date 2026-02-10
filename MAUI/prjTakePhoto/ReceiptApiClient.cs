using System.Net.Http.Headers;

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

        // "file" DOIT matcher le paramètre [FromForm] IFormFile file dans ton API
        form.Add(fileContent, "file", fileName);

        using var resp = await _http.PostAsync(url, form);
        var body = await resp.Content.ReadAsStringAsync();

        if (!resp.IsSuccessStatusCode)
            throw new HttpRequestException($"Upload failed: {(int)resp.StatusCode} {resp.ReasonPhrase}\n{body}");

        return body; // JSON retourné par ton API
    }
}
