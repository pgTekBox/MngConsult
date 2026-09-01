using System.Data;
using System.Globalization;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.Data.SqlClient;

namespace _60SecAI.Api.Services;

/// <summary>
/// Intégration Square (port fidèle de clsSquare + clsCrypto + les helpers Square de
/// clsData du site web). Chiffrement AES-256 des jetons, OAuth (refresh), et création
/// de lien de paiement hébergé. Config sous la section "Square", jeton de secours
/// "Square:AccessToken", clé de chiffrement "Square:TokenKey" (identique au site web).
/// </summary>
public sealed class SquareService
{
	private readonly string _connectionString;
	private readonly IConfiguration _config;
	private readonly IHttpClientFactory _httpFactory;

	public SquareService(IConfiguration configuration, IHttpClientFactory httpFactory)
	{
		_config = configuration;
		_httpFactory = httpFactory;
		_connectionString = configuration.GetConnectionString("Default")
			?? throw new InvalidOperationException("Chaîne de connexion 'Default' absente.");
	}

	public sealed record PaymentLinkResult(string? Id, string? Url, string? LongUrl, string? OrderId);

	private sealed record TokenInfo(string? AccessToken, string? RefreshToken, string? MerchantId, DateTime ExpiresAt);

	// ---------- Configuration ----------
	private string ApiBase()
	{
		var env = _config["Square:Environment"];
		return !string.IsNullOrEmpty(env) && env.Trim().ToLowerInvariant() == "production"
			? "https://connect.squareup.com"
			: "https://connect.squareupsandbox.com";
	}

	private string ApiVersion()
	{
		var v = _config["Square:ApiVersion"];
		return string.IsNullOrEmpty(v) ? "2025-06-18" : v;
	}

	// ---------- Chiffrement (port de clsCrypto : AES-256-CBC, clé = SHA256(Square.TokenKey)) ----------
	private byte[] CryptoKey()
	{
		var secret = _config["Square:TokenKey"];
		if (string.IsNullOrEmpty(secret))
		{
			throw new InvalidOperationException("Square:TokenKey n'est pas configuré.");
		}

		using var sha = SHA256.Create();
		return sha.ComputeHash(Encoding.UTF8.GetBytes(secret));
	}

	private string Encrypt(string plainText)
	{
		if (string.IsNullOrEmpty(plainText)) return "";

		using var aes = Aes.Create();
		aes.Key = CryptoKey();
		aes.Mode = CipherMode.CBC;
		aes.Padding = PaddingMode.PKCS7;
		aes.GenerateIV();

		var iv = aes.IV;
		using var enc = aes.CreateEncryptor();
		var plain = Encoding.UTF8.GetBytes(plainText);
		var cipher = enc.TransformFinalBlock(plain, 0, plain.Length);

		var result = new byte[iv.Length + cipher.Length];
		Buffer.BlockCopy(iv, 0, result, 0, iv.Length);
		Buffer.BlockCopy(cipher, 0, result, iv.Length, cipher.Length);
		return Convert.ToBase64String(result);
	}

	private string Decrypt(string cipherText)
	{
		if (string.IsNullOrEmpty(cipherText)) return "";

		var all = Convert.FromBase64String(cipherText);
		using var aes = Aes.Create();
		aes.Key = CryptoKey();
		aes.Mode = CipherMode.CBC;
		aes.Padding = PaddingMode.PKCS7;

		var iv = new byte[16];
		Buffer.BlockCopy(all, 0, iv, 0, 16);
		aes.IV = iv;

		using var dec = aes.CreateDecryptor();
		var plain = dec.TransformFinalBlock(all, 16, all.Length - 16);
		return Encoding.UTF8.GetString(plain);
	}

	// ---------- Jeton d'accès valide pour la compagnie (s0663 + refresh + s0662) ----------
	public async Task<string?> GetValidAccessTokenAsync(Guid companyGuid)
	{
		try
		{
			DataRow? row = null;
			await using (var conn = new SqlConnection(_connectionString))
			{
				await using var cmd = new SqlCommand("s0663GetCompanySquareAuth", conn) { CommandType = CommandType.StoredProcedure };
				cmd.Parameters.AddWithValue("@CompanyGUID", companyGuid);
				var ds = new DataSet();
				using var da = new SqlDataAdapter(cmd);
				da.Fill(ds);
				if (ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0)
				{
					row = ds.Tables[0].Rows[0];
				}
			}

			if (row is not null)
			{
				var accEnc = row["SquareAccessTokenEnc"] is DBNull ? "" : row["SquareAccessTokenEnc"].ToString()!;
				if (!string.IsNullOrEmpty(accEnc))
				{
					var access = Decrypt(accEnc);
					var expires = row["SquareTokenExpiresAt"] is DBNull ? DateTime.MinValue : Convert.ToDateTime(row["SquareTokenExpiresAt"]);

					if (expires != DateTime.MinValue && expires <= DateTime.Now.AddDays(7))
					{
						var refEnc = row["SquareRefreshTokenEnc"] is DBNull ? "" : row["SquareRefreshTokenEnc"].ToString()!;
						if (!string.IsNullOrEmpty(refEnc))
						{
							try
							{
								var info = await RefreshAccessTokenAsync(Decrypt(refEnc));
								await SaveTokensAsync(companyGuid, info);
								access = info.AccessToken ?? access;
							}
							catch
							{
								// on garde l'ancien jeton si le refresh échoue
							}
						}
					}

					return access;
				}
			}
		}
		catch
		{
			// on retombe sur le jeton de secours
		}

		return _config["Square:AccessToken"];
	}

	private async Task SaveTokensAsync(Guid companyGuid, TokenInfo info)
	{
		await using var conn = new SqlConnection(_connectionString);
		await using var cmd = new SqlCommand("s0662SaveCompanySquareTokens", conn) { CommandType = CommandType.StoredProcedure };
		cmd.Parameters.AddWithValue("@CompanyGUID", companyGuid);
		cmd.Parameters.AddWithValue("@MerchantId", string.IsNullOrEmpty(info.MerchantId) ? DBNull.Value : info.MerchantId);
		cmd.Parameters.AddWithValue("@AccessTokenEnc", string.IsNullOrEmpty(info.AccessToken) ? DBNull.Value : Encrypt(info.AccessToken!));
		cmd.Parameters.AddWithValue("@RefreshTokenEnc", string.IsNullOrEmpty(info.RefreshToken) ? DBNull.Value : Encrypt(info.RefreshToken!));
		cmd.Parameters.AddWithValue("@ExpiresAt", info.ExpiresAt == DateTime.MinValue ? DBNull.Value : info.ExpiresAt);
		cmd.Parameters.AddWithValue("@LocationId", DBNull.Value);
		await conn.OpenAsync();
		await cmd.ExecuteNonQueryAsync();
	}

	/// <summary>Estampille la facture avec le SquareOrderId (réconciliation webhook, s0688).</summary>
	public async Task LinkDocumentToSquareOrderAsync(Guid companyGuid, int invoiceId, string orderId)
	{
		if (string.IsNullOrEmpty(orderId)) return;

		await using var conn = new SqlConnection(_connectionString);
		await using var cmd = new SqlCommand("s0688LinkDocumentToSquareOrder", conn) { CommandType = CommandType.StoredProcedure };
		cmd.Parameters.AddWithValue("@CompanyGUID", companyGuid);
		cmd.Parameters.AddWithValue("@DocumentId", invoiceId);
		cmd.Parameters.AddWithValue("@SquareOrderId", orderId);
		await conn.OpenAsync();
		await cmd.ExecuteNonQueryAsync();
	}

	// ---------- Appels HTTP Square ----------
	private async Task<TokenInfo> RefreshAccessTokenAsync(string refreshToken)
	{
		var body = new JsonObject
		{
			["client_id"] = _config["Square:ApplicationId"],
			["client_secret"] = _config["Square:ApplicationSecret"],
			["refresh_token"] = refreshToken,
			["grant_type"] = "refresh_token",
		};

		var resp = await SendAsync(HttpMethod.Post, "/oauth2/token", body.ToJsonString(), null);
		using var doc = JsonDocument.Parse(resp);
		var root = doc.RootElement;

		var exp = JStr(root, "expires_at");
		var expiresAt = DateTime.TryParse(exp, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var dt)
			? dt : DateTime.Now.AddDays(30);

		return new TokenInfo(JStr(root, "access_token"), JStr(root, "refresh_token"), JStr(root, "merchant_id"), expiresAt);
	}

	public async Task<string?> GetMainLocationIdAsync(string accessToken)
	{
		var resp = await SendAsync(HttpMethod.Get, "/v2/locations", null, accessToken);
		using var doc = JsonDocument.Parse(resp);
		if (!doc.RootElement.TryGetProperty("locations", out var locs) || locs.ValueKind != JsonValueKind.Array || locs.GetArrayLength() == 0)
		{
			return null;
		}

		string? fallback = null;
		foreach (var l in locs.EnumerateArray())
		{
			var id = JStr(l, "id");
			fallback ??= id;
			if (string.Equals(JStr(l, "status"), "ACTIVE", StringComparison.OrdinalIgnoreCase))
			{
				return id;
			}
		}

		return fallback;
	}

	/// <summary>Crée un lien de paiement Square (POST /v2/online-checkout/payment-links). Montant en cents CAD.</summary>
	public async Task<PaymentLinkResult> CreatePaymentLinkAsync(
		string accessToken, string? locationId, long amountCents, string name, string? note,
		string? businessName = null, string? buyerEmail = null, string? supportEmail = null, string? redirectUrl = null)
	{
		var displayName = string.IsNullOrEmpty(businessName) ? name : businessName + " — " + name;

		var quick = new JsonObject
		{
			["name"] = displayName,
			["price_money"] = new JsonObject { ["amount"] = amountCents, ["currency"] = "CAD" },
		};
		if (!string.IsNullOrEmpty(locationId)) quick["location_id"] = locationId;

		var body = new JsonObject
		{
			["idempotency_key"] = Guid.NewGuid().ToString(),
			["quick_pay"] = quick,
		};

		var fullDesc = note;
		if (!string.IsNullOrEmpty(businessName))
		{
			fullDesc = string.IsNullOrEmpty(note) ? businessName : businessName + " · " + note;
		}
		if (!string.IsNullOrEmpty(fullDesc)) body["description"] = fullDesc;

		if (!string.IsNullOrEmpty(buyerEmail))
		{
			body["pre_populated_data"] = new JsonObject { ["buyer_email"] = buyerEmail };
		}

		var opts = new JsonObject();
		if (!string.IsNullOrEmpty(supportEmail)) opts["merchant_support_email"] = supportEmail;
		if (!string.IsNullOrEmpty(redirectUrl)) opts["redirect_url"] = redirectUrl;
		if (opts.Count > 0) body["checkout_options"] = opts;

		var resp = await SendAsync(HttpMethod.Post, "/v2/online-checkout/payment-links", body.ToJsonString(), accessToken);
		using var doc = JsonDocument.Parse(resp);
		if (doc.RootElement.TryGetProperty("payment_link", out var pl))
		{
			return new PaymentLinkResult(JStr(pl, "id"), JStr(pl, "url"), JStr(pl, "long_url"), JStr(pl, "order_id"));
		}

		return new PaymentLinkResult(null, null, null, null);
	}

	private async Task<string> SendAsync(HttpMethod method, string path, string? jsonBody, string? accessToken)
	{
		using var req = new HttpRequestMessage(method, ApiBase() + path);
		req.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
		req.Headers.TryAddWithoutValidation("Square-Version", ApiVersion());
		if (!string.IsNullOrEmpty(accessToken))
		{
			req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
		}
		if (jsonBody is not null)
		{
			req.Content = new StringContent(jsonBody, Encoding.UTF8, "application/json");
		}

		var client = _httpFactory.CreateClient();
		using var resp = await client.SendAsync(req);
		var text = await resp.Content.ReadAsStringAsync();
		if (!resp.IsSuccessStatusCode)
		{
			throw new Exception("Square API : " + text + " (" + (int)resp.StatusCode + ")");
		}

		return text;
	}

	private static string? JStr(JsonElement parent, string name)
	{
		if (parent.ValueKind != JsonValueKind.Object || !parent.TryGetProperty(name, out var v) || v.ValueKind == JsonValueKind.Null)
		{
			return null;
		}

		return v.ValueKind == JsonValueKind.String ? v.GetString() : v.ToString();
	}
}
