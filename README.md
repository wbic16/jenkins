# jenkins

Jenkins Stage 1 setup scripts (VM side): install, security configuration
(`groovy/` init scripts), the phext-lattice pilot job definition, and the
rock-mountain agent setup used to stand up the house Jenkins — controller
on aletheia-core, agent on rock-mountain. No credential values live in
these scripts; the installer generates the admin password on the node into
a 600-perm file the init scripts read.

Live copies run from `~/workspace/jenkins-stage1/` on the Muse VM. The
running controller's own configuration under `/var/lib/jenkins` on
aletheia-core is tracked separately.

## Fleet enrollment + dark theme (2026-11-15)

- `groovy/06-fleet.groovy` (also installed as
  `init.groovy.d/06-fleet.groovy`): idempotently defines all 22 ranch
  nodes as WebSocket inbound agents (2 executors, labels
  `ranch <short-name>`, remote root `/home/wbic16/jenkins-agent/work`),
  keeps each node's JNLP secret in
  `/var/lib/jenkins/<name>-agent-secret.txt` (0600; values never enter
  this repo), ensures the parameterized `agent-smoke` pipeline
  (`jobs/agent-smoke/config.xml` is its rendered form), and smoke-tests
  every online node once per boot window — status in
  `/var/lib/jenkins/fleet-status.txt`, pass markers in
  `/var/lib/jenkins/fleet/<node>.smoke-ok`. The job object is captured in
  the script body and handed to the verify thread, and the thread logs
  its scheduling decisions into the status file (`diag` lines): a v1
  that re-looked the job up by name inside the thread silently never
  scheduled a build.
- `groovy/07-theme-default.groovy`: sets the instance-default theme to
  Dark via the Theme Manager + Dark Theme plugins (installed with
  jenkins-plugin-manager: theme-manager, dark-theme). Per-user theme
  choices still override the default.
- Node side: `fleet-deploy.sh "name ip" [...]` pipes each node's secret
  from the controller through the operator VM (the value is never
  printed), stages `agent-install.sh`, and runs it. `agent-install.sh`
  installs JDK 21 when the node's Java is older than 17, fetches
  agent.jar from the controller (falling back to the hub's copy — the
  controller intermittently answers `/jnlpJars/agent.jar` with 403 to
  agent nodes), and enables a `jenkins-agent.service` (User=wbic16,
  `-webSocket`, Restart=always). `agent-probe.sh` is the read-only
  pre-check.
- `uncanny-valley-fixup.sh`: uncanny-valley runs under Jared's account
  with Java 8 as the system default. After the standard install, this
  restores the Java 8 default alternative and pins the agent unit's
  ExecStart to the explicit Java 21 binary, so nothing of Jared's
  environment changes. Note: if the agent service is restarted while
  the controller still holds the old WebSocket channel, the controller
  rejects reconnections as duplicates ("already connected") and builds
  fail on a dead channel — a controller restart clears the stale
  channel (seen 2026-11-15; the agent then reconnects on its own
  retry loop).
- Outcome 2026-11-15: 18 of 22 nodes enrolled, online, and smoke-PASS.
  Exceptions: great-white (SSH key refused), aurora-continuum,
  best-willow, delta-wood (down). Their node definitions and secret
  files already exist on the controller, so enrollment completes with
  `fleet-deploy.sh` alone once they are reachable.
- Naming: Jenkins is to be hosted via the Tailscale Service
  `svc:jenkins` (Will's direction, 2026-11-15). The serve endpoint is
  pending a console step — aletheia-core must be tagged as a host for
  the service — after which the Jenkins root URL will be set to the
  service's HTTPS name. Until then the root URL stays
  http://100.88.154.1:8080/ (tailnet-only).
