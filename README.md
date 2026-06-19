# dotfiles

Personal macOS developer-machine configuration, built on **Homebrew + chezmoi +
mise-en-place** (the successor to my old Nix / nix-darwin / home-manager setup).

| Concern | Tool |
| --- | --- |
| GUI apps, system services, most CLIs | Homebrew (`~/.Brewfile`) |
| Language runtimes + `git-tool` | mise (`~/.config/mise/config.toml`) |
| Dotfiles, macOS defaults, LaunchAgents, one-off setup | chezmoi (this repo) |

## Bootstrap a fresh machine

```bash
# 1. Install chezmoi and apply this repo in one shot.
#    (chezmoi pulls the repo, then its run_ scripts install Homebrew, run
#     `brew bundle`, `mise install`, set macOS defaults, etc.)
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply notheotherben/dotfiles

# 2. Open a new shell (fish is now the default login shell).
```

On Apple Silicon Homebrew lives at `/opt/homebrew`; the scripts assume that prefix.

## Day-to-day

```bash
chezmoi edit ~/.Brewfile     # change packages, then:
chezmoi apply                # re-runs brew bundle / mise install on change

brew bundle --global         # install/upgrade Homebrew packages manually
mise install                 # install/upgrade mise tools manually
chezmoi update               # git pull + apply
```

## Layout

```
.chezmoiroot                 -> "home" (chezmoi source root is home/)
home/
  dot_Brewfile               -> ~/.Brewfile          (Homebrew manifest)
  dot_gitconfig              -> ~/.gitconfig
  dot_zshrc                  -> ~/.zshrc
  dot_config/
    fish/config.fish         -> ~/.config/fish/config.fish
    starship.toml            -> ~/.config/starship.toml
    mise/config.toml         -> ~/.config/mise/config.toml
    certs/…                  -> internal CA bundle
  Library/LaunchAgents/…     -> ~/Library/LaunchAgents/dev.pannell.rustic-backup.plist
  run_once_before_10-install-homebrew.sh   bootstrap Homebrew
  run_onchange_after_20-brew-bundle.sh     brew bundle --global
  run_onchange_after_30-mise-install.sh    mise install
  run_onchange_after_40-macos-defaults.sh  Finder / global defaults
  run_once_after_50-touchid-sudo.sh        Touch ID for sudo
  run_once_after_60-default-shell.sh       chsh to fish
  run_onchange_after_70-rustic-launchagent.sh  (re)load backup agent
  run_once_after_80-trust-internal-ca.sh   trust internal CA
```

`run_once_*` scripts execute a single time (keyed by content); `run_onchange_*`
re-run whenever the thing they manage changes.

## Notes / manual steps

- **1Password** is installed manually (latest beta) so `op` and `op-ssh-sign`
  (git commit signing) are available. Brewfile entries are commented out.
- **rustic backup** expects its config at `~/.config/rustic`; the LaunchAgent
  runs `rustic backup` hourly. Create that config separately.
- The Touch ID, default-shell, and CA-trust scripts call `sudo` and will prompt
  for your password on first apply.

## What changed from Nix

- `environment.systemPackages` → split between `~/.Brewfile` and mise.
- `environment.variables` / `fish_add_path` / `home.sessionPath` → mise `[env]`.
- `programs.{git,starship,fish,zsh}` → dotfiles under `home/`.
- `system.defaults` / `security.pam` / `security.pki` → `run_*` scripts.
- `launchd.agents.rustic-backup` → managed LaunchAgent plist + reload script.
- `git-tool` flake input → mise `ubi:SierraSoftworks/git-tool`.
