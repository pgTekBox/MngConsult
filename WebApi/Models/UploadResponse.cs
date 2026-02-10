



namespace APIWebMngConsul.Models
{
 

    public sealed class UploadResponse
    {
        public Guid ReceiptId { get; init; }
        public string ContentType { get; init; } = "";
        public long SizeBytes { get; init; }
        public string Sha256Hex { get; init; } = "";
        public DateTimeOffset CreatedAtUtc { get; init; }
        public byte ProcessingStatus { get; init; }
    }


     


}
