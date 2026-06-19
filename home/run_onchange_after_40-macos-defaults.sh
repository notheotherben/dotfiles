#!/bin/sh
# macOS system defaults. Ported from the old nix system.defaults.finder.* block.
# Re-runs whenever this script changes.
set -eu

echo "==> Applying macOS defaults"

# Finder: show all file extensions (NSGlobalDomain)
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Finder: show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
# Finder: don't render icons on the Desktop
defaults write com.apple.finder CreateDesktop -bool false
# Finder: no warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

killall Finder 2>/dev/null || true
