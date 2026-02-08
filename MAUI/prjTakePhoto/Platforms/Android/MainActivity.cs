using Android.App;
using Android.Content.PM;
using Android.OS;
using AndroidX.Activity;
using AndroidX.Activity.Result;
using AndroidX.Activity.Result.Contract;

namespace prjTakePhoto;

[Activity(
    Theme = "@style/Maui.SplashTheme",
    MainLauncher = true,
    ConfigurationChanges =
        ConfigChanges.ScreenSize |
        ConfigChanges.Orientation |
        ConfigChanges.UiMode |
        ConfigChanges.ScreenLayout |
        ConfigChanges.SmallestScreenSize |
        ConfigChanges.Density)]
public class MainActivity : MauiAppCompatActivity
{
   // internal static ActivityResultLauncher<IntentSenderRequest>? ScanLauncher { get; private set; }
//    internal static Action<ActivityResult>? ScanResultCallback { get; set; }

   // public static ActivityResultLauncher<IntentSenderRequest>? ScanLauncher;
    public static ActivityResultLauncher? ScanLauncher;

    public static Action<ActivityResult>? ScanResultCallback;




    protected override void OnCreate(Bundle? savedInstanceState)
    {
        base.OnCreate(savedInstanceState);

        // ✅ Register early (OnCreate) to avoid IllegalStateException about RESUMED/STARTED
        ScanLauncher = RegisterForActivityResult(
            new ActivityResultContracts.StartIntentSenderForResult(),
            new ActivityResultCallback(ar => ScanResultCallback?.Invoke(ar))
        );
    }

    private sealed class ActivityResultCallback : Java.Lang.Object, IActivityResultCallback
    {
        private readonly Action<ActivityResult> _handler;

        public ActivityResultCallback(Action<ActivityResult> handler)
        {
            _handler = handler;
        }

        public void OnActivityResult(Java.Lang.Object? result)
        {
            if (result is ActivityResult ar)
                _handler(ar);
        }
    }
}
