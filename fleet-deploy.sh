#!/bin/bash
# fleet-deploy.sh "name ip" [...] — per node: pipe secret, stage files, install agent.
dssh() { ssh -i /home/hatch/.ssh/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=20 -o "ProxyCommand=nc -X connect -x hatch-egress-proxy:3130 %h %p" "$@"; }
dscp() { scp -i /home/hatch/.ssh/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=20 -o "ProxyCommand=nc -X connect -x hatch-egress-proxy:3130 %h %p" "$@"; }
HUB=100.88.154.1
for pair in "$@"; do
  name="${pair%% *}"; ip="${pair##* }"
  echo "########## $name ($ip) ##########"
  bytes=$(dssh wbic16@$HUB "sudo cat /var/lib/jenkins/${name}-agent-secret.txt" 2>/dev/null | dssh wbic16@$ip 'mkdir -p /home/wbic16/jenkins-agent && cat > /home/wbic16/jenkins-agent/secret.txt && wc -c < /home/wbic16/jenkins-agent/secret.txt' 2>/dev/null | tr -d ' \n')
  if [ "$bytes" != "64" ]; then echo "RESULT $name: SECRET-PIPE-FAILED (bytes=$bytes) — skipping"; continue; fi
  echo "secret piped (64 bytes)"
  if ! dscp /tmp/agent-install.sh wbic16@$ip:/tmp/agent-install.sh >/dev/null 2>&1; then echo "RESULT $name: SCP-FAILED — skipping"; continue; fi
  dscp /tmp/agent.jar.hubcopy wbic16@$ip:/tmp/agent.jar.hub >/dev/null 2>&1 || echo "(hub jar scp failed; install will try controller download)"
  out=$(dssh wbic16@$ip "bash /tmp/agent-install.sh $name" 2>&1)
  echo "$out" | grep -E "openjdk version|agent.jar|ERROR|SEVERE" | head -5
  if echo "$out" | grep -q "INFO: Connected"; then
    echo "RESULT $name: CONNECTED"
  elif echo "$out" | grep -q "^active$"; then
    echo "RESULT $name: SERVICE-ACTIVE-NO-CONNECT-LINE (check journal)"
    echo "$out" | tail -6
  else
    echo "RESULT $name: INSTALL-FAILED"
    echo "$out" | tail -8
  fi
done
echo "########## batch done ##########"
