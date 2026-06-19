#!/bin/sh
# Make fish the default login shell. Ported from nix users.users.<name>.shell.
# Requires sudo to register fish in /etc/shells.
set -eu

fish_path="/opt/homebrew/bin/fish"

if [ ! -x "$fish_path" ]; then
  echo "!! fish not found at $fish_path — skipping (brew bundle should install it)"
  exit 0
fi

if ! grep -qx "$fish_path" /etc/shells; then
  echo "==> Registering $fish_path in /etc/shells"
  echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
fi

if [ "${SHELL:-}" != "$fish_path" ]; then
  echo "==> Setting default shell to fish"
  chsh -s "$fish_path"
fi
