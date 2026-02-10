using System;
using SkiaSharp;

public static class ReceiptOcrImageFast
{
    public enum OutputMode
    {
        GrayscaleOnly,   // ✅ recommandé (OCR + papier thermique)
        HighContrast     // option "look scanner" sans vrai threshold
    }

    public sealed class Options
    {
        public int MaxWidth { get; set; } = 1200;

        // 1.00 = neutre, 1.15..1.35 = bon pour reçu thermique
        public float Contrast { get; set; } = 1.25f;

        // -0.10..+0.10 (petit ajustement)
        public float Brightness { get; set; } = 0.00f;

        // Sharpen: 0 off, 1 léger, 2 plus fort
        public int SharpenStrength { get; set; } = 1;

        public OutputMode Mode { get; set; } = OutputMode.GrayscaleOnly;

        public int JpegQuality { get; set; } = 88;
    }

    public static byte[] OptimizeForReceiptOCR(byte[] inputBytes, Options? opt = null)
    {
        opt ??= new Options();
        if (inputBytes == null || inputBytes.Length == 0)
            throw new ArgumentException("Image vide.");

        using var src = DecodeToRgba(inputBytes);
        using var resized = ResizeIfNeeded(src, opt.MaxWidth);

        // Grayscale + contrast (+ optional high contrast look)
        float contrast = opt.Contrast;
        float brightness = opt.Brightness;

        if (opt.Mode == OutputMode.HighContrast)
        {
            // look plus "scanner" sans binarisation
            contrast = Math.Max(contrast, 1.60f);
            brightness = brightness - 0.02f;
        }

        using var processed = ApplyGrayscaleAndTone(resized, contrast, brightness, opt.SharpenStrength);

        return EncodeJpeg(processed, opt.JpegQuality);
    }

    // -------------------- Pipeline fast (Canvas only) --------------------

    private static SKBitmap ApplyGrayscaleAndTone(SKBitmap src, float contrast, float brightness, int sharpenStrength)
    {
        var dst = new SKBitmap(src.Width, src.Height, SKColorType.Rgba8888, SKAlphaType.Premul);

        using var canvas = new SKCanvas(dst);
        canvas.Clear(SKColors.White);

        // Grayscale Rec.709
        float r = 0.2126f, g = 0.7152f, b = 0.0722f;

        // brightness: -0.2..+0.2 => offset -51..+51 environ
        float offset = brightness * 255f;

        // Contrast matrix around 0..255 space
        float c = contrast;

        // ColorMatrix 4x5
        float[] m =
        {
            r*c, g*c, b*c, 0, offset,
            r*c, g*c, b*c, 0, offset,
            r*c, g*c, b*c, 0, offset,
            0,   0,   0,   1, 0
        };

        using var paint = new SKPaint
        {
            ColorFilter = SKColorFilter.CreateColorMatrix(m),
            FilterQuality = SKFilterQuality.High,
            IsAntialias = false,
            IsDither = true
        };

        // Sharpen natif (convolution) — toujours Canvas (pas de loops pixels)
        if (sharpenStrength > 0)
        {
            float center = sharpenStrength >= 2 ? 7f : 5f;
            float[] kernel =
            {
                0, -1, 0,
               -1, center, -1,
                0, -1, 0
            };

            // Convolution 3x3
            var conv = SKImageFilter.CreateMatrixConvolution(
                new SKSizeI(3, 3),
                kernel,
                1f,   // gain
                0f,   // bias
                new SKPointI(1, 1),
                SKShaderTileMode.Clamp,
                true
            );

            paint.ImageFilter = conv;
        }

        canvas.DrawBitmap(src, 0, 0, paint);
        return dst;
    }

    // -------------------- Decode / Resize / Encode --------------------

    private static SKBitmap DecodeToRgba(byte[] bytes)
    {
        using var ms = new SKMemoryStream(bytes);
        using var tmp = SKBitmap.Decode(ms) ?? throw new InvalidOperationException("Decode failed.");

        var bmp = new SKBitmap(tmp.Width, tmp.Height, SKColorType.Rgba8888, SKAlphaType.Premul);
        using (var canvas = new SKCanvas(bmp))
        {
            canvas.Clear(SKColors.White);
            canvas.DrawBitmap(tmp, 0, 0);
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

        using var paint = new SKPaint { FilterQuality = SKFilterQuality.High, IsAntialias = true };
        canvas.DrawBitmap(src, new SKRect(0, 0, w, h), paint);

        return dst;
    }

    private static byte[] EncodeJpeg(SKBitmap bmp, int quality)
    {
        using var img = SKImage.FromBitmap(bmp);
        using var data = img.Encode(SKEncodedImageFormat.Jpeg, Clamp(quality, 1, 100));
        return data.ToArray();
    }

    private static int Clamp(int v, int min, int max) => v < min ? min : (v > max ? max : v);
}
