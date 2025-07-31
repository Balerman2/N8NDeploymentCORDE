#!/bin/bash

BACKUP_DIR="/opt/n8n/backups"
DB_CONTAINER="n8n-db"
DB_USER="n8n"
DB_NAME="n8n"

mkdir -p "$BACKUP_DIR"

DATE=$(date +"%Y-%m-%d")
FILE="$BACKUP_DIR/n8n-backup-$DATE.sql"

echo "Creating backup: $FILE"
docker exec -t "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" > "$FILE"

# Delete backups older than 30 days
find "$BACKUP_DIR" -type f -name "*.sql" -mtime +30 -exec rm {} \;
echo "Old backups cleaned."

echo "Backup complete."
