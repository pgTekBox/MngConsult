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
public class ReportsController : ControllerBase
{
	private readonly string _connectionString;

	public ReportsController(IConfiguration configuration)
	{
		_connectionString = configuration.GetConnectionString("Default")
			?? throw new InvalidOperationException("Chaîne de connexion 'Default' absente.");
	}

	private Guid CompanyGuid =>
		Guid.TryParse(User.FindFirstValue(TokenService.CompanyClaim), out var g) ? g : Guid.Empty;

	/// <summary>
	/// Aperçu financier (Revenus / Dépenses / Bénéfice net / Marge brute / Trésorerie / À recevoir)
	/// pour la période demandée (month | quarter | year). Lecture seule.
	/// </summary>
	[HttpGet("overview")]
	public async Task<ActionResult<ReportOverviewDto>> GetOverview([FromQuery] string period = "month")
	{
		var (start, end) = ResolvePeriod(period);
		var company = CompanyGuid;

		await using var conn = new SqlConnection(_connectionString);
		await conn.OpenAsync();

		// ----- État des résultats : s0085GetEtatResultats -----
		decimal revenus = 0, coutVentes = 0, charges = 0, impots = 0;
		await using (var cmd = new SqlCommand("s0085GetEtatResultats", conn) { CommandType = CommandType.StoredProcedure })
		{
			cmd.Parameters.AddWithValue("@CompanyGUID", company);
			cmd.Parameters.AddWithValue("@DateDebut", start);
			cmd.Parameters.AddWithValue("@DateFin", end);

			await using var reader = await cmd.ExecuteReaderAsync();
			var parentIdx = reader.GetOrdinal("ClasseParentId");
			var soldeIdx = reader.GetOrdinal("Solde");
			while (await reader.ReadAsync())
			{
				var parent = reader.IsDBNull(parentIdx) ? 0 : reader.GetInt32(parentIdx);
				var solde = reader.IsDBNull(soldeIdx) ? 0m : reader.GetDecimal(soldeIdx);
				switch (parent)
				{
					case 6: revenus += solde; break;    // Revenus (ventes)
					case 7: coutVentes += solde; break; // Coût des ventes
					case 8: charges += solde; break;    // Charges d'exploitation
					case 9: impots += solde; break;     // Impôts / extraordinaires
				}
			}
		}

		var beneficeBrut = revenus - coutVentes;
		var beneficeNet = beneficeBrut - charges - impots;
		var depenses = coutVentes + charges + impots;
		var margeBrutePct = revenus != 0 ? Math.Round(beneficeBrut / revenus * 100m, 1) : 0m;

		// ----- Solde bancaire (Trésorerie) : s0710GetSoldeBancaire -----
		decimal tresorerie = 0;
		await using (var cmd = new SqlCommand("s0710GetSoldeBancaire", conn) { CommandType = CommandType.StoredProcedure })
		{
			cmd.Parameters.AddWithValue("@CompanyGUID", company);
			var result = await cmd.ExecuteScalarAsync();
			if (result is not null && result is not DBNull)
			{
				tresorerie = Convert.ToDecimal(result);
			}
		}

		// ----- À recevoir des clients : s0026GetCustomersInvoices (somme des ResteAPayer) -----
		decimal aRecevoir = 0;
		await using (var cmd = new SqlCommand("s0026GetCustomersInvoices", conn) { CommandType = CommandType.StoredProcedure })
		{
			cmd.Parameters.AddWithValue("@CompanyGUID", company);
			cmd.Parameters.AddWithValue("@Search", string.Empty);

			await using var reader = await cmd.ExecuteReaderAsync();
			var resteIdx = reader.GetOrdinal("ResteAPayer");
			while (await reader.ReadAsync())
			{
				aRecevoir += reader.IsDBNull(resteIdx) ? 0m : reader.GetDecimal(resteIdx);
			}
		}

		return Ok(new ReportOverviewDto(
			Revenus: revenus,
			Depenses: depenses,
			BeneficeBrut: beneficeBrut,
			BeneficeNet: beneficeNet,
			MargeBrutePct: margeBrutePct,
			Tresorerie: tresorerie,
			ARecevoir: aRecevoir));
	}

	/// <summary>
	/// Bilan (Actifs / Passifs / Valeur nette) à une date donnée, via s0086GetBilan.
	/// Les lignes sont regroupées par sous-classe comme dans wbfBilan. Lecture seule.
	/// </summary>
	[HttpGet("bilan")]
	public async Task<ActionResult<ReportBilanDto>> GetBilan([FromQuery] DateTime? asOf)
	{
		var date = asOf ?? DateTime.Today;
		var company = CompanyGuid;

		// parent (ClasseParentId) -> (sous-classe -> somme des soldes), ordre d'insertion préservé.
		var byParent = new Dictionary<int, Dictionary<string, decimal>>();
		decimal beneficeNet = 0;

		await using var conn = new SqlConnection(_connectionString);
		await conn.OpenAsync();

		await using (var cmd = new SqlCommand("s0086GetBilan", conn) { CommandType = CommandType.StoredProcedure })
		{
			cmd.Parameters.AddWithValue("@CompanyGUID", company);
			cmd.Parameters.AddWithValue("@DateBilan", date);

			await using var reader = await cmd.ExecuteReaderAsync();

			var parentIdx = reader.GetOrdinal("ClasseParentId");
			var sousIdx = reader.GetOrdinal("SousClasseDescription");
			var nomIdx = reader.GetOrdinal("Nom");
			var soldeIdx = reader.GetOrdinal("Solde");

			while (await reader.ReadAsync())
			{
				var parent = reader.IsDBNull(parentIdx) ? 0 : reader.GetInt32(parentIdx);
				var solde = reader.IsDBNull(soldeIdx) ? 0m : reader.GetDecimal(soldeIdx);
				var label = !reader.IsDBNull(sousIdx) ? reader.GetString(sousIdx)
					: reader.IsDBNull(nomIdx) ? "—" : reader.GetString(nomIdx);

				if (!byParent.TryGetValue(parent, out var lines))
				{
					lines = new Dictionary<string, decimal>();
					byParent[parent] = lines;
				}

				lines[label] = lines.TryGetValue(label, out var existing) ? existing + solde : solde;
			}

			// Table(1) : bénéfice net de l'exercice (injecté dans les capitaux propres).
			if (await reader.NextResultAsync() && await reader.ReadAsync())
			{
				var bnIdx = reader.GetOrdinal("BeneficeNet");
				beneficeNet = reader.IsDBNull(bnIdx) ? 0m : reader.GetDecimal(bnIdx);
			}
		}

		BilanSectionDto Section(int parent)
		{
			var lines = byParent.TryGetValue(parent, out var d)
				? d.Select(kv => new BilanLine(kv.Key, kv.Value)).ToList()
				: [];
			return new BilanSectionDto(lines, lines.Sum(l => l.Amount));
		}

		var actifsCourants = Section(1);
		var actifsLongTerme = Section(2);
		var totalActifs = actifsCourants.Subtotal + actifsLongTerme.Subtotal;

		var passifsCourants = Section(3);
		var passifsLongTerme = Section(4);
		var totalPassifs = passifsCourants.Subtotal + passifsLongTerme.Subtotal;

		var capitauxPropres = byParent.TryGetValue(5, out var cp) ? cp.Values.Sum() : 0m;
		var valeurNette = capitauxPropres + beneficeNet;
		var totalPassifsPlusVn = totalPassifs + valeurNette;

		var passifsPct = totalActifs != 0 ? Math.Round(totalPassifs / totalActifs * 100m, 0) : 0m;
		var vnPct = totalActifs != 0 ? Math.Round(valeurNette / totalActifs * 100m, 0) : 0m;

		return Ok(new ReportBilanDto(
			actifsCourants, actifsLongTerme, totalActifs,
			passifsCourants, passifsLongTerme, totalPassifs,
			valeurNette, totalPassifsPlusVn, passifsPct, vnPct));
	}

	// Codes de la vue de flux (méthode indirecte) → libellés d'affichage.
	private static readonly (string Code, string Label)[] ExploitationCodes =
	[
		("BeneficeNet", "Bénéfice net"),
		("Amortissement", "Amortissement"),
		("CreancesDouteuses", "Créances douteuses"),
		("GainPerteDispositionActif", "Gain/perte sur disposition"),
		("ImpotsDifferes", "Impôts différés"),
		("VarComptesClients", "Var. comptes clients"),
		("VarStocks", "Var. stocks"),
		("VarFraisPayesAvance", "Var. frais payés d'avance"),
		("VarTaxesRecevoir", "Var. taxes à recevoir"),
		("VarComptesFournisseurs", "Var. comptes fournisseurs"),
		("VarChargesAPayer", "Var. charges à payer"),
		("VarTaxesAPayer", "Var. taxes à payer"),
		("VarRetenuesSalariales", "Var. retenues salariales"),
		("VarRevenusReportes", "Var. revenus reportés"),
	];

	private static readonly (string Code, string Label)[] InvestissementCodes =
	[
		("AcquisitionImmoCorpo", "Acquisition immo. corporelles"),
		("DispositionImmoCorpo", "Disposition immo. corporelles"),
		("AcquisitionImmoIncorpo", "Acquisition immo. incorporelles"),
		("AcquisitionPlacements", "Acquisition de placements"),
		("DispositionPlacements", "Disposition de placements"),
	];

	private static readonly (string Code, string Label)[] FinancementCodes =
	[
		("EmpruntsNouveaux", "Nouveaux emprunts"),
		("RemboursementEmprunts", "Remboursement d'emprunts"),
		("EmissionActions", "Émission d'actions"),
		("DividendesVerses", "Dividendes versés"),
		("ApportsProprietaire", "Apports du propriétaire"),
		("RetraitsProprietaire", "Retraits du propriétaire"),
	];

	/// <summary>
	/// Flux de trésorerie (méthode indirecte), via s0087GetFluxTresorerie. Lecture seule.
	/// </summary>
	[HttpGet("tresorerie")]
	public async Task<ActionResult<ReportTresorerieDto>> GetTresorerie([FromQuery] string period = "month")
	{
		var (start, end) = ResolvePeriod(period);
		var company = CompanyGuid;

		var values = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);

		await using var conn = new SqlConnection(_connectionString);
		await conn.OpenAsync();

		await using (var cmd = new SqlCommand("s0087GetFluxTresorerie", conn) { CommandType = CommandType.StoredProcedure })
		{
			cmd.Parameters.AddWithValue("@CompanyGUID", company);
			cmd.Parameters.AddWithValue("@DateDebut", start);
			cmd.Parameters.AddWithValue("@DateFin", end);

			await using var reader = await cmd.ExecuteReaderAsync();
			var codeIdx = reader.GetOrdinal("Code");
			var montantIdx = reader.GetOrdinal("Montant");
			while (await reader.ReadAsync())
			{
				if (reader.IsDBNull(codeIdx))
				{
					continue;
				}

				var code = reader.GetString(codeIdx);
				var montant = reader.IsDBNull(montantIdx) ? 0m : reader.GetDecimal(montantIdx);
				values[code] = montant;
			}
		}

		(List<TresorerieLine> Lines, decimal Total) Build((string Code, string Label)[] codes)
		{
			var lines = new List<TresorerieLine>();
			decimal total = 0;
			foreach (var (code, label) in codes)
			{
				var amount = values.TryGetValue(code, out var v) ? v : 0m;
				total += amount;
				if (amount != 0m)
				{
					lines.Add(new TresorerieLine(label, amount));
				}
			}

			return (lines, total);
		}

		var (exploit, totalExploit) = Build(ExploitationCodes);
		var (invest, totalInvest) = Build(InvestissementCodes);
		var (finance, totalFinance) = Build(FinancementCodes);
		var variationNette = totalExploit + totalInvest + totalFinance;

		return Ok(new ReportTresorerieDto(
			exploit, totalExploit,
			invest, totalInvest,
			finance, totalFinance,
			variationNette));
	}

	/// <summary>
	/// Comptes clients (à recevoir, avec âge) et fournisseurs (à payer),
	/// via s0026GetCustomersInvoices et s0023GetSuppliersInvoices. Lecture seule.
	/// </summary>
	[HttpGet("comptes")]
	public async Task<ActionResult<ReportComptesDto>> GetComptes()
	{
		var company = CompanyGuid;
		var today = DateTime.Today;

		await using var conn = new SqlConnection(_connectionString);
		await conn.OpenAsync();

		// ----- Clients (à recevoir) -----
		var clientTotals = new Dictionary<string, decimal>();
		var clientWorst = new Dictionary<string, int>(); // 0 = 0-30, 1 = 31-60, 2 = 90+
		decimal aging0 = 0, aging1 = 0, aging2 = 0;

		await using (var cmd = new SqlCommand("s0026GetCustomersInvoices", conn) { CommandType = CommandType.StoredProcedure })
		{
			cmd.Parameters.AddWithValue("@CompanyGUID", company);
			cmd.Parameters.AddWithValue("@Search", string.Empty);

			await using var reader = await cmd.ExecuteReaderAsync();
			var cols = ColumnSet(reader);
			var resteIdx = Ordinal(reader, cols, "ResteAPayer", "Reste", "SoldeDu");
			var nameIdx = Ordinal(reader, cols, "DisplayName", "Name", "NomClient", "Beneficiaire");
			var dueIdx = Ordinal(reader, cols, "DueDate", "DateEcheance", "DocumentDate", "IssueDate");

			while (await reader.ReadAsync())
			{
				var reste = ReadDecimal(reader, resteIdx);
				if (reste <= 0m)
				{
					continue;
				}

				var name = ReadString(reader, nameIdx, "Client");
				var due = ReadDate(reader, dueIdx);
				var bucket = BucketIndex(today, due);

				switch (bucket)
				{
					case 0: aging0 += reste; break;
					case 1: aging1 += reste; break;
					default: aging2 += reste; break;
				}

				clientTotals[name] = clientTotals.TryGetValue(name, out var t) ? t + reste : reste;
				clientWorst[name] = clientWorst.TryGetValue(name, out var w) ? Math.Max(w, bucket) : bucket;
			}
		}

		var clients = clientTotals
			.Select(kv => new ComptesClientLine(kv.Key, kv.Value, BucketLabel(clientWorst[kv.Key])))
			.OrderByDescending(c => c.Amount)
			.ToList();
		var totalClients = aging0 + aging1 + aging2;

		// ----- Fournisseurs (à payer) -----
		var fournisseurs = new List<ComptesSupplierLine>();
		decimal totalFournisseurs = 0;

		await using (var cmd = new SqlCommand("s0023GetSuppliersInvoices", conn) { CommandType = CommandType.StoredProcedure })
		{
			cmd.Parameters.AddWithValue("@CompanyGUID", company);
			cmd.Parameters.AddWithValue("@Search", string.Empty);

			await using var reader = await cmd.ExecuteReaderAsync();
			var cols = ColumnSet(reader);
			var resteIdx = Ordinal(reader, cols, "ResteAPayer", "Reste", "SoldeDu");
			var nameIdx = Ordinal(reader, cols, "DisplayName", "Name", "NomFournisseur", "Beneficiaire");
			var dueIdx = Ordinal(reader, cols, "DueDate", "DateEcheance", "DocumentDate");

			while (await reader.ReadAsync())
			{
				var reste = ReadDecimal(reader, resteIdx);
				if (reste <= 0m)
				{
					continue;
				}

				var name = ReadString(reader, nameIdx, "Fournisseur");
				var due = ReadDate(reader, dueIdx);
				totalFournisseurs += reste;
				fournisseurs.Add(new ComptesSupplierLine(name, reste, due.HasValue ? DateOnly.FromDateTime(due.Value) : null));
			}
		}

		fournisseurs = fournisseurs.OrderBy(f => f.DueDate ?? DateOnly.MaxValue).ToList();

		return Ok(new ReportComptesDto(
			totalClients, aging0, aging1, aging2, clients,
			totalFournisseurs, fournisseurs));
	}

	/// <summary>
	/// Taxes TPS/TVQ pour la période, calculées directement depuis les factures
	/// (T060Document) — lecture pure, sans la procédure d'écriture sp_GenererRapportTaxe.
	/// Perçues = factures clients (DocumentTypeId 1) ; payées = factures fournisseurs (2,5).
	/// </summary>
	[HttpGet("taxes")]
	public async Task<ActionResult<ReportTaxesDto>> GetTaxes([FromQuery] string period = "month")
	{
		var (start, end) = ResolvePeriod(period);
		var company = CompanyGuid;

		decimal tpsPercue = 0, tvqPercue = 0, tpsPayee = 0, tvqPayee = 0;

		await using var conn = new SqlConnection(_connectionString);
		await conn.OpenAsync();
		await using (var cmd = new SqlCommand("s0711GetTaxesResume", conn) { CommandType = CommandType.StoredProcedure })
		{
			cmd.Parameters.AddWithValue("@CompanyGUID", company);
			cmd.Parameters.AddWithValue("@DateDebut", start);
			cmd.Parameters.AddWithValue("@DateFin", end);

			await using var reader = await cmd.ExecuteReaderAsync();
			if (await reader.ReadAsync())
			{
				tpsPercue = reader.IsDBNull(0) ? 0m : reader.GetDecimal(0);
				tvqPercue = reader.IsDBNull(1) ? 0m : reader.GetDecimal(1);
				tpsPayee = reader.IsDBNull(2) ? 0m : reader.GetDecimal(2);
				tvqPayee = reader.IsDBNull(3) ? 0m : reader.GetDecimal(3);
			}
		}

		var tpsNette = tpsPercue - tpsPayee;
		var tvqNette = tvqPercue - tvqPayee;

		return Ok(new ReportTaxesDto(
			tpsPercue, tpsPayee, tpsNette,
			tvqPercue, tvqPayee, tvqNette,
			TotalCollecte: tpsPercue + tvqPercue,
			TotalPaye: tpsPayee + tvqPayee,
			TotalARemettre: tpsNette + tvqNette));
	}

	// ----- Helpers de lecture défensifs (colonnes de vue inconnues) -----
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

	private static int BucketIndex(DateTime today, DateTime? due)
	{
		if (due is null)
		{
			return 0;
		}

		var days = (today - due.Value.Date).Days;
		return days <= 30 ? 0 : days <= 60 ? 1 : 2;
	}

	private static string BucketLabel(int index) => index switch
	{
		0 => "0-30",
		1 => "31-60",
		_ => "90+",
	};

	private static (DateTime Start, DateTime End) ResolvePeriod(string period)
	{
		var today = DateTime.Today;
		return period?.ToLowerInvariant() switch
		{
			"year" => (new DateTime(today.Year, 1, 1), today),
			"quarter" => (new DateTime(today.Year, ((today.Month - 1) / 3) * 3 + 1, 1), today),
			_ => (new DateTime(today.Year, today.Month, 1), today),
		};
	}
}
