#!/bin/bash
echo "== host =="; hostname
echo "== load =="; uptime
echo "== temps =="; sensors 2>/dev/null | grep -E "Tctl|Core" | head -4 || echo "no sensors"
echo "== mem/disk =="; free -h | head -2; df -h /home | tail -1
echo "== java =="; java -version 2>&1 || echo "no java"; ls /usr/lib/jvm/ 2>/dev/null || true
echo "== os =="; grep PRETTY /etc/os-release
echo "== sudo =="; sudo -n true 2>&1 && echo "passwordless sudo OK" || echo "no passwordless sudo"
echo "== reach controller =="; timeout 8 curl -s -o /dev/null -w "%{http_code}\n" http://100.88.154.1:8080/login || echo "unreachable"
