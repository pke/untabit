# Generates store listing images into store-assets\:
#   promo-tile-440x280.png    Chrome Web Store small promo tile
#   marquee-1400x560.png      Chrome Web Store marquee promo tile
#   screenshot-1-1280x800.png / screenshot-2-1280x800.png   store screenshots
Add-Type -AssemblyName System.Drawing

$out = $PSScriptRoot

function New-RRPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function New-Canvas([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush -ArgumentList $rect,
        ([System.Drawing.Color]::FromArgb(255, 79, 70, 229)),
        ([System.Drawing.Color]::FromArgb(255, 124, 58, 237)), 40.0
    $g.FillRectangle($grad, $rect)
    return @($bmp, $g)
}

$white = [System.Drawing.Color]::White
$whiteBrush = New-Object System.Drawing.SolidBrush $white
$indigoBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 79, 70, 229))
$dimPenColor = [System.Drawing.Color]::FromArgb(150, 255, 255, 255)

function New-WhitePen([float]$width) {
    $p = New-Object System.Drawing.Pen -ArgumentList ([System.Drawing.Color]::White), $width
    $p.StartCap = 'Round'; $p.EndCap = 'Round'; $p.LineJoin = 'Round'
    return $p
}

# The icon's window+arrow motif, scaled: source geometry is on a 128px grid.
function Draw-IconMotif($g, [float]$x, [float]$y, [float]$s) {
    $k = $s / 128
    $pen = New-WhitePen (9 * $k)
    $g.DrawPath($pen, (New-RRPath ($x + 24 * $k) ($y + 56 * $k) (48 * $k) (48 * $k) (8 * $k)))
    $g.DrawLine($pen, $x + 58 * $k, $y + 70 * $k, $x + 100 * $k, $y + 28 * $k)
    $g.DrawLine($pen, $x + 72 * $k, $y + 28 * $k, $x + 100 * $k, $y + 28 * $k)
    $g.DrawLine($pen, $x + 100 * $k, $y + 28 * $k, $x + 100 * $k, $y + 56 * $k)
}

function Draw-CenteredText($g, [string]$text, $font, $brush, [float]$cx, [float]$y) {
    $sz = $g.MeasureString($text, $font)
    $g.DrawString($text, $font, $brush, [float]($cx - $sz.Width / 2), $y)
}

function Draw-Arrow($g, [float]$x1, [float]$y1, [float]$x2, [float]$y2) {
    $pen = New-WhitePen 10
    $g.DrawLine($pen, $x1, $y1, $x2, $y2)
    $ang = [Math]::Atan2($y2 - $y1, $x2 - $x1)
    $head = 26.0
    $p1 = New-Object System.Drawing.PointF ([float]$x2), ([float]$y2)
    $p2 = New-Object System.Drawing.PointF ([float]($x2 - $head * [Math]::Cos($ang - 0.45))), ([float]($y2 - $head * [Math]::Sin($ang - 0.45)))
    $p3 = New-Object System.Drawing.PointF ([float]($x2 - $head * [Math]::Cos($ang + 0.45))), ([float]($y2 - $head * [Math]::Sin($ang + 0.45)))
    $g.FillPolygon($whiteBrush, [System.Drawing.PointF[]]@($p1, $p2, $p3))
}

# Simplified browser window mock. $leavingTab: index of the highlighted tab (-1 none).
function Draw-BrowserMock($g, [float]$x, [float]$y, [float]$w, [float]$h, [int]$tabCount, [int]$activeTab) {
    $pen = New-WhitePen 6
    $dimPen = New-Object System.Drawing.Pen -ArgumentList $dimPenColor, 4.0
    $g.DrawPath($pen, (New-RRPath $x $y $w $h 16))
    for ($i = 0; $i -lt $tabCount; $i++) {
        $tx = $x + 24 + $i * 104
        if ($i -eq $activeTab) {
            $g.FillPath($whiteBrush, (New-RRPath $tx ($y + 18) 92 30 8))
        } else {
            $g.DrawPath($dimPen, (New-RRPath $tx ($y + 18) 92 30 8))
        }
    }
    $g.DrawPath($dimPen, (New-RRPath ($x + 24) ($y + 64) ($w - 48) 26 13))
}

function Draw-Key($g, [float]$x, [float]$y, [string]$label, $font) {
    $sz = $g.MeasureString($label, $font)
    $w = $sz.Width + 28
    $h = $sz.Height + 14
    $g.FillPath($whiteBrush, (New-RRPath $x $y $w $h 10))
    $g.DrawString($label, $font, $indigoBrush, [float]($x + 14), [float]($y + 7))
    return $w
}

function Save-Png($bmp, $g, [string]$name) {
    $g.Dispose()
    $bmp.Save((Join-Path $out $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "wrote $name"
}

$fontHead   = New-Object System.Drawing.Font "Segoe UI", 54, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$fontSub    = New-Object System.Drawing.Font "Segoe UI", 28, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$fontKey    = New-Object System.Drawing.Font "Segoe UI", 30, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$fontTitleXL = New-Object System.Drawing.Font "Segoe UI", 120, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$fontTitleM  = New-Object System.Drawing.Font "Segoe UI", 58, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$fontSmall  = New-Object System.Drawing.Font "Segoe UI", 22, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)

# ---- screenshot 1: pop out ----
$bmp, $g = New-Canvas 1280 800
Draw-CenteredText $g "Pop any tab into its own window" $fontHead $whiteBrush 640 60
Draw-CenteredText $g "The tab moves instantly - nothing reloads, video keeps playing" $fontSub $whiteBrush 640 150
Draw-BrowserMock $g 120 260 460 330 3 1
Draw-BrowserMock $g 880 300 280 230 1 0
Draw-Arrow $g 620 400 850 400
$kx = 555.0
$kw = Draw-Key $g $kx 690 "Alt" $fontKey
$g.DrawString("+", $fontKey, $whiteBrush, [float]($kx + $kw + 10), 697.0)
$null = Draw-Key $g ($kx + $kw + 44) 690 "U" $fontKey
Save-Png $bmp $g "screenshot-1-1280x800.png"

# ---- screenshot 2: merge back ----
$bmp, $g = New-Canvas 1280 800
Draw-CenteredText $g "Press again to merge it back" $fontHead $whiteBrush 640 60
Draw-CenteredText $g "The tab returns to the window it came from, at its old position" $fontSub $whiteBrush 640 150
Draw-BrowserMock $g 140 300 280 230 1 0
Draw-BrowserMock $g 700 260 460 330 3 1
Draw-Arrow $g 450 400 670 400
Draw-CenteredText $g "No page reload   |   No data access   |   Chrome, Brave, Edge, Firefox" $fontSub $whiteBrush 640 700
Save-Png $bmp $g "screenshot-2-1280x800.png"

# ---- small promo tile 440x280 ----
$bmp, $g = New-Canvas 440 280
Draw-IconMotif $g 40 70 130
$g.DrawString("Untabit", $fontTitleM, $whiteBrush, 190.0, 90.0)
$g.DrawString("Untab it - and back", $fontSmall, $whiteBrush, 195.0, 170.0)
Save-Png $bmp $g "promo-tile-440x280.png"

# ---- marquee 1400x560 ----
$bmp, $g = New-Canvas 1400 560
Draw-IconMotif $g 130 150 260
$g.DrawString("Untabit", $fontTitleXL, $whiteBrush, 450.0, 120.0)
$g.DrawString("Pop any tab into its own window - and back.", $fontSub, $whiteBrush, 465.0, 310.0)
$kx = 465.0
$kw = Draw-Key $g $kx 370 "Alt" $fontKey
$g.DrawString("+", $fontKey, $whiteBrush, [float]($kx + $kw + 10), 377.0)
$null = Draw-Key $g ($kx + $kw + 44) 370 "U" $fontKey
Save-Png $bmp $g "marquee-1400x560.png"

Write-Host "done"
