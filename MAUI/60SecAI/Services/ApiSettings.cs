namespace _60SecAI.Services;

/// <summary>Configuration de l'accès à l'API.</summary>
public class ApiSettings
{
	/// <summary>
	/// URL de base de l'API.
	/// - Émulateur Android : 10.0.2.2 pointe vers le localhost de la machine hôte.
	/// - Windows / iOS simulateur : localhost.
	/// À remplacer par l'URL du serveur en production.
	/// </summary>
	public string BaseUrl { get; init; } =
		DeviceInfo.Platform == DevicePlatform.Android
			? "http://10.0.2.2:5048/"
			: "http://localhost:5048/";
}
