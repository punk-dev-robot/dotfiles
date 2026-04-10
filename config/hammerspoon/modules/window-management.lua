-- Window management — basic foundation, to be expanded
-- Ctrl+Alt+Arrow : snap to half
-- Ctrl+Alt+F     : maximise
-- Ctrl+Alt+Shift+Arrow : throw to next/previous screen

local function snap(unitRect)
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit(unitRect) end
end

hs.hotkey.bind({"ctrl", "alt"}, "left",  function() snap({0,   0, 0.5, 1  }) end)
hs.hotkey.bind({"ctrl", "alt"}, "right", function() snap({0.5, 0, 0.5, 1  }) end)
hs.hotkey.bind({"ctrl", "alt"}, "up",    function() snap({0,   0, 1,   0.5}) end)
hs.hotkey.bind({"ctrl", "alt"}, "down",  function() snap({0, 0.5, 1,   0.5}) end)

hs.hotkey.bind({"ctrl", "alt"}, "f", function()
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit({0, 0, 1, 1}) end
end)

hs.hotkey.bind({"ctrl", "alt", "shift"}, "right", function()
  local win = hs.window.focusedWindow()
  if win then win:moveToScreen(win:screen():next()) end
end)

hs.hotkey.bind({"ctrl", "alt", "shift"}, "left", function()
  local win = hs.window.focusedWindow()
  if win then win:moveToScreen(win:screen():previous()) end
end)
