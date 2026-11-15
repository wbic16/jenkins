#!/bin/bash
set -eu
PW=$(sudo awk -F= '/^password=/{print $2}' /var/lib/jenkins/admin-credentials.txt)
cd /home/wbic16
rm -f /tmp/jcookies /tmp/crumb.json
curl -s -u "admin:$PW" -c /tmp/jcookies "http://100.88.154.1:8080/crumbIssuer/api/json" > /tmp/crumb.json
CRUMB=$(python3 -c "import json;print(json.load(open('/tmp/crumb.json'))['crumb'])")
curl -s -u "admin:$PW" -b /tmp/jcookies -H "Jenkins-Crumb: $CRUMB" --data-urlencode "script@/home/wbic16/create-node.groovy" http://100.88.154.1:8080/scriptText
sudo chown jenkins:jenkins /var/lib/jenkins/rock-mountain-agent-secret.txt
sudo chmod 600 /var/lib/jenkins/rock-mountain-agent-secret.txt
sudo ls -l /var/lib/jenkins/rock-mountain-agent-secret.txt
curl -s -u "admin:$PW" -o /home/wbic16/agent.jar http://100.88.154.1:8080/jnlpJars/agent.jar
ls -l /home/wbic16/agent.jar
curl -s -u "admin:$PW" "http://100.88.154.1:8080/computer/api/json?tree=computer[displayName,offline]" 
echo
