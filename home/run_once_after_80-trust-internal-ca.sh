#!/bin/sh
# Trust the internal SierraSoftworks CA. Ported from nix security.pki.certificates.
# Adds it as a trusted root in the System keychain. Requires sudo once.
set -eu

cert="$HOME/.config/certs/sierrasoftworks-internal.crt"
cn="internal.sierrasoftworks.com"
keychain="/Library/Keychains/System.keychain"

if security find-certificate -c "$cn" "$keychain" >/dev/null 2>&1; then
  echo "==> Internal CA already trusted"
  exit 0
fi

echo "==> Trusting internal CA ($cn) — you'll be prompted for your password"
sudo security add-trusted-cert -d -r trustRoot -k "$keychain" "$cert"
