# Builds per-browser packages into dist\:
#   dist\chromium\  + untabit-chromium.zip   (Chrome, Brave, Edge)
#   dist\firefox\   + untabit-firefox.zip    (Firefox; its manifest is manifest.firefox.json renamed)
$root = $PSScriptRoot
$dist = Join-Path $root "dist"
Remove-Item -Recurse -Force $dist -ErrorAction SilentlyContinue

foreach ($target in "chromium", "firefox") {
    $out = Join-Path $dist $target
    New-Item -ItemType Directory -Force $out | Out-Null
    Copy-Item (Join-Path $root "background.js") $out
    Copy-Item (Join-Path $root "shortcut-help.html") $out
    Copy-Item (Join-Path $root "icons") $out -Recurse
    if ($target -eq "chromium") {
        Copy-Item (Join-Path $root "manifest.json") $out
    } else {
        Copy-Item (Join-Path $root "manifest.firefox.json") (Join-Path $out "manifest.json")
    }
    Compress-Archive -Path (Join-Path $out "*") -DestinationPath (Join-Path $dist "untabit-$target.zip") -Force
}
Write-Host "Built:" (Get-ChildItem $dist -Recurse -File | Measure-Object).Count "files under $dist"
