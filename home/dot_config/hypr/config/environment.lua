-- Environmental variables (for reference https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/)
-- if you use UWSM, define your variables in ~/.config/uwsm/env
-- if you don't use UWSM, define your variables here (e.g. hl.env("QT_QPA_PLATFORM", "wayland"))

-- This machine launches Hyprland through UWSM (wayland-wm-env@hyprland.desktop.service),
-- so all environment variables live in ~/.config/uwsm/env instead. Defining them here as
-- well would only cover processes Hyprland itself spawns, and would drift out of sync.
-- The NVIDIA block (GBM_BACKEND, __GLX_VENDOR_LIBRARY_NAME, LIBVA_DRIVER_NAME,
-- __GL_GSYNC_ALLOWED, NVD_BACKEND) was moved there for that reason.
