#!/bin/bash
sudo -u jenkins bash -c 'echo PATH=$PATH; which -a cargo rustc sccache; ls ~/.cargo/bin/ 2>/dev/null; ls ~/.rustup/toolchains/ 2>/dev/null; echo "---"; ls -l /usr/local/bin/cargo /usr/local/cargo/bin 2>/dev/null; true'
ls -l /usr/bin/cargo; dpkg -S /usr/bin/cargo 2>/dev/null || true
