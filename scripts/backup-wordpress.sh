
#!/bin/bash

# WordPress backup script
# Backs up files + database with timestamp

set -euo pipefail

# === Configuration ===
WP_PATH="/var/www/wordpress"
BACKUP_DIR="/var/backups/wordpress"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
DB_NAME="YOUR_DB_NAME"
DB_USER="YOUR_DB_USER"
DB_PASS="YOUR_DB_PASSWORD"
RETENTION_DAYS=7

# === Create temporary working directory ===
TMP_DIR=$(mktemp -d)
BACKUP_NAME="wordpress_backup_${DATE}"
WORK_DIR="${TMP_DIR}/${BACKUP_NAME}"
mkdir -p "${WORK_DIR}"

echo "[+] Starting WordPress backup: ${DATE}"

# === 1. Backup WordPress files ===
echo "[+] Backing up files from ${WP_PATH}"
sudo tar -czf "${WORK_DIR}/wordpress_files.tar.gz" -C "$(dirname ${WP_PATH})" "$(basename ${WP_PATH})"

# === 2. Backup MariaDB database ===
echo "[+] Backing up database: ${DB_NAME}"
mysqldump -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" > "${WORK_DIR}/wordpress_db.sql"

# === 3. Pack everything together ===
echo "[+] Creating final archive"
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C "${TMP_DIR}" "${BACKUP_NAME}"

# === 4. Cleanup temporary files ===
rm -rf "${TMP_DIR}"

# === 5. Delete old backups ===
echo "[+] Removing backups older than ${RETENTION_DAYS} days"
find "${BACKUP_DIR}" -name "wordpress_backup_*.tar.gz" -mtime +${RETENTION_DAYS} -delete

echo "[✓] Backup completed: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
ls -lh "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
