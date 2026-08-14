using System.Net.Http.Json;
using System.Text.Json;

namespace _60SecAI.Services;

public class AuthService
{
	private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

	private readonly HttpClient _http;
	private readonly AuthTokenStore _tokenStore;

	public AuthService(HttpClient http, AuthTokenStore tokenStore)
	{
		_http = http;
		_tokenStore = tokenStore;
	}

	/// <summary>
	/// Authentifie l'utilisateur auprès de l'API. Renvoie la réponse (token stocké)
	/// ou null si les identifiants sont invalides. Lève en cas d'erreur réseau.
	/// </summary>
	public async Task<AuthResponse?> LoginAsync(string username, string password, CancellationToken ct = default)
	{
		using var response = await _http.PostAsJsonAsync(
			"api/auth/login", new LoginRequest(username, password), JsonOptions, ct);

		if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
		{
			return null;
		}

		response.EnsureSuccessStatusCode();

		var auth = await response.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions, ct);
		if (auth is not null)
		{
			await _tokenStore.SetTokenAsync(auth.Token);
		}

		return auth;
	}

	public void Logout() => _tokenStore.Clear();
}
