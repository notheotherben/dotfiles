-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    -- The AW3225QF comes up dim after the desktop moved from HDR to SDR: its
    -- OSD brightness only takes effect once it is touched again, so nudge it
    -- over DDC/CI on every start. Hyprland's sdrbrightness cannot do this: it
    -- only applies while the output is in PQ/HDR mode. Addressed by model so
    -- the i2c bus number does not matter. noctalia's brightness controls use
    -- the same DDC channel afterwards (see noctalia/config.toml).
    hl.exec_cmd("ddcutil --model AW3225QF setvcp 10 100")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("xhost +SI:localuser:root")
end)
