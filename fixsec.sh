#!/bin/bash
set -eu
echo "--- pre-state ---"
sudo grep -E "securityRealm|authorizationStrategy|useSecurity" /var/lib/jenkins/config.xml || echo "no security lines in config.xml"
sudo ls /var/lib/jenkins/users/ 2>/dev/null || echo "no users dir"
sudo cp /home/wbic16/groovy/01-security.groovy /home/wbic16/groovy/04-matrix-auth.groovy /var/lib/jenkins/init.groovy.d/
sudo chown jenkins:jenkins /var/lib/jenkins/init.groovy.d/*.groovy
sudo systemctl restart jenkins
for i in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://100.88.154.1:8080/login 2>/dev/null || echo 000)
  if [ "$code" = "200" ]; then echo "login page 200 after ${i} tries"; break; fi
  sleep 5
done
sleep 3
sudo grep -E "security init|security:|controller agent" /var/log/jenkins/jenkins.log 2>/dev/null || sudo journalctl -u jenkins --no-pager -n 300 | grep -E "security init|security:|GroovyHookScript" | tail -10
echo "--- auth checks (password never printed) ---"
PW=$(sudo awk -F= '/^password=/{print $2}' /var/lib/jenkins/admin-credentials.txt)
curl -s -o /dev/null -w "anon /api/json: %{http_code}\n" http://100.88.154.1:8080/api/json
curl -s -u "admin:$PW" http://100.88.154.1:8080/whoAmI/api/json | head -c 300; echo
curl -s -o /dev/null -w "admin /api/json: %{http_code}\n" -u "admin:$PW" http://100.88.154.1:8080/api/json
curl -s -o /dev/null -w "wrongpass /api/json: %{http_code}\n" -u "admin:definitely-wrong" http://100.88.154.1:8080/api/json
