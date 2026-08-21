namespace _60SecAI.Services;

/// <summary>Configuration de l'accès à l'API.</summary>
public class ApiSettings
{
	/// <summary>
	/// URL de base de l'API.
	/// - Release : serveur de production (api.60sec.ca:6090).
	/// - Debug   : API locale sur le port 5048 (émulateur Android = 10.0.2.2, sinon localhost).
	/// </summary>
	public string BaseUrl { get; init; } =
#if DEBUG
		DeviceInfo.Platform == DevicePlatform.Android
			? "http://10.0.2.2:5048/"
			: "http://localhost:5048/";
#else
		"http://api.60sec.ca:6090/";
#endif
}
