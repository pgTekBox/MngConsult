using System.Data;
using System.Security.Claims;
using System.Security.Cryptography;
using _60SecAI.Api.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace _60SecAI.Api.Controllers;

/// <summary>
/// Dépôt d'un reçu numérisé depuis l'application mobile.
/// Le jeton est exigé et c'est LUI qui désigne la compagnie : l'appelant ne
/// choisit pas où le reçu est rangé. (L'ancien dépôt, sur une autre API, était
/// ouvert à tous et prenait la compagnie dans la requête.)
/// </summary>
[ApiController]
[Route("api/receipts")]
[Authorize]
public class ReceiptsController : ControllerBase
{
	private static readonly HashSet<string> AllowedContentTypes = new(StringComparer.OrdinalIgnoreCase)
	{
		"image/jpeg",
		"image/png",
		"application/pdf",
	};

	private const long MaxBytes = 20 * 1024 * 1024; // 20 Mo

	private readonly string _connectionString;

	public ReceiptsController(IConfiguration configuration)
	{
		_connectionString = configuration.GetConnectionString("Default")
			?? throw new InvalidOperationException("Chaîne de connexion 'Default' absente.");
	}

	private Guid CompanyGuid =>
		Guid.TryParse(User.FindFirstValue(TokenService.CompanyClaim), out var g) ? g : Guid.Empty;

	public sealed record UploadResult(Guid ReceiptId, string ContentType, long SizeBytes, string Sha256Hex, DateTimeOffset CreatedAtUtc);

	/// <summary>Enregistre le reçu (s0001InsertDocument) dans la compagnie du jeton.</summary>
	[HttpPost("upload")]
	[Consumes("multipart/form-data")]
	[RequestSizeLimit(MaxBytes + 1024 * 1024)]
	public async Task<ActionResult<UploadResult>> Upload(IFormFile? file, CancellationToken ct)
	{
		var company = CompanyGuid;
		if (company == Guid.Empty)
		{
			return Forbid();
		}

		if (file is null || file.Length <= 0)
		{
			return BadRequest(new { message = "Fichier manquant ou vide." });
		}

		if (file.Length > MaxBytes)
		{
			return BadRequest(new { message = "Fichier trop gros (20 Mo au maximum)." });
		}

		var contentType = string.IsNullOrWhiteSpace(file.ContentType) ? "application/octet-stream" : file.ContentType;
		if (!AllowedContentTypes.Contains(contentType))
		{
			return BadRequest(new { message = $"Type non supporté : {contentType}" });
		}

		byte[] bytes;
		await using (var ms = new MemoryStream((int)file.Length))
		{
			await file.CopyToAsync(ms, ct);
			bytes = ms.ToArray();
		}

		var sha = SHA256.HashData(bytes);
		var fileName = string.IsNullOrWhiteSpace(file.FileName) ? "receipt" : Path.GetFileName(file.FileName);

		await using var conn = new SqlConnection(_connectionString);
		await conn.OpenAsync(ct);
		await using var cmd = new SqlCommand("s0001InsertDocument", conn) { CommandType = CommandType.StoredProcedure };
		// La compagnie vient du jeton, jamais de la requête.
		cmd.Parameters.AddWithValue("@AccountId", company);
		cmd.Parameters.AddWithValue("@UserId", DBNull.Value);
		cmd.Parameters.AddWithValue("@SourceFileName", fileName);
		cmd.Parameters.AddWithValue("@SourceContentType", contentType);
		cmd.Parameters.AddWithValue("@SourceSizeBytes", bytes.Length);
		cmd.Parameters.Add("@SourceSha256", SqlDbType.VarBinary, -1).Value = sha;
		cmd.Parameters.Add("@SourceBlob", SqlDbType.VarBinary, -1).Value = bytes;
		cmd.Parameters.AddWithValue("@ProcessingStatus", 1);

		var result = await cmd.ExecuteScalarAsync(ct);
		var receiptId = result is Guid g ? g : Guid.Empty;

		return Ok(new UploadResult(receiptId, contentType, bytes.LongLength, Convert.ToHexString(sha), DateTimeOffset.UtcNow));
	}
}
