# Full local rebuild + start via compose.yml (HTTP :8080).
# Removes any existing container named onlyshrooms so the name never conflicts.
param(
    [string]$Tag = "onlyshrooms"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$env:ONLYSHROOMS_IMAGE = $Tag

Write-Host "==> Removing old containers (onlyshrooms / onlyshrooms-dev) if present"
docker rm -f onlyshrooms onlyshrooms-dev 2>$null | Out-Null

Write-Host "==> Building and starting local stack (HTTP on :8080)"
Write-Host "    On a phone: http://<this-pc-lan-ip>:8080"
docker compose -f "$root/compose.yml" up --build --force-recreate --remove-orphans
