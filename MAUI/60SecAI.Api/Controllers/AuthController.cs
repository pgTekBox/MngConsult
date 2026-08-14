using System.Security.Claims;
using _60SecAI.Api.Data;
using _60SecAI.Api.Dtos;
using _60SecAI.Api.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace _60SecAI.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
	private readonly AppDbContext _db;
	private readonly ITokenService _tokens;

	public AuthController(AppDbContext db, ITokenService tokens)
	{
		_db = db;
		_tokens = tokens;
	}

	/// <summary>
	/// Authentifie un utilisateur (par courriel) contre la table T015User
	/// et renvoie un token JWT. Mot de passe vérifié en bcrypt.
	/// </summary>
	[HttpPost("login")]
	[AllowAnonymous]
	public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
	{
		// Le champ "Username" transporte le courriel (identifiant de connexion).
		var email = (request.Username ?? string.Empty).Trim().ToLowerInvariant();

		var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email && !u.IsDeleted);
		if (user is null || !user.IsActive)
		{
			return Unauthorized(new { message = "Utilisateur ou mot de passe incorrect." });
		}

		bool valid;
		try
		{
			valid = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
		}
		catch
		{
			valid = false;
		}

		if (!valid)
		{
			return Unauthorized(new { message = "Utilisateur ou mot de passe incorrect." });
		}

		var (token, expiresAt) = _tokens.CreateToken(user);
		return Ok(new AuthResponse(token, expiresAt, user.DisplayName, user.Role));
	}

	/// <summary>Renvoie les informations de l'utilisateur connecté.</summary>
	[HttpGet("me")]
	[Authorize]
	public ActionResult<UserInfo> Me()
	{
		var email = User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Email) ?? "";
		var displayName = User.FindFirstValue(ClaimTypes.Name) ?? "";
		var role = User.FindFirstValue(ClaimTypes.Role) ?? "";
		return Ok(new UserInfo(email, displayName, role));
	}
}
