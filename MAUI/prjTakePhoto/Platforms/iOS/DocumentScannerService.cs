#if IOS
using Foundation;
using UIKit;
using VisionKit;

namespace prjTakePhoto.Platforms.iOS;

public sealed class DocumentScannerService : NSObject, IDocumentScannerService, IVNDocumentCameraViewControllerDelegate
{
    private TaskCompletionSource<DocumentScanResult?>? _tcs;

    public Task<DocumentScanResult?> OpenDocumentScannerAsync()
    {
        if (!UIDevice.CurrentDevice.CheckSystemVersion(13, 0))
            return Task.FromResult<DocumentScanResult?>(null);

        _tcs = new TaskCompletionSource<DocumentScanResult?>();

        MainThread.BeginInvokeOnMainThread(() =>
        {
            var vc = new VNDocumentCameraViewController { Delegate = this };
            GetTopViewController().PresentViewController(vc, true, null);
        });

        return _tcs.Task;
    }

    [Export("documentCameraViewControllerDidCancel:")]
    public void DidCancel(VNDocumentCameraViewController controller)
    {
        controller.DismissViewController(true, null);
        _tcs?.TrySetResult(null);
    }

    [Export("documentCameraViewController:didFailWithError:")]
    public void DidFail(VNDocumentCameraViewController controller, NSError error)
    {
        controller.DismissViewController(true, null);
        _tcs?.TrySetResult(null);
    }

    [Export("documentCameraViewController:didFinishWithScan:")]
    public void DidFinish(VNDocumentCameraViewController controller, VNDocumentCameraScan scan)
    {
        controller.DismissViewController(true, null);

        try
        {
            var res = new DocumentScanResult();
            var dir = FileSystem.CacheDirectory;

            for (nuint i = 0; i < scan.PageCount; i++)
            {
                using var img = scan.GetImage(i);
                using var jpeg = img.AsJPEG(0.9f);

                var path = Path.Combine(dir, $"scan_{DateTime.UtcNow:yyyyMMdd_HHmmss}_{i}.jpg");
                File.WriteAllBytes(path, jpeg.ToArray());
                res.Images.Add(new Uri(path));
            }

            _tcs?.TrySetResult(res);
        }
        catch
        {
            _tcs?.TrySetResult(null);
        }
    }

    private static UIViewController GetTopViewController()
    {
        var window = UIApplication.SharedApplication.KeyWindow
            ?? UIApplication.SharedApplication.Windows.FirstOrDefault(w => w.IsKeyWindow);

        var vc = window?.RootViewController ?? throw new InvalidOperationException("RootViewController introuvable.");
        while (vc.PresentedViewController != null) vc = vc.PresentedViewController;
        return vc;
    }
}
#endif
