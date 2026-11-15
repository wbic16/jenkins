import jenkins.model.*
import hudson.model.*
import hudson.slaves.*
def name = 'rock-mountain'
if (Jenkins.get().getNode(name) == null) {
  def launcher = new JNLPLauncher()
  try { launcher.setWebSocket(true); println "websocket enabled on launcher" } catch (Throwable t) { println "ws setter failed: ${t.getMessage()}" }
  def node = new DumbSlave(name, '/home/wbic16/jenkins-agent/work', launcher)
  node.setNumExecutors(2)
  node.setLabelString('ranch rock-mountain')
  node.setMode(Node.Mode.NORMAL)
  node.setRetentionStrategy(new RetentionStrategy.Always())
  Jenkins.get().addNode(node)
  Jenkins.get().save()
  println "node created: ${name}"
} else {
  println "node already exists: ${name}"
}
def mac = Jenkins.get().getComputer(name).getJnlpMac()
new File('/var/lib/jenkins/rock-mountain-agent-secret.txt').text = mac
println "secret written to file (${mac.length()} chars, value not printed)"
