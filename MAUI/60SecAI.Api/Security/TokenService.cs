using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using _60SecAI.Api.Models;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace _60SecAI.Api.Security;

public interface ITokenService
{
	(string Token, DateTime ExpiresAt) CreateToken(AppUser user);
}

public class TokenService : ITokenService
{
	public const string CompanyClaim = "companyGuid";

	private readonly JwtOptions _options;

	public TokenService(IOptions<JwtOptions> options)
	{
		_options = options.Value;
	}

	public (string Token, DateTime ExpiresAt) CreateToken(AppUser user)
	{
		var expiresAt = DateTime.UtcNow.AddMinutes(_options.ExpiryMinutes);

		var claims = new List<Claim>
		{
			new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
			new(JwtRegisteredClaimNames.Email, user.Email),
			new(ClaimTypes.Name, user.DisplayName),
			new(ClaimTypes.Role, user.Role),
			new(CompanyClaim, user.CompanyGUID?.ToString() ?? Guid.Empty.ToString()),
			new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
		};

		var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.Key));
		var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

		var token = new JwtSecurityToken(
			issuer: _options.Issuer,
			audience: _options.Audience,
			claims: claims,
			expires: expiresAt,
			signingCredentials: credentials);

		var jwt = new JwtSecurityTokenHandler().WriteToken(token);
		return (jwt, expiresAt);
	}
}
