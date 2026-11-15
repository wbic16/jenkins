#!/bin/bash
set -u
echo "== host =="; hostname; uname -a
echo "== os =="; cat /etc/os-release
echo "== uptime/load =="; uptime; cat /proc/loadavg
echo "== cpu/mem/disk =="; nproc; free -h; df -h / /home 2>/dev/null | head -20
echo "== temps =="; sensors 2>/dev/null | head -40 || cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null || echo "no sensors"
echo "== java =="; which java javac 2>/dev/null; java -version 2>&1 || echo "no java"; ls /usr/lib/jvm/ 2>/dev/null || true; apt list --installed 2>/dev/null | grep -i -E "jdk|jre|jenkins" || true
echo "== jenkins existing =="; which jenkins 2>/dev/null; systemctl status jenkins --no-pager 2>&1 | head -20; ls -ld /var/lib/jenkins /opt/jenkins 2>/dev/null || echo "no jenkins dirs"
echo "== ports 8080 =="; ss -tlnp 2>/dev/null | grep 8080 || echo "8080 free"
echo "== tailscale =="; tailscale ip -4 2>/dev/null; tailscale status 2>/dev/null | head -5
echo "== sudo =="; sudo -n true 2>&1 && echo "passwordless sudo OK" || echo "sudo needs password or check"
echo "== cargo/git =="; which cargo git curl wget; cargo --version 2>/dev/null; git --version
echo "== sccache =="; which sccache; cat ~/.config/sccache/config 2>/dev/null | head -20; env | grep -i sccache || true
