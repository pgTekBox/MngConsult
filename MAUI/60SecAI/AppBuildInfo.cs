using System.Reflection;

namespace _60SecAI;

/// <summary>
/// Informations de version/build affichées sur l'écran de login.
/// La date de build est estampillée automatiquement à chaque publication (Release)
/// via l'attribut d'assembly [AssemblyMetadata("BuildDate", ...)] (voir 60SecAI.csproj).
/// </summary>
public static class AppBuildInfo
{
	/// <summary>Date/heure de compilation (Release), ou "dev" en Debug.</summary>
	public static string BuildDate =>
		Assembly.GetExecutingAssembly()
			.GetCustomAttributes<AssemblyMetadataAttribute>()
			.FirstOrDefault(a => a.Key == "BuildDate")?.Value ?? "dev";

	/// <summary>Numéro de version affiché (ApplicationDisplayVersion).</summary>
	public static string Version => AppInfo.Current.VersionString;

	/// <summary>Ligne complète, ex. « v1.0 • build 2026-08-26 15:04 ».</summary>
	public static string Display => $"v{Version} • build {BuildDate}";
}
