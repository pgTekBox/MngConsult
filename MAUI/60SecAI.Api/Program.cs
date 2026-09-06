using System.Text;
using _60SecAI.Api.Data;
using _60SecAI.Api.Security;
using _60SecAI.Api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

// QuestPDF : licence communautaire (génération du PDF de facture).
QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;

var builder = WebApplication.CreateBuilder(args);

// ----- Base de données (SQL Server) -----
builder.Services.AddDbContext<AppDbContext>(options =>
	options.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

// ----- Envoi de facture par courriel (PDF + lien Square) -----
builder.Services.AddHttpClient();
builder.Services.AddScoped<InvoicePdfService>();
builder.Services.AddScoped<SquareService>();
builder.Services.AddScoped<MailQueueService>();
builder.Services.AddScoped<InvoiceEmailService>();

// ----- Sécurité -----
builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection(JwtOptions.SectionName));
builder.Services.AddScoped<ITokenService, TokenService>();

var jwt = builder.Configuration.GetSection(JwtOptions.SectionName).Get<JwtOptions>()!;

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
	.AddJwtBearer(options =>
	{
		options.TokenValidationParameters = new TokenValidationParameters
		{
			ValidateIssuer = true,
			ValidateAudience = true,
			ValidateLifetime = true,
			ValidateIssuerSigningKey = true,
			ValidIssuer = jwt.Issuer,
			ValidAudience = jwt.Audience,
			IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Key)),
			ClockSkew = TimeSpan.FromSeconds(30),
		};
	});

builder.Services.AddAuthorization();

// ----- CORS (dev : autorise l'app cliente à tester via navigateur) -----
builder.Services.AddCors(options =>
	options.AddPolicy("DevCors", policy =>
		policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

// ----- API -----
builder.Services.AddControllers();

var app = builder.Build();

// ----- Pipeline -----
if (app.Environment.IsDevelopment())
{
	app.UseCors("DevCors");

	// ⚠️ SEEDER DÉSACTIVÉ : l'API pointe sur la base de PRODUCTION MngConsul.
	// Ne jamais exécuter EnsureCreated/seed sur cette base.
	// await DbSeeder.SeedAsync(app.Services);
}
else
{
	// Redirection HTTPS en production uniquement (facilite les tests émulateur en dev).
	app.UseHttpsRedirection();
}

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
