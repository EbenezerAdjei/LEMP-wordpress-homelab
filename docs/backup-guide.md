# Backup Guide – WordPress on LEMP

This document describes an automated backup solution for a WordPress site 
running on a LEMP stack (Linux, nginx, MariaDB, PHP-FPM).

The backup script creates a timestamped archive containing:

- WordPress application files
- MariaDB database dump

Backups are stored locally on the server and old backups are removed 
automatically based on a retention policy.

---

## Overview

| Item | Details |
|------|---------|
| Script location | `~/scripts/backup-wordpress.sh` |
| Backup directory | `/var/backups/wordpress` |
| Contents | Website files + database dump |
| Format | `.tar.gz` archive |
| Retention | 7 days (configurable) |

---

## Prerequisites

- WordPress installed under `/var/www/wordpress`
- MariaDB database and user already created
- Sufficient disk space in `/var/backups`
- Script executed by a user with permission to read the WordPress files 
and dump the database

---

## Backup Directory Setup

```bash
sudo mkdir -p /var/backups/wordpress
sudo chown $USER:$USER /var/backups/wordpress
```

What the Script Does

1.Creates a temporary working directory
2.Compresses the WordPress files into wordpress_files.tar.gz
3.Dumps the MariaDB database into wordpress_db.sql
4.Packs both into a single timestamped archive:
   - Example: wordpress_backup_2026-10-01_09-00-50.tar.gz
5.Stores the archive in /var/backups/wordpress
6.Deletes backups older than the configured retention period


Running the Backup
```bash
chmod +x ~/scripts/backup-wordpress.sh
~/scripts/backup-wordpress.sh
```

Successful output example:

- [+] Starting WordPress backup: 2026-10-01_09-00-50
- [+] Backing up files from /var/www/wordpress
- [+] Backing up database: wordpress
- [+] Creating final archive
- [+] Removing backups older than 7 days
- [✓] Backup completed: 
/var/backups/wordpress/wordpress_backup_2026-10-01_09-00-50.tar.gz

Verifying the Backup
List backups:
```bash
ls -lh /var/backups/wordpress/
```

Inspect archive contents:
```bash
tar -tzf 
/var/backups/wordpress/wordpress_backup_YYYY-MM-DD_HH-MM-SS.tar.gz
```

Expected contents include:
- wordpress_files.tar.gz
- wordpress_db.sql
