using System.Data;
using Microsoft.Data.SqlClient;

namespace _60SecAI.Api.Security;

/// <summary>
/// Cloisonnement par compagnie. Tout identifiant reçu du client (numéro de
/// facture dans l'adresse, PartyGUID dans le corps) doit être confronté à la
/// compagnie du jeton AVANT de lire ou de modifier l'enregistrement : les
/// procédures « par Id » (s0038, s0039, s0720, s0721, s0696…) ne reçoivent pas
/// la compagnie et ne peuvent pas le faire elles-mêmes.
/// Même procédure que l'ERP : s0891AppartientCompagnie.
/// </summary>
public static class Ownership
{
	/// <summary>Vrai si le document (facture client ou fournisseur) est à la compagnie.</summary>
	public static Task<bool> OwnsDocumentAsync(string connectionString, Guid companyGuid, int documentId, CancellationToken ct = default)
		=> documentId <= 0 ? Task.FromResult(false) : CheckAsync(connectionString, companyGuid, "DOCUMENT", documentId, null, ct);

	/// <summary>Vrai si le tiers (client ou fournisseur) désigné par son PartyGUID est à la compagnie.</summary>
	public static Task<bool> OwnsPartyAsync(string connectionString, Guid companyGuid, Guid partyGuid, CancellationToken ct = default)
		=> partyGuid == Guid.Empty ? Task.FromResult(false) : CheckAsync(connectionString, companyGuid, "PARTYGUID", null, partyGuid, ct);

	private static async Task<bool> CheckAsync(string connectionString, Guid companyGuid, string type, int? id, Guid? guid, CancellationToken ct)
	{
		// Un jeton sans compagnie ne possède rien.
		if (companyGuid == Guid.Empty)
		{
			return false;
		}

		try
		{
			await using var conn = new SqlConnection(connectionString);
			await conn.OpenAsync(ct);
			await using var cmd = new SqlCommand("s0891AppartientCompagnie", conn) { CommandType = CommandType.StoredProcedure };
			cmd.Parameters.AddWithValue("@CompanyGUID", companyGuid);
			cmd.Parameters.AddWithValue("@Type", type);
			cmd.Parameters.AddWithValue("@Id", (object?)id ?? DBNull.Value);
			cmd.Parameters.AddWithValue("@Guid", (object?)guid ?? DBNull.Value);
			var result = await cmd.ExecuteScalarAsync(ct);
			return result is not null && result is not DBNull && Convert.ToBoolean(result);
		}
		catch
		{
			// Dans le doute, on refuse.
			return false;
		}
	}
}
