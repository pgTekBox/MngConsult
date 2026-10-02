using APIWebMngConsul.Models;
using APIWebMngConsul.Security;
using Microsoft.AspNetCore.Mvc;
using System.Security.Cryptography;

namespace APIWebMngConsul.Controllers
{
    public interface IReceiptRepository
    {
        Task<Guid> InsertAsync(ReceiptDbInsert row, CancellationToken ct);
    }

    public sealed class ReceiptDbInsert
    {
        /// <summary>La compagnie du reçu : toujours celle du jeton de l'appelant.</summary>
        public Guid CompanyGuid { get; init; }
        public string? SourceFileName { get; init; }
        public string SourceContentType { get; init; } = "application/octet-stream";
        public long SourceSizeBytes { get; init; }
        public byte[]? SourceSha256 { get; init; }      // 32 octets
        public byte[] SourceBlob { get; init; } = Array.Empty<byte>();
        public byte ProcessingStatus { get; init; } = 1; // UPLOADED
    }

    public sealed class ReceiptRepository : IReceiptRepository
    {
        private readonly string _cs;

        public ReceiptRepository(IConfiguration cfg)
            => _cs = cfg.GetConnectionString("Sql") is { Length: > 0 } cs
                 ? cs
                 : throw new InvalidOperationException(
                     "ConnectionStrings:Sql manquant : renseignez-le dans appsettings.Local.json (non suivi par git).");

        public Task<Guid> InsertAsync(ReceiptDbInsert row, CancellationToken ct)
        {
            var db = new DatabaseHelper(_cs);
            var p = new Dictionary<string, object>
            {
                // s0001InsertDocument range le reçu dans la compagnie @AccountId
                // quand @UserId est absent.
                { "@AccountId", row.CompanyGuid },
                { "@UserId", DBNull.Value },
                { "@SourceFileName", (object?)row.SourceFileName ?? DBNull.Value },
                { "@SourceContentType", row.SourceContentType },
                { "@SourceSizeBytes", row.SourceSizeBytes },
                { "@SourceSha256", (object?)row.SourceSha256 ?? DBNull.Value },
                { "@SourceBlob", row.SourceBlob },
                { "@ProcessingStatus", row.ProcessingStatus },
            };

            var result = db.GetDataSet("s0001InsertDocument", p);
            var id = result.Tables[0].Rows[0][0] != DBNull.Value ? (Guid)result.Tables[0].Rows[0][0] : Guid.Empty;
            return Task.FromResult(id);
        }
    }

    [ApiController]
    [Route("api/receipts")]
    public class ReceiptsController : ControllerBase
    {
        private readonly IReceiptRepository _repo;
        private readonly JwtGuard _jwt;

        public ReceiptsController(IReceiptRepository repo, JwtGuard jwt)
        {
            _repo = repo;
            _jwt = jwt;
        }

        private static readonly HashSet<string> AllowedContentTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            "image/jpeg",
            "image/png",
            "application/pdf"
        };

        private const long MaxBytes = 20 * 1024 * 1024; // 20 Mo

        [HttpPost("upload")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(typeof(UploadResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<ActionResult<UploadResponse>> Upload([FromForm] UploadRequest req, CancellationToken ct)
        {
            // Le jeton de l'application mobile est exigé, et c'est lui qui désigne
            // la compagnie. Avant, le dépôt était ouvert à tous et l'appelant
            // choisissait la compagnie.
            if (!_jwt.TryGetCompany(Request, out var companyGuid))
                return Unauthorized();

            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            var file = req.File;
            if (file is null)
                return BadRequest("Fichier manquant.");
            if (file.Length <= 0)
                return BadRequest("Fichier vide.");
            if (file.Length > MaxBytes)
                return BadRequest($"Fichier trop gros (max {MaxBytes} bytes).");

            var contentType = string.IsNullOrWhiteSpace(file.ContentType)
                ? "application/octet-stream"
                : file.ContentType;

            if (!AllowedContentTypes.Contains(contentType))
                return BadRequest($"Type non supporté: {contentType}");

            byte[] bytes;
            await using (var ms = new MemoryStream((int)Math.Min(file.Length, int.MaxValue)))
            {
                await file.CopyToAsync(ms, ct);
                bytes = ms.ToArray();
            }

            var sha = SHA256.HashData(bytes);
            var shaHex = Convert.ToHexString(sha);

            var originalName =
                !string.IsNullOrWhiteSpace(req.OriginalFileName) ? req.OriginalFileName :
                !string.IsNullOrWhiteSpace(file.FileName) ? file.FileName :
                "receipt";

            var receiptId = await _repo.InsertAsync(new ReceiptDbInsert
            {
                CompanyGuid = companyGuid,
                SourceFileName = originalName,
                SourceContentType = contentType,
                SourceSizeBytes = bytes.LongLength,
                SourceSha256 = sha,
                SourceBlob = bytes,
                ProcessingStatus = 1
            }, ct);

            return Ok(new UploadResponse
            {
                ReceiptId = receiptId,
                ContentType = contentType,
                SizeBytes = bytes.LongLength,
                Sha256Hex = shaHex,
                CreatedAtUtc = DateTimeOffset.UtcNow,
                ProcessingStatus = 1
            });
        }
    }
}
