# dotfiles

Machine configuration for a macOS laptop and a CachyOS/Arch desktop, applied
with [chezmoi](https://chezmoi.io) and [mise](https://mise.jdx.dev).

## Before you start

- **macOS on Apple Silicon** (the scripts assume `/opt/homebrew`) or
  **CachyOS/Arch** with a Hyprland session.
- **1Password**, installed and signed in, with CLI integration and biometric
  unlock enabled. Several templates call `op` at apply time to pull backup
  credentials and Yubikey handles; `chezmoi apply` fails outright without it.
- **A password.** Touch ID, the internal CA, `chsh`, and every PAM change prompt
  for `sudo` on the first apply.
- **Optional, but most of the interesting Linux behaviour assumes it:** a FIDO2
  Yubikey on an account managed by systemd-homed.

## Bootstrap a machine

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply notheotherben/dotfiles
```

chezmoi clones the repo, then its `run_` scripts install the package manager,
sync packages, run `mise install`, and make the OS-level changes. Open a new
shell afterwards — fish is now the login shell. On Linux, reboot to land on the
new greeter.

## Day to day

```bash
chezmoi edit ~/.Brewfile                # macOS packages
chezmoi edit --source home/run_onchange_after_15-arch-packages.sh.tmpl  # Linux packages
chezmoi apply                           # re-runs whatever changed
chezmoi update                          # git pull + apply
chezmoi diff                            # before applying over something a GUI edited

brew bundle --global                    # macOS packages, by hand
mise install                            # mise tools, by hand
```

`run_once_*` scripts execute a single time, keyed by content. `run_onchange_*`
re-run whenever the thing they manage changes — the package manifests, the mise
config, the backup units.

## What it sets up

### Everywhere

- **fish** as the login shell, with **starship** for the prompt and **atuin**
  for history, synced to a self-hosted server over Tailscale.
- **git** signing commits with SSH through 1Password's `op-ssh-sign`, and the
  1Password agent behind `~/.ssh/config`.
- **git-tool** owning `~/dev`, `~/scratch`, and `~/worktrees`.
- **mise** for Go, Node, Deno, the HashiCorp CLIs, and `PATH`/env
  (`VAULT_ADDR`, `NOMAD_ADDR`, `GITTOOL_CONFIG`). Rust and .NET come from the
  native package manager instead — mise's plugins for both are
  community-maintained and less reliable than brew or pacman.
- **Hourly [rustic](https://rustic.cli.rs) backups** of `$HOME` to an SMB share,
  with OpenTelemetry metrics and check-ins to a cron monitor so a silently dead
  backup gets noticed. Retention is 7 daily / 5 monthly / 2 yearly.
- **A Monokai Pro Spectrum palette** across Ghostty, starship, and hyprlock, so
  a terminal looks the same on either machine. `Ctrl+Shift+C`/`V` for the
  clipboard, because `Ctrl+C` belongs to the shell.
- **An internal CA**, trusted in the System keychain or the p11-kit anchor
  store.

### macOS

- **Touch ID for `sudo`**, via `/etc/pam.d/sudo_local` so it survives OS
  updates.
- **Homebrew** as the package manager, driven by `~/.Brewfile`.
- **Finder defaults**: all extensions, hidden files, no desktop icons, no
  extension-change warning.
- Backups run from a **LaunchAgent** that mounts the SMB share with `osascript`
  before each run.

### CachyOS / Arch

- **A Windows Hello-style PIN.** `pam_u2f` sits `sufficient` in front of `sudo`,
  `su`, polkit, and hyprlock, so those prompts take the Yubikey's PIN instead of
  the account password. Deliberately *not* wired into greetd or `login`: on
  systemd-homed the password typed at boot is what unlocks the encrypted home
  area, and a `sufficient` Yubikey rule there would satisfy PAM while leaving
  `$HOME` locked. The greetd script re-checks that invariant and refuses to
  switch display managers if it has been broken.
- **hyprlock and ReGreet** in place of noctalia's locker and SDDM. The reasoning
  is below; it is the one choice here that is genuinely load-bearing.
- **hypridle** owning idle behaviour: screen off at 60s, lock at 10 minutes,
  everything routed through `loginctl lock-session` so the idle timer, `Super+L`,
  the session panel, and logind's own Lock signal all end up in one place.
- **Hyprland**, forked from the CachyOS defaults: HDR on the primary monitor
  with the full colour-management protocol enabled, per-monitor workspaces, a
  gaming workspace that catches `steam_app*` windows and inhibits idle, and a
  communication scratchpad on `Super+,` that tiles Signal, Telegram, WhatsApp,
  and Fastmail into an even grid.
- **noctalia** as the bar and shell, with its lock screen and idle timers
  switched off.
- **Backups** on a systemd user timer with `Persistent=true`, and lingering
  explicitly *disabled* — on systemd-homed, starting `user@.service` at boot
  makes PAM demand the token PIN before any greeter exists, and Plymouth eats
  the prompt.
- **pam_faillock** loosened to 10 failures / 60 seconds, for the reason in the
  next section.
- **Host telemetry**: a native `otelcol-contrib` service ships journald logs
  and host metrics to `telemetry.sierrasoftworks.com`, and the OTel eBPF
  profiler (a privileged Docker container, as on the cluster nodes) adds
  whole-host continuous profiling. `OTEL_EXPORTER_OTLP_*` is set session-wide
  (`environment.d` + mise) so instrumented apps default to the same endpoint.
  Configs live in `home/dot_config/otelcol/`; the install is
  `run_onchange_after_49-otelcol`.

## Make it yours

This is one person's configuration rather than a framework, and a fair amount of
it is bound to specific accounts, hosts, and hardware. Fork it and work through
this list before applying it to anything that matters.

| What | Where | Notes |
| --- | --- | --- |
| Git identity and signing key | `home/dot_config/git/config.tmpl` | Name, email, and the SSH public key 1Password signs with. The `op-ssh-sign` paths are already templated per-OS. |
| 1Password item IDs | `home/dot_config/rustic/private_rustic.toml.tmpl`, `home/dot_config/Yubico/private_u2f_keys.tmpl` | Both hard-code an item UUID. The backup item needs `server`, `volume`, `encryption`, `domain`, `telemetry`, and `cron_token` fields plus a username; the Yubikey item needs a `u2f_keys` field. Templates fail loudly when a field is missing, which is the right failure. |
| Service endpoints | `home/dot_config/mise/config.toml`, `home/dot_config/atuin/config.toml`, `home/private_dot_ssh/private_config.tmpl` | `VAULT_ADDR`, `NOMAD_ADDR`, the atuin sync server, and the `nas` host all point at a private tailnet. |
| Backup target and monitoring | `home/dot_config/rustic/private_rustic.toml.tmpl` | The status check-in URL, the SMB share, and — on Linux — the `/backup` mount that `rustic-backup.service` declares in `RequiresMountsFor`. That mount comes from `/etc/fstab` and is *not* managed here. |
| Internal CA | `home/dot_config/certs/`, `run_once_after_80-trust-internal-ca.sh.tmpl` | Swap the certificate and the CN the script checks for, or drop both. |
| Package manifests | `home/dot_Brewfile`, `run_onchange_after_15-arch-packages.sh.tmpl` | The obvious first thing to prune. |
| Monitors | `home/dot_config/hypr/config/variables.lua`, `monitors.lua` | Outputs, modes, and positions. The luminance numbers come from a specific panel's EDID and are meaningless on another one. |
| Yubikey registration | `run_onchange_after_45-pam-u2f.sh.tmpl` | `origin`/`appid` are bound to the hostname, so every machine needs its own `pamu2fcfg -o pam://$(hostname) -i pam://$(hostname)` run, stored back in 1Password. |
| git-tool services | `home/dot_config/git-tool/config.yml.tmpl` | Repository root and the GitHub/GHP service definitions. |
| Autostart and scratchpad apps | `home/dot_config/autostart/`, `hypr/config/windowrules.lua` | The window classes tiled by the communication scratchpad are listed by hand. |

The Linux desktop half also assumes systemd-homed with an enrolled FIDO2 token.
On a conventional local account the PAM scripts still apply cleanly, but the
reasoning behind them — everything in the next section — stops applying, and a
simpler locker would be a defensible choice.

## Why the lock screen and greeter are custom

Authenticating this account is a *multi-prompt* PAM conversation: the account
password, then `Security token PIN:`, then `Sorry, retry security token PIN:` if
that one was wrong. Any UI that buffers a single string and replays it at every
prompt hands the Yubikey three wrong PINs in about a second — the CTAP2
consecutive-failure limit. The token then blocks itself until it is physically
reinserted, and three of its eight lifetime retries are gone. Finding that out
cost exactly one real lockout.

noctalia's built-in lock screen behaves that way, and so does every prettier
greeter that was tried. Both halves were replaced with implementations that
re-prompt:

- **hyprlock** waits for fresh input whenever the prompt text changes, so a typo
  costs one retry instead of three. It also gets its own `/etc/pam.d/hyprlock`
  rather than the `auth include login` the package ships, which keeps the
  Yubikey rule from leaking into tty login.
- **ReGreet** loops over greetd's `auth_message` responses and clears the field
  each time. `hyprlogin` was evaluated and rejected: it handles exactly one auth
  message per session and cancels on the second, so it cannot complete a homed
  login at all — and it writes the submitted secret to `/tmp` in debug mode.

Both configs put the live PAM prompt on screen, because knowing whether PAM
currently wants the password or the PIN is the whole difference between one
wrong attempt and a blocked key. hyprlock deserves a warning here: it *discards*
`PAM_ERROR_MSG`, so systemd's "Security token PIN incorrect" is logged and never
drawn, and `$PAMFAIL` only fires once `pam_authenticate` returns. The prompt
flipping to "Sorry, retry…" is the only in-band signal, which is why it gets its
own label above the field instead of sitting greyed out as placeholder text.

Nothing here can stop a blocked token. What `46-faillock.sh` prevents is
faillock's stock 3-strikes rule landing on top of one, which would also reject
the account password and the recovery key — the two secrets that still work
while the token is blocked. Recovery is one of those (`homectl inspect` lists
both), with the key power-cycled later at a calmer moment.

The tension is still live. Every one of these UIs looks better when it hides
PAM's state machine behind a single password box, and hiding that state machine
is precisely what costs retries. Both screens here take the ugly, chatty end of
that trade on purpose.

## How the platform split works

Every `run_` script is a chezmoi template wrapped in an
`{{ if eq .chezmoi.os "…" }}` guard that falls through to `exit 0` on the other
platform. Files that only exist on one platform — the Brewfile, the LaunchAgent,
the systemd units, everything under `hypr/`, `noctalia/`, `autostart/`, and
`Yubico/` — are filtered by `home/.chezmoiignore`.

```
.chezmoiroot                            -> "home"
home/
  dot_Brewfile                          macOS packages
  dot_config/                           fish, git, ghostty, starship, atuin,
                                        mise, rustic, git-tool, hypr, noctalia
  private_dot_ssh/private_config.tmpl   1Password agent socket, per-OS
  Library/LaunchAgents/                 backup job (macOS)
  run_once_before_10-install-homebrew   bootstrap Homebrew        (macOS)
  run_onchange_after_15-arch-packages   pacman / AUR / Flathub    (Linux)
  run_onchange_after_20-brew-bundle     brew bundle --global      (macOS)
  run_onchange_after_25-hyprpm-plugins  Hyprland plugins          (Linux)
  run_onchange_after_30-mise-install    mise install
  run_onchange_after_35-mise-autocomplete
  run_onchange_after_40-macos-defaults  Finder / globals          (macOS)
  run_onchange_after_45-pam-u2f         Yubikey PIN for sudo etc. (Linux)
  run_onchange_after_46-faillock        lockout thresholds        (Linux)
  run_onchange_after_47-greetd          ReGreet login screen      (Linux)
  run_onchange_after_48-hypridle        (re)load hypridle         (Linux)
  run_onchange_after_49-otelcol         OTel collector + profiler (Linux)
  run_once_after_50-touchid-sudo        Touch ID for sudo         (macOS)
  run_once_after_60-default-shell       chsh to fish
  run_onchange_after_70-rustic-schedule (re)load the backup job
  run_once_after_80-trust-internal-ca   trust the internal CA
```

## Sharp edges

- **noctalia's `config.toml` is managed here**, which is unusual for this repo,
  because its lock screen and idle sections have to stay off. noctalia's own
  settings UI writes to the same file, so `chezmoi diff` after tweaking anything
  in the GUI is worth a look before `chezmoi apply` reverts it. Its session
  panel entries are `action = "command"` rather than the built-in `lock`,
  because noctalia strips the built-ins whenever its own locker is disabled —
  *before* it reads any `command` override.
- **`~/.config/hypr/hyprland.lua` belongs to CachyOS.** The files under
  `hypr/config/` are forks, so upstream changes to those specific files no
  longer reach the machine. `animations`, `autostart`, `colors`, `environment`,
  and `inputs` are still CachyOS's. Autostart goes through XDG `.desktop`
  entries because the session runs under UWSM, and `hyprbars` has to be rebuilt
  by hyprpm inside a live session whenever Hyprland updates.
- **ReGreet's theming is deliberately minimal.** It is a GTK app that noctalia
  cannot sync, and anything under `~/.local/share` — fonts, the Bibata cursor —
  lives inside the encrypted home this screen exists to unlock.
  `skip_selection` caches the last user under `/var/cache/regreet`, so the first
  boot after a wipe still shows the picker.
- **SDDM stays installed** as the fallback. `systemctl disable greetd &&
  systemctl enable sddm` reverts the greeter, and `cage -s` keeps VT switching
  available if it ever wedges.
- **Not replaced on Linux**: `little-snitch` has no equivalent (opensnitch is
  the closest), `orbstack` becomes a native Docker install, `grpcurl`'s AUR
  build fails, and WhatsApp has no official client so Flathub's ZapZap stands
  in.
