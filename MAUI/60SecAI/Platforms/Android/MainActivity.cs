using Android.App;
using Android.Content.PM;
using Android.OS;
using AndroidX.Activity.Result;
using AndroidX.Activity.Result.Contract;

namespace _60SecAI;

[Activity(Theme = "@style/Maui.SplashTheme", MainLauncher = true, LaunchMode = LaunchMode.SingleTop, ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation | ConfigChanges.UiMode | ConfigChanges.ScreenLayout | ConfigChanges.SmallestScreenSize | ConfigChanges.Density)]
public class MainActivity : MauiAppCompatActivity
{
	// Launcher partagé pour le scanner de documents ML Kit (voir DocumentScannerService).
	public static ActivityResultLauncher? ScanLauncher;
	public static Action<ActivityResult>? ScanResultCallback;

	protected override void OnCreate(Bundle? savedInstanceState)
	{
		base.OnCreate(savedInstanceState);

		// Enregistré tôt (OnCreate) pour éviter l'IllegalStateException RESUMED/STARTED.
		ScanLauncher = RegisterForActivityResult(
			new ActivityResultContracts.StartIntentSenderForResult(),
			new ScanActivityResultCallback(ar => ScanResultCallback?.Invoke(ar)));
	}

	private sealed class ScanActivityResultCallback : Java.Lang.Object, IActivityResultCallback
	{
		private readonly Action<ActivityResult> _handler;

		public ScanActivityResultCallback(Action<ActivityResult> handler) => _handler = handler;

		public void OnActivityResult(Java.Lang.Object? result)
		{
			if (result is ActivityResult ar)
			{
				_handler(ar);
			}
		}
	}
}
