#!/bin/bash
set -euo pipefail
exec > >(tee -a /home/wbic16/jenkins-install.log) 2>&1
echo "=== install1b start $(date -Is) ==="
export DEBIAN_FRONTEND=noninteractive
for y in 2026 2025 2023; do
  if curl -fsSL "https://pkg.jenkins.io/debian-stable/jenkins.io-$y.key" -o /tmp/jenkins-key-$y.asc 2>/dev/null; then
    echo "fetched key $y: $(gpg --show-keys --with-fingerprint /tmp/jenkins-key-$y.asc 2>/dev/null | grep -i fpr | head -1)"
    sudo cp /tmp/jenkins-key-$y.asc /usr/share/keyrings/jenkins-keyring.asc
    break
  fi
done
sudo apt-get update -qq 2>&1 | tail -3
apt-cache policy jenkins
sudo apt-get install -y -qq jenkins > /tmp/apt-jenkins.log 2>&1 || { tail -30 /tmp/apt-jenkins.log; exit 1; }
echo "jenkins package installed:"
dpkg -l jenkins | tail -1
sudo systemctl stop jenkins || true
sleep 2
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
sudo usermod -aG wbic16 jenkins
id jenkins
echo "=== install1b done $(date -Is) ==="
