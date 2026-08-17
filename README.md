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
    hypr/hyprlock.conf       -> ~/.config/hypr/hyprlock.conf  (Linux)
    hypr/hypridle.conf       -> ~/.config/hypr/hypridle.conf  (Linux)
    noctalia/config.toml     -> ~/.config/noctalia/config.toml (Linux)
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
  run_onchange_after_45-pam-u2f.sh         Yubikey for sudo/su/polkit/hyprlock (Linux)
  run_onchange_after_46-faillock.sh        pam_faillock thresholds    (Linux)
  run_onchange_after_47-greetd.sh          ReGreet login screen       (Linux)
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
  `sufficient` rule to `/etc/pam.d/{sudo,su,su-l,polkit-1}` and writes a
  dedicated `/etc/pam.d/hyprlock`. The login screen is deliberately excluded
  because systemd-homed needs the password to unlock the home area; hyprlock is
  the exception, since `$HOME` is already unlocked while the screen is locked.
  The credential mapping comes from the `u2f_keys` field on the "CachyOS"
  1Password item; re-register with `pamu2fcfg -o pam://$(hostname)
  -i pam://$(hostname)` and update that field.
- **Why the lock screen and greeter are what they are.** This account is
  systemd-homed with a FIDO2 token, so authenticating is a *multi-prompt* PAM
  conversation: the account password, then `Security token PIN:`, then `Sorry,
  retry security token PIN:` if that one was wrong. Any UI that buffers a single
  string and replays it at every prompt therefore hands the Yubikey three wrong
  PINs in about a second — the CTAP2 consecutive-failure limit — which blocks
  the token until it is physically reinserted and burns three of its eight
  lifetime retries. noctalia's built-in lock screen does exactly that; it cost a
  real lockout, so both halves were replaced with implementations that re-prompt:
  - **hyprlock** waits for fresh input whenever the prompt text changes
    (`initialPrompt || PROMPTCHANGED` in its PAM conversation), so a typo costs
    one retry. `[lockscreen] enabled = false` in noctalia's config turns the old
    one off.
  - **ReGreet** loops over greetd's `auth_message` responses, clearing the field
    each time. `hyprlogin` was evaluated and rejected: it handles exactly one
    auth message per session and cancels on the second, so it cannot complete a
    homed login at all — and it writes the submitted secret to
    `/tmp/hyprlogin-debug.log` when `general:debug_mode` is on.
  Both configs surface the live PAM prompt (`$PAMPROMPT` in hyprlock), because
  knowing whether PAM currently wants the password or the PIN is the difference
  between one wrong attempt and a blocked key. hyprlock is worth a warning here:
  it *discards* `PAM_ERROR_MSG`, so systemd's "Security token PIN incorrect for
  user …" is only logged and never drawn, and `fail_text`/`$PAMFAIL` only fire
  once `pam_authenticate` returns rather than on a mid-conversation retry. The
  prompt flipping to "Sorry, retry security token PIN:" is the only in-band
  signal, which is why it gets its own label above the field instead of sitting
  greyed out as placeholder text.
  If the token does get blocked, recover with the **account password** or the
  **recovery key** (`homectl inspect` lists both) rather than hot-plugging the
  Yubikey, then power-cycle the key at a calmer moment. The 46-faillock script
  exists so PAM does not lock the account for ten minutes while you do that.
- **Idle and locking** are owned by `hypridle`, autostarted from
  `~/.config/autostart/hypridle.desktop`, with every noctalia idle behaviour
  disabled so the two do not arm competing timers. Everything routes through
  `loginctl lock-session` — the idle timeout, `Super+L`, the session panel
  button, and logind's own Lock signal all end up running hyprlock once.
  Worth knowing when editing either config: noctalia strips the built-in `lock`
  and `lock_and_suspend` actions from the panel, the launcher, and its session
  IPC whenever `[lockscreen] enabled = false`, *before* it reads any `command`
  override. So the panel's lock button is an `action = "command"` entry, and
  `Super+L` calls `loginctl` directly rather than `noctalia msg session lock`,
  which would just answer `error: lock screen disabled`.
- **noctalia's `config.toml` is managed here**, which is unusual for this repo:
  the lock screen and idle sections have to stay switched off for the above to
  hold. Changes made in noctalia's own settings UI land in the same file, so
  `chezmoi diff` after tweaking something in the GUI is worth a look before
  `chezmoi apply` reverts it.
- **Login screen** is ReGreet on greetd inside `cage`, not SDDM. The greetd
  script writes `/etc/greetd/config.toml` and `/etc/greetd/regreet.toml`, then
  flips `display-manager.service` from `sddm` to `greetd`. SDDM stays installed
  as a fallback — `systemctl disable greetd && systemctl enable sddm` reverts
  it. `cage -s` keeps VT switching available, which is the escape hatch if the
  greeter ever wedges. Two things are worth knowing:
  - **systemd-homed.** greetd authenticates through `/etc/pam.d/greetd`, which
    reaches `pam_systemd_home` via `system-local-login` → `system-auth`. Before
    switching display managers the script walks that whole `include` chain and
    refuses to proceed if `pam_u2f` has crept into it or `pam_systemd_home` has
    dropped out, because either one locks you out of `$HOME` at the next boot.
    Submitting an empty password at the first prompt hands the conversation back
    to PAM, which is how the enrolled FIDO2 token (`homectl inspect` → *FIDO2
    Token*) gets asked for instead of the passphrase.
  - **Session cache.** `skip_selection` is on, so the greeter opens straight on
    the password prompt for whoever logged in last. That choice is cached under
    `/var/cache/regreet`, which the script creates for the `greeter` user; the
    first boot after a wipe still shows the picker, and the user/session
    dropdowns come back on any authentication failure.
  Theming is minimal on purpose. ReGreet is a GTK app and cannot be driven by
  `noctalia msg greeter-sync`, so `[shell.greeter_sync] auto_sync` is off and
  the greeter just uses a dark Adwaita. No custom cursor either, because Bibata
  only exists under `~/.local/share/icons` — inside the encrypted home the
  greeter is there to unlock.
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
