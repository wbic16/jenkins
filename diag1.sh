#!/bin/bash
sudo journalctl -u jenkins --no-pager -n 400 | grep -B2 -A6 "01-security" | head -60
echo "=== anon check ==="
curl -s -o /dev/null -w "anon /api/json: %{http_code}\n" http://100.88.154.1:8080/api/json
curl -s -o /dev/null -w "anon /: %{http_code}\n" http://100.88.154.1:8080/
