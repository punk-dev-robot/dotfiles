-- Monitors (KUB-102). Loaded after omarchy defaults; last hl.monitor() per output wins.
-- List: hyprctl monitors all

-- Scale-1 panel: GDK_SCALE 1 (omarchy default is 2).
hl.env("GDK_SCALE", "1")

-- Catch-all for office / unknown outputs.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.25 })

-- Home ultrawide. Match by description: the connector (DP-3 → DP-6) changes between docks.
hl.monitor({
  output = "desc:Philips Consumer Electronics Company PHL 499P9 AU02015015203",
  mode = "5120x1440@70",
  position = "0x0",
  scale = 1,
  bitdepth = 10,
})
