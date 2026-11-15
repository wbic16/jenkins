#!/bin/bash
set -eu
PW=$(sudo awk -F= '/^password=/{print $2}' /var/lib/jenkins/admin-credentials.txt)
cd /home/wbic16
echo "Tctl before build: $(sensors 2>/dev/null | grep Tctl || echo unknown)"
java -jar jenkins-cli.jar -s http://100.88.154.1:8080/ -auth "admin:$PW" build phext-lattice
echo "build triggered at $(date -Is)"
