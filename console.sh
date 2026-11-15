#!/bin/bash
PW=$(sudo awk -F= '/^password=/{print $2}' /var/lib/jenkins/admin-credentials.txt)
curl -s -u "admin:$PW" "http://100.88.154.1:8080/job/phext-lattice/1/consoleText"
