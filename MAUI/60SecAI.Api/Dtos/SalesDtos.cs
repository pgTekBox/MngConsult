namespace _60SecAI.Api.Dtos;

public record InvoiceDto(
	int Id,
	string Number,
	string ClientName,
	string Description,
	decimal Amount,
	string Status,
	DateOnly IssuedOn,
	DateOnly DueOn);

/// <summary>Résumé AI Sales (les trois status du tableau de bord).</summary>
public record SalesSummaryDto(decimal Overdue, decimal Collected, decimal Receivable);

// ----- Création d'une facture -----
public record ClientLookupDto(int Id, Guid PartyGUID, string DisplayName);

public record CreateClientRequest(string Name);

public record ProductLookupDto(int Id, string Name, decimal Price, string? AccountNumber = null);

/// <summary>Compte comptable (numero + nom) pour l'infobulle d'une ligne.</summary>
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

// ----- Envoi de facture par courriel -----
public record SendInvoiceRequest(bool IncludeSquare = false);

/// <summary>Status : Sent | NotFound | NoEmail | PdfFail. SquareStatus : NotRequested | Included | AlreadyPaid | NotConnected | NotGenerated | Error.</summary>
public record SendInvoiceResult(string Status, string? Email, string? DocNumber, string SquareStatus, string? SquareError);

/// <summary>Status : Created | AlreadyPaid | NotConnected | NotGenerated | Error | NotFound.</summary>
public record PaymentLinkResult(string Status, string? Url, string? DocNumber, string? Phone, decimal Amount, string? Error);

/// <summary>Métadonnées d'une photo de facture (sans le blob). Created = date/heure de prise.</summary>
public record InvoicePhotoDto(int Id, string FileName, string ContentType, int SizeBytes, DateTime? Created);

// ----- Détail d'une facture -----
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
