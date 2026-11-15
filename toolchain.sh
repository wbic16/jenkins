#!/bin/bash
set -eu
exec > >(tee -a /home/wbic16/jenkins-install.log) 2>&1
echo "=== toolchain for jenkins user start $(date -Is) ==="
sudo -u jenkins -H rustup toolchain install stable 2>&1 | tail -4
sudo -u jenkins -H rustup default stable 2>&1 | tail -2
sudo -u jenkins -H bash -c 'cargo --version; rustc --version'
echo "=== toolchain done $(date -Is) ==="
