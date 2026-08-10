-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = "MONITOR1",
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })

hl.monitor({
    output    = MONITOR1,
    mode      = "preferred",
    position  = "auto",
    scale     = 1,
    vrr = 1,
    bitdepth = 10,
    cm = "hdr",
    sdr_eotf = "gamma22",
    sdrbrightness = 0.5,
    sdrsaturation = 1.0,
    sdr_min_luminance = 0,
    sdr_max_luminance = 250,
    min_luminance = 0,
    max_luminance = 940,
    max_avg_luminance = 250
})

hl.monitor({
    output    = MONITOR2,
    mode      = "preferred",
    position  = "auto-center-right",
    scale     = 1.25,
    bitdepth = 10,
    cm = "hdr",
    sdr_eotf = "gamma22",
    sdrbrightness = 1.0,
    sdrsaturation = 1.0,
    sdr_min_luminance = 0,
    sdr_max_luminance = 250,
    min_luminance = 0,
    max_luminance = 350,
    max_avg_luminance = 450
})
