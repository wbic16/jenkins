def loc = jenkins.model.JenkinsLocationConfiguration.get()
loc.setUrl('http://100.88.154.1:8080/')
loc.save()
println "jenkins url set to ${loc.getUrl()}"
