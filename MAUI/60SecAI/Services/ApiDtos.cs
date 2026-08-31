namespace _60SecAI.Services;

// Contrats échangés avec l'API (doivent correspondre aux DTOs de 60SecAI.Api).

public record LoginRequest(string Username, string Password);

public record AuthResponse(string Token, DateTime ExpiresAt, string DisplayName, string Role);

public record InvoiceDto(
	int Id,
	string Number,
	string ClientName,
	string Description,
	decimal Amount,
	string Status,
	DateOnly IssuedOn,
	DateOnly DueOn);

public record SalesSummaryDto(decimal Overdue, decimal Collected, decimal Receivable);

public record ClientLookupDto(int Id, Guid PartyGUID, string DisplayName);

public record CreateClientRequest(string Name);

public record ProductLookupDto(int Id, string Name, decimal Price, string? AccountNumber = null);

public record AccountInfoDto(string Number, string Name);

public record CreateProductRequest(string Name, decimal Price);

public record CreateInvoiceLine(string Description, decimal Qty, decimal UnitPrice, int TaxeStatus = 1, string? AccountNumber = null);

public record CreateInvoiceRequest(
	Guid PartyGUID,
	DateOnly IssueDate,
	DateOnly DueDate,
	List<CreateInvoiceLine> Lines,
	double? Latitude = null,
	double? Longitude = null);

public record CreateInvoiceResult(int Id);

/// <summary>Métadonnées d'une photo de facture (Created = date/heure de prise).</summary>
public record InvoicePhotoDto(int Id, string FileName, string ContentType, int SizeBytes, DateTime? Created);

public record InvoiceLineDto(string Description, decimal Qty, decimal UnitPrice, decimal Amount);

public record InvoiceDetailDto(
	int Id,
	string Number,
	string ClientName,
	string ClientAddress,
	DateOnly IssuedOn,
	DateOnly DueOn,
	decimal SubTotal,
	decimal Tps,
	decimal Tvq,
	decimal Total,
	decimal Paid,
	decimal Balance,
	string Note,
	string PoNumber,
	List<InvoiceLineDto> Lines,
	double? Latitude = null,
	double? Longitude = null);

public record PaymentDto(
	int Id,
	string Payer,
	decimal Amount,
	string Category,
	DateOnly DueDate,
	string Detail,
	string DelayText);

public record ReportOverviewDto(
	decimal Revenus,
	decimal Depenses,
	decimal BeneficeBrut,
	decimal BeneficeNet,
	decimal MargeBrutePct,
	decimal Tresorerie,
	decimal ARecevoir);

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

public record TresorerieLine(string Description, decimal Amount);

public record ReportTresorerieDto(
	List<TresorerieLine> Exploitation,
	decimal TotalExploitation,
	List<TresorerieLine> Investissement,
	decimal TotalInvestissement,
	List<TresorerieLine> Financement,
	decimal TotalFinancement,
	decimal VariationNette);

public record ComptesClientLine(string Name, decimal Amount, string Bucket);

public record ComptesSupplierLine(string Name, decimal Amount, DateOnly? DueDate);

public record ReportComptesDto(
	decimal TotalClients,
	decimal Aging0_30,
	decimal Aging31_60,
	decimal Aging90Plus,
	List<ComptesClientLine> Clients,
	decimal TotalFournisseurs,
	List<ComptesSupplierLine> Fournisseurs);

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
