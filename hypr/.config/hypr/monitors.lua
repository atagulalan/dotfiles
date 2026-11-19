-- This layout matches the current desk. On a different machine, replace these
-- rules with `hyprctl monitors all` output or use the generic fallback below.

hl.env("GDK_SCALE", "2")

-- Safe fallback for unknown displays. Specific rules below take precedence.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.monitor({
  output = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. AORUS FO32U2 0x01010101",
  mode = "3840x2160@240.00",
  position = "0x0",
  scale = 1.6,
  sdr_min_luminance = 0.2,
  sdr_max_luminance = 80,
})

hl.monitor({
  output = "desc:Dell Inc. DELL P2219H J99D8W2",
  mode = "1920x1080@60.00",
  position = "2400x-70",
  scale = 1.2,
  transform = 3,
  sdr_min_luminance = 0.2,
  sdr_max_luminance = 80,
})
