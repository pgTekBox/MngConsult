using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using SkiaSharp;

namespace prjTakePhoto;

public static class ImageCompress
{
    public static byte[] ResizeAndCompressJpeg(byte[] inputBytes, int maxWidth = 1200, int quality = 80)
    {
        using var input = new SKMemoryStream(inputBytes);
        using var codec = SKCodec.Create(input);
        using var original = SKBitmap.Decode(codec);

        if (original == null) throw new Exception("Image invalide");

        int w = original.Width;
        int h = original.Height;

        SKBitmap bitmapToEncode = original;

        if (w > maxWidth)
        {
            double scale = (double)maxWidth / w;
            int newW = maxWidth;
            int newH = (int)Math.Round(h * scale);

            var resized = original.Resize(new SKImageInfo(newW, newH), SKFilterQuality.Medium);
            if (resized != null) bitmapToEncode = resized;
        }

        using var image = SKImage.FromBitmap(bitmapToEncode);
        using var data = image.Encode(SKEncodedImageFormat.Jpeg, quality);
        return data.ToArray();
    }
}
