#!/usr/bin/env bash
# Backup local PostgreSQL (Docker) to .tmp/backups/
# Usage: ./scripts/backup-postgres.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$ROOT/.tmp/backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
OUT_FILE="$BACKUP_DIR/laundry_db-$TIMESTAMP.sql"

mkdir -p "$BACKUP_DIR"

echo "Backing up laundry_db -> $OUT_FILE"
docker exec laundry-db pg_dump -U laundry_user -d laundry_db --no-owner --no-acl > "$OUT_FILE"
echo "Backup complete."
