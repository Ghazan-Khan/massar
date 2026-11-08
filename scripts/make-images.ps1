# Massar Services - raster brand assets (icons + Open Graph images)
# Requires Windows PowerShell 5.1 with System.Drawing (Windows).
# Pure ASCII source.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$imgDir = Join-Path $root 'src/assets/img'
New-Item -ItemType Directory -Force -Path $imgDir | Out-Null

function New-RoundedPath {
    param([single]$X, [single]$Y, [single]$W, [single]$H, [single]$R)
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $R * 2
    $p.AddArc($X, $Y, $d, $d, 180, 90)
    $p.AddArc($X + $W - $d, $Y, $d, $d, 270, 90)
    $p.AddArc($X + $W - $d, $Y + $H - $d, $d, $d, 0, 90)
    $p.AddArc($X, $Y + $H - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function Get-Color {
    param([string]$Hex)
    return [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function New-RoundPen {
    param([string]$Hex, [single]$Width)
    $pen = New-Object System.Drawing.Pen (Get-Color $Hex), $Width
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    return $pen
}

function New-PointF {
    param([double]$X, [double]$Y)
    return [System.Drawing.PointF]::new([single]$X, [single]$Y)
}

function Draw-Mark {
    param($G, [double]$X, [double]$Y, [double]$Size, [string]$OuterColor, [string]$InnerColor)
    $s = $Size / 64.0
    $outer = New-RoundPen $OuterColor ([single](3.6 * $s))
    $inner = New-RoundPen $InnerColor ([single](3.2 * $s))
    $outerPts = [System.Drawing.PointF[]]@(
        (New-PointF ($X + 15 * $s) ($Y + 46 * $s)),
        (New-PointF ($X + 15 * $s) ($Y + 27.5 * $s)),
        (New-PointF ($X + 32 * $s) ($Y + 18 * $s)),
        (New-PointF ($X + 49 * $s) ($Y + 27.5 * $s)),
        (New-PointF ($X + 49 * $s) ($Y + 46 * $s))
    )
    $innerPts = [System.Drawing.PointF[]]@(
        (New-PointF ($X + 23 * $s) ($Y + 46 * $s)),
        (New-PointF ($X + 23 * $s) ($Y + 33.5 * $s)),
        (New-PointF ($X + 32 * $s) ($Y + 28 * $s)),
        (New-PointF ($X + 41 * $s) ($Y + 33.5 * $s)),
        (New-PointF ($X + 41 * $s) ($Y + 46 * $s))
    )
    $g.DrawLines($outer, $outerPts)
    $g.DrawLines($inner, $innerPts)
    $g.DrawLine($inner, (New-PointF ($X + 32 * $s) ($Y + 46 * $s)), (New-PointF ($X + 32 * $s) ($Y + 41 * $s)))
    $outer.Dispose()
    $inner.Dispose()
}

function Save-Png {
    param($Bitmap, [string]$Path)
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function New-Icon {
    param([int]$Size, [string]$Path, [bool]$Maskable)
    $bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $teal = New-Object System.Drawing.SolidBrush (Get-Color '#0f4c46')
    if ($Maskable) {
        $g.FillRectangle($teal, 0, 0, $Size, $Size)
        $markSize = $Size * 0.58
        $offset = ($Size - $markSize) / 2
        Draw-Mark $g $offset $offset $markSize '#f7f3ea' '#c9a227'
    } else {
        $radius = [single]($Size * 15 / 64)
        $shape = New-RoundedPath 0 0 $Size $Size $radius
        $g.FillPath($teal, $shape)
        $shape.Dispose()
        $markSize = $Size * 0.64
        $offset = ($Size - $markSize) / 2
        Draw-Mark $g $offset $offset $markSize '#f7f3ea' '#c9a227'
    }

    Save-Png $bmp $Path
    $teal.Dispose()
    $g.Dispose()
    $bmp.Dispose()
}

function New-OgImage {
    param([string]$Path, [bool]$Arabic)
    $w = 1200
    $h = 630
    $bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $teal = New-Object System.Drawing.SolidBrush (Get-Color '#0f4c46')
    $g.FillRectangle($teal, 0, 0, $w, $h)

    # decorative geometry, right side
    $ring = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(55, 232, 212, 138)), 10
    $g.DrawEllipse($ring, 820, 40, 470, 470)
    $ring2 = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(38, 247, 243, 234)), 3
    $g.DrawEllipse($ring2, 890, 110, 330, 330)
    $g.DrawEllipse($ring2, 955, 175, 200, 200)

    $arch = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(90, 201, 162, 39)), 12
    $arch.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $arch.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $archPts = [System.Drawing.PointF[]]@(
        (New-PointF 880 520),
        (New-PointF 880 280),
        (New-PointF 1045 170),
        (New-PointF 1210 280),
        (New-PointF 1210 520)
    )
    $g.DrawLines($arch, $archPts)

    # logo mark
    Draw-Mark $g 80 72 92 '#f7f3ea' '#e8d48a'

    $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $light = New-Object System.Drawing.SolidBrush (Get-Color '#d8e9e5')
    $gold = New-Object System.Drawing.SolidBrush (Get-Color '#e8d48a')

    $fontFamily = 'Segoe UI'
    try {
        $test = New-Object System.Drawing.Font $fontFamily, 12
        $test.Dispose()
    } catch {
        $fontFamily = 'Arial'
    }

    $labelFont = New-Object System.Drawing.Font $fontFamily, 22, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $titleFont = New-Object System.Drawing.Font $fontFamily, 58, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $subFont = New-Object System.Drawing.Font $fontFamily, 27, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
    $smallFont = New-Object System.Drawing.Font $fontFamily, 23, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)

    $g.DrawString('MASSAR SERVICES', $labelFont, $gold, 80, 186)

    $titleRect = New-Object System.Drawing.RectangleF 78, 224, 660, 190
    if ($Arabic) {
        $g.DrawString('Massar Services', $titleFont, $white, $titleRect)
        $g.DrawString('massarservices.ma', $smallFont, $gold, 80, 520)
        $g.DrawString('Independent information guide', $subFont, $light, (New-Object System.Drawing.RectangleF 78, 300, 620, 120))
    } else {
        $g.DrawString('A clear guide to Morocco''s Massar education services', $titleFont, $white, $titleRect)
        $g.DrawString('massarservices.ma', $smallFont, $gold, 80, 520)
        $g.DrawString('Independent. Not affiliated with the Ministry.', $subFont, $light, (New-Object System.Drawing.RectangleF 78, 432, 640, 80))
    }

    Save-Png $bmp $Path
    $teal.Dispose(); $white.Dispose(); $light.Dispose(); $gold.Dispose()
    $ring.Dispose(); $ring2.Dispose(); $arch.Dispose()
    $labelFont.Dispose(); $titleFont.Dispose(); $subFont.Dispose(); $smallFont.Dispose()
    $g.Dispose(); $bmp.Dispose()
}

Write-Host 'Drawing icons...'
New-Icon 180 (Join-Path $imgDir 'apple-touch-icon.png') $true
New-Icon 192 (Join-Path $imgDir 'logo-192.png') $false
New-Icon 512 (Join-Path $imgDir 'logo-512.png') $false
New-Icon 512 (Join-Path $imgDir 'logo-maskable-512.png') $true

Write-Host 'Drawing Open Graph images...'
New-OgImage (Join-Path $imgDir 'og-ar.png') $true
New-OgImage (Join-Path $imgDir 'og-en.png') $false

Write-Host 'Done.'
