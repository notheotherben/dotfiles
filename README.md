# dotfiles

Personal developer-machine configuration for **macOS** and **CachyOS/Arch**,
built on **chezmoi + mise-en-place** (the successor to my old Nix / nix-darwin /
home-manager setup).

| Concern | macOS | Linux |
| --- | --- | --- |
| GUI apps, system services, most CLIs | Homebrew (`~/.Brewfile`) | pacman / AUR / Flathub |
| Tools with no native package (`git-tool`, `shig`, `tailservice`) | Homebrew (`sierrasoftworks/tap`) | mise (`conf.d/linux.toml`) |
| Language runtimes | mise (`~/.config/mise/config.toml`) | mise |
| Scheduled backups | launchd (LaunchAgent) | systemd user timer |
| Dotfiles, OS defaults, one-off setup | chezmoi (this repo) | chezmoi (this repo) |

Native packages win wherever they exist. Homebrew is macOS-only: on Linux
everything comes from pacman, the AUR, or Flathub — see
[home/run_onchange_after_15-arch-packages.sh.tmpl](home/run_onchange_after_15-arch-packages.sh.tmpl).
The Sierra Softworks tools are the one exception, with no distro package at all,
so mise pulls the same GitHub release binaries the tap would.

## Bootstrap a fresh machine

```bash
# 1. Install chezmoi and apply this repo in one shot.
#    (chezmoi pulls the repo, then its run_ scripts install the package manager,
#     sync packages, run `mise install`, set OS defaults, etc.)
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply notheotherben/dotfiles

# 2. Open a new shell (fish is now the default login shell).
```

On Apple Silicon Homebrew lives at `/opt/homebrew`; the scripts assume that
prefix. On Linux the package script installs `paru` if no AUR helper is present
(CachyOS already ships one).

## Day-to-day

```bash
chezmoi edit ~/.Brewfile     # macOS packages
chezmoi edit --source home/run_onchange_after_15-arch-packages.sh.tmpl  # Linux packages
chezmoi apply                # re-runs the package sync / mise install on change
chezmoi update               # git pull + apply

brew bundle --global         # macOS: install/upgrade packages manually
mise install                 # install/upgrade mise tools manually
```

## How the platform split works

Every `run_` script is a chezmoi template whose body is wrapped in an
`{{ if eq .chezmoi.os "…" }}` guard, falling through to `exit 0` on the other
platform. Files that only exist on one platform (the Brewfile, the LaunchAgent,
the systemd units, the Linux-only mise config) are filtered by
`home/.chezmoiignore`.

## Layout

```
.chezmoiroot                 -> "home" (chezmoi source root is home/)
home/
  .chezmoiignore             per-OS file filtering
  dot_Brewfile               -> ~/.Brewfile          (Homebrew manifest, macOS)
  dot_zshrc                  -> ~/.zshrc
  dot_config/
    autostart/….desktop      -> ~/.config/autostart/…         (XDG autostart, Linux)
    fish/config.fish.tmpl    -> ~/.config/fish/config.fish
    ghostty/config           -> ~/.config/ghostty/config
    git/config.tmpl          -> ~/.config/git/config         (per-OS op-ssh-sign)
    hypr/config/…            -> ~/.config/hypr/config/…       (Linux)
    starship.toml            -> ~/.config/starship.toml
    mise/config.toml         -> ~/.config/mise/config.toml
    mise/conf.d/linux.toml   -> extra mise tools              (Linux only)
    rustic/rustic.toml.tmpl  -> ~/.config/rustic/rustic.toml (per-OS repo path)
    systemd/user/…           -> rustic-backup .service/.timer (Linux only)
    Yubico/u2f_keys          -> ~/.config/Yubico/u2f_keys  (from 1Password, Linux)
    certs/…                  -> internal CA bundle
  private_dot_ssh/private_config.tmpl -> ~/.ssh/config        (per-OS 1Password agent socket)
  Library/LaunchAgents/…     -> rustic-backup plist           (macOS only)
  run_once_before_10-install-homebrew.sh   bootstrap Homebrew       (macOS)
  run_onchange_after_15-arch-packages.sh   pacman / AUR / flatpak   (Linux)
  run_onchange_after_20-brew-bundle.sh     brew bundle --global     (macOS)
  run_onchange_after_25-hyprpm-plugins.sh  Hyprland plugins         (Linux)
  run_onchange_after_30-mise-install.sh    mise install
  run_onchange_after_40-macos-defaults.sh  Finder / global defaults (macOS)
  run_onchange_after_45-pam-u2f.sh         Yubikey for sudo/su/polkit (Linux)
  run_onchange_after_47-greetd.sh          noctalia-greeter login screen (Linux)
  run_once_after_50-touchid-sudo.sh        Touch ID for sudo        (macOS)
  run_once_after_60-default-shell.sh       chsh to fish
  run_onchange_after_70-rustic-schedule.sh (re)load LaunchAgent / systemd timer
  run_once_after_80-trust-internal-ca.sh   trust internal CA
```

`run_once_*` scripts execute a single time (keyed by content); `run_onchange_*`
re-run whenever the thing they manage changes.

## Notes / manual steps

- **1Password** provides the SSH agent and `op-ssh-sign` for commit signing.
  The agent socket and signer binary live in different places on each platform,
  so `~/.ssh/config` and `~/.config/git/config` are templated accordingly. The
  stable release supports both, so no beta channel is needed.
- **rustic backup** runs hourly and expects its config at `~/.config/rustic`.
  On macOS the pre-backup hook mounts the SMB share via `osascript` under
  `/Volumes`; on Linux the repository is `/backup`, mounted at boot from
  `/etc/fstab`, and the systemd unit declares `RequiresMountsFor=/backup`.
- The Touch ID, default-shell, and CA-trust scripts call `sudo` and will prompt
  for your password on first apply. On Linux the pacman/AUR/flatpak script does
  too.
- No Linux equivalent is installed for `little-snitch` (`opensnitch` in `extra`
  is the closest); `orbstack` is replaced by a native `docker` install, and
  WhatsApp has no official Linux client so Flathub's ZapZap stands in.
- **Yubikey / pam_u2f** (Linux) is the counterpart to Touch ID: it adds a
  `sufficient` rule to `/etc/pam.d/{sudo,su,su-l,polkit-1}`. The login screen is
  deliberately excluded because systemd-homed needs the password to unlock the
  home area. The credential mapping comes from the `u2f_keys` field on the
  "CachyOS" 1Password item; re-register with `pamu2fcfg -o pam://$(hostname)
  -i pam://$(hostname)` and update that field.
- **Login screen** is `noctalia-greeter` on greetd, not SDDM. The greetd script
  writes `/etc/greetd/config.toml` and the greeter's declarative
  `/var/lib/noctalia-greeter/greeter.toml`, then flips
  `display-manager.service` from `sddm` to `greetd`. SDDM stays installed as a
  fallback — `systemctl disable greetd && systemctl enable sddm` reverts it.
  Two things are worth knowing:
  - **systemd-homed.** greetd authenticates through `/etc/pam.d/greetd`, which
    reaches `pam_systemd_home` via `system-local-login` → `system-auth`. Before
    switching display managers the script walks that whole `include` chain and
    refuses to proceed if `pam_u2f` has crept into it or `pam_systemd_home` has
    dropped out, because either one locks you out of `$HOME` at the next boot.
    `[auth] allow_empty_password` is on so that submitting an empty password
    hands the conversation back to PAM, which is how the enrolled FIDO2 token
    (`homectl inspect` → *FIDO2 Token*) can unlock the home area instead of the
    passphrase.
  - **Idle blanking** is set to 60s in `greeter.toml`. The greeter never blanks
    by default, and a login screen left sitting on an OLED panel is exactly the
    burn-in case worth avoiding. The logged-in session keeps noctalia's own
    defaults (screen off at 180s, lock at 600s), which live in the shell's
    settings rather than here.
  Theming is *not* managed: `noctalia msg greeter-sync` pushes the wallpaper,
  palette, and monitor layout into the sibling `sync.toml`, and keys in
  `greeter.toml` win over it, so the two never collide. No `[cursor]` block is
  set either, because Bibata only exists under `~/.local/share/icons` — inside
  the encrypted home the greeter is there to unlock.
- **Hyprland** is loaded by `~/.config/hypr/hyprland.lua`, which ships with
  CachyOS and is *not* managed here. The files under `hypr/config/` are forks of
  the CachyOS defaults, so upstream changes to those specific files no longer
  reach this machine. The unforked ones (`animations`, `autostart`, `colors`,
  `environment`, `inputs`) are still owned by CachyOS.
  Autostart uses XDG `.desktop` entries rather than `autostart.lua` because the
  session runs under UWSM. The `hyprbars` title bars come from the hyprpm
  plugin script, which has to run inside a live session and rebuilds the
  plugin whenever Hyprland is updated.

## What changed from Nix

- `environment.systemPackages` → split between `~/.Brewfile` and mise.
- `environment.variables` / `fish_add_path` / `home.sessionPath` → mise `[env]`.
- `programs.{git,starship,fish,zsh}` → dotfiles under `home/`.
- `system.defaults` / `security.pam` / `security.pki` → `run_*` scripts.
- `launchd.agents.rustic-backup` → managed LaunchAgent plist + reload script.
- `git-tool` flake input → mise `github:SierraSoftworks/git-tool`.
