using System;
using SkiaSharp;

public static class ReceiptOcrImage
{
    public enum OutputMode
    {
        GrayscaleOnly,   // recommandé pour papier thermique
        BlackAndWhite    // rendu "scan" (peut perdre du texte si trop agressif)
    }

    public sealed class Options
    {
        public int MaxWidth { get; set; } = 1200;
        public OutputMode Mode { get; set; } = OutputMode.GrayscaleOnly;

        // Qualité JPEG si on encode en JPG
        public int JpegQuality { get; set; } = 88;

        // Pour le N&B: PNG évite les artéfacts JPEG (souvent meilleur pour OCR/archivage)
        public bool PngWhenBlackAndWhite { get; set; } = true;

        // Papier thermique: seuil "safe" (150-175 typique). Plus bas => plus de noir (risque bruit).
        public int ThermalThreshold { get; set; } = 165;

        // Si true: N&B utilise un seuil "thermal safe" (plutôt que Otsu)
        public bool ThermalSafeBinarize { get; set; } = true;

        // Force un léger "boost" gamma sur thermique avant seuil (aide texte pâle)
        public double ThermalGamma { get; set; } = 0.85; // <1 = fonce les gris
    }

    public static byte[] OptimizeForReceiptOCR(byte[] inputBytes, Options? opt = null)
    {
        opt ??= new Options();
        if (inputBytes == null || inputBytes.Length == 0)
            throw new ArgumentException("inputBytes vide.");

        using var original = DecodeBitmap(inputBytes);
        using var resized = ResizeIfNeeded(original, opt.MaxWidth);

        using var gray = ToGrayscale(resized);
        StretchContrastInPlace(gray);

        using var sharpened = Unsharp3x3(gray, amount: 0.65f);

        if (opt.Mode == OutputMode.GrayscaleOnly)
        {
            return EncodeJpeg(sharpened, opt.JpegQuality);
        }

        using var bw = opt.ThermalSafeBinarize
            ? BinarizeThermalSafe(sharpened, opt.ThermalThreshold, opt.ThermalGamma)
            : OtsuBinarize(sharpened);

        if (opt.PngWhenBlackAndWhite)
            return EncodePng(bw);

        return EncodeJpeg(bw, opt.JpegQuality);
    }

    // -------------------- Decode / Resize --------------------

    private static SKBitmap DecodeBitmap(byte[] bytes)
    {
        using var ms = new SKMemoryStream(bytes);
        var bmp = SKBitmap.Decode(ms);
        if (bmp == null) throw new InvalidOperationException("Impossible de décoder l'image.");
        // Assure un format standard
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

    // -------------------- Grayscale / Contrast --------------------

    private static SKBitmap ToGrayscale(SKBitmap src)
    {
        var dst = new SKBitmap(src.Width, src.Height, SKColorType.Rgba8888, SKAlphaType.Premul);

        for (int y = 0; y < src.Height; y++)
        {
            for (int x = 0; x < src.Width; x++)
            {
                var c = src.GetPixel(x, y);

                // Luma (Rec. 709)
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
        // si range trop petit, l'auto-contrast peut amplifier le bruit
        if (range < 18) return;

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

    // -------------------- Unsharp (blur 3x3) --------------------

    private static SKBitmap Unsharp3x3(SKBitmap gray, float amount = 0.65f)
    {
        // gray: R=G=B
        using var blurred = BoxBlur3x3(gray);

        var dst = new SKBitmap(gray.Width, gray.Height, SKColorType.Rgba8888, SKAlphaType.Premul);

        for (int y = 0; y < gray.Height; y++)
        {
            for (int x = 0; x < gray.Width; x++)
            {
                int s = gray.GetPixel(x, y).Red;
                int b = blurred.GetPixel(x, y).Red;

                int v = (int)Math.Round(s + amount * (s - b));
                byte outv = (byte)Clamp(v, 0, 255);

                dst.SetPixel(x, y, new SKColor(outv, outv, outv, 255));
            }
        }

        return dst;
    }

    private static SKBitmap BoxBlur3x3(SKBitmap gray)
    {
        int w = gray.Width;
        int h = gray.Height;

        var dst = new SKBitmap(w, h, SKColorType.Rgba8888, SKAlphaType.Premul);

        for (int y = 0; y < h; y++)
        {
            int y0 = Math.Max(0, y - 1);
            int y1 = y;
            int y2 = Math.Min(h - 1, y + 1);

            for (int x = 0; x < w; x++)
            {
                int x0 = Math.Max(0, x - 1);
                int x1 = x;
                int x2 = Math.Min(w - 1, x + 1);

                int sum =
                    gray.GetPixel(x0, y0).Red + gray.GetPixel(x1, y0).Red + gray.GetPixel(x2, y0).Red +
                    gray.GetPixel(x0, y1).Red + gray.GetPixel(x1, y1).Red + gray.GetPixel(x2, y1).Red +
                    gray.GetPixel(x0, y2).Red + gray.GetPixel(x1, y2).Red + gray.GetPixel(x2, y2).Red;

                byte v = (byte)(sum / 9);
                dst.SetPixel(x, y, new SKColor(v, v, v, 255));
            }
        }

        return dst;
    }

    // -------------------- Binarize --------------------

    private static SKBitmap BinarizeThermalSafe(SKBitmap gray, int threshold, double gamma)
    {
        var bw = new SKBitmap(gray.Width, gray.Height, SKColorType.Rgba8888, SKAlphaType.Premul);

        // gamma < 1 => assombrit les gris => texte plus noir
        double inv255 = 1.0 / 255.0;

        for (int y = 0; y < gray.Height; y++)
        {
            for (int x = 0; x < gray.Width; x++)
            {
                byte v = gray.GetPixel(x, y).Red;
                int boosted = (int)Math.Round(Math.Pow(v * inv255, gamma) * 255.0);
                boosted = Clamp(boosted, 0, 255);

                byte outv = (boosted >= threshold) ? (byte)255 : (byte)0;
                bw.SetPixel(x, y, new SKColor(outv, outv, outv, 255));
            }
        }

        return bw;
    }

    private static SKBitmap OtsuBinarize(SKBitmap gray)
    {
        int[] hist = new int[256];
        int total = gray.Width * gray.Height;

        for (int y = 0; y < gray.Height; y++)
            for (int x = 0; x < gray.Width; x++)
                hist[gray.GetPixel(x, y).Red]++;

        float sum = 0;
        for (int t = 0; t < 256; t++) sum += t * hist[t];

        float sumB = 0;
        int wB = 0;
        int wF = 0;

        float varMax = 0;
        int threshold = 128;

        for (int t = 0; t < 256; t++)
        {
            wB += hist[t];
            if (wB == 0) continue;

            wF = total - wB;
            if (wF == 0) break;

            sumB += t * hist[t];

            float mB = sumB / wB;
            float mF = (sum - sumB) / wF;

            float varBetween = (float)wB * wF * (mB - mF) * (mB - mF);
            if (varBetween > varMax)
            {
                varMax = varBetween;
                threshold = t;
            }
        }

        var bw = new SKBitmap(gray.Width, gray.Height, SKColorType.Rgba8888, SKAlphaType.Premul);

        for (int y = 0; y < gray.Height; y++)
        {
            for (int x = 0; x < gray.Width; x++)
            {
                byte v = gray.GetPixel(x, y).Red;
                byte outv = (v >= threshold) ? (byte)255 : (byte)0;
                bw.SetPixel(x, y, new SKColor(outv, outv, outv, 255));
            }
        }

        return bw;
    }

    // -------------------- Encode --------------------

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

    // -------------------- Utils --------------------

    private static int Clamp(int v, int min, int max) => v < min ? min : (v > max ? max : v);
}
