#!/bin/bash
echo "host: $(hostname)"
echo "os: $(. /etc/os-release 2>/dev/null; echo ${PRETTY_NAME:-unknown})"
if command -v java >/dev/null 2>&1; then echo "java: $(java -version 2>&1 | head -1)"; else echo "java: MISSING"; fi
if sudo -n true 2>/dev/null; then echo "sudo: passwordless OK"; else echo "sudo: NOT passwordless"; fi
echo "existing agent dir: $(ls -d /home/wbic16/jenkins-agent 2>/dev/null || echo none)"
echo "existing agent unit: $(systemctl is-active jenkins-agent 2>/dev/null || echo inactive/absent)"
echo "controller agent.jar: $(curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://100.88.154.1:8080/jnlpJars/agent.jar)"
echo "home space: $(df -h /home/wbic16 | tail -1 | awk '{print $4" free"}')"
