$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "A Docker nincs telepítve."
}

docker compose exec -T db psql -U lumen -d lumen_klinika -f /demo/lekerdezesek.sql
