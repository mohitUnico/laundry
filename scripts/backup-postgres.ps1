# Backup local PostgreSQL (Docker) to .tmp/backups/
# Usage: .\scripts\backup-postgres.ps1
# Requires: docker compose postgres running (laundry-db container)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$BackupDir = Join-Path $Root ".tmp\backups"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$OutFile = Join-Path $BackupDir "laundry_db-$Timestamp.sql"

New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

Write-Host "Backing up laundry_db -> $OutFile" -ForegroundColor Cyan

docker exec laundry-db pg_dump -U laundry_user -d laundry_db --no-owner --no-acl | Set-Content -Encoding utf8 $OutFile

if ($LASTEXITCODE -ne 0) {
    Write-Error "pg_dump failed. Is laundry-db running? (docker compose up -d postgres)"
}

Write-Host "Backup complete." -ForegroundColor Green
