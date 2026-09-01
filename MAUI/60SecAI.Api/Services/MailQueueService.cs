using System.Data;
using Microsoft.Data.SqlClient;

namespace _60SecAI.Api.Services;

/// <summary>
/// Dépôt d'un courriel sortant dans la file du service de courriels (T400Mails +
/// T402Attachments) — port des appels s0610InsertOutboundMail / s1579InsertAttachemnt_A
/// et du Reply-To vérifié (s0694GetCompanyReplyTo). Le From reste noreply@60sec.ca ;
/// c'est le Reply-To qui porte l'adresse de la compagnie (si vérifiée).
/// </summary>
public sealed class MailQueueService
{
	private readonly string _connectionString;     // base principale (Reply-To)
	private readonly string _mailConnectionString; // base du service de courriels

	public MailQueueService(IConfiguration configuration)
	{
		_connectionString = configuration.GetConnectionString("Default")
			?? throw new InvalidOperationException("Chaîne de connexion 'Default' absente.");

		_mailConnectionString = configuration.GetConnectionString("Mail") ?? "";
		if (string.IsNullOrWhiteSpace(_mailConnectionString))
		{
			throw new InvalidOperationException(
				"Chaîne de connexion 'Mail' non configurée (base MailService du service de courriels).");
		}
	}

	/// <summary>Dépose un courriel HTML avec une pièce jointe PDF. Retourne le MailId créé.</summary>
	public async Task<int> QueueEmailWithPdfAsync(
		Guid companyGuid, string toEmail, string subject, string htmlBody, byte[] pdfBytes, string fileName)
	{
		var replyTo = await GetVerifiedReplyToAsync(companyGuid);

		// 1. Courriel sortant -> MailId (base du service de courriels)
		int mailId;
		await using (var conn = new SqlConnection(_mailConnectionString))
		{
			await using var cmd = new SqlCommand("s0610InsertOutboundMail", conn) { CommandType = CommandType.StoredProcedure };
			cmd.Parameters.AddWithValue("@To", toEmail);
			cmd.Parameters.AddWithValue("@Subject", subject);
			cmd.Parameters.AddWithValue("@HTMLBody", htmlBody);
			cmd.Parameters.AddWithValue("@ReplyTo", string.IsNullOrEmpty(replyTo) ? DBNull.Value : replyTo);
			await conn.OpenAsync();
			var result = await cmd.ExecuteScalarAsync();
			mailId = result is null || result is DBNull ? 0 : Convert.ToInt32(result);
		}

		// 2. Pièce jointe PDF
		await using (var conn = new SqlConnection(_mailConnectionString))
		{
			await using var cmd = new SqlCommand("s1579InsertAttachemnt_A", conn) { CommandType = CommandType.StoredProcedure };
			cmd.Parameters.AddWithValue("@FileName", fileName);
			cmd.Parameters.Add(new SqlParameter("@content", SqlDbType.VarBinary, -1) { Value = pdfBytes });
			cmd.Parameters.AddWithValue("@MailId", mailId);
			cmd.Parameters.AddWithValue("@ContentType", "application/pdf");
			cmd.Parameters.AddWithValue("@ContentId", "");
			await conn.OpenAsync();
			await cmd.ExecuteNonQueryAsync();
		}

		return mailId;
	}

	/// <summary>Adresse Reply-To vérifiée de la compagnie (s0694), ou "" si indisponible.</summary>
	private async Task<string> GetVerifiedReplyToAsync(Guid companyGuid)
	{
		if (companyGuid == Guid.Empty) return "";
		try
		{
			await using var conn = new SqlConnection(_connectionString);
			await using var cmd = new SqlCommand("s0694GetCompanyReplyTo", conn) { CommandType = CommandType.StoredProcedure };
			cmd.Parameters.AddWithValue("@CompanyGUID", companyGuid);
			await conn.OpenAsync();
			var o = await cmd.ExecuteScalarAsync();
			return o is null || o is DBNull ? "" : o.ToString()!;
		}
		catch
		{
			return "";
		}
	}
}
