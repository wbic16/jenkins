#!/bin/bash
sudo journalctl -u jenkins --no-pager --since "2026-11-15 03:46:10" | grep -A12 "Failed to run script" | head -40
echo "=== initialAdminPassword present? ==="
sudo ls -l /var/lib/jenkins/secrets/ 2>/dev/null
echo "=== users ==="
sudo ls /var/lib/jenkins/users/
sudo cat /var/lib/jenkins/users/admin_*/config.xml 2>/dev/null | grep -E "fullName|passwordHash" | sed 's/<passwordHash>.*<\/passwordHash>/<passwordHash>REDACTED<\/passwordHash>/'
