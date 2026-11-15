#!/bin/bash
PW=$(sudo awk -F= '/^password=/{print $2}' /var/lib/jenkins/admin-credentials.txt)
curl -s -u "admin:$PW" "http://100.88.154.1:8080/job/phext-lattice/lastBuild/api/json?tree=number,building,result,duration,estimatedDuration" ; echo
echo "Tctl now: $(sensors 2>/dev/null | grep Tctl || echo unknown)"
curl -s -u "admin:$PW" "http://100.88.154.1:8080/job/phext-lattice/lastBuild/consoleText" | tail -15
