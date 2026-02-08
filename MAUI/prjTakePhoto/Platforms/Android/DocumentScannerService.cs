#if ANDROID
using System;
using System.IO;
//using System.Threading.Tasks;

using Android.App;
using Android.Content;
using Android.Gms.Tasks;
using Android.Net;

using AUri = Android.Net.Uri;
using SUri = System.Uri;

using AndroidX.Activity;
using AndroidX.Activity.Result;
using AndroidX.Activity.Result.Contract;

using Microsoft.Maui.ApplicationModel;
using Microsoft.Maui.Storage;
using Net.Google.MLKit.Vision.DocumentScanner;

using GmsTask = Android.Gms.Tasks.Task;
using SysTask = System.Threading.Tasks.Task;

using GmsTasks = Android.Gms.Tasks;
using SysTasks = System.Threading.Tasks;


//using System.Threading.Tasks;

namespace prjTakePhoto.Platforms.Android;

public sealed class DocumentScannerService : Java.Lang.Object, IDocumentScannerService
{
    private TaskCompletionSource<DocumentScanResult?>? _tcs;

    public async Task<DocumentScanResult?> OpenDocumentScannerAsync()
    {
        _tcs = new TaskCompletionSource<DocumentScanResult?>();
        
        var activity = Platform.CurrentActivity;
        if (activity is null)
        {
            _tcs.TrySetResult(null);
            return await _tcs.Task;
        }

        var launcher = await WaitForLauncherAsync();
        if (launcher is null)
        {
            _tcs.TrySetResult(null);
            return await _tcs.Task;
        }

        // ✅ Config scanner
        var options = new global::Net.Google.MLKit.Vision.DocumentScanner.GmsDocumentScannerOptions.Builder()
            .SetScannerMode(global::Net.Google.MLKit.Vision.DocumentScanner.GmsDocumentScannerOptions.ScannerModeBase )
            .SetResultFormats(global::Net.Google.MLKit.Vision.DocumentScanner.GmsDocumentScannerOptions.ResultFormatJpeg)
            .SetGalleryImportAllowed(false)
            .SetPageLimit(1)
            .Build();

        var scanner = global::Net.Google.MLKit.Vision.DocumentScanner.GmsDocumentScanning.GetClient(options);
        GmsTask gmsTask = scanner.GetStartScanIntent(activity);
        
        gmsTask.AddOnSuccessListener(new SuccessListener(intentSender =>
        {
            prjTakePhoto.MainActivity.ScanResultCallback = (ActivityResult ar) =>
            {
                try
                {
                    if (ar.ResultCode == (int)Result.Ok)
                    {
                        var scanResult = global::Net.Google.MLKit.Vision.DocumentScanner.GmsDocumentScanningResult
                            .FromActivityResultIntent(ar.Data);

                        var pages = scanResult?.Pages;
                        if (pages is not null && pages.Count > 0)
                        {
                            AUri imgUri = pages[0].ImageUri;
                            var localPath = CopyUriToCache(activity, imgUri);

                            if (!string.IsNullOrWhiteSpace(localPath))
                            {
                                var res = new DocumentScanResult();
                                res.Images.Add(new SUri(localPath));
                                _tcs?.TrySetResult(res);
                                return;
                            }
                        }
                    }

                    _tcs?.TrySetResult(null);
                }
                catch
                {
                    _tcs?.TrySetResult(null);
                }
                finally
                {
                    prjTakePhoto.MainActivity.ScanResultCallback = null;
                }
            };

            launcher!.Launch(new IntentSenderRequest.Builder(intentSender).Build());
        }));

        gmsTask.AddOnFailureListener(new FailureListener(_ =>
        {
            _tcs?.TrySetResult(null);
        }));
        return await _tcs.Task;
    }
    //private static string? CopyUriToCache(Activity activity, Android.Net.Uri uri)
    private static string? CopyUriToCache(Activity activity, AUri uri)
    {
        try
        {
            using var input = activity.ContentResolver?.OpenInputStream(uri);
            if (input is null) return null;

            var fileName = $"scan_{DateTime.UtcNow:yyyyMMdd_HHmmss}.jpg";
            var path = Path.Combine(FileSystem.CacheDirectory, fileName);

            using var output = File.Open(path, FileMode.Create, FileAccess.Write, FileShare.None);
            input.CopyTo(output);
            return path;
        }
        catch
        {
            return null;
        }
    }

    //private static async Task<ActivityResultLauncher<IntentSenderRequest>?> WaitForLauncherAsync()
    private static async Task<ActivityResultLauncher?> WaitForLauncherAsync()
    {
        for (int i = 0; i < 20; i++)
        {
            var launcher = prjTakePhoto.MainActivity.ScanLauncher;
            if (launcher is not null) return launcher;
            await SysTask.Delay(100);
        }
        return null;
    }

    private sealed class SuccessListener : Java.Lang.Object, GmsTasks.IOnSuccessListener
    {
        
         
        private readonly Action<IntentSender> _onSuccess;
        public SuccessListener(Action<IntentSender> onSuccess) => _onSuccess = onSuccess;

        public void OnSuccess(Java.Lang.Object? result)
        {
            if (result is IntentSender sender)
                _onSuccess(sender);
        }
    }

    private sealed class FailureListener : Java.Lang.Object,  GmsTasks.IOnFailureListener
    {
        private readonly Action<Java.Lang.Exception> _onFailure;
        public FailureListener(Action<Java.Lang.Exception> onFailure) => _onFailure = onFailure;

        public void OnFailure(Java.Lang.Exception e) => _onFailure(e);
    }
}
#endif
