-- Input / misc / binds / cursor overrides (KUB-102, museum values from configs/settings.conf).
-- Keys not listed here keep omarchy's defaults (kb_layout/options, numlock, touchpad, ...).

hl.config({
  input = {
    -- ponytail: calibration knob, museum values; omarchy is 250/40.
    repeat_delay = 600,
    repeat_rate = 25,
    follow_mouse = 1,
    follow_mouse_threshold = 1,
    special_fallthrough = true,
    kb_options = "compose:caps,shift:both_capslock_cancel,altwin:swap_lalt_lwin",
  },
  misc = {
    focus_on_activate = false,
    enable_swallow = true,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    enable_anr_dialog = false,
  },
  binds = {
    workspace_back_and_forth = true,
    allow_workspace_cycles = true,
    pass_mouse_when_bound = false,
    drag_threshold = 10,
    scroll_event_delay = 0,
  },
  cursor = {
    no_hardware_cursors = true,
    warp_on_change_workspace = true,
  },
  xwayland = {
    force_zero_scaling = true,
  },
})

-- KUB-111: screenshots land in ~/Pictures/Screenshots (omarchy default: ~/Pictures). Editor = satty
-- (tensaku trial over); local/bin/satty-edit supplies the flags — omarchy passes the editor as a single
-- argv element with a bare path, so a plain "satty -f" string cannot work.
hl.env("OMARCHY_SCREENSHOT_DIR", os.getenv("HOME") .. "/Pictures/Screenshots")
hl.env("OMARCHY_SCREENSHOT_EDITOR", "satty-edit")
