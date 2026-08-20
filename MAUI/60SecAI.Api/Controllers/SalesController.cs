using System.Data;
using System.Security.Claims;
using _60SecAI.Api.Dtos;
using _60SecAI.Api.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace _60SecAI.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SalesController : ControllerBase
{
	private readonly string _connectionString;

	public SalesController(IConfiguration configuration)
	{
		_connectionString = configuration.GetConnectionString("Default")
			?? throw new InvalidOperationException("Chaîne de connexion 'Default' absente.");
	}

	private Guid CompanyGuid =>
		Guid.TryParse(User.FindFirstValue(TokenService.CompanyClaim), out var g) ? g : Guid.Empty;

	/// <summary>StatutPaiement (procédure) → statut de l'app.</summary>
	private static string MapStatus(string? statut) => statut?.ToUpperInvariant() switch
	{
		"PAYEE" => "Collected",
		"EN_RETARD" => "Overdue",
		_ => "Receivable", // OUVERTE, PARTIELLE, IN_PROGRESS…
	};

	/// <summary>
	/// Liste des factures clients (s0026GetCustomersInvoices), optionnellement filtrées par status
	/// (Collected | Overdue | Receivable). Sans filtre = toutes les factures.
	/// </summary>
	[HttpGet("invoices")]
	public async Task<ActionResult<IEnumerable<InvoiceDto>>> GetInvoices([FromQuery] string? status)
	{
		var invoices = await LoadInvoicesAsync();

		if (!string.IsNullOrWhiteSpace(status))
		{
			invoices = invoices
				.Where(i => string.Equals(i.Status, status, StringComparison.OrdinalIgnoreCase))
				.ToList();
		}

		return Ok(invoices.OrderByDescending(i => i.IssuedOn));
	}

	/// <summary>Résumé AI Sales : montants En retard / Collecté / À recevoir.</summary>
	[HttpGet("summary")]
	public async Task<ActionResult<SalesSummaryDto>> GetSummary()
	{
		var invoices = await LoadInvoicesAsync();
		decimal Sum(string s) => invoices.Where(i => i.Status == s).Sum(i => i.Amount);

		return Ok(new SalesSummaryDto(
			Overdue: Sum("Overdue"),
			Collected: Sum("Collected"),
			Receivable: Sum("Receivable")));
	}

	/// <summary>Liste des clients pour le sélecteur de facture (s0713GetClientsLookup).</summary>
	[HttpGet("customers")]
	public async Task<ActionResult<IEnumerable<ClientLookupDto>>> GetCustomers()
	{
		var list = new List<ClientLookupDto>();

		await using var conn = new SqlConnection(_connectionString);
		await conn.OpenAsync();
		await using var cmd = new SqlCommand("s0713GetClientsLookup", conn) { CommandType = CommandType.StoredProcedure };
		cmd.Parameters.AddWithValue("@CompanyGUID", CompanyGuid);

		await using var reader = await cmd.ExecuteReaderAsync();
		var cols = ColumnSet(reader);
		var idIdx = Ordinal(reader, cols, "Id");
		var guidIdx = Ordinal(reader, cols, "PartyGUID");
		var nameIdx = Ordinal(reader, cols, "DisplayName", "Name");

		while (await reader.ReadAsync())
		{
			var id = idIdx is int ii && !reader.IsDBNull(ii) ? Convert.ToInt32(reader.GetValue(ii)) : 0;
			var guid = guidIdx is int gi && !reader.IsDBNull(gi) ? reader.GetGuid(gi) : Guid.Empty;
			var name = StripHtml(ReadString(reader, nameIdx, "Client"));
			list.Add(new ClientLookupDto(id, guid, name));
		}

		return Ok(list);
	}

	/// <summary>
	/// Crée une facture client (brouillon) via s0040SaveInvoiceItems (TVP dbo.TVP_InvoiceItem_v6).
	/// L'en-tête, le numéro provisoire (BROUILLON-…) et les totaux/taxes sont calculés par la base.
	/// </summary>
	[HttpPost("invoices")]
	public async Task<ActionResult<CreateInvoiceResult>> CreateInvoice([FromBody] CreateInvoiceRequest request)
	{
		if (request.PartyGUID == Guid.Empty || request.Lines is null || request.Lines.Count == 0)
		{
			return BadRequest(new { message = "Client et au moins une ligne sont requis." });
		}

		var items = BuildItemsTable(request.Lines);

		await using var conn = new SqlConnection(_connectionString);
		await conn.OpenAsync();
		await using var cmd = new SqlCommand("s0040SaveInvoiceItems", conn) { CommandType = CommandType.StoredProcedure };
		cmd.Parameters.AddWithValue("@InvoiceId", 0);
		cmd.Parameters.AddWithValue("@toPost", 0);
		cmd.Parameters.AddWithValue("@PartyGUID", request.PartyGUID);
		cmd.Parameters.AddWithValue("@DueDate", request.DueDate.ToDateTime(TimeOnly.MinValue));
		cmd.Parameters.AddWithValue("@IssueDate", request.IssueDate.ToDateTime(TimeOnly.MinValue));
		cmd.Parameters.AddWithValue("@DocumentType", "CLIENT");
		cmd.Parameters.AddWithValue("@CompanyGUID", CompanyGuid);
		cmd.Parameters.Add(new SqlParameter("@Items", SqlDbType.Structured)
		{
			TypeName = "dbo.TVP_InvoiceItem_v6",
			Value = items,
		});

		var result = await cmd.ExecuteScalarAsync();
		var newId = result is null || result is DBNull ? 0 : Convert.ToInt32(result);
		return Ok(new CreateInvoiceResult(newId));
	}

	/// <summary>Construit le TVP des lignes (mêmes colonnes/ordre que l'app web).</summary>
	private static DataTable BuildItemsTable(IReadOnlyList<CreateInvoiceLine> lines)
	{
		var dt = new DataTable();
		dt.Columns.Add("Id", typeof(int));
		dt.Columns.Add("ProductId", typeof(int));
		dt.Columns.Add("ProductName", typeof(string));
		dt.Columns.Add("AccountId", typeof(int));
		dt.Columns.Add("AccountName", typeof(string));
		dt.Columns.Add("Description", typeof(string));
		dt.Columns.Add("Qty", typeof(double));
		dt.Columns.Add("UnitPrice", typeof(double));
		dt.Columns.Add("Amount", typeof(double));
		dt.Columns.Add("Dirty", typeof(int));
		dt.Columns.Add("Deleted", typeof(int));
		dt.Columns.Add("Ordre", typeof(int));
		dt.Columns.Add("TaxeStatus", typeof(int));

		for (var i = 0; i < lines.Count; i++)
		{
			var line = lines[i];
			var amount = Math.Round(line.Qty * line.UnitPrice, 2);
			dt.Rows.Add(
				-(i + 1),               // Id : négatif = nouvelle ligne
				0,                      // ProductId
				DBNull.Value,           // ProductName
				0,                      // AccountId
				DBNull.Value,           // AccountName
				line.Description ?? string.Empty,
				(double)line.Qty,
				(double)line.UnitPrice,
				(double)amount,
				1,                      // Dirty
				0,                      // Deleted
				i + 1,                  // Ordre
				line.TaxeStatus <= 0 ? 1 : line.TaxeStatus);
		}

		return dt;
	}

	/// <summary>Détail d'une facture : en-tête (s0038GetInvoiceById) + lignes (s0039GetInvoiceItems).</summary>
	[HttpGet("invoices/{id:int}")]
	public async Task<ActionResult<InvoiceDetailDto>> GetInvoice(int id)
	{
		await using var conn = new SqlConnection(_connectionString);
		await conn.OpenAsync();

		// ----- En-tête -----
		string number = string.Empty, clientName = "Client", address = string.Empty, note = string.Empty, po = string.Empty;
		decimal subTotal = 0, tps = 0, tvq = 0, total = 0;
		DateTime? issued = null, due = null;
		var found = false;

		await using (var cmd = new SqlCommand("s0038GetInvoiceById", conn) { CommandType = CommandType.StoredProcedure })
		{
			cmd.Parameters.AddWithValue("@InvoiceId", id);
			await using var reader = await cmd.ExecuteReaderAsync();
			var cols = ColumnSet(reader);
			if (await reader.ReadAsync())
			{
				found = true;
				number = StripHtml(ReadString(reader, Ordinal(reader, cols, "DocumentNumber", "RefNo"), string.Empty));
				clientName = StripHtml(ReadString(reader, Ordinal(reader, cols, "Name", "DisplayName"), "Client"));
				address = StripHtml(ReadString(reader, Ordinal(reader, cols, "FullName"), string.Empty));
				subTotal = ReadDecimal(reader, Ordinal(reader, cols, "SubTotal"));
				tps = ReadDecimal(reader, Ordinal(reader, cols, "TPS"));
				tvq = ReadDecimal(reader, Ordinal(reader, cols, "TVQ"));
				total = ReadDecimal(reader, Ordinal(reader, cols, "Total"));
				note = StripHtml(ReadString(reader, Ordinal(reader, cols, "Note"), string.Empty));
				po = StripHtml(ReadString(reader, Ordinal(reader, cols, "PoNumber"), string.Empty));
				issued = ReadDate(reader, Ordinal(reader, cols, "IssueDate", "DocumentDate"));
				due = ReadDate(reader, Ordinal(reader, cols, "DueDate"));
			}
		}

		if (!found)
		{
			return NotFound();
		}

		// ----- Payé / Reste à payer -----
		decimal paid = 0;
		await using (var cmd = new SqlCommand("s0712GetInvoicePaid", conn) { CommandType = CommandType.StoredProcedure })
		{
			cmd.Parameters.AddWithValue("@InvoiceId", id);
			var result = await cmd.ExecuteScalarAsync();
			if (result is not null && result is not DBNull)
			{
				paid = Convert.ToDecimal(result);
			}
		}

		var balance = total - paid;

		// ----- Lignes -----
		var lines = new List<InvoiceLineDto>();
		await using (var cmd = new SqlCommand("s0039GetInvoiceItems", conn) { CommandType = CommandType.StoredProcedure })
		{
			cmd.Parameters.AddWithValue("@InvoiceId", id);
			await using var reader = await cmd.ExecuteReaderAsync();
			var cols = ColumnSet(reader);
			var descIdx = Ordinal(reader, cols, "Description");
			var qtyIdx = Ordinal(reader, cols, "Qty", "Nombre");
			var priceIdx = Ordinal(reader, cols, "UnitPrice", "Prix");
			var amountIdx = Ordinal(reader, cols, "Amount", "Montant");

			while (await reader.ReadAsync())
			{
				lines.Add(new InvoiceLineDto(
					StripHtml(ReadString(reader, descIdx, string.Empty)),
					ReadDecimal(reader, qtyIdx),
					ReadDecimal(reader, priceIdx),
					ReadDecimal(reader, amountIdx)));
			}
		}

		return Ok(new InvoiceDetailDto(
			id, number, clientName, address,
			issued.HasValue ? DateOnly.FromDateTime(issued.Value) : DateOnly.FromDateTime(DateTime.Today),
			due.HasValue ? DateOnly.FromDateTime(due.Value) : DateOnly.FromDateTime(DateTime.Today),
			subTotal, tps, tvq, total, paid, balance, note, po, lines));
	}

	private async Task<List<InvoiceDto>> LoadInvoicesAsync()
	{
		var list = new List<InvoiceDto>();

		await using var conn = new SqlConnection(_connectionString);
		await conn.OpenAsync();
		await using var cmd = new SqlCommand("s0026GetCustomersInvoices", conn) { CommandType = CommandType.StoredProcedure };
		cmd.Parameters.AddWithValue("@CompanyGUID", CompanyGuid);
		cmd.Parameters.AddWithValue("@Search", string.Empty);

		await using var reader = await cmd.ExecuteReaderAsync();
		var cols = ColumnSet(reader);
		var idIdx = Ordinal(reader, cols, "Id");
		var numberIdx = Ordinal(reader, cols, "DocumentNumber", "RefNo", "NoFacture", "Numero");
		var nameIdx = Ordinal(reader, cols, "DisplayName", "Name", "NomClient", "Beneficiaire", "Nom");
		var descIdx = Ordinal(reader, cols, "Description", "Note");
		var amountIdx = Ordinal(reader, cols, "Total", "Montant");
		var statutIdx = Ordinal(reader, cols, "StatutPaiement", "Statut");
		var issuedIdx = Ordinal(reader, cols, "DocumentDate", "IssueDate", "DateFacture");
		var dueIdx = Ordinal(reader, cols, "DueDate", "DateEcheance");

		while (await reader.ReadAsync())
		{
			var id = idIdx is int ii && !reader.IsDBNull(ii) ? Convert.ToInt32(reader.GetValue(ii)) : 0;
			var number = StripHtml(ReadString(reader, numberIdx, string.Empty));
			var name = StripHtml(ReadString(reader, nameIdx, "Client"));
			var desc = StripHtml(ReadString(reader, descIdx, string.Empty));
			var amount = ReadDecimal(reader, amountIdx);
			var status = MapStatus(ReadString(reader, statutIdx, string.Empty));
			var issued = ReadDate(reader, issuedIdx);
			var due = ReadDate(reader, dueIdx);

			list.Add(new InvoiceDto(
				id, number, name, desc, amount, status,
				issued.HasValue ? DateOnly.FromDateTime(issued.Value) : DateOnly.FromDateTime(DateTime.Today),
				due.HasValue ? DateOnly.FromDateTime(due.Value) : DateOnly.FromDateTime(DateTime.Today)));
		}

		return list;
	}

	// ----- Lecture défensive (colonnes de vue inconnues) -----
	private static HashSet<string> ColumnSet(SqlDataReader reader)
	{
		var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
		for (var i = 0; i < reader.FieldCount; i++)
		{
			set.Add(reader.GetName(i));
		}

		return set;
	}

	private static int? Ordinal(SqlDataReader reader, HashSet<string> cols, params string[] candidates)
	{
		foreach (var name in candidates)
		{
			if (cols.Contains(name))
			{
				return reader.GetOrdinal(name);
			}
		}

		return null;
	}

	private static decimal ReadDecimal(SqlDataReader reader, int? idx)
		=> idx is int i && !reader.IsDBNull(i) ? Convert.ToDecimal(reader.GetValue(i)) : 0m;

	private static string ReadString(SqlDataReader reader, int? idx, string fallback)
		=> idx is int i && !reader.IsDBNull(i) ? reader.GetValue(i).ToString() ?? fallback : fallback;

	private static DateTime? ReadDate(SqlDataReader reader, int? idx)
		=> idx is int i && !reader.IsDBNull(i) ? Convert.ToDateTime(reader.GetValue(i)) : null;

	/// <summary>Retire les balises HTML et décode les entités (certaines colonnes contiennent du HTML).</summary>
	private static string StripHtml(string? value)
	{
		if (string.IsNullOrEmpty(value))
		{
			return string.Empty;
		}

		var noTags = System.Text.RegularExpressions.Regex.Replace(value, "<[^>]+>", " ");
		var decoded = System.Net.WebUtility.HtmlDecode(noTags);
		return System.Text.RegularExpressions.Regex.Replace(decoded, "\\s+", " ").Trim();
	}
}
