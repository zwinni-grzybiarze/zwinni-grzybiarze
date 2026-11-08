#requires -Version 5.1
# Build the local image and start HTTPS (Caddy) for LAN phone / PWA testing.
param(
    [string]$Tag = 'onlyshrooms'
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

& (Join-Path $root 'build-local.ps1') -Tag $Tag
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& bash (Join-Path $root 'deploy/ensure-tls.sh')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$env:ONLYSHROOMS_IMAGE = $Tag

docker rm -f onlyshrooms-dev 2>$null | Out-Null

Write-Host "==> Starting LAN stack (HTTPS on :443, HTTP app on :8080)" -ForegroundColor Cyan
Write-Host "    On a phone: https://<this-pc-lan-ip>  (accept cert warning once, then Install app)" -ForegroundColor DarkGray
docker compose -f (Join-Path $root 'docker-compose.yml') up --remove-orphans
