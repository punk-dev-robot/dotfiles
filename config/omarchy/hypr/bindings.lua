-- Personal bindings on top of omarchy (KUB-102, from KUB-90 verdicts + ADR 0001/0002).
-- Omarchy SUPER binds stay unless listed in the unbind block below. SUPER is the primary WM/app layer
-- (ADR 0001 v2); ALT is secondary WM (monitor/layout, less-frequent). SHIFT = variant of same action.
-- Every o.bind carries a description: omarchy-menu-keybindings reads them.
-- Validate: hyprctl reload && hyprctl configerrors; dispatcher arg errors only surface at keypress.

---------------------------------------------------------------------------
-- 0. Consolidated unbinds — one initial pass, before any replacement registration.
--    Later unbinds can erase newly registered replacements; keep them all here.
---------------------------------------------------------------------------
for _, k in ipairs({
  "SUPER + J",                    -- omarchy: toggle split, unused; J stays focus-down only
  "SUPER + L",                    -- omarchy: 2-way layout toggle; ours is SUPER+ALT+L (3-way)
  "SUPER + LEFT", "SUPER + RIGHT", "SUPER + UP", "SUPER + DOWN", -- omarchy: directional focus -> resize
  "SUPER + TAB",                  -- omarchy: next workspace (e+1) -> former workspace
  "SUPER + CTRL + TAB",           -- omarchy: former-workspace alias, redundant with SUPER+TAB
  "ALT + TAB", "ALT + SHIFT + TAB", -- omarchy: cycle-next/bring-to-top/prev (unused; left to apps)
  "CTRL + ALT + TAB", "CTRL + ALT + SHIFT + TAB", -- omarchy: monitor cycling, redundant with SUPER+ALT+`
  "CTRL + ALT + DELETE",          -- omarchy: close all windows, unused
  "SUPER + SPACE",                -- omarchy: Omarchy menu -> floating toggle / scratchpad pull (vicinae is SUPER+D)
  "SUPER + SHIFT + SPACE",        -- omarchy: top-bar toggle, unused -> floating<->tiled focus
  "SUPER + comma",                -- omarchy: dismiss last notification -> roll stack left
  "SUPER + K",                    -- omarchy: desktop keybindings help -> folded into SUPER+CTRL+K
  "SUPER + ALT + K",               -- omarchy: tmux help, unused (tmux replaced by Herdr)
  "SUPER + CTRL + K",              -- omarchy: Herdr keybindings -> SUPER+CTRL+SHIFT+K
  "SUPER + CTRL + N",              -- omarchy: nightlight, unused -> dismiss-latest notification
  "SUPER + ALT + code:34", "SUPER + ALT + code:35", -- omarchy: webcam overlay resize, unused; frees Super+Alt+[/]
  "SUPER + mouse_down", "SUPER + mouse_up", -- omarchy: scroll workspace e+-1 -> relative r+-1
  "SUPER + BACKSPACE", "SUPER + SHIFT + BACKSPACE", "SUPER + O", "SUPER + SHIFT + O", "SUPER + SHIFT + A",
  "SUPER + P", "SUPER + T", "SUPER + V", "SUPER + RETURN", -- scratchpad trigger keys (retargeted below)
  "SUPER + SHIFT + RETURN",       -- omarchy: Browser -> new plain terminal
  "SUPER + CTRL + A",             -- omarchy: Audio -> pipewire profile toggle
  "SUPER + SHIFT + D",            -- omarchy: Docker webapp -> Omarchy menu
  "SUPER + SHIFT + S",            -- omarchy: Google Maps webapp -> screenshot (HHKB has no PrtScr)
  "SUPER + CTRL + S",             -- omarchy: Share menu (still in omarchy-menu) -> capture menu, next to SHIFT+S
  "SUPER + CTRL + C",             -- omarchy: capture menu -> moved to SUPER+CTRL+S
  "SUPER + CTRL + V", "SUPER + CTRL + E", -- omarchy: clipboard/emoji shell panels -> vicinae (omarchy ones on +SHIFT/+ALT)
  "SUPER + CTRL + Q", "XF86Calculator", "SUPER + ALT + SPACE", -- omarchy: omacalc, apps menu -> vicinae root search does both
}) do
  hl.unbind(k)
end

for code = 10, 19 do
  hl.unbind("SUPER + code:" .. code)        -- omarchy: switch workspace (re-registered below, own callback)
  hl.unbind("SUPER + SHIFT + code:" .. code) -- omarchy: move window + follow -> silent move
end
for _, code in ipairs({ 10, 11, 12, 13, 14 }) do
  hl.unbind("SUPER + ALT + code:" .. code) -- omarchy: grouped-window select -> move window + follow
end

---------------------------------------------------------------------------
-- 1. SUPER window-management layer (ADR 0001 v2 — Super primary, Alt secondary)
---------------------------------------------------------------------------
local dirs = { H = "l", J = "d", K = "u", L = "r" }
for key, d in pairs(dirs) do
  o.bind("SUPER + " .. key, "Focus window " .. d, hl.dsp.focus({ direction = d }))
  o.bind("SUPER + SHIFT + " .. key, "Move window " .. d, hl.dsp.window.move({ direction = d }))
end

-- Workspaces 1..10 on keycodes 10..19 (layout-independent). SHIFT = move silently, ALT = move and follow.
for ws = 1, 10 do
  local key = "code:" .. (ws + 9)
  o.bind("SUPER + " .. key, "Workspace " .. ws, hl.dsp.focus({ workspace = tostring(ws) }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. ws .. " (silent)",
    hl.dsp.window.move({ workspace = tostring(ws), follow = false }))
  o.bind("SUPER + ALT + " .. key, "Move window to workspace " .. ws,
    hl.dsp.window.move({ workspace = tostring(ws) }))
end
o.bind("SUPER + bracketleft", "Previous workspace (relative)", hl.dsp.focus({ workspace = "r-1" }))
o.bind("SUPER + bracketright", "Next workspace (relative)", hl.dsp.focus({ workspace = "r+1" }))
o.bind("SUPER + SHIFT + bracketleft", "Move window to previous workspace (silent)",
  hl.dsp.window.move({ workspace = "r-1", follow = false }))
o.bind("SUPER + SHIFT + bracketright", "Move window to next workspace (silent)",
  hl.dsp.window.move({ workspace = "r+1", follow = false }))
o.bind("SUPER + ALT + bracketleft", "Move window to previous workspace", hl.dsp.window.move({ workspace = "r-1" }))
o.bind("SUPER + ALT + bracketright", "Move window to next workspace", hl.dsp.window.move({ workspace = "r+1" }))
o.bind("SUPER + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))
o.bind("SUPER + mouse_down", "Next workspace (relative)", hl.dsp.focus({ workspace = "r+1" }))
o.bind("SUPER + mouse_up", "Previous workspace (relative)", hl.dsp.focus({ workspace = "r-1" }))

-- Floating
-- KUB-106: on a scratchpad (special ws, id < 0) togglefloating just tiles it inside the full-screen special overlay;
-- pull it into the current regular workspace instead (lands tiled).
o.bind("SUPER + SPACE", "Toggle floating / pull scratchpad window into workspace", function()
  local w = hl.get_active_window()
  if w and w.workspace and w.workspace.id < 0 then
    hl.dispatch(hl.dsp.window.move({ workspace = "e+0" }))
    if w.floating then hl.dispatch(hl.dsp.window.float({ action = "off" })) end -- scratch rule floats it; owner wants tiled
  else
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  end
end)
o.bind("SUPER + SHIFT + SPACE", "Focus other layer (floating <-> tiled)", function()
  local active = hl.get_active_window()
  if not active then return end
  local ws = hl.get_active_workspace()
  for _, w in ipairs(hl.get_windows({ workspace = ws and ws.id, floating = not active.floating })) do
    hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
    return
  end
end)

-- Monitors
o.bind("SUPER + ALT + SHIFT + grave", "Move window to next monitor", hl.dsp.window.move({ monitor = "+1" }))
o.bind("SUPER + ALT + W", "Move workspace to next monitor", hl.dsp.workspace.move({ monitor = "+1" }))
o.bind("SUPER + ALT + grave", "Focus next monitor", hl.dsp.focus({ monitor = "+1" }))

-- Master layout
o.bind("SUPER + semicolon", "Swap with master", hl.dsp.layout("swapwithmaster auto"))
o.bind("SUPER + comma", "Roll stack left", hl.dsp.layout("rollprev"))
o.bind("SUPER + period", "Roll stack right", hl.dsp.layout("rollnext"))
-- 3-way layout cycle for the active workspace (replaces hyprtogglelayout; `layoutmsg setlayout` is gone in 0.56).
-- KUB-120: persisted the way omarchy-hyprland-workspace-layout-toggle does — one line in
-- $XDG_STATE_HOME/omarchy/workspace-layouts/<id>.lua, which default/hypr/workspace-layouts.lua re-applies on every reload.
local layouts_dir = require("default.hypr.paths").state_home .. "/omarchy/workspace-layouts"
o.bind("SUPER + ALT + L", "Cycle layout master → dwindle → scrolling", function()
  local ws = hl.get_active_workspace()
  if not ws then return end
  local nxt = ({ master = "dwindle", dwindle = "scrolling", scrolling = "master" })[ws.tiled_layout] or "master"
  hl.workspace_rule({ workspace = tostring(ws.id), layout = nxt })
  os.execute("mkdir -p '" .. layouts_dir .. "'")
  local f = io.open(layouts_dir .. "/" .. ws.id .. ".lua", "w")
  if f then
    f:write(string.format('hl.workspace_rule({ workspace = "%s", layout = "%s" })\n', ws.id, nxt))
    f:close()
  end
  hl.exec_cmd("omarchy-notification-send -g 󱂬 'Layout: " .. nxt .. "'")
end)

-- Resize: SUPER+arrows ±50 (repeat), SUPER+R submap h/j/k/l ±10, escape to leave.
o.bind("SUPER + LEFT", "Resize window left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }),
  { repeating = true })
o.bind("SUPER + RIGHT", "Resize window right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }),
  { repeating = true })
o.bind("SUPER + UP", "Resize window up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
o.bind("SUPER + DOWN", "Resize window down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })
o.bind("SUPER + R", "Resize submap: hjkl then escape", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
  hl.bind("escape", hl.dsp.submap("reset"))
  hl.bind("H", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
  hl.bind("L", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
  hl.bind("K", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
  hl.bind("J", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
end)

-- Mouse
-- SUPER+mouse:272/273 (drag/resize) reuse stock Omarchy binds — same semantics/flags; no personal override.
-- Logitech MX Master extra buttons → shortcuts into the active window
o.bind("mouse:276", "MX forward: Obsidian web clipper", hl.dsp.send_shortcut({ mods = "SHIFT SUPER", key = "O" }))
o.bind("mouse:277", "MX haptic: reopen tab", hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "T" }))
o.bind("mouse:278", "MX gesture: close tab", hl.dsp.send_shortcut({ mods = "CTRL", key = "W" }))

-- KUB-114: SUPER = WM/app layer. SUPER+Q close, SUPER+SHIFT+Q force-kill (omarchy SUPER+W close stays).
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + SHIFT + Q", "Kill window", hl.dsp.window.kill())

---------------------------------------------------------------------------
-- 2. Apps / misc
---------------------------------------------------------------------------
o.bind("SUPER + CTRL + A", "Toggle pipewire profile", "pw-profile toggle")
o.bind("SUPER + CTRL + SHIFT + V", "EasyEffects: toggle speakers/headphones preset", "ee-toggle")
-- Volume keys: omarchy's script can't resolve through EasyEffects 8 (see ee-volume header) → rebind.
for _, k in ipairs({ "XF86AudioRaiseVolume", "XF86AudioLowerVolume", "XF86AudioMute",
                     "ALT + XF86AudioRaiseVolume", "ALT + XF86AudioLowerVolume" }) do hl.unbind(k) end
o.bind("XF86AudioRaiseVolume", "Volume up", "ee-volume raise", { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", "ee-volume lower", { locked = true, repeating = true })
o.bind("XF86AudioMute", "Mute", "ee-volume mute-toggle", { locked = true })
o.bind("ALT + XF86AudioRaiseVolume", "Volume up precise", "ee-volume +1", { locked = true, repeating = true })
o.bind("ALT + XF86AudioLowerVolume", "Volume down precise", "ee-volume -1", { locked = true, repeating = true })
-- KUB-128: Vicinae is the primary launcher (user service vicinae.service). Omarchy menu moves SUPER+SPACE → SUPER+SHIFT+D
-- (SUPER+SPACE itself is unbound above and now runs the floating-toggle WM binding).
-- Omarchy-menu binds other than apps (capture/toggle/hardware/system) stay.
-- Clipboard + emoji go to vicinae; omarchy's shell panels keep a fallback (SHIFT for emoji; clipboard on ALT — SUPER+CTRL+SHIFT+V is ee-toggle).
o.bind("SUPER + D", "Vicinae launcher", "vicinae toggle")
o.bind("SUPER + SHIFT + D", "Omarchy menu", "omarchy-menu toggle")
o.bind("SUPER + CTRL + V", "Clipboard history (vicinae)", "vicinae deeplink vicinae://launch/clipboard/history")
o.bind("SUPER + CTRL + E", "Emojis (vicinae)", "vicinae deeplink vicinae://launch/core/search-emojis")
o.bind("SUPER + CTRL + ALT + V", "Clipboard manager (omarchy)", "omarchy-shell shell toggle omarchy.clipboard")
o.bind("SUPER + CTRL + SHIFT + E", "Emojis (omarchy)", "omarchy-shell shell toggle omarchy.emojis")
-- KUB-127: hold Right ◇ (SUPER_R, HHKB) = push-to-talk dictation; same release shape as omarchy's F9.
-- ALT+ALT_L tap-toggle dropped (mistriggers). Omarchy SUPER+CTRL+X toggle and F9 PTT stay.
-- Probed: press fires as bare "SUPER_R"; release only fires with the modifier in the mask ("SUPER + SUPER_R").
o.bind("SUPER_R", "Dictation (hold)", "voxtype record start")
o.bind("SUPER + SUPER_R", "Dictation (release)", "voxtype record stop", { release = true })

-- Capture, grouped on S. Omarchy puts screenshot/recording/OCR on PRINT; the HHKB (ydkb firmware, see
-- config/shared/keyboards/ydkb/) has no PrtScr on any layer, so those binds are unreachable there.
-- Capture menu moves C -> S so both live on the same key; omarchy's Share menu it displaces stays
-- reachable from omarchy-menu. Omarchy has no edit-screenshot bind at all (SUPER+ALT+, is the generic
-- "invoke last notification"), so CTRL+SHIFT+S opens the newest shot in satty directly.
o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")
o.bind("SUPER + CTRL + S", "Capture menu (record / OCR / QR / webcam)", "omarchy-menu toggle capture")
o.bind("SUPER + CTRL + SHIFT + S", "Edit last screenshot (satty)", "satty-edit")
-- Help
o.bind("SUPER + CTRL + K", "Keybindings", "omarchy-menu-keybindings")
o.bind("SUPER + CTRL + SHIFT + K", "Herdr keybindings", "omarchy-menu-herdr-keybindings")

-- Notifications
o.bind("SUPER + CTRL + N", "Dismiss last notification", "omarchy-shell notifications dismissOne")
o.bind_toggle("SUPER + CTRL + SHIFT + N", "Toggle silencing notifications", "notification-silencing")

-- Terminal
o.bind("SUPER + SHIFT + RETURN", "Terminal", { omarchy = "terminal" })
-- SUPER+RETURN dropterm (below, scratchpads) and SUPER+CTRL+RETURN Herdr (omarchy, unchanged) stay as-is.

---------------------------------------------------------------------------
-- 3. Scratchpads as special workspaces (ADR 0002). Terminal app-ids must be reverse-DNS (ghostty rejects
--    "drop-term" and falls back to com.mitchellh.ghostty). Class regexes are case-sensitive. No daemon: if a window whose class contains
--    `match` exists → toggle its special workspace, else launch it (window rule parks it there).
---------------------------------------------------------------------------

local function scratch(key, name, match, cmd, rules)
  o.bind(key, "Scratchpad: " .. name, function()
    -- "[Ss]potify.*" → "spotify" for the plain-find below (window-rule class regexes are full-match)
    local needle = match:gsub("%[%a(%a)%]", "%1"):gsub("%.%*", ""):lower()
    for _, w in ipairs(hl.get_windows({ mapped = true })) do
      if w.class:lower():find(needle, 1, true) then
        -- Tiled on a regular workspace = owner pinned it there (SUPER + SPACE pull). Focus only,
        -- never re-park/re-float (parity with local/bin/aerospace-toggle TILED_ID).
        -- Float it again (SUPER + SPACE) and it goes back to being a scratchpad: falls through below.
        if w.workspace and w.workspace.id >= 0 and not w.floating then
          hl.dispatch(hl.dsp.focus({ window = w }))
          return
        end
        -- Self-heal: a window that opened while another special was showing lands there. Adopt it.
        if not (w.workspace and w.workspace.name == "special:" .. name) then
          hl.dispatch(hl.dsp.focus({ window = w }))
          hl.dispatch(hl.dsp.window.move({ workspace = "special:" .. name, follow = false }))
          if not w.floating then -- window rules only apply at map time
            hl.dispatch(hl.dsp.window.float({ action = "on" }))
            hl.dispatch(hl.dsp.window.resize({ x = 1920, y = 1200 }))
            hl.dispatch(hl.dsp.window.center())
          end
        end
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
        -- input.special_fallthrough=true: a floating-only special doesn't take focus by itself.
        local sp = hl.get_active_special_workspace()
        if sp and sp.name == "special:" .. name then
          hl.dispatch(hl.dsp.focus({ window = w }))
        end
        return
      end
    end
    hl.exec_cmd("uwsm-app -- " .. cmd)
  end)
  -- not "silent": first launch should reveal the special workspace
  local rule = { workspace = "special:" .. name, float = true, center = true, size = { 1920, 1200 } }
  for k, v in pairs(rules or {}) do rule[k] = v end
  o.window(match, rule)
end

scratch("SUPER + BACKSPACE", "slack", "[Ss]lack", "slack")
scratch("SUPER + SHIFT + BACKSPACE", "whatsapp", "chrome-web.whatsapp.com__.*",
  "omarchy-launch-webapp https://web.whatsapp.com/")
scratch("SUPER + O", "obsidian", "obsidian", "obsidian")
scratch("SUPER + N", "notion", "chrome-www.notion.so__.*", "omarchy-launch-webapp https://www.notion.so")
scratch("SUPER + P", "1password", "1[Pp]assword", "1password", { size = { "33%", "66%" } })
scratch("SUPER + M", "spotify", "[Ss]potify.*", "spotify-launcher")
scratch("SUPER + A", "openwebui", "crx_ciaamnabomjhndmogimfmmkflefihebh", "gtk-launch openwebui")
scratch("SUPER + SHIFT + A", "claude", "[Cc]laude.*", "claude-desktop")
scratch("SUPER + E", "protonmail", ".*[Pp]roton.*", "proton-mail")
scratch("SUPER + T", "linear", "[Ll]inear-linux", "gtk-launch Linear") -- KUB-118: user .desktop adds GDK_BACKEND=x11 (class is Linear-linux on XWayland)
scratch("SUPER + V", "volume", "org.pulseaudio.pavucontrol", "pavucontrol", { size = { 800, 600 } })
scratch("SUPER + SHIFT + V", "easyeffects", "com.github.wwmm.easyeffects", "easyeffects")
scratch("SUPER + I", "top", "scratch.btm", "xdg-terminal-exec --app-id=scratch.btm -e btm")
scratch("SUPER + SHIFT + I", "nvtop", "scratch.nvtop", "xdg-terminal-exec --app-id=scratch.nvtop -e nvtop")
scratch("SUPER + RETURN", "dropterm", "scratch.dropterm", "xdg-terminal-exec --app-id=scratch.dropterm")
scratch("SUPER + DELETE", "reclaim", "chrome-reclaim.ai__-Profile_1", "gtk-launch reclaim")
scratch("SUPER + SHIFT + DELETE", "todoist", ".*[Tt]odoist.*", "todoist")
o.window("obsidian", { focus_on_activate = true })
