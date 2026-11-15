#!/bin/bash
set -eu
J21=$(ls -d /usr/lib/jvm/java-21-openjdk-*/bin/java 2>/dev/null | head -1)
echo "java21 binary: $J21"
grep "^ExecStart" /etc/systemd/system/jenkins-agent.service || sudo grep "^ExecStart" /etc/systemd/system/jenkins-agent.service
sudo update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
sudo sed -i "s|^ExecStart=/usr/bin/java |ExecStart=${J21} |" /etc/systemd/system/jenkins-agent.service
sudo grep "^ExecStart" /etc/systemd/system/jenkins-agent.service
sudo systemctl daemon-reload
sudo systemctl restart jenkins-agent
sleep 10
echo "service: $(sudo systemctl is-active jenkins-agent)"
echo "default java now: $(java -version 2>&1 | head -1)"
sudo journalctl -u jenkins-agent --no-pager -n 30 | grep -E "Connected|SEVERE" | tail -3
