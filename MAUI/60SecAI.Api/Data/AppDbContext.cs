using _60SecAI.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace _60SecAI.Api.Data;

/// <summary>
/// Contexte EF Core en LECTURE sur la base existante MngConsul.
/// Aucune migration / EnsureCreated : le schéma appartient à l'application Web.
/// Pour l'instant : uniquement l'authentification (table T015User).
/// </summary>
public class AppDbContext : DbContext
{
	public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
	{
	}

	public DbSet<AppUser> Users => Set<AppUser>();

	protected override void OnModelCreating(ModelBuilder modelBuilder)
	{
		base.OnModelCreating(modelBuilder);

		modelBuilder.Entity<AppUser>().ToTable("T015User");
	}
}
