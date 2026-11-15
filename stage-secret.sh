#!/bin/bash
set -eu
sudo cp /var/lib/jenkins/rock-mountain-agent-secret.txt /home/wbic16/rock-secret-transfer.txt
sudo chown wbic16:wbic16 /home/wbic16/rock-secret-transfer.txt
chmod 600 /home/wbic16/rock-secret-transfer.txt
ls -l /home/wbic16/rock-secret-transfer.txt /home/wbic16/agent.jar
