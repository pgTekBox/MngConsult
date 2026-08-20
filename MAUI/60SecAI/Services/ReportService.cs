using System.Net.Http.Json;
using System.Text.Json;

namespace _60SecAI.Services;

public class ReportService
{
	private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

	private readonly HttpClient _http;

	public ReportService(HttpClient http)
	{
		_http = http;
	}

	/// <summary>Aperçu financier pour la période (month | quarter | year).</summary>
	public async Task<ReportOverviewDto?> GetOverviewAsync(string period = "month", CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<ReportOverviewDto>($"api/reports/overview?period={period}", JsonOptions, ct);

	/// <summary>Bilan à la date du jour.</summary>
	public async Task<ReportBilanDto?> GetBilanAsync(CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<ReportBilanDto>("api/reports/bilan", JsonOptions, ct);

	/// <summary>Flux de trésorerie pour la période.</summary>
	public async Task<ReportTresorerieDto?> GetTresorerieAsync(string period = "month", CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<ReportTresorerieDto>($"api/reports/tresorerie?period={period}", JsonOptions, ct);

	/// <summary>Comptes clients / fournisseurs.</summary>
	public async Task<ReportComptesDto?> GetComptesAsync(CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<ReportComptesDto>("api/reports/comptes", JsonOptions, ct);

	/// <summary>Taxes TPS/TVQ pour la période.</summary>
	public async Task<ReportTaxesDto?> GetTaxesAsync(string period = "month", CancellationToken ct = default)
		=> await _http.GetFromJsonAsync<ReportTaxesDto>($"api/reports/taxes?period={period}", JsonOptions, ct);
}
