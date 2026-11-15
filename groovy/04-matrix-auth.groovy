import jenkins.model.*
import hudson.security.*
// Runs once matrix-auth plugin is present; upgrades strategy from
// FullControlOnceLoggedIn to per-user matrix (admin only). Guarded:
// if the class is unavailable the existing strategy is left untouched.
try {
    def clazz = Class.forName('hudson.security.ProjectMatrixAuthorizationStrategy')
    def instance = Jenkins.get()
    if (!(instance.getAuthorizationStrategy().getClass().getName().contains('Matrix'))) {
        def props = new Properties()
        new File('/var/lib/jenkins/admin-credentials.txt').withInputStream { props.load(it) }
        String adminUser = props.getProperty('user', 'admin')
        def strategy = clazz.newInstance()
        try {
            def entry = Class.forName('hudson.security.PermissionEntry').user(adminUser)
            strategy.add(Jenkins.ADMINISTER, entry)
        } catch (Throwable t2) {
            strategy.add(Jenkins.ADMINISTER, adminUser)
        }
        instance.setAuthorizationStrategy(strategy)
        instance.save()
        println "matrix-auth: ProjectMatrixAuthorizationStrategy set for ${adminUser}"
    } else {
        println "matrix-auth: matrix strategy already in place"
    }
} catch (ClassNotFoundException e) {
    println "matrix-auth: plugin not present yet, keeping current strategy"
}
