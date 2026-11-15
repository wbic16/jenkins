#!/bin/bash
set -eu
exec > >(tee -a /home/wbic16/jenkins-install.log) 2>&1
echo "=== plugins start $(date -Is) ==="
PW=$(sudo awk -F= '/^password=/{print $2}' /var/lib/jenkins/admin-credentials.txt)
cd /home/wbic16
curl -s -u "admin:$PW" -o jenkins-cli.jar http://100.88.154.1:8080/jnlpJars/jenkins-cli.jar
ls -l jenkins-cli.jar
java -jar jenkins-cli.jar -s http://100.88.154.1:8080/ -auth "admin:$PW" install-plugin git workflow-aggregator credentials-binding timestamper matrix-auth 2>&1 | tail -20
echo "--- restarting ---"
java -jar jenkins-cli.jar -s http://100.88.154.1:8080/ -auth "admin:$PW" safe-restart || sudo systemctl restart jenkins
for i in $(seq 1 72); do
  code=$(curl -s -o /dev/null -w "%{http_code}" -u "admin:$PW" http://100.88.154.1:8080/api/json 2>/dev/null || echo 000)
  if [ "$code" = "200" ]; then echo "Jenkins back after ${i} tries"; break; fi
  sleep 5
done
sleep 5
echo "--- matrix groovy result ---"
sudo journalctl -u jenkins --no-pager -n 300 | grep -E "matrix-auth:" | tail -3
sudo grep -E "authorizationStrategy class" /var/lib/jenkins/config.xml
echo "--- installed plugins (short names of interest) ---"
curl -s -u "admin:$PW" "http://100.88.154.1:8080/pluginManager/api/json?depth=1" | python3 -c "
import json,sys
d=json.load(sys.stdin)
names=sorted(p['shortName']+' '+p['version'] for p in d['plugins'] if p['enabled'])
print(len(names),'enabled plugins')
for n in names:
    if any(k in n for k in ['git','workflow','credentials','timestamper','matrix','pipeline','scm','token','ssh','structs','branch','durable','support']):
        print(' ',n)
"
curl -s -o /dev/null -w "anon after plugins: %{http_code}\n" http://100.88.154.1:8080/api/json
echo "=== plugins done $(date -Is) ==="
