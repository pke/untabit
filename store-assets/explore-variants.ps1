# Renders alternative illustration styles (both scenes each) into
# store-assets\variants\ so a style can be picked before composing the
# final assets with make-ai-assets.ps1.
param([string]$Quality = "high")
$ErrorActionPreference = "Stop"

$key = $env:OPENAI_API_KEY
$keyFile = Join-Path $env:USERPROFILE ".secrets\openai_api_key"
if (-not $key -and (Test-Path $keyFile)) { $key = (Get-Content $keyFile -Raw).Trim() }
if (-not $key) { throw "No API key found: set OPENAI_API_KEY or create $keyFile" }

$outDir = Join-Path $PSScriptRoot "variants"
New-Item -ItemType Directory -Force $outDir | Out-Null

$sceneOut = @"
Scene: a large stylized browser window with a row of tabs on top. One
tab has just popped out of the row and become a SMALL SEPARATE BROWSER
WINDOW floating to the upper right: unmistakably a miniature browser
window with its own single tab on top, its own address bar and a few
content lines - not a card, not a sticky note. A dashed motion arc
leads from the empty gap in the large window's tab row to the small
floating browser window.
"@

$sceneIn = @"
Scene: a small floating browser window to the upper right - unmistakably
a miniature browser window with its own single tab on top, its own
address bar and a few content lines - is flying back INTO a large
stylized browser window with a row of tabs. A dashed motion arc leads
from the small floating window into a highlighted empty gap in the
large window's tab row, showing the small window docking back in as a
tab.
"@

$common = @"
Marketing banner illustration for a browser extension.
Indigo-to-violet gradient background (#4F46E5 to #7C3AED), generous
empty background space at the top and bottom for text overlays. Both
windows share the same visual style. Absolutely no text, letters,
numbers or words anywhere in the image.
"@

$styles = @{
    "lineart" = "Style: modern flat vector, clean white line-art windows with thin rounded strokes, soft shadows, minimal and elegant."
    "glass"   = "Style: soft 3D glassmorphism, frosted translucent white windows with depth, gentle inner glow, floating above the background with realistic soft shadows."
    "playful" = "Style: bold flat geometric shapes, chunky rounded windows in white and light lavender fills, energetic motion streaks and a few small star sparkles, friendly and playful."
}

foreach ($styleName in $styles.Keys | Sort-Object) {
    foreach ($scene in @(@("out", $sceneOut), @("in", $sceneIn))) {
        $sceneName, $sceneText = $scene
        $prompt = "$common`n$($styles[$styleName])`n$sceneText"
        $file = Join-Path $outDir "$styleName-$sceneName.png"
        $body = @{ model = "gpt-image-1"; prompt = $prompt; size = "1536x1024"; quality = $Quality; n = 1 } | ConvertTo-Json
        Write-Host "generating $styleName-$sceneName..."
        $resp = Invoke-RestMethod -Uri "https://api.openai.com/v1/images/generations" -Method Post `
            -Headers @{ Authorization = "Bearer $key" } -ContentType "application/json" -Body $body
        [IO.File]::WriteAllBytes($file, [Convert]::FromBase64String($resp.data[0].b64_json))
        Write-Host "wrote variants\$styleName-$sceneName.png"
    }
}
Write-Host "done"
