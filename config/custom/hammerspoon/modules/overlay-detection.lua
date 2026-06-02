-- Karabiner variable bridge for overlay apps that don't steal frontmost app status.
-- When Raycast (NSPanel) opens over a terminal, Karabiner's frontmost_application_unless
-- still sees the terminal → swap doesn't fire → Cmd shortcuts break.
-- This module detects Raycast visibility and sets a Karabiner variable so a targeted
-- rule can restore the swap for specific shortcuts only.

local KARABINER_CLI = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
local TERMINAL_BUNDLE_IDS = {
  ["com.mitchellh.ghostty"]  = true,
  ["com.apple.Terminal"]     = true,
  ["net.kovidgoyal.kitty"]   = true,
  ["com.raphaelamorim.rio"]  = true,
}

local function setVariable(name, value)
  local json = string.format('{"%s":%d}', name, value)
  hs.execute(string.format("'%s' --set-variables '%s'", KARABINER_CLI, json))
end

local function isFrontmostTerminal()
  local app = hs.application.frontmostApplication()
  return app and TERMINAL_BUNDLE_IDS[app:bundleID()] or false
end

local raycastFilter = hs.window.filter.new(false):setAppFilter("Raycast", {})

raycastFilter:subscribe(hs.window.filter.windowCreated, function()
  if isFrontmostTerminal() then
    setVariable("raycast_over_terminal", 1)
  end
end)

raycastFilter:subscribe(hs.window.filter.windowDestroyed, function()
  setVariable("raycast_over_terminal", 0)
end)
