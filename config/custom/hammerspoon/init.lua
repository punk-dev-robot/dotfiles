require("modules.overlay-detection")
require("modules.window-management")

hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function()
  hs.reload()
end):start()
