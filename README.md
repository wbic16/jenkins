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
