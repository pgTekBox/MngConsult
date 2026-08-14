namespace _60SecAI.Services;

// Contrats échangés avec l'API (doivent correspondre aux DTOs de 60SecAI.Api).

public record LoginRequest(string Username, string Password);

public record AuthResponse(string Token, DateTime ExpiresAt, string DisplayName, string Role);

public record InvoiceDto(
	int Id,
	string ClientName,
	string Description,
	decimal Amount,
	string Status,
	DateOnly IssuedOn,
	DateOnly DueOn);

public record SalesSummaryDto(decimal Overdue, decimal Collected, decimal Receivable);

public record PaymentDto(
	int Id,
	string Payer,
	decimal Amount,
	string Category,
	DateOnly DueDate,
	string Detail,
	string DelayText);
