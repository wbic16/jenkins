#!/bin/bash
set -eu
chmod 600 /home/wbic16/jenkins-agent/secret.txt
ls -l /home/wbic16/jenkins-agent/
sudo tee /etc/systemd/system/jenkins-agent.service > /dev/null << 'EOF'
[Unit]
Description=Jenkins agent (rock-mountain) for aletheia-core controller
After=network-online.target tailscaled.service
Wants=network-online.target

[Service]
User=wbic16
WorkingDirectory=/home/wbic16/jenkins-agent
ExecStart=/usr/bin/java -jar /home/wbic16/jenkins-agent/agent.jar -url http://100.88.154.1:8080/ -secret @/home/wbic16/jenkins-agent/secret.txt -name rock-mountain -workDir /home/wbic16/jenkins-agent/work -webSocket
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable jenkins-agent
sudo systemctl start jenkins-agent
sleep 12
sudo systemctl status jenkins-agent --no-pager | head -10
sudo journalctl -u jenkins-agent --no-pager -n 15 | tail -15
