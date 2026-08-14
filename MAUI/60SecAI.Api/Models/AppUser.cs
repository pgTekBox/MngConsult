using System.ComponentModel.DataAnnotations.Schema;

namespace _60SecAI.Api.Models;

/// <summary>
/// Utilisateur — mappé sur la table existante <c>dbo.T015User</c> de la base MngConsul.
/// Seules les colonnes nécessaires à l'authentification sont déclarées.
/// </summary>
[Table("T015User")]
public class AppUser
{
	public int Id { get; set; }
	public Guid? CompanyGUID { get; set; }
	public string Email { get; set; } = string.Empty;
	public string PasswordHash { get; set; } = string.Empty;
	public string? FirstName { get; set; }
	public string? LastName { get; set; }
	public bool IsAdmin { get; set; }
	public bool IsAccountant { get; set; }
	public bool IsActive { get; set; }
	public bool IsDeleted { get; set; }

	[NotMapped]
	public string DisplayName =>
		string.Join(" ", new[] { FirstName, LastName }.Where(s => !string.IsNullOrWhiteSpace(s))).Trim();

	[NotMapped]
	public string Role => IsAdmin ? "Admin" : IsAccountant ? "Accountant" : "User";
}
