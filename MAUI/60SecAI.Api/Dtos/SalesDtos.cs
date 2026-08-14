namespace _60SecAI.Api.Dtos;

public record InvoiceDto(
	int Id,
	string ClientName,
	string Description,
	decimal Amount,
	string Status,
	DateOnly IssuedOn,
	DateOnly DueOn);

/// <summary>Résumé AI Sales (les trois status du tableau de bord).</summary>
public record SalesSummaryDto(decimal Overdue, decimal Collected, decimal Receivable);
