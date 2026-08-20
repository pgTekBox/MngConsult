using System.Net.Http.Json;
using System.Text.Json;

namespace _60SecAI.Services;

/// <summary>Factures fournisseur — même contrat que SalesService, endpoints api/suppliers.</summary>
public class SupplierService
{
	private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

	private readonly HttpClient _http;

	public SupplierService(HttpClient http)
	{
		_http = http;
	}

	/// <summary>Résumé fournisseur (Payé / En retard / À payer).</summary>
	public async Task<SalesSummaryDto?> GetSummaryAsync(CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<SalesSummaryDto>("api/suppliers/summary", JsonOptions, ct);

	/// <summary>Liste des factures fournisseur, optionnellement filtrées par status.</summary>
	public async Task<IReadOnlyList<InvoiceDto>> GetInvoicesAsync(string? status = null, CancellationToken ct = default)
	{
		var url = string.IsNullOrWhiteSpace(status) ? "api/suppliers/invoices" : $"api/suppliers/invoices?status={status}";
		var invoices = await _http.GetFromJsonAsync<List<InvoiceDto>>(url, JsonOptions, ct);
		return invoices ?? [];
	}

	/// <summary>Détail d'une facture fournisseur (en-tête + lignes + payé).</summary>
	public async Task<InvoiceDetailDto?> GetInvoiceAsync(int id, CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<InvoiceDetailDto>($"api/suppliers/invoices/{id}", JsonOptions, ct);

	/// <summary>Liste des fournisseurs (pour le sélecteur de facture fournisseur).</summary>
	public async Task<IReadOnlyList<ClientLookupDto>> GetSuppliersAsync(CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<List<ClientLookupDto>>("api/suppliers/lookup", JsonOptions, ct) ?? [];

	/// <summary>Crée une facture fournisseur brouillon. Renvoie l'Id créé (0 si échec).</summary>
	public async Task<int> CreateInvoiceAsync(CreateInvoiceRequest request, CancellationToken ct = default)
	{
		using var response = await _http.PostAsJsonAsync("api/suppliers/invoices", request, JsonOptions, ct);
		response.EnsureSuccessStatusCode();
		var result = await response.Content.ReadFromJsonAsync<CreateInvoiceResult>(JsonOptions, ct);
		return result?.Id ?? 0;
	}
}
