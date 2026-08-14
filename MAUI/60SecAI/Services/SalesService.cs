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
}
