#!/bin/bash
set -eu
exec > >(tee -a /home/wbic16/jenkins-install.log) 2>&1
echo "=== configure1 start $(date -Is) ==="
sudo cp /home/wbic16/groovy/01-security.groovy /home/wbic16/groovy/02-controller-agent.groovy /home/wbic16/groovy/03-location.groovy /var/lib/jenkins/init.groovy.d/
sudo chown jenkins:jenkins /var/lib/jenkins/init.groovy.d/*.groovy
sudo install -d -m 0755 /etc/systemd/system/jenkins.service.d
sudo tee /etc/systemd/system/jenkins.service.d/override.conf > /dev/null << 'EOF'
[Unit]
After=tailscaled.service network-online.target
Wants=network-online.target

[Service]
Environment="JENKINS_LISTEN_ADDRESS=100.88.154.1"
Environment="JENKINS_PORT=8080"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
EOF
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins
echo "waiting for Jenkins HTTP..."
for i in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://100.88.154.1:8080/login 2>/dev/null || echo 000)
  echo "try $i: HTTP $code"
  if [ "$code" = "200" ] || [ "$code" = "403" ]; then break; fi
  sleep 5
done
sudo systemctl status jenkins --no-pager | head -12
ss -tlnp 2>/dev/null | grep 8080 || true
echo "--- journal tail ---"
sudo journalctl -u jenkins --no-pager -n 30 | grep -v -E "^--" | tail -30
echo "=== configure1 done $(date -Is) ==="
