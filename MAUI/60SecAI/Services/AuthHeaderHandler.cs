using System.Net.Http.Headers;

namespace _60SecAI.Services;

/// <summary>Ajoute automatiquement l'en-tête Authorization: Bearer &lt;token&gt; aux requêtes.</summary>
public class AuthHeaderHandler : DelegatingHandler
{
	private readonly AuthTokenStore _tokenStore;

	public AuthHeaderHandler(AuthTokenStore tokenStore)
	{
		_tokenStore = tokenStore;
	}

	protected override async Task<HttpResponseMessage> SendAsync(
		HttpRequestMessage request, CancellationToken cancellationToken)
	{
		var token = await _tokenStore.GetTokenAsync();
		if (!string.IsNullOrEmpty(token))
		{
			request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
		}

		return await base.SendAsync(request, cancellationToken);
	}
}
