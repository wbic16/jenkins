#!/bin/bash
echo "== public repo test =="
timeout 20 git ls-remote https://github.com/wbic16/phext-lattice.git refs/heads/exo 2>&1 | head -3
echo "== mounts mirrorborn =="
mount | grep -i mirrorborn || ls /mnt/mirrorborn/shared/ 2>/dev/null || echo "no mirrorborn mount visible"
ls -ld /mnt/mirrorborn/shared/sccache 2>/dev/null || echo "no shared sccache dir"
echo "== wbic16 sccache config =="
ls ~/.cache/sccache 2>/dev/null | head; sccache --show-stats 2>&1 | head -8
echo "== network jenkins pkg =="
timeout 15 curl -fsSI https://pkg.jenkins.io/debian-stable/ 2>&1 | head -3
echo "== apt jdk candidates =="
apt-cache policy openjdk-21-jre-headless openjdk-17-jre-headless 2>/dev/null | grep -A1 '^openjdk'
