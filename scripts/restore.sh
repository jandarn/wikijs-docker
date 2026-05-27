#!/bin/bash
set -euo pipefail

file="$1"
if [ -z "${file:-}" ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi
if [ ! -f "$file" ]; then
    echo "Backup file does not exist: $file"
    exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
set -a
source "$PROJECT_ROOT/.env"
set +a

: "${DB_USER:?DB_USER not set in .env}"
: "${DB_PASS:?DB_PASS not set in .env}"
: "${DB_NAME:?DB_NAME not set in .env}"

cleanup() {
    docker compose start wikijs postgres-exporter
}
trap cleanup EXIT

docker compose stop wikijs postgres-exporter

echo "Restoring backup from file: $file"
docker compose exec -T psql \
    env PGPASSWORD="$DB_PASS" \
    pg_restore -U "$DB_USER" -d "$DB_NAME" --clean --if-exists < "$file"

echo "Restore completed successfully from file: $file"