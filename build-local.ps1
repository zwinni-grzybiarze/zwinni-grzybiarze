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
    & $action
    if ($LASTEXITCODE -ne 0) { throw "$description failed (exit code $LASTEXITCODE)" }
}

if (Test-Path $artifacts) { Remove-Item $artifacts -Recurse -Force }

Push-Location (Join-Path $root 'src/frontend')
try {
    Invoke-Step 'flutter pub get' { flutter pub get }
    Invoke-Step 'flutter build web' { flutter build web --release --no-wasm-dry-run }
}
finally {
    Pop-Location
}
Copy-Item (Join-Path $root 'src/frontend/build/web') (Join-Path $artifacts 'web') -Recurse

Invoke-Step 'dotnet publish' {
    dotnet publish (Join-Path $root 'src/backend/OnlyShrooms/OS.WebApi/OS.WebApi.csproj') `
        -c $Configuration -o (Join-Path $artifacts 'api') /p:UseAppHost=false
}

Invoke-Step 'docker build' {
    docker build -f (Join-Path $root 'Dockerfile.local') -t $Tag $root
}

Write-Host "Image '$Tag' built. Run: docker run --rm -p 8080:8080 -v onlyshrooms-data:/data $Tag" -ForegroundColor Green
