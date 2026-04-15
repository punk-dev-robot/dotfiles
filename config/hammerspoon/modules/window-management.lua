-- Window management
-- Opt+HJKL   : focus window directionally
-- Opt+Arrows : resize window incrementally (50px steps)

local resizeStep = 50

local function withFocused(fn)
  local win = hs.window.focusedWindow()
  if win then fn(win) end
end

-- Focus
hs.hotkey.bind({"alt"}, "h", function() withFocused(function(w) w:focusWindowWest()  end) end)
hs.hotkey.bind({"alt"}, "l", function() withFocused(function(w) w:focusWindowEast()  end) end)
hs.hotkey.bind({"alt"}, "k", function() withFocused(function(w) w:focusWindowNorth() end) end)
hs.hotkey.bind({"alt"}, "j", function() withFocused(function(w) w:focusWindowSouth() end) end)

-- Resize (arrow keys = firmware '/' layer + hjkl)
hs.hotkey.bind({"alt"}, "left",  function() withFocused(function(w)
  local f = w:frame(); f.w = math.max(200, f.w - resizeStep); w:setFrame(f)
end) end)

hs.hotkey.bind({"alt"}, "right", function() withFocused(function(w)
  local f = w:frame(); f.w = f.w + resizeStep; w:setFrame(f)
end) end)

hs.hotkey.bind({"alt"}, "up", function() withFocused(function(w)
  local f = w:frame(); f.h = math.max(200, f.h - resizeStep); w:setFrame(f)
end) end)

hs.hotkey.bind({"alt"}, "down", function() withFocused(function(w)
  local f = w:frame(); f.h = f.h + resizeStep; w:setFrame(f)
end) end)
