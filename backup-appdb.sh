#!/usr/bin/env bash
# Daily backup of instance/app.db
# Example cron entry (runs every day at 02:00):
#   0 2 * * * /path/to/employee-dialogue/bin/backup-appdb.sh >> /var/log/appdb-backup.log 2>&1

set -euo pipefail

PROJECT_DIR=/opt/employee-dialogue

DB_FILE="${DB_FILE:-$PROJECT_DIR/instance/app.db}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_DIR/backups}"
MAX_BACKUPS="${MAX_BACKUPS:-30}"

DATE="$(date +%Y-%m-%d)"
TIME="$(date +%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/app-$DATE-$TIME.db"

if [[ ! -f "$DB_FILE" ]]; then
    echo "$(date '+%F %T') ERROR: database not found: $DB_FILE" >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"

# Use sqlite3 online backup if available (safe while DB is in use), else plain copy
if command -v sqlite3 >/dev/null 2>&1; then
    sqlite3 "$DB_FILE" ".backup '$BACKUP_FILE'"
else
    cp -p "$DB_FILE" "$BACKUP_FILE"
fi

gzip -f "$BACKUP_FILE"
echo "$(date '+%F %T') Backup created: $BACKUP_FILE.gz"

# Keep only the newest $MAX_BACKUPS backups
ls -1t "$BACKUP_DIR"/app-*.db.gz 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) | while IFS= read -r old; do
    rm -f -- "$old"
    echo "$(date '+%F %T') Removed old backup: $old"
done
