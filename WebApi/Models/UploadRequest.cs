using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace APIWebMngConsul.Models
{
    /// <summary>
    /// Dépôt d'un reçu. La compagnie n'est plus un champ de la requête : elle
    /// vient du jeton de l'appelant.
    /// </summary>
    public class UploadRequest
    {
        [Required]
        public IFormFile File { get; set; } = default!;

        [MaxLength(260)]
        public string? OriginalFileName { get; set; } = null;
    }
}
