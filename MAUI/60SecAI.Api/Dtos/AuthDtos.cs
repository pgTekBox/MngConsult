namespace _60SecAI.Api.Dtos;

public record LoginRequest(string Username, string Password);

public record AuthResponse(string Token, DateTime ExpiresAt, string DisplayName, string Role);

public record UserInfo(string Username, string DisplayName, string Role);
