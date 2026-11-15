#!/bin/bash
set -eu
PW=$(sudo awk -F= '/^password=/{print $2}' /var/lib/jenkins/admin-credentials.txt)
cd /home/wbic16
java -jar jenkins-cli.jar -s http://100.88.154.1:8080/ -auth "admin:$PW" create-job agent-smoke-rock < smoke-job.xml || java -jar jenkins-cli.jar -s http://100.88.154.1:8080/ -auth "admin:$PW" update-job agent-smoke-rock < smoke-job.xml
java -jar jenkins-cli.jar -s http://100.88.154.1:8080/ -auth "admin:$PW" build agent-smoke-rock -s -v 2>&1 | grep -E "hostname|rock-mountain|Linux|openjdk|Finished:|SUCCESS|FAILURE" | head -10
