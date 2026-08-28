$ErrorActionPreference = "Stop"

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"
$envLine = Get-Content -LiteralPath $envFile |
    Where-Object { $_ -match "^TINYPNG_API_KEY=" } |
    Select-Object -First 1

if (-not $envLine) { throw "TINYPNG_API_KEY is missing from .env" }
$key = $envLine.Substring("TINYPNG_API_KEY=".Length).Trim().Trim('"').Trim("'")
if (-not $key) { throw "TINYPNG_API_KEY is empty in .env" }

$paths = @(
    "icons\icon16.png"
    "icons\icon32.png"
    "icons\icon48.png"
    "icons\icon128.png"
)

Add-Type -AssemblyName System.Drawing

function Get-PngDimensions([string] $path) {
    $image = [Drawing.Image]::FromFile($path)
    try {
        [pscustomobject]@{ Width = $image.Width; Height = $image.Height }
    }
    finally {
        $image.Dispose()
    }
}

$before = @{}
foreach ($relativePath in $paths) {
    $path = Join-Path $root $relativePath
    $dimensions = Get-PngDimensions $path
    $before[$relativePath] = [pscustomobject]@{
        Bytes = (Get-Item -LiteralPath $path).Length
        Width = $dimensions.Width
        Height = $dimensions.Height
    }
}

$tempDir = Join-Path ([IO.Path]::GetTempPath()) ("untabit-tinypng-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempDir | Out-Null
$client = [Net.Http.HttpClient]::new()
$credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("api:$key"))
$client.DefaultRequestHeaders.Authorization =
    [Net.Http.Headers.AuthenticationHeaderValue]::new("Basic", $credentials)

try {
    foreach ($relativePath in $paths) {
        $path = Join-Path $root $relativePath
        $content = [Net.Http.ByteArrayContent]::new([IO.File]::ReadAllBytes($path))
        $content.Headers.ContentType = [Net.Http.Headers.MediaTypeHeaderValue]::new("image/png")
        $response = $client.PostAsync("https://api.tinify.com/shrink", $content).GetAwaiter().GetResult()
        $responseBody = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) {
            throw "TinyPNG rejected $relativePath (HTTP $([int] $response.StatusCode)): $responseBody"
        }

        $location = $response.Headers.Location
        if (-not $location) { throw "TinyPNG returned no output URL for $relativePath" }
        $optimized = $client.GetByteArrayAsync($location).GetAwaiter().GetResult()
        $target = Join-Path $tempDir ([IO.Path]::GetFileName($relativePath))
        [IO.File]::WriteAllBytes($target, $optimized)

        $dimensions = Get-PngDimensions $target
        $original = $before[$relativePath]
        if ($dimensions.Width -ne $original.Width -or $dimensions.Height -ne $original.Height) {
            throw "TinyPNG changed the dimensions of $relativePath"
        }
        if ($optimized.Length -ge $original.Bytes) {
            throw "TinyPNG did not reduce $relativePath"
        }
    }

    foreach ($relativePath in $paths) {
        $source = Join-Path $tempDir ([IO.Path]::GetFileName($relativePath))
        [IO.File]::Copy($source, (Join-Path $root $relativePath), $true)
    }
}
finally {
    $client.Dispose()
    if (Test-Path -LiteralPath $tempDir) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force
    }
}

foreach ($relativePath in $paths) {
    $after = (Get-Item -LiteralPath (Join-Path $root $relativePath)).Length
    $original = $before[$relativePath].Bytes
    [pscustomobject]@{
        File = $relativePath
        Before = $original
        After = $after
        Saved = $original - $after
        Reduction = [math]::Round((1 - $after / $original) * 100, 1)
    }
}
