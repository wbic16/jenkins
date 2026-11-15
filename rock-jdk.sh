#!/bin/bash
set -eu
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq fontconfig openjdk-21-jre-headless > /tmp/apt-rock-jdk.log 2>&1 || { tail -20 /tmp/apt-rock-jdk.log; exit 1; }
java -version 2>&1
install -d -m 0755 /home/wbic16/jenkins-agent/work
echo "rock JDK ready"
