#!/bin/bash
# agent-install.sh <node-name> — mirrors the rock-mountain Stage 1 pattern.
set -eu
NAME="$1"
echo "=== agent install on $(hostname) as $NAME ==="
# JDK 21 if java missing or too old (agent.jar for this controller needs 17+)
need_jdk=1
if command -v java >/dev/null 2>&1; then
  major=$(java -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/')
  if [ "${major:-0}" -ge 17 ] 2>/dev/null; then need_jdk=0; fi
fi
if [ "$need_jdk" = "1" ]; then
  echo "installing openjdk-21-jre-headless..."
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update -qq
  sudo apt-get install -y -qq fontconfig openjdk-21-jre-headless > /tmp/apt-agent-jdk.log 2>&1 || { tail -20 /tmp/apt-agent-jdk.log; exit 1; }
fi
java -version 2>&1 | head -1
install -d -m 0755 /home/wbic16/jenkins-agent/work
# agent.jar: prefer a fresh download from the controller; fall back to the hub copy staged at /tmp/agent.jar.hub
code=$(curl -s -o /tmp/agent-dl.jar -w "%{http_code}" --max-time 30 http://100.88.154.1:8080/jnlpJars/agent.jar || echo 000)
size=$(stat -c%s /tmp/agent-dl.jar 2>/dev/null || echo 0)
if [ "$code" = "200" ] && [ "$size" -gt 500000 ]; then
  mv /tmp/agent-dl.jar /home/wbic16/jenkins-agent/agent.jar
  echo "agent.jar downloaded from controller (${size} bytes)"
elif [ -s /tmp/agent.jar.hub ]; then
  cp /tmp/agent.jar.hub /home/wbic16/jenkins-agent/agent.jar
  echo "agent.jar: controller download gave ${code}/${size}B — used hub copy ($(stat -c%s /home/wbic16/jenkins-agent/agent.jar) bytes)"
else
  echo "ERROR: could not obtain agent.jar (controller code=${code} size=${size}, no hub copy)"; exit 1
fi
if [ ! -s /home/wbic16/jenkins-agent/secret.txt ]; then echo "ERROR: secret.txt missing — pipe it in first"; exit 1; fi
chmod 600 /home/wbic16/jenkins-agent/secret.txt
ls -la /home/wbic16/jenkins-agent/
sudo tee /etc/systemd/system/jenkins-agent.service > /dev/null << EOF
[Unit]
Description=Jenkins agent ($NAME) for aletheia-core controller
After=network-online.target tailscaled.service
Wants=network-online.target

[Service]
User=wbic16
WorkingDirectory=/home/wbic16/jenkins-agent
ExecStart=/usr/bin/java -jar /home/wbic16/jenkins-agent/agent.jar -url http://100.88.154.1:8080/ -secret @/home/wbic16/jenkins-agent/secret.txt -name $NAME -workDir /home/wbic16/jenkins-agent/work -webSocket
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable jenkins-agent
sudo systemctl restart jenkins-agent
sleep 12
sudo systemctl is-active jenkins-agent
sudo journalctl -u jenkins-agent --no-pager -n 25 | grep -E "Connected|SEVERE|ERROR|INFO: " | tail -8
echo "=== done $NAME ==="
