# Builds per-browser packages into dist\:
#   dist\chromium\  + untabit-chromium.zip   (Chrome, Brave, Edge)
#   dist\firefox\   + untabit-firefox.zip    (Firefox; its manifest is manifest.firefox.json renamed)
$root = $PSScriptRoot
$dist = Join-Path $root "dist"
Remove-Item -Recurse -Force $dist -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.IO.Compression.FileSystem

# Compress-Archive writes backslash entry names, which violates the zip
# spec and is rejected by AMO validation - zip via .NET with / separators.
function New-Zip([string]$dir, [string]$zipPath) {
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    $zip = [System.IO.Compression.ZipFile]::Open($zipPath, "Create")
    try {
        foreach ($f in Get-ChildItem $dir -Recurse -File) {
            $rel = $f.FullName.Substring($dir.Length + 1) -replace "\\", "/"
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, $rel) | Out-Null
        }
    } finally {
        $zip.Dispose()
    }
}

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
    New-Zip $out (Join-Path $dist "untabit-$target.zip")
}
Write-Host "Built:" (Get-ChildItem $dist -Recurse -File | Measure-Object).Count "files under $dist"
