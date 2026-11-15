#!/bin/bash
set -eu
sudo cp /home/wbic16/groovy/01-security.groovy /var/lib/jenkins/init.groovy.d/
sudo chown jenkins:jenkins /var/lib/jenkins/init.groovy.d/01-security.groovy
sudo systemctl restart jenkins
for i in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://100.88.154.1:8080/login 2>/dev/null || echo 000)
  if [ "$code" = "200" ]; then echo "login page 200 after ${i} tries"; break; fi
  sleep 5
done
sleep 3
sudo journalctl -u jenkins --no-pager -n 200 | grep -E "security:" | tail -8
# initialAdminPassword is superseded by the credential file; remove it
sudo rm -f /var/lib/jenkins/secrets/initialAdminPassword
echo "--- auth checks (password never printed) ---"
PW=$(sudo awk -F= '/^password=/{print $2}' /var/lib/jenkins/admin-credentials.txt)
curl -s -o /dev/null -w "anon /api/json: %{http_code}\n" http://100.88.154.1:8080/api/json
curl -s -o /dev/null -w "admin /api/json: %{http_code}\n" -u "admin:$PW" http://100.88.154.1:8080/api/json
curl -s -u "admin:$PW" http://100.88.154.1:8080/whoAmI/api/json | head -c 200; echo
curl -s -o /dev/null -w "wrongpass /api/json: %{http_code}\n" -u "admin:definitely-wrong" http://100.88.154.1:8080/api/json
sudo ls -l /var/lib/jenkins/admin-credentials.txt
sudo grep -E "authorizationStrategy class" /var/lib/jenkins/config.xml
