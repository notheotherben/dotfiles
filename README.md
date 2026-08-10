# dotfiles

Personal developer-machine configuration for **macOS** and **CachyOS/Arch**,
built on **chezmoi + mise-en-place** (the successor to my old Nix / nix-darwin /
home-manager setup).

| Concern | macOS | Linux |
| --- | --- | --- |
| GUI apps, system services, most CLIs | Homebrew (`~/.Brewfile`) | pacman / AUR / Flathub |
| Tools with no native package (`git-tool`, `shig`, `tailservice`) | Homebrew (`sierrasoftworks/tap`) | Homebrew (`sierrasoftworks/tap`) |
| Language runtimes | mise (`~/.config/mise/config.toml`) | mise |
| Dotfiles, OS defaults, LaunchAgents, one-off setup | chezmoi (this repo) | chezmoi (this repo) |

On Linux, Homebrew is deliberately limited to the Sierra Softworks tap —
anything that pacman, the AUR, or Flathub provides is installed from there
instead. See [home/run_onchange_after_15-arch-packages.sh.tmpl](home/run_onchange_after_15-arch-packages.sh.tmpl).

## Bootstrap a fresh machine

```bash
# 1. Install chezmoi and apply this repo in one shot.
#    (chezmoi pulls the repo, then its run_ scripts install Homebrew, run
#     `brew bundle`, `mise install`, set macOS defaults, etc.)
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply notheotherben/dotfiles

# 2. Open a new shell (fish is now the default login shell).
```

On Apple Silicon Homebrew lives at `/opt/homebrew`; on Linux at
`/home/linuxbrew/.linuxbrew`. The scripts assume those prefixes.

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
  .chezmoiignore             macOS-only targets are skipped on Linux
  dot_Brewfile.tmpl          -> ~/.Brewfile          (Homebrew manifest)
  dot_gitconfig              -> ~/.gitconfig
  dot_zshrc                  -> ~/.zshrc
  dot_config/
    fish/config.fish         -> ~/.config/fish/config.fish
    ghostty/config           -> ~/.config/ghostty/config
    hypr/config/…            -> ~/.config/hypr/config/…       (Linux)
    starship.toml            -> ~/.config/starship.toml
    mise/config.toml         -> ~/.config/mise/config.toml
    Yubico/u2f_keys          -> ~/.config/Yubico/u2f_keys  (from 1Password, Linux)
    certs/…                  -> internal CA bundle
  Library/LaunchAgents/…     -> ~/Library/LaunchAgents/dev.pannell.rustic-backup.plist
  run_once_before_10-install-homebrew.sh   bootstrap Homebrew
  run_onchange_after_15-arch-packages.sh   pacman / AUR / flatpak   (Linux)
  run_onchange_after_20-brew-bundle.sh     brew bundle --global
  run_onchange_after_30-mise-install.sh    mise install
  run_onchange_after_40-macos-defaults.sh  Finder / global defaults (macOS)
  run_onchange_after_45-pam-u2f.sh         Yubikey for sudo/su/polkit (Linux)
  run_once_after_50-touchid-sudo.sh        Touch ID for sudo        (macOS)
  run_once_after_60-default-shell.sh       chsh to fish
  run_onchange_after_70-rustic-launchagent.sh  (re)load backup agent (macOS)
  run_once_after_80-trust-internal-ca.sh   trust internal CA
```

`run_once_*` scripts execute a single time (keyed by content); `run_onchange_*`
re-run whenever the thing they manage changes.

## Notes / manual steps

- **1Password** is installed manually (latest beta) so `op` and `op-ssh-sign`
  (git commit signing) are available. Brewfile entries are commented out.
  On Linux the `1password` / `1password-cli` AUR packages provide both.
- **rustic backup** expects its config at `~/.config/rustic`; the LaunchAgent
  runs `rustic backup` hourly. Create that config separately. macOS only —
  the config and LaunchAgent are ignored on Linux.
- The Touch ID, default-shell, and CA-trust scripts call `sudo` and will prompt
  for your password on first apply. On Linux the pacman/AUR/flatpak script does
  too.
- No Linux equivalent is installed for `little-snitch`; `orbstack` is replaced
  by a native `docker` install.
- **Yubikey / pam_u2f** (Linux) is the counterpart to Touch ID: it adds a
  `sufficient` rule to `/etc/pam.d/{sudo,su,su-l,polkit-1}`. Login/SDDM are
  deliberately excluded because systemd-homed needs the password to unlock the
  home area. The credential mapping comes from the `u2f_keys` field on the
  "CachyOS" 1Password item; re-register with `pamu2fcfg -o pam://$(hostname)
  -i pam://$(hostname)` and update that field.

## What changed from Nix

- `environment.systemPackages` → split between `~/.Brewfile` and mise.
- `environment.variables` / `fish_add_path` / `home.sessionPath` → mise `[env]`.
- `programs.{git,starship,fish,zsh}` → dotfiles under `home/`.
- `system.defaults` / `security.pam` / `security.pki` → `run_*` scripts.
- `launchd.agents.rustic-backup` → managed LaunchAgent plist + reload script.
- `git-tool` flake input → mise `ubi:SierraSoftworks/git-tool`.
