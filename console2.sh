#!/bin/bash
PW=$(sudo awk -F= '/^password=/{print $2}' /var/lib/jenkins/admin-credentials.txt)
curl -s -u "admin:$PW" "http://100.88.154.1:8080/job/phext-lattice/2/consoleText" > /tmp/console2.txt
echo "=== test results lines ==="
grep -E "test result:|running [0-9]+ test|FAILED|failures:" /tmp/console2.txt | head -40
echo "=== failed test names ==="
grep -E "^test .* FAILED" /tmp/console2.txt | head -20
grep -A6 "^failures:$" /tmp/console2.txt | head -30
echo "=== sccache stats in build ==="
grep -A11 "Compile requests" /tmp/console2.txt | head -14
echo "=== checkout head ==="
grep -E "Checking out Revision|Commit message" /tmp/console2.txt
