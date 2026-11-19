# GNOME Workspaces

A compact GNOME-style workspace indicator for the Omarchy shell bar.

- The active workspace is a pill; the others are dots.
- Only workspaces on the bar's monitor are shown.
- Left-click focuses a workspace.
- One wheel movement moves one workspace: down goes forward and up goes
  backward, wrapping at the ends. Fine touchpad deltas are accumulated.
- The indicator follows Omarchy's current bar foreground color.

The widget is designed to work with the dynamic workspaces created by
`~/.config/hypr/macos-fullscreen.lua`, so indicators appear and disappear as
fullscreen application workspaces are created and removed.
