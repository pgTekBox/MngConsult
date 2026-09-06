using System.Data;
using System.Globalization;
using System.Text;
using Microsoft.Data.SqlClient;

namespace _60SecAI.Api.Services;

/// <summary>
/// Envoi d'une facture au client par courriel (PDF + lien Square optionnel) — port
/// fidèle de wbfCustomersInvoices.SendInvoiceByEmail / BuildSquarePaymentLink.
/// </summary>
public sealed class InvoiceEmailService
{
	private readonly string _connectionString;
	private readonly InvoicePdfService _pdf;
	private readonly SquareService _square;
	private readonly MailQueueService _mail;

	public InvoiceEmailService(IConfiguration configuration, InvoicePdfService pdf, SquareService square, MailQueueService mail)
	{
		_connectionString = configuration.GetConnectionString("Default")
			?? throw new InvalidOperationException("Chaîne de connexion 'Default' absente.");
		_pdf = pdf;
		_square = square;
		_mail = mail;
	}

	/// <summary>Statut d'envoi : Sent | NotFound | NoEmail | PdfFail.</summary>
	public sealed record SendResult(string Status, string? Email, string? DocNumber, string SquareStatus, string? SquareError);

	public async Task<SendResult> SendAsync(Guid companyGuid, int invoiceId, bool includeSquare, string? supportEmail)
	{
		// 1. Charger les données de la facture (s0696)
		var (row, ds) = await LoadAsync(invoiceId);
		if (row is null)
		{
			return new SendResult("NotFound", null, null, "NotRequested", null);
		}

		var toEmail = row["Email"] is DBNull ? "" : row["Email"].ToString()!.Trim();
		if (toEmail == "")
		{
			return new SendResult("NoEmail", null, null, "NotRequested", null);
		}

		// 2. S'assurer que le PDF existe (sinon le générer)
		if (row["PdfData"] is DBNull)
		{
			await _pdf.GenerateAndSaveAsync(invoiceId);
			(row, ds) = await LoadAsync(invoiceId);
		}
		if (row is null || row["PdfData"] is DBNull)
		{
			return new SendResult("PdfFail", toEmail, null, "NotRequested", null);
		}

		var pdfBytes = (byte[])row["PdfData"];
		var docNumber = row["DocumentNumber"] is DBNull ? invoiceId.ToString() : row["DocumentNumber"].ToString()!;
		var companyName = row["CompanyName"] is DBNull ? "" : row["CompanyName"].ToString()!;
		var docGuid = row["DocumentGUID"] is DBNull ? "" : row["DocumentGUID"].ToString()!;
		var fileName = row.Table.Columns.Contains("PdfFileName") && row["PdfFileName"] is not DBNull && row["PdfFileName"].ToString() != ""
			? row["PdfFileName"].ToString()!
			: "Facture_" + docNumber + ".pdf";
		var reste = row.Table.Columns.Contains("ResteAPayer") && row["ResteAPayer"] is not DBNull ? Convert.ToDecimal(row["ResteAPayer"]) : 0m;

		// 3. Lien de paiement Square (optionnel, sur le solde restant)
		var squareLinkHtml = "";
		var squareStatus = "NotRequested";
		string? squareError = null;
		if (includeSquare)
		{
			(squareLinkHtml, squareStatus, squareError) = await BuildSquarePaymentLinkAsync(companyGuid, invoiceId, docNumber, companyName, toEmail, reste, supportEmail);
		}

		// 4. Corps HTML (+ lien de visualisation en secours)
		var viewUrl = "https://60sec.ca/InvoicePdf.ashx?g=" + docGuid;
		var subject = "Facture " + docNumber + (companyName != "" ? " — " + companyName : "");
		var body = new StringBuilder();
		body.Append("<div style=\"font-family:Arial,sans-serif;font-size:14px;color:#0f172a\">");
		body.Append("<p>Bonjour,</p>");
		body.Append("<p>Veuillez trouver ci-jointe la facture <strong>").Append(HtmlEncode(docNumber)).Append("</strong>");
		if (companyName != "") body.Append(" de ").Append(HtmlEncode(companyName));
		body.Append(".</p>");
		body.Append("<p><a href=\"").Append(viewUrl).Append("\" style=\"display:inline-block;padding:10px 18px;background:#2563eb;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:700\">Voir la facture (PDF)</a></p>");
		if (squareLinkHtml != "") body.Append(squareLinkHtml);
		body.Append("<p>Merci de votre confiance.</p>");
		if (companyName != "") body.Append("<p>").Append(HtmlEncode(companyName)).Append("</p>");
		body.Append("</div>");

		// 5. Déposer le courriel + pièce jointe
		await _mail.QueueEmailWithPdfAsync(companyGuid, toEmail, subject, body.ToString(), pdfBytes, fileName);

		return new SendResult("Sent", toEmail, docNumber, squareStatus, squareError);
	}

	private async Task<(string Html, string Status, string? Error)> BuildSquarePaymentLinkAsync(
		Guid companyGuid, int invoiceId, string docNumber, string companyName, string buyerEmail, decimal reste, string? supportEmail)
	{
		var (url, status, error) = await CreateSquareLinkCoreAsync(companyGuid, invoiceId, docNumber, companyName, buyerEmail, reste, supportEmail);
		if (status != "Created" || string.IsNullOrEmpty(url))
		{
			// Pour le courriel, "Created" n'est jamais retourné tel quel ; on mappe les échecs.
			return ("", status, error);
		}

		var html = "<p><a href=\"" + url + "\" style=\"display:inline-block;padding:10px 18px;" +
				   "background:#16a34a;color:#ffffff;text-decoration:none;border-radius:8px;font-weight:700\">" +
				   "Payer maintenant (" + reste.ToString("N2", CultureInfo.GetCultureInfo("fr-CA")) + " $)</a></p>";
		return (html, "Included", null);
	}

	/// <summary>
	/// Cœur commun : crée le lien de paiement Square pour une facture (courriel/SMS/copie).
	/// Statut : Created | AlreadyPaid | NotConnected | NotGenerated | Error.
	/// </summary>
	private async Task<(string? Url, string Status, string? Error)> CreateSquareLinkCoreAsync(
		Guid companyGuid, int invoiceId, string docNumber, string companyName, string buyerEmail, decimal reste, string? supportEmail)
	{
		try
		{
			if (reste <= 0m)
			{
				return (null, "AlreadyPaid", null);
			}

			string? token;
			try
			{
				token = await _square.GetValidAccessTokenAsync(companyGuid);
			}
			catch (SquareService.SquareConfigException ex)
			{
				// Compte connecté mais config API invalide (Square:TokenKey) : message dédié.
				return (null, "Misconfigured", ex.Message);
			}
			catch
			{
				token = null;
			}

			if (string.IsNullOrEmpty(token))
			{
				return (null, "NotConnected", null);
			}

			var locationId = await _square.GetMainLocationIdAsync(token);
			var cents = (long)Math.Round(reste * 100m);
			var name = "Facture #" + docNumber;
			var link = await _square.CreatePaymentLinkAsync(
				token, locationId, cents, name, "Facture client #" + docNumber, companyName, buyerEmail, supportEmail, null);

			if (link is null || string.IsNullOrEmpty(link.Url))
			{
				return (null, "NotGenerated", null);
			}

			if (!string.IsNullOrEmpty(link.OrderId))
			{
				await _square.LinkDocumentToSquareOrderAsync(companyGuid, invoiceId, link.OrderId!);
			}

			return (link.Url, "Created", null);
		}
		catch (Exception ex)
		{
			return (null, "Error", ex.Message);
		}
	}

	/// <summary>Statut d'un lien : Created | AlreadyPaid | NotConnected | NotGenerated | Error | NotFound.</summary>
	public sealed record PaymentLinkResult(string Status, string? Url, string? DocNumber, string? Phone, decimal Amount, string? Error);

	/// <summary>Génère (sans courriel) un lien de paiement Square pour une facture + renvoie le téléphone du client.</summary>
	public async Task<PaymentLinkResult> CreatePaymentLinkAsync(Guid companyGuid, int invoiceId, string? supportEmail)
	{
		var info = await LoadPaymentInfoAsync(invoiceId);
		if (info is null)
		{
			return new PaymentLinkResult("NotFound", null, null, null, 0m, null);
		}

		var (url, status, error) = await CreateSquareLinkCoreAsync(
			companyGuid, invoiceId, info.DocNumber, info.CompanyName, info.Email, info.Reste, supportEmail);

		return new PaymentLinkResult(status, url, info.DocNumber, info.Phone, info.Reste, error);
	}

	private sealed record PaymentInfo(string DocNumber, string Email, string Phone, string CompanyName, decimal Reste);

	private async Task<PaymentInfo?> LoadPaymentInfoAsync(int invoiceId)
	{
		var ds = new DataSet();
		await using (var conn = new SqlConnection(_connectionString))
		{
			await using var cmd = new SqlCommand("s0724GetInvoicePaymentInfo", conn) { CommandType = CommandType.StoredProcedure };
			cmd.Parameters.AddWithValue("@InvoiceId", invoiceId);
			using var da = new SqlDataAdapter(cmd);
			da.Fill(ds);
		}

		if (ds.Tables.Count == 0 || ds.Tables[0].Rows.Count == 0)
		{
			return null;
		}

		var r = ds.Tables[0].Rows[0];
		var docNumber = r["DocumentNumber"] is DBNull ? invoiceId.ToString() : r["DocumentNumber"].ToString()!;
		var email = r["Email"] is DBNull ? "" : r["Email"].ToString()!.Trim();
		var phone = r["Phone"] is DBNull ? "" : r["Phone"].ToString()!.Trim();
		var companyName = r["CompanyName"] is DBNull ? "" : r["CompanyName"].ToString()!;
		var reste = r["ResteAPayer"] is DBNull ? 0m : Convert.ToDecimal(r["ResteAPayer"]);
		return new PaymentInfo(docNumber, email, phone, companyName, reste);
	}

	private async Task<(DataRow? Row, DataSet Ds)> LoadAsync(int invoiceId)
	{
		var ds = new DataSet();
		await using (var conn = new SqlConnection(_connectionString))
		{
			await using var cmd = new SqlCommand("s0696GetInvoiceForEmail", conn) { CommandType = CommandType.StoredProcedure };
			cmd.Parameters.AddWithValue("@InvoiceId", invoiceId);
			using var da = new SqlDataAdapter(cmd);
			da.Fill(ds);
		}

		var row = ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0 ? ds.Tables[0].Rows[0] : null;
		return (row, ds);
	}

	private static string HtmlEncode(string s) => System.Net.WebUtility.HtmlEncode(s);
}
