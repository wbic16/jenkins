// 06-fleet.groovy — fleet agent enrollment (idempotent) + smoke verification.
// Enrolls every ranch node as a WebSocket inbound agent (2 executors,
// labels "ranch <short-name>", remote root /home/wbic16/jenkins-agent/work),
// keeps each node's JNLP secret in /var/lib/jenkins/<name>-agent-secret.txt
// (0600), ensures the parameterized 'agent-smoke' pipeline exists, and —
// for ~50 minutes after each boot — smoke-tests every online node once,
// recording status in /var/lib/jenkins/fleet-status.txt and pass markers
// in /var/lib/jenkins/fleet/<node>.smoke-ok.
// Note: the root URL is NOT managed here. The jenkins.phext.io plan was
// dropped by Will (2026-11-15 16:30 CST) in favor of a Tailscale Service
// (svc:jenkins); the root URL gets set to the service name once the serve
// endpoint exists.
// v2: the smoke thread receives the job object from this script body (no
// name lookup inside the thread) and logs its scheduling decisions and any
// exception into fleet-status.txt (diag= lines) so failures are observable.

import jenkins.model.Jenkins
import hudson.slaves.DumbSlave
import hudson.slaves.JNLPLauncher
import hudson.slaves.RetentionStrategy
import hudson.model.StringParameterValue
import hudson.model.ParametersAction
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import hudson.model.ParametersDefinitionProperty
import hudson.model.StringParameterDefinition

def fleetNodes = [
  'rock-mountain', 'ashfall-haven', 'elven-path', 'free-fall',
  'halycon-vector', 'lighthouse-omen', 'logos-prime', 'ni-knight',
  'orchid-flow', 'plain-view', 'quacked-hill', 'scroll-central',
  'jacked-kite', 'kaleidoscope-one', 'moon-beam', 'west-lincoln',
  'yeet-max', 'great-white', 'uncanny-valley', 'aurora-continuum',
  'best-willow', 'delta-wood'
]

def jenkins = Jenkins.get()
def home = jenkins.getRootDir()
def fleetDir = new File(home, 'fleet')
fleetDir.mkdirs()

fleetNodes.each { name ->
  if (jenkins.getNode(name) == null) {
    def agent = new DumbSlave(
      name,
      '/home/wbic16/jenkins-agent/work',
      new JNLPLauncher(true)          // WebSocket inbound, like rock-mountain
    )
    agent.setNumExecutors(2)
    agent.setMode(hudson.model.Node.Mode.NORMAL)
    agent.setLabelString('ranch ' + name)
    agent.setRetentionStrategy(new RetentionStrategy.Always())
    agent.setNodeDescription('Ranch node ' + name + ' (fleet enrollment, 06-fleet.groovy)')
    jenkins.addNode(agent)
    println "fleet: node created: ${name}"
  }
  def secretFile = new File(home, name + '-agent-secret.txt')
  def secret = jenkins.getComputer(name)?.getJnlpMac()
  if (secret != null && (!secretFile.exists() || secretFile.text.trim() != secret)) {
    secretFile.text = secret
    secretFile.setReadable(false, false); secretFile.setReadable(true, true)
    secretFile.setWritable(false, false); secretFile.setWritable(true, true)
    println "fleet: secret file written for ${name}"
  }
}

// Smoke job (parameterized; the per-node Stage 1 job agent-smoke-rock is untouched).
def smokeJob = jenkins.getItemByFullName('agent-smoke')
if (smokeJob == null) {
  smokeJob = jenkins.createProject(WorkflowJob, 'agent-smoke')
  println 'fleet: smoke job created'
}
def smokeScript = '''
pipeline {
  agent { label params.NODE_LABEL }
  stages {
    stage('smoke') {
      steps { sh 'hostname; uname -sr; java -version 2>&1 | head -1; echo FLEET-SMOKE-OK' }
    }
  }
}
'''
smokeJob.setDefinition(new CpsFlowDefinition(smokeScript, true))
smokeJob.setDescription('Fleet smoke test: proves the agent selected by NODE_LABEL executes work. Managed by 06-fleet.groovy.')
if (smokeJob.getProperty(ParametersDefinitionProperty) == null) {
  smokeJob.addProperty(new ParametersDefinitionProperty(
    new StringParameterDefinition('NODE_LABEL', 'rock-mountain', 'Agent label to smoke-test')))
}
smokeJob.save()
println 'fleet: smoke job configured'

// Background verification: smoke-test each online node once per boot window.
// fleet-status.txt is the evidence surface; diag lines record the thread's
// own decisions so a silent no-op is impossible.
def capturedJob = smokeJob
def marker = new File(home, 'fleet-verify-started.txt')
long nowMs = System.currentTimeMillis()
boolean startThread = true
if (marker.exists() && (nowMs - marker.lastModified() < 45L * 60L * 1000L)) {
  startThread = false   // a previous boot's window is still fresh; do not double-run
}
if (startThread) {
  marker.text = new Date().toString()
  def verifyBody = {
    def inFlight = [:]
    def lastDiag = 'no scheduling attempt yet'
    long deadline = System.currentTimeMillis() + 50L * 60L * 1000L
    def writeStatus = { String diagLine ->
      def sb = new StringBuilder()
      sb << 'updated=' << new Date().toString() << '\n'
      sb << 'diag ' << diagLine << '\n'
      try {
        def q = Jenkins.get().getQueue().getItems().collect { qi ->
          qi.task.name + ' why=' + (qi.getWhy()?.getShortDescription() ?: '?')
        }.join(' ; ')
        sb << 'diag queue=[' << q << ']\n'
      } catch (Exception ignored) {}
      fleetNodes.each { n ->
        def comp = Jenkins.get().getComputer(n)
        def ok = new File(fleetDir, n + '.smoke-ok').exists()
        def state = ok ? 'PASS' : (inFlight.containsKey(n) ? 'RUNNING' : 'pending')
        sb << 'node=' << n << ' online=' << (comp != null && !comp.isOffline()) <<
              ' idle=' << (comp?.isIdle()) << ' smoke=' << state << '\n'
      }
      new File(home, 'fleet-status.txt').text = sb.toString()
    }
    try {
      while (System.currentTimeMillis() < deadline) {
        // reap finished builds
        inFlight.keySet().collect().each { n ->
          def fut = inFlight[n]
          if (fut.isDone()) {
            inFlight.remove(n)
            try {
              def run = fut.get()
              if (run != null && run.getResult() != null &&
                  run.getResult().toString() == 'SUCCESS') {
                new File(fleetDir, n + '.smoke-ok').text =
                  'build #' + run.getNumber() + ' ' + new Date().toString()
                println "fleet: smoke PASS ${n} (build #${run.getNumber()})"
                lastDiag = "PASS ${n} build #${run.getNumber()}"
              } else {
                lastDiag = "smoke ${n} finished result=${run?.getResult()}"
                println "fleet: ${lastDiag}"
              }
            } catch (Exception e) {
              lastDiag = "smoke ${n} future failed: ${e.class.simpleName}: ${e.message}"
              println "fleet: ${lastDiag}"
            }
          }
        }
        // schedule the next pending node (one at a time)
        try {
          def queueBusy = Jenkins.get().getQueue().getItems().any { it.task == capturedJob }
          if (!queueBusy && inFlight.isEmpty() && !capturedJob.isBuilding()) {
            def next = fleetNodes.find { n ->
              if (new File(fleetDir, n + '.smoke-ok').exists()) return false
              def c = Jenkins.get().getComputer(n)
              return c != null && !c.isOffline()
            }
            if (next != null) {
              def fut = capturedJob.scheduleBuild2(0,
                new ParametersAction(new StringParameterValue('NODE_LABEL', next)))
              if (fut != null) {
                inFlight[next] = fut
                lastDiag = "scheduled smoke for ${next}"
                println "fleet: smoke build started for ${next}"
              } else {
                lastDiag = "scheduleBuild2 returned null for ${next} (auth=" +
                  Jenkins.get().getAuthentication().getName() + ')'
              }
            }
          }
        } catch (Exception e) {
          lastDiag = 'schedule attempt threw: ' + e.class.name + ': ' + e.message
          println "fleet: ${lastDiag}"
        }
        writeStatus(lastDiag)
        Thread.sleep(15000)
      }
    } catch (Exception e) {
      println "fleet: verify thread failed: ${e}"
      try { writeStatus('thread failed: ' + e.class.name + ': ' + e.message) } catch (Exception ignored) {}
    }
  }
  def th = new Thread(verifyBody as Runnable, 'fleet-verify')
  th.setDaemon(true)
  th.start()
  println 'fleet: verify thread started'
} else {
  println 'fleet: verify thread not started (fresh marker from a previous boot)'
}
println 'fleet: 06-fleet.groovy done'
