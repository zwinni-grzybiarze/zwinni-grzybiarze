#requires -Version 5.1
# Build the local image and start the app via compose.yml (HTTP :8080).
param(
    [string]$Tag = 'onlyshrooms'
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

& (Join-Path $root 'build-local.ps1') -Tag $Tag
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$env:ONLYSHROOMS_IMAGE = $Tag

docker rm -f onlyshrooms-dev 2>$null | Out-Null

Write-Host "==> Starting local stack (HTTP on :8080)" -ForegroundColor Cyan
Write-Host "    On a phone: http://<this-pc-lan-ip>:8080" -ForegroundColor DarkGray
docker compose -f (Join-Path $root 'compose.yml') up --remove-orphans
