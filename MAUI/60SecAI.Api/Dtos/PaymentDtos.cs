namespace _60SecAI.Api.Dtos;

public record PaymentDto(
	int Id,
	string Payer,
	decimal Amount,
	string Category,
	DateOnly DueDate,
	string Detail,
	string DelayText);
