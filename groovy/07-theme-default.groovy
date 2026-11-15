import jenkins.model.Jenkins
import hudson.ExtensionList

// 07-theme-default.groovy — set the instance default theme to Dark Theme
// (theme-manager's ThemeManagerPageDecorator.theme), leaving per-user
// selection enabled (disableUserThemes stays false). Idempotent.

def resultFile = new File('/var/lib/jenkins/theme-set-result.txt')
def sb = new StringBuilder()
def log = { Object s -> sb << s.toString() << '\n' }
try {
  def decorator = ExtensionList.lookup(hudson.model.PageDecorator.class).find {
    it.class.name == 'io.jenkins.plugins.thememanager.ThemeManagerPageDecorator'
  }
  if (decorator == null) {
    log('FAIL: ThemeManagerPageDecorator not found')
  } else {
    log('decorator found; current theme field = ' + decorator.theme)
    // Resolve the dark factory: extension list first, direct instantiation as fallback
    def darkFactory = null
    try {
      def factories = ExtensionList.lookup(io.jenkins.plugins.thememanager.ThemeManagerFactory.class)
      log('factories via ExtensionList.lookup: ' + factories.collect { it.class.name })
      darkFactory = factories.find { it.class.name == 'io.jenkins.plugins.darktheme.DarkThemeManagerFactory' }
    } catch (Throwable t) {
      log('factory lookup failed: ' + t)
    }
    if (darkFactory == null) {
      try {
        def cls = Class.forName('io.jenkins.plugins.darktheme.DarkThemeManagerFactory')
        darkFactory = cls.getDeclaredConstructor().newInstance()
        log('dark factory instantiated directly: ' + darkFactory.class.name)
      } catch (Throwable t) {
        log('direct instantiation failed: ' + t)
      }
    }
    if (darkFactory == null) {
      log('FAIL: could not obtain DarkThemeManagerFactory')
    } else {
      try { log('dark factory descriptor themeKey=' + darkFactory.getDescriptor().getThemeKey() + ' displayName=' + darkFactory.getDescriptor().getDisplayName()) } catch (Throwable t) { log('descriptor probe: ' + t.message) }
      if (decorator.theme != null && decorator.theme.class.name == 'io.jenkins.plugins.darktheme.DarkThemeManagerFactory') {
        log('theme already set to dark; nothing to do')
      } else {
        try {
          decorator.setTheme(darkFactory)
          log('setTheme() used')
        } catch (Throwable t) {
          log('setTheme failed (' + t.message + '); setting field reflectively')
          def f = decorator.class.getDeclaredField('theme')
          f.setAccessible(true)
          f.set(decorator, darkFactory)
        }
        try { decorator.save() } catch (Throwable t) { log('decorator.save(): ' + t.message) }
        Jenkins.get().save()
        log('theme set; decorator.theme now = ' + decorator.theme?.class?.name)
      }
      try { log('findThemeFactory() -> ' + decorator.findThemeFactory()?.class?.name) } catch (Throwable t) { log('findThemeFactory probe: ' + t.message) }
      try { log('themeKey -> ' + decorator.getThemeKey()) } catch (Throwable t) { log('getThemeKey probe: ' + t.message) }
    }
  }
} catch (Throwable t) {
  log('TOPLEVEL FAILURE: ' + t)
}
resultFile.text = sb.toString()
println 'theme-default: ' + sb.toString().replace('\n', ' | ')
