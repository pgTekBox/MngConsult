namespace _60SecAI.Api.Dtos;

/// <summary>
/// Chiffres de l'onglet Aperçu / Résultats des Rapports financiers,
/// calculés à partir des procédures stockées de MngConsul.
/// </summary>
public record ReportOverviewDto(
	decimal Revenus,
	decimal Depenses,
	decimal BeneficeBrut,
	decimal BeneficeNet,
	decimal MargeBrutePct,
	decimal Tresorerie,
	decimal ARecevoir);

// ----- Bilan -----
public record BilanLine(string Description, decimal Amount);

public record BilanSectionDto(List<BilanLine> Lines, decimal Subtotal);

public record ReportBilanDto(
	BilanSectionDto ActifsCourants,
	BilanSectionDto ActifsLongTerme,
	decimal TotalActifs,
	BilanSectionDto PassifsCourants,
	BilanSectionDto PassifsLongTerme,
	decimal TotalPassifs,
	decimal ValeurNette,
	decimal TotalPassifsPlusValeurNette,
	decimal PassifsPct,
	decimal ValeurNettePct);

// ----- Trésorerie (flux, méthode indirecte) -----
public record TresorerieLine(string Description, decimal Amount);

public record ReportTresorerieDto(
	List<TresorerieLine> Exploitation,
	decimal TotalExploitation,
	List<TresorerieLine> Investissement,
	decimal TotalInvestissement,
	List<TresorerieLine> Financement,
	decimal TotalFinancement,
	decimal VariationNette);

// ----- Comptes (clients / fournisseurs) -----
public record ComptesClientLine(string Name, decimal Amount, string Bucket); // Bucket : "0-30" | "31-60" | "90+"

public record ComptesSupplierLine(string Name, decimal Amount, DateOnly? DueDate);

public record ReportComptesDto(
	decimal TotalClients,
	decimal Aging0_30,
	decimal Aging31_60,
	decimal Aging90Plus,
	List<ComptesClientLine> Clients,
	decimal TotalFournisseurs,
	List<ComptesSupplierLine> Fournisseurs);

// ----- Taxes (TPS/TVQ, calcul depuis les factures) -----
public record ReportTaxesDto(
	decimal TpsPercue,
	decimal TpsPayee,
	decimal TpsNette,
	decimal TvqPercue,
	decimal TvqPayee,
	decimal TvqNette,
	decimal TotalCollecte,
	decimal TotalPaye,
	decimal TotalARemettre);
