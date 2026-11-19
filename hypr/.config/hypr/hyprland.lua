-- Personal Omarchy / Hyprland overrides.
-- Omarchy supplies the base configuration; this file is intentionally kept
-- small so it remains compatible with Omarchy updates.

dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Omarchy swallows client maximize requests so tiled windows do not echo
-- Hyprland's CSD-suppression hint back as a real maximize. Nautilus, Cursor,
-- and Zen use that same request for a header-bar double-click, so let them through.
local register_window_rule = hl.window_rule
hl.window_rule = function(rules)
  if type(rules) == "table"
      and rules.suppress_event == "maximize"
      and type(rules.match) == "table"
      and rules.match.class == ".*" then
    rules.match.class = "negative:(?i)^(org\\.gnome\\.nautilus|nautilus|cursor|zen)$"
  end
  return register_window_rule(rules)
end

require("default.hypr.omarchy")

hl.window_rule = register_window_rule

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")
require("default.hypr.toggles")

-- Keep windows fully opaque.
o.window(".*", { opacity = "1 1" })

-- Keep Zen alone and maximized on the main display while leaving the bar visible.
-- The existing macos-fullscreen helper moves maximized windows to a dedicated workspace.
-- o.window("^zen$", {
--     monitor = "HDMI-A-1 silent",
--     maximize = true,
-- })

-- Give Cursor and VS Code the same bar-visible, dedicated-workspace behavior.
-- o.window("^(Cursor|cursor|Code|code)$", {
--     monitor = "HDMI-A-1 silent",
--     maximize = true,
-- })

-- Steam client only: open on the side display. Game windows use
-- different classes (steam_app_*) and are intentionally left untouched.
o.window("^steam$", {
    monitor = "DP-1 silent",
})

-- Always open Discord on the side display without stealing focus.
o.window("^discord$", {
    monitor = "DP-1 silent",
})

-- Every new window floats, like a normal desktop. Later rules win, so this
-- overrides Omarchy's tiled browser rules. Super+T still toggles one window.
o.window(".*", { float = true })

-- Cursor re-activates itself when a window on the same workspace is clicked,
-- so the click never sticks and Ghostty stays behind it.
o.window("^(cursor|Cursor)$", { focus_on_activate = false })

hl.on("hyprland.start", function()
    -- Keep the development build authoritative; the HyprPM copy is removed.
    hl.exec_cmd("hyprpm reload && hyprctl plugin load /home/xava/Projects/gloview/build/gloview.so && hyprctl reload")
end)

require("hypr.macos-fullscreen")

-- Click / focus a tiled window → minimize floating windows on that workspace.
require("hypr.minimize-floats-on-tile")

-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.
do local path = os.getenv("HOME") .. "/.config/hypr/hyprmoncfg-monitors.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end
