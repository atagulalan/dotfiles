-- Personal Omarchy / Hyprland overrides.
-- Omarchy supplies the base configuration; this file is intentionally kept
-- small so it remains compatible with Omarchy updates.

dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")
require("default.hypr.omarchy")

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")
require("default.hypr.toggles")

-- Keep windows fully opaque.
o.window(".*", { opacity = "1 1" })

-- Open every window in floating mode.
-- o.window(".*", { float = true })

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpm reload && hyprctl reload")
end)

hl.config({
    plugin = {
        hyprbars = {
            bar_height = 0,
            bar_text_align = "left",
      }
    }
})
