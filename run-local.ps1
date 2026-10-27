#requires -Version 5.1
# Builds the local image (build-local.ps1) and runs it on http://localhost:8080.
param(
    [string]$Tag = 'onlyshrooms',
    [string]$Name = 'onlyshrooms-dev'
)

$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'build-local.ps1') -Tag $Tag
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

docker rm -f $Name 2>$null | Out-Null

Write-Host "==> Running http://localhost:8080 (Ctrl+C or stop debugging to quit)" -ForegroundColor Cyan
docker run --rm --name $Name -p 8080:8080 -v onlyshrooms-data:/data $Tag
