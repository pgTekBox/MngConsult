# =============================================================================
# Genere les icones de ServiceExecuteur : un rouage avec un glyphe d'etat au
# centre. L'icone de l'application porte le triangle « lecture » ; les trois
# icones du controleur reprennent le meme rouage avec la couleur et le glyphe
# de leur etat (lecture / pause / arret).
#
# Tout est dessine par GDI+ dans un repere 64x64 puis mis a l'echelle : une
# seule geometrie, toutes les tailles.
#
# En dessous de 26 px les dents du rouage se transforment en bouillie : a ces
# tailles on dessine une variante simplifiee (anneau plus epais, sans dents)
# qui se lit encore et reste la meme icone.
# =============================================================================
Add-Type -AssemblyName System.Drawing

function New-RoundedRectPath {
    param([single]$x, [single]$y, [single]$w, [single]$h, [single]$r)
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function New-IconBitmap {
    param(
        [int]$Size,
        [string]$BackHex,      # fond de la tuile
        [string]$Glyph         # play | pause | stop
    )

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $s = $Size / 64.0
    $g.ScaleTransform($s, $s)

    $back = [System.Drawing.ColorTranslator]::FromHtml($BackHex)
    $white = [System.Drawing.Color]::White
    $brushBack = New-Object System.Drawing.SolidBrush($back)
    $brushWhite = New-Object System.Drawing.SolidBrush($white)

    # Tuile de fond. Le rayon suit la taille : a 16 px un rayon de 14/64 donne
    # un coin quasi carre, ce qui est justement ce qu'on veut voir.
    $tile = New-RoundedRectPath 2 2 60 60 14
    $g.FillPath($brushBack, $tile)
    $tile.Dispose()

    # Deux niveaux de detail. Le rouage complet demande de la place ; en dessous
    # de 40 px il ne reste plus assez de pixels pour les dents ET le glyphe, et
    # c'est le glyphe qui doit gagner : lui seul distingue demarre de en pause
    # et d'arrete. Le fond colore et la tuile arrondie suffisent a garder la
    # famille.
    $niveau = if ($Size -ge 40) { 'plein' } else { 'petit' }

    # H = demi-hauteur du glyphe. Toute sa geometrie en decoule.
    $H = if ($niveau -eq 'plein') { 6.0 } else { 14.0 }

    if ($niveau -ne 'petit') {
        # Dents du rouage : huit tuiles arrondies autour du centre.
        $state = $g.Save()
        $g.TranslateTransform(32, 32)
        for ($i = 0; $i -lt 8; $i++) {
            $tooth = New-RoundedRectPath -3 -25 6 8 2
            $g.FillPath($brushWhite, $tooth)
            $tooth.Dispose()
            $g.RotateTransform(45)
        }
        $g.Restore($state)

        $rayon = 15.0
        $pen = New-Object System.Drawing.Pen($white, [single]6.0)
        $g.DrawEllipse($pen, 32 - $rayon, 32 - $rayon, $rayon * 2, $rayon * 2)
        $pen.Dispose()
    }

    switch ($Glyph) {
        'play' {
            # Triangle equilibre autour du centre optique (barycentre en x = 32).
            $pts = @(
                (New-Object System.Drawing.PointF([single](32 - 0.583 * $H), [single](32 - $H))),
                (New-Object System.Drawing.PointF([single](32 + 1.167 * $H), [single]32)),
                (New-Object System.Drawing.PointF([single](32 - 0.583 * $H), [single](32 + $H)))
            )
            $g.FillPolygon($brushWhite, [System.Drawing.PointF[]]$pts)
        }
        'pause' {
            $lw = 0.53 * $H; $lh = 2.08 * $H; $gap = 0.40 * $H
            $g.FillRectangle($brushWhite, [single](32 - $gap / 2 - $lw), [single](32 - $lh / 2), [single]$lw, [single]$lh)
            $g.FillRectangle($brushWhite, [single](32 + $gap / 2), [single](32 - $lh / 2), [single]$lw, [single]$lh)
        }
        'stop' {
            $c = 1.75 * $H
            $sq = New-RoundedRectPath ([single](32 - $c / 2)) ([single](32 - $c / 2)) ([single]$c) ([single]$c) ([single](0.30 * $H))
            $g.FillPath($brushWhite, $sq)
            $sq.Dispose()
        }
    }

    $brushBack.Dispose(); $brushWhite.Dispose(); $g.Dispose()
    return $bmp
}

function Get-DibBytes {
    <#
      Une entree d'icone au format DIB 32 bits : en-tete BITMAPINFOHEADER dont
      la hauteur est doublee (image + masque), pixels BGRA de bas en haut, puis
      le masque AND 1 bpp. On garde le DIB plutot que le PNG : System.Drawing
      lit les deux, le shell aussi, mais le DIB ne surprend personne.
    #>
    param([System.Drawing.Bitmap]$Bmp)

    $w = $Bmp.Width; $h = $Bmp.Height
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $data = $Bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $pixels = New-Object byte[] ($data.Stride * $h)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $pixels, 0, $pixels.Length)
    $Bmp.UnlockBits($data)

    $maskStride = [int](([math]::Floor(($w + 31) / 32)) * 4)

    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)

    $bw.Write([uint32]40)          # biSize
    $bw.Write([int32]$w)           # biWidth
    $bw.Write([int32]($h * 2))     # biHeight : image + masque
    $bw.Write([uint16]1)           # biPlanes
    $bw.Write([uint16]32)          # biBitCount
    $bw.Write([uint32]0)           # biCompression = BI_RGB
    $bw.Write([uint32]($w * $h * 4 + $maskStride * $h))
    $bw.Write([int32]0); $bw.Write([int32]0)
    $bw.Write([uint32]0); $bw.Write([uint32]0)

    # Pixels, derniere ligne en premier.
    for ($y = $h - 1; $y -ge 0; $y--) {
        $bw.Write($pixels, $y * $data.Stride, $w * 4)
    }

    # Masque AND : tout a zero, la transparence est portee par le canal alpha.
    $zero = New-Object byte[] ($maskStride * $h)
    $bw.Write($zero, 0, $zero.Length)

    $bw.Flush()
    $out = $ms.ToArray()
    $bw.Dispose(); $ms.Dispose()
    return $out
}

function Write-IcoFile {
    param([string]$Path, [int[]]$Sizes, [string]$BackHex, [string]$Glyph)

    $images = @()
    foreach ($sz in $Sizes) {
        $bmp = New-IconBitmap -Size $sz -BackHex $BackHex -Glyph $Glyph
        $images += [pscustomobject]@{ Size = $sz; Bytes = (Get-DibBytes $bmp) }
        $bmp.Dispose()
    }

    $fs = [System.IO.File]::Create($Path)
    $bw = New-Object System.IO.BinaryWriter($fs)

    $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$images.Count)

    $offset = 6 + 16 * $images.Count
    foreach ($img in $images) {
        $dim = if ($img.Size -ge 256) { 0 } else { $img.Size }
        $bw.Write([byte]$dim); $bw.Write([byte]$dim)
        $bw.Write([byte]0); $bw.Write([byte]0)
        $bw.Write([uint16]1); $bw.Write([uint16]32)
        $bw.Write([uint32]$img.Bytes.Length)
        $bw.Write([uint32]$offset)
        $offset += $img.Bytes.Length
    }
    foreach ($img in $images) { $bw.Write($img.Bytes, 0, $img.Bytes.Length) }

    $bw.Flush(); $bw.Dispose(); $fs.Dispose()
    "{0} — {1} tailles, {2:N0} octets" -f (Split-Path $Path -Leaf), $images.Count, (Get-Item $Path).Length
}

$root = 'C:\MesSources\MngConsul\ServiceExecuteur'
$tailles = @(16, 20, 24, 32, 48, 64, 128, 256)
$taillesTray = @(16, 20, 24, 32, 48, 64)

Write-IcoFile -Path "$root\ServiceExecuteur.ico"   -Sizes $tailles     -BackHex '#2563eb' -Glyph 'play'
Write-IcoFile -Path "$root\Resources\Running.ico"  -Sizes $taillesTray -BackHex '#10b981' -Glyph 'play'
Write-IcoFile -Path "$root\Resources\Paused.ico"   -Sizes $taillesTray -BackHex '#f59e0b' -Glyph 'pause'
Write-IcoFile -Path "$root\Resources\Stopped.ico"  -Sizes $taillesTray -BackHex '#64748b' -Glyph 'stop'
