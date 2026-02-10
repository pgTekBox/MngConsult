
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace APIWebMngConsul.Models
{
    public class UploadRequest
    {

        public Guid? AccountId { get; set; }
        public Guid? UserId { get; set; }

        [Required]
        public IFormFile File { get; set; } = default!;

        [MaxLength(260)]
        public string? OriginalFileName { get; set; } = null;


    }
}