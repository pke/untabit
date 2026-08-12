# Generates extension icon candidates with gpt-image-1 plus a size-preview
# strip (128/48/32/16 px on light and dark) for judging small-size legibility.
# Candidates land in store-assets\icon-candidates\ - nothing in icons\ is
# touched until a candidate is adopted.
param(
    [string]$Quality = "high",
    [int]$Count = 3
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$key = $env:OPENAI_API_KEY
$keyFile = Join-Path $env:USERPROFILE ".secrets\openai_api_key"
if (-not $key -and (Test-Path $keyFile)) { $key = (Get-Content $keyFile -Raw).Trim() }
if (-not $key) { throw "No API key found: set OPENAI_API_KEY or create $keyFile" }

$outDir = Join-Path $PSScriptRoot "icon-candidates"
New-Item -ItemType Directory -Force $outDir | Out-Null

$prompt = @"
App icon for a browser extension, on a fully transparent background.
A rounded-square tile with a smooth indigo-to-violet gradient
(#4F46E5 to #7C3AED). On the tile: soft 3D glassmorphism style, a
frosted translucent white miniature browser window with a single tab,
popping out towards the upper right with a short motion arc, subtle
inner glow and soft shadow. Extremely simple, bold, centered
composition with thick shapes - must stay recognizable when scaled
down to 16x16 pixels. No text, letters, numbers or words.
"@

for ($i = 1; $i -le $Count; $i++) {
    $file = Join-Path $outDir "candidate-$i.png"
    $body = @{ model = "gpt-image-1"; prompt = $prompt; size = "1024x1024"; quality = $Quality; background = "transparent"; n = 1 } | ConvertTo-Json
    Write-Host "generating icon candidate $i..."
    $resp = Invoke-RestMethod -Uri "https://api.openai.com/v1/images/generations" -Method Post `
        -Headers @{ Authorization = "Bearer $key" } -ContentType "application/json" -Body $body
    [IO.File]::WriteAllBytes($file, [Convert]::FromBase64String($resp.data[0].b64_json))

    # preview strip: 128/48/32/16 on a light half and a dark half
    $src = [System.Drawing.Image]::FromFile($file)
    $strip = New-Object System.Drawing.Bitmap 720, 180
    $g = [System.Drawing.Graphics]::FromImage($strip)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $light = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 245, 245, 250))
    $dark = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 43, 42, 51))
    $g.FillRectangle($light, 0, 0, 360, 180)
    $g.FillRectangle($dark, 360, 0, 360, 180)
    foreach ($half in 0, 360) {
        $x = $half + 20
        foreach ($s in 128, 48, 32, 16) {
            $g.DrawImage($src, $x, [int](90 - $s / 2), $s, $s)
            $x += $s + 30
        }
    }
    $g.Dispose()
    $strip.Save((Join-Path $outDir "candidate-$i-sizes.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $strip.Dispose()
    $src.Dispose()
    Write-Host "wrote candidate-$i.png + candidate-$i-sizes.png"
}
Write-Host "done"
