using APIWebMngConsul.Controllers;
using APIWebMngConsul.Security;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Secrets locaux (chaîne de connexion, clé de signature des jetons) : dans
// appsettings.Local.json, ignoré par git. Aucun identifiant n'est dans le code.
builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false);

builder.Services.AddControllers();

builder.Services.Configure<FormOptions>(o =>
{
    o.MultipartBodyLengthLimit = 20 * 1024 * 1024;
});

builder.Services.AddScoped<IReceiptRepository, ReceiptRepository>();

// Jeton de l'application mobile : exigé par le dépôt de reçus.
builder.Services.AddSingleton<JwtGuard>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "APIWebMngConsul", Version = "v1" });
});

var app = builder.Build();

// La documentation interactive n'est publiée qu'en développement : elle
// décrivait tous les points d'entrée à quiconque, en production.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapControllers();

app.Run();
