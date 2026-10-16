$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "A Docker nincs telepítve. Helyi PostgreSQL-hez a sql/futtatas.sql fájlt futtasd psql-lel. A lépések a README-ben vannak."
}

docker compose down -v
docker compose up -d --wait
Write-Host "Az adatbázis felállt. Port: 5432, adatbázis: lumen_klinika, felhasználó: lumen"
