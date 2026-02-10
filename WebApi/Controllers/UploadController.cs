using APIWebMngConsul.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Data;
using System.Security.Cryptography;

namespace APIWebMngConsul.Controllers
{
    public interface IReceiptRepository
    {
        Task<Guid> InsertAsync(ReceiptDbInsert row, CancellationToken ct);
    }

    public sealed class ReceiptDbInsert
    {
        public Guid? AccountId { get; init; }
        public Guid? UserId { get; init; }
        public string? SourceFileName { get; init; }
        public string SourceContentType { get; init; } = "application/octet-stream";
        public long SourceSizeBytes { get; init; }
        public byte[]? SourceSha256 { get; init; }      // 32 bytes
        public byte[] SourceBlob { get; init; } = Array.Empty<byte>();
        public byte ProcessingStatus { get; init; } = 1; // UPLOADED
    }

    public sealed class ReceiptRepository : IReceiptRepository
    {
        private readonly string _cs;

        public ReceiptRepository(IConfiguration cfg)
            => _cs = cfg.GetConnectionString("Sql")
                 ?? throw new InvalidOperationException("ConnectionStrings:Sql manquant.");

        public async Task<Guid> InsertAsync(ReceiptDbInsert row, CancellationToken ct)
        {

            DatabaseHelper DBHelper = new DatabaseHelper();
            Dictionary<string, object> myparams = new Dictionary<string, object>();

            myparams.Add("@AccountId", (object?)row.AccountId ?? DBNull.Value);
            myparams.Add("@UserId", (object?)row.UserId ?? DBNull.Value);
            myparams.Add("@SourceFileName", (object?)row.SourceFileName ?? DBNull.Value);
            myparams.Add("@SourceContentType", row.SourceContentType);
            myparams.Add("@SourceSizeBytes", row.SourceSizeBytes);
            myparams.Add("@SourceSha256", (object?)row.SourceSha256 ?? DBNull.Value);
            myparams.Add("@SourceBlob", row.SourceBlob);
            myparams.Add("@ProcessingStatus", row.ProcessingStatus);

            System.Data.DataSet result = DBHelper.GetDataSet("s0001InsertDocument", myparams);

            Guid ImageGUID;
            ImageGUID = result.Tables[0].Rows[0][0] != DBNull.Value ? (Guid)result.Tables[0].Rows[0][0] : Guid.Empty;
            return ImageGUID;



            //            const string sql = @"
            //INSERT INTO dbo.Receipts
            //(
            //    AccountId, UserId,
            //    SourceFileName, SourceContentType, SourceSizeBytes,
            //    SourceSha256, SourceBlob,
            //    ProcessingStatus
            //)
            //OUTPUT INSERTED.ReceiptId
            //VALUES
            //(
            //    @AccountId, @UserId,
            //    @SourceFileName, @SourceContentType, @SourceSizeBytes,
            //    @SourceSha256, @SourceBlob,
            //    @ProcessingStatus
            //);";

            //await using var conn = new SqlConnection(_cs);
            //await conn.OpenAsync(ct);

            //await using var cmd = new SqlCommand(sql, conn);

            //cmd.Parameters.Add("@AccountId", SqlDbType.UniqueIdentifier).Value =
            //    (object?)row.AccountId ?? DBNull.Value;

            //cmd.Parameters.Add("@UserId", SqlDbType.UniqueIdentifier).Value =
            //    (object?)row.UserId ?? DBNull.Value;

            //cmd.Parameters.Add("@SourceFileName", SqlDbType.NVarChar, 260).Value =
            //    (object?)row.SourceFileName ?? DBNull.Value;

            //cmd.Parameters.Add("@SourceContentType", SqlDbType.NVarChar, 100).Value =
            //    row.SourceContentType;

            //cmd.Parameters.Add("@SourceSizeBytes", SqlDbType.BigInt).Value =
            //    row.SourceSizeBytes;

            //cmd.Parameters.Add("@SourceSha256", SqlDbType.VarBinary, 32).Value =
            //    (object?)row.SourceSha256 ?? DBNull.Value;

            //cmd.Parameters.Add("@SourceBlob", SqlDbType.VarBinary, -1).Value =
            //    row.SourceBlob;

            //cmd.Parameters.Add("@ProcessingStatus", SqlDbType.TinyInt).Value =
            //row.ProcessingStatus;

            //var receiptIdObj = await cmd.ExecuteScalarAsync(ct);
           // return (Guid)(receiptIdObj ?? throw new InvalidOperationException("Insert n'a pas retourné ReceiptId."));
        }
    }

    [ApiController]
    [Route("api/receipts")]
    public class ReceiptsController : ControllerBase
    {
        private readonly IReceiptRepository _repo;

        public ReceiptsController(IReceiptRepository repo) => _repo = repo;

        private static readonly HashSet<string> AllowedContentTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            "image/jpeg",
            "image/png",
            "application/pdf"
        };

        private const long MaxBytes = 20 * 1024 * 1024; // 20 MB

        [HttpPost("upload")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(typeof(UploadResponse), StatusCodes.Status200OK)]
        public async Task<ActionResult<UploadResponse>> Upload([FromForm] UploadRequest req, CancellationToken ct)
        {
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
                AccountId = req.AccountId,
                UserId = req.UserId,
                SourceFileName = originalName,
                SourceContentType = contentType,
                SourceSizeBytes = bytes.LongLength,
                SourceSha256 = sha,
                SourceBlob = bytes,
                ProcessingStatus = 1
            }, ct);

            var now = DateTimeOffset.UtcNow;

            return Ok(new UploadResponse
            {
                ReceiptId = receiptId,
                ContentType = contentType,
                SizeBytes = bytes.LongLength,
                Sha256Hex = shaHex,
                CreatedAtUtc = now,
                ProcessingStatus = 1
            });
        }
    }
}
