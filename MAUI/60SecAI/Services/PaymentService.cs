using System.Net.Http.Json;
using System.Text.Json;

namespace _60SecAI.Services;

public class PaymentService
{
	private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

	private readonly HttpClient _http;

	public PaymentService(HttpClient http)
	{
		_http = http;
	}

	/// <summary>Liste des paiements, optionnellement filtrés par catégorie.</summary>
	public async Task<IReadOnlyList<PaymentDto>> GetPaymentsAsync(string? category = null, CancellationToken ct = default)
	{
		var url = string.IsNullOrWhiteSpace(category) ? "api/payments" : $"api/payments?category={category}";
		var payments = await _http.GetFromJsonAsync<List<PaymentDto>>(url, JsonOptions, ct);
		return payments ?? [];
	}
}
