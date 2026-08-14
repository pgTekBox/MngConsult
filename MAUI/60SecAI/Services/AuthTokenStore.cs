namespace _60SecAI.Services;

/// <summary>Stocke le token JWT de façon sécurisée (chiffré par l'OS via SecureStorage).</summary>
public class AuthTokenStore
{
	private const string TokenKey = "auth_token";
	private string? _cached;

	public async Task SetTokenAsync(string token)
	{
		_cached = token;
		await SecureStorage.Default.SetAsync(TokenKey, token);
	}

	public async Task<string?> GetTokenAsync()
	{
		if (!string.IsNullOrEmpty(_cached))
		{
			return _cached;
		}

		_cached = await SecureStorage.Default.GetAsync(TokenKey);
		return _cached;
	}

	public void Clear()
	{
		_cached = null;
		SecureStorage.Default.Remove(TokenKey);
	}
}
