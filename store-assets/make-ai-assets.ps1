# Generates store artwork using OpenAI gpt-image-1 for the illustration and
# System.Drawing for exact store dimensions + crisp text overlays.
#
# API key: $env:OPENAI_API_KEY, or the file %USERPROFILE%\.secrets\openai_api_key
# (one line, never inside the repo).
#
#   .\make-ai-assets.ps1                 # generate base art + compose all assets
#   .\make-ai-assets.ps1 -SkipGenerate   # recompose from existing ai-base.png only
param(
    [string]$Quality = "high",
    [switch]$SkipGenerate
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$out = $PSScriptRoot
$baseOutPath = Join-Path $out "ai-base-out-1536x1024.png"   # tab popping out
$baseInPath = Join-Path $out "ai-base-in-1536x1024.png"     # window merging back

# ---------- 1. base illustrations via gpt-image-1 ----------
$style = @"
Modern flat vector illustration for a browser extension marketing banner.
Indigo-to-violet gradient background (#4F46E5 to #7C3AED), clean white
line-art with soft shadows, slightly playful, generous empty background
space at the top and bottom for text overlays. Both windows are drawn in
the exact same white line-art style. Absolutely no text, letters,
numbers or words anywhere in the image.
"@

$promptOut = @"
$style
Scene: a large stylized browser window with a row of tabs on top. One
tab has just popped out of the row and become a SMALL SEPARATE BROWSER
WINDOW floating to the upper right: unmistakably a miniature browser
window with its own single tab on top, its own address bar and a few
content lines - not a card, not a sticky note. A dashed motion arc
leads from the empty gap in the large window's tab row to the small
floating browser window.
"@

$promptIn = @"
$style
Scene: a small floating browser window to the upper right - unmistakably
a miniature browser window with its own single tab on top, its own
address bar and a few content lines - is flying back INTO a large
stylized browser window with a row of tabs. A dashed motion arc leads
from the small floating window into a highlighted empty gap in the
large window's tab row, showing the small window docking back in as a
tab.
"@

if (-not $SkipGenerate) {
    $key = $env:OPENAI_API_KEY
    $keyFile = Join-Path $env:USERPROFILE ".secrets\openai_api_key"
    if (-not $key -and (Test-Path $keyFile)) { $key = (Get-Content $keyFile -Raw).Trim() }
    if (-not $key) { throw "No API key found: set OPENAI_API_KEY or create $keyFile" }

    foreach ($job in @(@($promptOut, $baseOutPath), @($promptIn, $baseInPath))) {
        $prompt, $path = $job
        $body = @{ model = "gpt-image-1"; prompt = $prompt; size = "1536x1024"; quality = $Quality; n = 1 } | ConvertTo-Json
        Write-Host "requesting illustration from gpt-image-1 (quality: $Quality)..."
        $resp = Invoke-RestMethod -Uri "https://api.openai.com/v1/images/generations" -Method Post `
            -Headers @{ Authorization = "Bearer $key" } -ContentType "application/json" -Body $body
        [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($resp.data[0].b64_json))
        Write-Host "wrote $(Split-Path $path -Leaf)"
    }
}
foreach ($p in $baseOutPath, $baseInPath) {
    if (-not (Test-Path $p)) { throw "$p missing - run without -SkipGenerate first" }
}

# ---------- 2. compose exact-size assets with text overlays ----------
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

$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(140, 30, 20, 90))
$scrim = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(90, 40, 30, 120))
$indigo = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 79, 70, 229))

$baseOut = [System.Drawing.Image]::FromFile($baseOutPath)
$baseIn = [System.Drawing.Image]::FromFile($baseInPath)

# Center-crop a base image to the target aspect ratio, scaled to target size.
function New-CroppedCanvas([int]$w, [int]$h, $base) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $targetAspect = $w / [float]$h
    $srcAspect = $base.Width / [float]$base.Height
    if ($srcAspect -gt $targetAspect) {
        $sh = $base.Height; $sw = [int]($sh * $targetAspect)
        $sx = [int](($base.Width - $sw) / 2); $sy = 0
    } else {
        $sw = $base.Width; $sh = [int]($sw / $targetAspect)
        $sx = 0; $sy = [int](($base.Height - $sh) / 2)
    }
    $srcRect = New-Object System.Drawing.Rectangle $sx, $sy, $sw, $sh
    $dstRect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
    $g.DrawImage($base, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    return @($bmp, $g)
}

function Draw-CenteredText($g, [string]$text, $font, [float]$cx, [float]$y) {
    $sz = $g.MeasureString($text, $font)
    $x = [float]($cx - $sz.Width / 2)
    $g.DrawString($text, $font, $shadow, [float]($x + 2), [float]($y + 3))
    $g.DrawString($text, $font, $white, $x, $y)
}

function Draw-Key($g, [float]$x, [float]$y, [string]$label, $font) {
    $sz = $g.MeasureString($label, $font)
    $w = $sz.Width + 28
    $g.FillPath($white, (New-RRPath $x $y $w ($sz.Height + 14) 10))
    $g.DrawString($label, $font, $indigo, [float]($x + 14), [float]($y + 7))
    return $w
}

function Draw-KeyCombo($g, [float]$cx, [float]$y, $font) {
    $kx = $cx - 90
    $kw = Draw-Key $g $kx $y "Alt" $font
    $g.DrawString("+", $font, $white, [float]($kx + $kw + 10), [float]($y + 7))
    $null = Draw-Key $g ($kx + $kw + 44) $y "U" $font
}

function Save-Png($bmp, $g, [string]$name) {
    $g.Dispose()
    $bmp.Save((Join-Path $out $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "wrote $name"
}

$fontHead  = New-Object System.Drawing.Font "Segoe UI", 54, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$fontSub   = New-Object System.Drawing.Font "Segoe UI", 27, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$fontKey   = New-Object System.Drawing.Font "Segoe UI", 30, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$fontXL    = New-Object System.Drawing.Font "Segoe UI", 110, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$fontTitle = New-Object System.Drawing.Font "Segoe UI", 56, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$fontSmall = New-Object System.Drawing.Font "Segoe UI", 22, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)

# screenshot 1: pop out
$bmp, $g = New-CroppedCanvas 1280 800 $baseOut
$g.FillRectangle($scrim, 0, 40, 1280, 170)
Draw-CenteredText $g "Pop any tab into its own window" $fontHead 640 55
Draw-CenteredText $g "The tab moves instantly - nothing reloads, video keeps playing" $fontSub 640 145
Draw-KeyCombo $g 640 690 $fontKey
Draw-CenteredText $g "macOS: Ctrl + U" $fontSmall 640 752
Save-Png $bmp $g "screenshot-1-1280x800.png"

# screenshot 2: merge back
$bmp, $g = New-CroppedCanvas 1280 800 $baseIn
$g.FillRectangle($scrim, 0, 40, 1280, 170)
Draw-CenteredText $g "Press again to merge it back" $fontHead 640 55
Draw-CenteredText $g "The tab returns to the window it came from, at its old position" $fontSub 640 145
$g.FillRectangle($scrim, 0, 685, 1280, 70)
Draw-CenteredText $g "No page reload   |   No data access   |   Chrome, Brave, Edge, Firefox" $fontSub 640 700
Save-Png $bmp $g "screenshot-2-1280x800.png"

# small promo tile 440x280
$bmp, $g = New-CroppedCanvas 440 280 $baseOut
$g.FillRectangle($scrim, 0, 150, 440, 130)
Draw-CenteredText $g "Untabit" $fontTitle 220 158
Draw-CenteredText $g "Untab it - and back" $fontSmall 220 232
Save-Png $bmp $g "promo-tile-440x280.png"

# Open Graph share card 1200x630 (for the GitHub Pages site)
$bmp, $g = New-CroppedCanvas 1200 630 $baseOut
$g.FillRectangle($scrim, 0, 380, 1200, 250)
Draw-CenteredText $g "Untabit" $fontXL 600 380
Draw-CenteredText $g "Pop any tab into its own window - and back." $fontSub 600 545
$g.Dispose()
$ogPath = Join-Path (Split-Path $out -Parent) "docs\og-image.png"
if (Test-Path (Split-Path $ogPath -Parent)) {
    $bmp.Save($ogPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "wrote docs\og-image.png"
}
$bmp.Dispose()

# GitHub repo social preview 1280x640
$bmp, $g = New-CroppedCanvas 1280 640 $baseOut
$g.FillRectangle($scrim, 0, 390, 1280, 250)
Draw-CenteredText $g "Untabit" $fontXL 640 390
Draw-CenteredText $g "Pop any tab into its own window - and back." $fontSub 640 555
Save-Png $bmp $g "gh-social-1280x640.png"

# marquee 1400x560
$bmp, $g = New-CroppedCanvas 1400 560 $baseOut
$g.FillRectangle($scrim, 0, 330, 1400, 230)
Draw-CenteredText $g "Untabit" $fontXL 700 330
Draw-CenteredText $g "Pop any tab into its own window - and back." $fontSub 700 480
Save-Png $bmp $g "marquee-1400x560.png"

$baseOut.Dispose()
$baseIn.Dispose()
Write-Host "done"
