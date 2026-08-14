-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = "MONITOR1",
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })

-- Hyprland only advertises a cut-down colour-management protocol by default, so
-- HDR-aware clients (games under Proton, video players) see no HDR support and
-- silently fall back to SDR even when the monitor itself is in HDR mode.
-- This takes effect on a full Hyprland restart, not on `hyprctl reload`.
hl.config({
    debug = {
        full_cm_proto = true,
    },
})

hl.monitor({
    output    = MONITOR1,
    -- No vrr override here: this QD-OLED panel flickers badly with always-on VRR,
    -- so it inherits misc.vrr = 3 (fullscreen games only) instead. Note that a VRR
    -- change only takes effect after the mode is toggled, not on a bare reload.
    mode      = "3840x2160@240",
    -- Explicit position rather than "auto": toggling this monitor off and on made
    -- Hyprland re-place it to the right of MONITOR2 instead of its usual left slot.
    position  = "0x0",
    scale     = 1,
    bitdepth = 10,
    cm = "hdr",
    sdr_eotf = "gamma22",
    sdrbrightness = 0.75,
    sdrsaturation = 1.1,
    sdr_min_luminance = 0,
    sdr_max_luminance = 150,
    min_luminance = 0,
    max_luminance = 800,
    max_avg_luminance = 270
})

hl.monitor({
    output    = MONITOR2,
    mode      = "preferred",
    -- MONITOR1 is 3840 logical px wide, so this sits immediately to its right.
    -- Vertically centred against it: (2160 - 2160/1.25) / 2 = 216.
    position  = "3840x216",
    scale     = 1.25,
    bitdepth = 10,
    -- cm = "dcip3",
    sdr_eotf = "gamma22",
    sdrbrightness = 1.0,
    sdrsaturation = 1.0,
    sdr_min_luminance = 1,
    sdr_max_luminance = 300,
    -- Values taken from the panel's EDID (max 400, frame-average 322, min 0.098).
    min_luminance = 0.098,
    max_luminance = 400,
    max_avg_luminance = 322
})
