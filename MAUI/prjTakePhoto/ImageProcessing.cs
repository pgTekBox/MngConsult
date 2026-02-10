using System;
using SkiaSharp;

public static class ImageProcessing
{
    /// <summary>
    /// Resize (si > maxWidth) puis encode en JPEG avec quality.
    /// </summary>
    public static byte[] ResizeAndCompressJpeg(byte[] inputBytes, int maxWidth = 1200, int quality = 85)
    {
        using var bmp = DecodeBitmap(inputBytes);
        using var resized = ResizeIfNeeded(bmp, maxWidth);
        return EncodeJpeg(resized, quality);
    }

    /// <summary>
    /// Convertit en grayscale (R=G=B), puis encode en JPEG.
    /// (Recommandé pour papier thermique si tu veux garder les nuances.)
    /// </summary>
    public static byte[] ToGrayscaleJpeg(byte[] inputBytes, int maxWidth = 1200, int quality = 88)
    {
        using var bmp = DecodeBitmap(inputBytes);
        using var resized = ResizeIfNeeded(bmp, maxWidth);
        using var gray = ToGrayscale(resized);
        StretchContrastInPlace(gray); // aide sur papier thermique
        return EncodeJpeg(gray, quality);
    }

    /// <summary>
    /// Noir & Blanc (binarisation) "safe" pour papier thermique.
    /// Retourne PNG par défaut (plus net que JPEG pour du N&B).
    /// </summary>
    public static byte[] ToBlackAndWhiteThermalSafe(byte[] inputBytes, int maxWidth = 1200, int threshold = 165, double gamma = 0.85, bool asPng = true, int jpegQuality = 90)
    {
        using var bmp = DecodeBitmap(inputBytes);
        using var resized = ResizeIfNeeded(bmp, maxWidth);
        using var gray = ToGrayscale(resized);
        StretchContrastInPlace(gray);

        using var bw = BinarizeThermalSafe(gray, threshold, gamma);

        return asPng ? EncodePng(bw) : EncodeJpeg(bw, jpegQuality);
    }

    // ------------------ Internals ------------------

    private static SKBitmap DecodeBitmap(byte[] bytes)
    {
        if (bytes == null || bytes.Length == 0)
            throw new ArgumentException("Image vide.");

        using var ms = new SKMemoryStream(bytes);
        var bmp = SKBitmap.Decode(ms);
        if (bmp == null)
            throw new InvalidOperationException("Impossible de décoder l'image.");

        // Normalise en RGBA
        if (bmp.ColorType != SKColorType.Rgba8888)
        {
            var converted = new SKBitmap(bmp.Width, bmp.Height, SKColorType.Rgba8888, SKAlphaType.Premul);
            using var canvas = new SKCanvas(converted);
            canvas.Clear(SKColors.White);
            canvas.DrawBitmap(bmp, 0, 0);
            bmp.Dispose();
            return converted;
        }

        return bmp;
    }

    private static SKBitmap ResizeIfNeeded(SKBitmap src, int maxWidth)
    {
        if (maxWidth <= 0 || src.Width <= maxWidth)
            return src.Copy();

        float scale = (float)maxWidth / src.Width;
        int w = maxWidth;
        int h = Math.Max(1, (int)Math.Round(src.Height * scale));

        var dst = new SKBitmap(w, h, SKColorType.Rgba8888, SKAlphaType.Premul);

        using var canvas = new SKCanvas(dst);
        canvas.Clear(SKColors.White);

        using var paint = new SKPaint
        {
            IsAntialias = true,
            FilterQuality = SKFilterQuality.High,
            IsDither = true
        };

        canvas.DrawBitmap(src, new SKRect(0, 0, w, h), paint);
        return dst;
    }

    private static SKBitmap ToGrayscale(SKBitmap src)
    {
        var dst = new SKBitmap(src.Width, src.Height, SKColorType.Rgba8888, SKAlphaType.Premul);

        for (int y = 0; y < src.Height; y++)
        {
            for (int x = 0; x < src.Width; x++)
            {
                var c = src.GetPixel(x, y);

                // Luma Rec.709
                int v = (int)Math.Round(0.2126 * c.Red + 0.7152 * c.Green + 0.0722 * c.Blue);
                byte b = (byte)Clamp(v, 0, 255);

                dst.SetPixel(x, y, new SKColor(b, b, b, 255));
            }
        }

        return dst;
    }

    private static void StretchContrastInPlace(SKBitmap gray)
    {
        byte min = 255, max = 0;

        for (int y = 0; y < gray.Height; y++)
        {
            for (int x = 0; x < gray.Width; x++)
            {
                byte v = gray.GetPixel(x, y).Red;
                if (v < min) min = v;
                if (v > max) max = v;
            }
        }

        if (max <= min) return;

        int range = max - min;
        if (range < 18) return; // évite d'amplifier le bruit

        float scale = 255f / range;

        for (int y = 0; y < gray.Height; y++)
        {
            for (int x = 0; x < gray.Width; x++)
            {
                byte v = gray.GetPixel(x, y).Red;
                int nv = (int)Math.Round((v - min) * scale);
                byte b = (byte)Clamp(nv, 0, 255);
                gray.SetPixel(x, y, new SKColor(b, b, b, 255));
            }
        }
    }

    private static SKBitmap BinarizeThermalSafe(SKBitmap gray, int threshold, double gamma)
    {
        var bw = new SKBitmap(gray.Width, gray.Height, SKColorType.Rgba8888, SKAlphaType.Premul);

        double inv255 = 1.0 / 255.0;

        for (int y = 0; y < gray.Height; y++)
        {
            for (int x = 0; x < gray.Width; x++)
            {
                byte v = gray.GetPixel(x, y).Red;

                // gamma < 1 => assombrit les gris => texte plus noir (utile thermique)
                int boosted = (int)Math.Round(Math.Pow(v * inv255, gamma) * 255.0);
                boosted = Clamp(boosted, 0, 255);

                byte outv = (boosted >= threshold) ? (byte)255 : (byte)0;
                bw.SetPixel(x, y, new SKColor(outv, outv, outv, 255));
            }
        }

        return bw;
    }

    private static byte[] EncodeJpeg(SKBitmap bmp, int quality)
    {
        using var img = SKImage.FromBitmap(bmp);
        using var data = img.Encode(SKEncodedImageFormat.Jpeg, Clamp(quality, 1, 100));
        return data.ToArray();
    }

    private static byte[] EncodePng(SKBitmap bmp)
    {
        using var img = SKImage.FromBitmap(bmp);
        using var data = img.Encode(SKEncodedImageFormat.Png, 100);
        return data.ToArray();
    }

    private static int Clamp(int v, int min, int max) => v < min ? min : (v > max ? max : v);
}
