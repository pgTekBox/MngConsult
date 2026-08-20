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

	/// <summary>Crée une facture brouillon. Renvoie l'Id créé (0 si échec).</summary>
	public async Task<int> CreateInvoiceAsync(CreateInvoiceRequest request, CancellationToken ct = default)
	{
		using var response = await _http.PostAsJsonAsync("api/sales/invoices", request, JsonOptions, ct);
		response.EnsureSuccessStatusCode();
		var result = await response.Content.ReadFromJsonAsync<CreateInvoiceResult>(JsonOptions, ct);
		return result?.Id ?? 0;
	}
}
