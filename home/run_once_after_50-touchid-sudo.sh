#!/bin/sh
# Enable Touch ID for sudo. Ported from nix security.pam.services.sudo_local.
# Uses /etc/pam.d/sudo_local (survives macOS updates). Requires sudo once.
set -eu

if grep -q "pam_tid.so" /etc/pam.d/sudo_local 2>/dev/null; then
  echo "==> Touch ID for sudo already enabled"
  exit 0
fi

echo "==> Enabling Touch ID for sudo (you'll be prompted for your password)"
printf '# Managed by chezmoi\nauth       sufficient     pam_tid.so\n' \
  | sudo tee /etc/pam.d/sudo_local >/dev/null
