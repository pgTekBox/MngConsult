using Microsoft.Extensions.DependencyInjection;

namespace _60SecAI.Services;

/// <summary>Accès au conteneur de DI depuis les pages (créées hors DI par le Shell).</summary>
public static class ServiceHelper
{
	public static T GetService<T>() where T : notnull
		=> Current.GetRequiredService<T>();

	private static IServiceProvider Current =>
		IPlatformApplication.Current?.Services
		?? throw new InvalidOperationException("Le fournisseur de services n'est pas disponible.");
}
