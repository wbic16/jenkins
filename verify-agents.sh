#!/bin/bash
PW=$(sudo awk -F= '/^password=/{print $2}' /var/lib/jenkins/admin-credentials.txt)
curl -sg -u "admin:$PW" "http://100.88.154.1:8080/computer/api/json?tree=computer[displayName,offline,numExecutors]" | python3 -m json.tool
rm -f /home/wbic16/rock-secret-transfer.txt
echo "transfer copy on aletheia removed"
sudo systemctl is-enabled jenkins; sudo systemctl is-active jenkins
