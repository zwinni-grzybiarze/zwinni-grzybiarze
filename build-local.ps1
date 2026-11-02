#requires -Version 5.1
# Builds Flutter web and the API on the host, then packages them into a Docker image.
# Useful when the Docker build can't reach pub.dev / nuget.org (e.g. TLS-intercepting proxy).
param(
    [string]$Tag = 'onlyshrooms',
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$artifacts = Join-Path $root 'artifacts'

function Invoke-Step($description, [scriptblock]$action) {
    Write-Host "==> $description" -ForegroundColor Cyan
    # Native tools write progress to stderr; judge success by exit code only.
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $action } finally { $ErrorActionPreference = $previous }
    if ($LASTEXITCODE -ne 0) { throw "$description failed (exit code $LASTEXITCODE)" }
}

function Resolve-DotNet {
    $candidates = @()
    if ($env:DOTNET) { $candidates += $env:DOTNET }
    $userLocal = Join-Path $env:USERPROFILE '.dotnet\dotnet.exe'
    if (Test-Path $userLocal) { $candidates += $userLocal }
    $onPath = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($onPath) { $candidates += $onPath.Source }

    foreach ($d in $candidates) {
        if (-not (Test-Path $d)) { continue }
        $sdks = & $d --list-sdks 2>$null
        if ($sdks -match '(?m)^10\.') { return $d }
    }

    throw @"
No .NET 10 SDK found (projects target net10.0).
Install from https://aka.ms/dotnet/download or set DOTNET to a net10-capable dotnet.exe
"@
}

$dotnetBin = Resolve-DotNet
Write-Host "==> using dotnet: $dotnetBin ($(& $dotnetBin --version))" -ForegroundColor Cyan

if (Test-Path $artifacts) { Remove-Item $artifacts -Recurse -Force }

Push-Location (Join-Path $root 'src/frontend')
try {
    Invoke-Step 'flutter pub get' { flutter pub get }
    # Empty API_BASE => same-origin requests (required for LAN phone / PWA installs).
    Invoke-Step 'flutter build web' {
        flutter build web --release --no-wasm-dry-run `
            --dart-define=USE_MOCK_DATA=false `
            --dart-define=API_BASE=
    }
}
finally {
    Pop-Location
}
Copy-Item (Join-Path $root 'src/frontend/build/web') (Join-Path $artifacts 'web') -Recurse

Invoke-Step 'dotnet publish' {
    & $dotnetBin publish (Join-Path $root 'src/backend/OnlyShrooms/OS.WebApi/OS.WebApi.csproj') `
        -c $Configuration -o (Join-Path $artifacts 'api') /p:UseAppHost=false
}

Invoke-Step 'docker build' {
    docker build -f (Join-Path $root 'Dockerfile.local') -t $Tag $root
}

Write-Host "Image '$Tag' built. Run: docker run --rm -p 8080:8080 -v onlyshrooms-data:/data $Tag" -ForegroundColor Green
