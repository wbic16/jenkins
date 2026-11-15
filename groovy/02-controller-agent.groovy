import jenkins.model.*
import hudson.model.*
def j = Jenkins.get()
j.setNumExecutors(4)
try { j.setLabelString('controller local ranch') } catch (Throwable t) { println "labels: ${t}" }
j.setMode(Node.Mode.NORMAL)
j.save()
println "controller agent: executors=${j.getNumExecutors()} labels=${j.getLabelString()}"
