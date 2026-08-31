using System.Net.Http.Json;
using System.Text.Json;

namespace _60SecAI.Services;

public class SalesService
{
	private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

	private readonly HttpClient _http;

	public SalesService(HttpClient http)
	{
		_http = http;
	}

	/// <summary>Résumé AI Sales (En retard / Collecté / À recevoir).</summary>
	public async Task<SalesSummaryDto?> GetSummaryAsync(CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<SalesSummaryDto>("api/sales/summary", JsonOptions, ct);

	/// <summary>Liste des factures, optionnellement filtrées par status.</summary>
	public async Task<IReadOnlyList<InvoiceDto>> GetInvoicesAsync(string? status = null, CancellationToken ct = default)
	{
		var url = string.IsNullOrWhiteSpace(status) ? "api/sales/invoices" : $"api/sales/invoices?status={status}";
		var invoices = await _http.GetFromJsonAsync<List<InvoiceDto>>(url, JsonOptions, ct);
		return invoices ?? [];
	}

	/// <summary>Détail d'une facture (en-tête + lignes).</summary>
	public async Task<InvoiceDetailDto?> GetInvoiceAsync(int id, CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<InvoiceDetailDto>($"api/sales/invoices/{id}", JsonOptions, ct);

	/// <summary>Liste des clients (pour le sélecteur de facture).</summary>
	public async Task<IReadOnlyList<ClientLookupDto>> GetClientsAsync(CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<List<ClientLookupDto>>("api/sales/customers", JsonOptions, ct) ?? [];

	/// <summary>Crée un client et renvoie sa fiche (Id/PartyGUID/DisplayName).</summary>
	public async Task<ClientLookupDto?> CreateClientAsync(string name, CancellationToken ct = default)
	{
		using var response = await _http.PostAsJsonAsync("api/sales/customers", new CreateClientRequest(name), JsonOptions, ct);
		response.EnsureSuccessStatusCode();
		return await response.Content.ReadFromJsonAsync<ClientLookupDto>(JsonOptions, ct);
	}

	/// <summary>Liste des produits/services.</summary>
	public async Task<IReadOnlyList<ProductLookupDto>> GetProductsAsync(CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<List<ProductLookupDto>>("api/sales/products", JsonOptions, ct) ?? [];

	/// <summary>Ajoute une photo à une facture (multipart). Renvoie true si OK.</summary>
	public async Task<bool> UploadInvoicePhotoAsync(int invoiceId, byte[] imageBytes, string fileName, string contentType, CancellationToken ct = default)
	{
		using var form = new MultipartFormDataContent();
		using var fileContent = new ByteArrayContent(imageBytes);
		fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(
			string.IsNullOrWhiteSpace(contentType) ? "image/jpeg" : contentType);
		form.Add(fileContent, "file", string.IsNullOrWhiteSpace(fileName) ? "photo.jpg" : fileName);

		using var response = await _http.PostAsync($"api/sales/invoices/{invoiceId}/photo", form, ct);
		return response.IsSuccessStatusCode;
	}

	/// <summary>Compte comptable par défaut d'une ligne de facture (numéro + nom).</summary>
	public async Task<AccountInfoDto?> GetDefaultAccountAsync(CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<AccountInfoDto>("api/sales/accounts/default", JsonOptions, ct);

	/// <summary>Nom du compte comptable à partir de son numéro (vide si introuvable).</summary>
	public async Task<string> GetAccountNameAsync(string noCompte, CancellationToken ct = default)
	{
		if (string.IsNullOrWhiteSpace(noCompte))
		{
			return string.Empty;
		}

		var info = await _http.GetFromJsonAsync<AccountInfoDto>($"api/sales/accounts/{Uri.EscapeDataString(noCompte)}", JsonOptions, ct);
		return info?.Name ?? string.Empty;
	}

	/// <summary>Liste des photos d'une facture (métadonnées + date de prise).</summary>
	public async Task<IReadOnlyList<InvoicePhotoDto>> GetInvoicePhotosAsync(int invoiceId, CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<List<InvoicePhotoDto>>($"api/sales/invoices/{invoiceId}/photos", JsonOptions, ct) ?? [];

	/// <summary>Télécharge le contenu binaire d'une photo (null si absente).</summary>
	public async Task<byte[]?> GetInvoicePhotoContentAsync(int invoiceId, int photoId, CancellationToken ct = default)
	{
		using var response = await _http.GetAsync($"api/sales/invoices/{invoiceId}/photos/{photoId}", ct);
		if (!response.IsSuccessStatusCode)
		{
			return null;
		}

		return await response.Content.ReadAsByteArrayAsync(ct);
	}

	/// <summary>Crée un produit/service et renvoie sa fiche (Id/Name/Price).</summary>
	public async Task<ProductLookupDto?> CreateProductAsync(string name, decimal price, CancellationToken ct = default)
	{
		using var response = await _http.PostAsJsonAsync("api/sales/products", new CreateProductRequest(name, price), JsonOptions, ct);
		response.EnsureSuccessStatusCode();
		return await response.Content.ReadFromJsonAsync<ProductLookupDto>(JsonOptions, ct);
	}

	/// <summary>Crée une facture brouillon. Renvoie l'Id créé (0 si échec).</summary>
	public async Task<int> CreateInvoiceAsync(CreateInvoiceRequest request, CancellationToken ct = default)
	{
		using var response = await _http.PostAsJsonAsync("api/sales/invoices", request, JsonOptions, ct);
		response.EnsureSuccessStatusCode();
		var result = await response.Content.ReadFromJsonAsync<CreateInvoiceResult>(JsonOptions, ct);
		return result?.Id ?? 0;
	}
}
