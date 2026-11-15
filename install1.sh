#!/bin/bash
set -euo pipefail
exec > >(tee -a /home/wbic16/jenkins-install.log) 2>&1
echo "=== install1 start $(date -Is) ==="
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq fontconfig openjdk-21-jre-headless ca-certificates curl gnupg > /tmp/apt-jdk.log 2>&1 || { tail -30 /tmp/apt-jdk.log; exit 1; }
java -version 2>&1
# Jenkins LTS repo
sudo install -m 0755 -d /usr/share/keyrings
if [ ! -f /usr/share/keyrings/jenkins-keyring.asc ]; then
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
fi
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -qq
apt-cache policy jenkins | head -8
sudo apt-get install -y -qq jenkins > /tmp/apt-jenkins.log 2>&1 || { tail -30 /tmp/apt-jenkins.log; exit 1; }
echo "jenkins package installed:"
dpkg -l jenkins | tail -1
ls -l /usr/share/java/jenkins.war
sudo systemctl stop jenkins || true
sleep 2
# admin credential file (600, jenkins-owned) - generate once
sudo install -d -o jenkins -g jenkins -m 0755 /var/lib/jenkins/init.groovy.d
if [ ! -f /var/lib/jenkins/admin-credentials.txt ]; then
  PW=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)
  printf 'user=admin\npassword=%s\n' "$PW" | sudo tee /var/lib/jenkins/admin-credentials.txt > /dev/null
  sudo chown jenkins:jenkins /var/lib/jenkins/admin-credentials.txt
  sudo chmod 600 /var/lib/jenkins/admin-credentials.txt
  echo "admin credential file created"
else
  echo "admin credential file already exists"
fi
ls -l /var/lib/jenkins/admin-credentials.txt
# jenkins user joins wbic16 group for shared sccache access
sudo usermod -aG wbic16 jenkins
id jenkins
echo "=== install1 done $(date -Is) ==="
