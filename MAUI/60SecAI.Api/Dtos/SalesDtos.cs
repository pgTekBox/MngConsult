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

public record CreateInvoiceLine(string Description, decimal Qty, decimal UnitPrice, int TaxeStatus = 1);

public record CreateInvoiceRequest(
	Guid PartyGUID,
	DateOnly IssueDate,
	DateOnly DueDate,
	List<CreateInvoiceLine> Lines);

public record CreateInvoiceResult(int Id);

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
	List<InvoiceLineDto> Lines);
