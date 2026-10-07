#!/usr/bin/env bash
# Restore instance/app.db from a backup created by backup-appdb.sh
# Usage:
#   restore-appdb.sh <backup-file>
# <backup-file> may be a bare file name (looked up in $BACKUP_DIR) or a path,
# compressed (.db.gz) or uncompressed (.db).
# Stop the application before restoring to avoid writes to the old database.

set -euo pipefail

PROJECT_DIR=/opt/employee-dialogue

DB_FILE="${DB_FILE:-$PROJECT_DIR/instance/app.db}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_DIR/backups}"

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <backup-file>" >&2
    echo "Available backups in $BACKUP_DIR:" >&2
    ls -1t "$BACKUP_DIR"/app-*.db.gz 2>/dev/null | xargs -r -n1 basename >&2 || true
    exit 1
fi

SRC="$1"
if [[ ! -f "$SRC" && -f "$BACKUP_DIR/$SRC" ]]; then
    SRC="$BACKUP_DIR/$SRC"
fi

if [[ ! -f "$SRC" ]]; then
    echo "$(date '+%F %T') ERROR: backup not found: $1" >&2
    exit 1
fi

TMP_FILE="$(mktemp "${DB_FILE}.restore.XXXXXX")"
trap 'rm -f -- "$TMP_FILE"' EXIT

if [[ "$SRC" == *.gz ]]; then
    gzip -dc -- "$SRC" > "$TMP_FILE"
else
    cp -- "$SRC" "$TMP_FILE"
fi

# Verify the backup is a valid SQLite database before replacing anything
if command -v sqlite3 >/dev/null 2>&1; then
    RESULT="$(sqlite3 "$TMP_FILE" 'PRAGMA integrity_check;' 2>&1 || true)"
    if [[ "$RESULT" != "ok" ]]; then
        echo "$(date '+%F %T') ERROR: integrity check failed for $SRC: $RESULT" >&2
        exit 1
    fi
fi

mkdir -p "$(dirname "$DB_FILE")"

# Keep a safety copy of the current database
if [[ -f "$DB_FILE" ]]; then
    SAFETY_FILE="${DB_FILE}.pre-restore-$(date +%Y-%m-%d-%H%M%S)"
    cp -p -- "$DB_FILE" "$SAFETY_FILE"
    echo "$(date '+%F %T') Current database saved to: $SAFETY_FILE"
    # Keep ownership/permissions of the existing database (mktemp creates 0600)
    chmod --reference="$DB_FILE" -- "$TMP_FILE"
    chown --reference="$DB_FILE" -- "$TMP_FILE" 2>/dev/null || true
else
    chmod 0644 -- "$TMP_FILE"
fi

# Remove stale WAL/journal files that belong to the old database
rm -f -- "${DB_FILE}-wal" "${DB_FILE}-shm" "${DB_FILE}-journal"

mv -f -- "$TMP_FILE" "$DB_FILE"
trap - EXIT
echo "$(date '+%F %T') Database restored from: $SRC"
