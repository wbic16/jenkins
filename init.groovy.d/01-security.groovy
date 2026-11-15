import jenkins.model.*
import hudson.security.*
import hudson.model.User

def credFile = new File('/var/lib/jenkins/admin-credentials.txt')
def props = new Properties()
credFile.withInputStream { props.load(it) }
String adminUser = props.getProperty('user', 'admin')
String adminPass = props.getProperty('password')

def instance = Jenkins.get()
def realm = new HudsonPrivateSecurityRealm(false)
instance.setSecurityRealm(realm)

def existing = User.getById(adminUser, false)
if (existing == null) {
    realm.createAccount(adminUser, adminPass)
    println "security: created admin account ${adminUser}"
} else {
    try {
        existing.addProperty(HudsonPrivateSecurityRealm.Details.fromPlainPassword(adminPass))
    } catch (Throwable t) {
        existing.addProperty(new HudsonPrivateSecurityRealm.Details(adminPass))
    }
    existing.save()
    println "security: reset password for existing admin account ${adminUser} from credential file"
}
def currentName = instance.getAuthorizationStrategy().getClass().getName()
if (!currentName.contains('FullControlOnceLoggedIn') && !currentName.contains('Matrix')) {
    def fc = new FullControlOnceLoggedInAuthorizationStrategy()
    fc.setAllowAnonymousRead(false)
    instance.setAuthorizationStrategy(fc)
    println "security: FullControlOnceLoggedIn set (was ${currentName}), anonymous read disabled"
} else {
    println "security: authorization strategy kept: ${currentName}"
}
try {
    def InstallState = Class.forName('jenkins.install.InstallState')
    instance.setInstallState(InstallState.valueOf('INITIAL_SETUP_COMPLETED'))
} catch (Throwable t) { println "installstate skip: ${t}" }
instance.save()
println "security init done"
