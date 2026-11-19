#!/bin/bash

set -euo pipefail

THEME_DIR="$HOME/.local/state/omarchy/current/theme"
COLORS_FILE="$THEME_DIR/colors.toml"
GTK4_DIR="$HOME/.config/gtk-4.0"
GTK_CSS="$GTK4_DIR/gtk.css"

[[ -f $COLORS_FILE ]] || exit 0

theme_color() {
  omarchy-theme-color --file "$COLORS_FILE" "$1" "$2"
}

contrast_color() {
  local hex="${1#\#}"
  local brightness

  if [[ $hex =~ ^[0-9A-Fa-f]{6}$ ]]; then
    brightness=$((
      (299 * 16#${hex:0:2} + 587 * 16#${hex:2:2} + 114 * 16#${hex:4:2}) / 1000
    ))
    (( brightness >= 110 )) && printf '#000000\n' || printf '#ffffff\n'
  else
    printf '#ffffff\n'
  fi
}

accent=$(theme_color accent blue)
background=$(theme_color background '#1d1d20')
foreground=$(theme_color foreground '#ffffff')
surface=$(theme_color lighter_background background)
deep_surface=$(theme_color dark_background background)
selection=$(theme_color selection surface)
muted=$(theme_color muted foreground)
red=$(theme_color red '#e62d42')
green=$(theme_color green '#3a944a')
yellow=$(theme_color yellow '#c88800')
accent_foreground=$(contrast_color "$accent")
red_foreground=$(contrast_color "$red")
green_foreground=$(contrast_color "$green")
yellow_foreground=$(contrast_color "$yellow")

theme_name="${1:-}"
if [[ -z $theme_name && -f $HOME/.local/state/omarchy/current/theme.name ]]; then
  theme_name=$(<"$HOME/.local/state/omarchy/current/theme.name")
fi

view_surface=$deep_surface
card_surface=$selection
border_color=$muted
menu_border_color=$muted
menu_border_width=1px
menu_rounding_rule=''
shade_color='rgba(0, 0, 0, 0.25)'
sidebar_shade_color='rgba(0, 0, 0, 0.20)'
scrollbar_outline_color='rgba(0, 0, 0, 0.50)'
surface_shadow='0 1px rgba(0, 0, 0, 0.25)'

# Miasma uses one uninterrupted black canvas in Nautilus. Accent and selection
# colors remain intact so focused and selected controls are still visible.
if [[ $theme_name == "miasma" ]]; then
  surface=$background
  deep_surface=$background
  view_surface=$background
  card_surface=$background
  border_color=transparent
  menu_border_color=$selection
  menu_border_width=2px
  menu_rounding_rule='border-radius: 12px;'
  shade_color=transparent
  sidebar_shade_color=transparent
  scrollbar_outline_color=transparent
  surface_shadow=none
fi

mkdir -p "$GTK4_DIR"
temporary_css=$(mktemp "$GTK4_DIR/.gtk.css.XXXXXX")
trap 'rm -f "$temporary_css"' EXIT

cat >"$temporary_css" <<EOF
/* Generated from the active Omarchy theme by 50-gtk4-theme.sh. */
@define-color accent_color $accent;
@define-color accent_bg_color $accent;
@define-color accent_fg_color $accent_foreground;

@define-color window_bg_color $background;
@define-color window_fg_color $foreground;
@define-color view_bg_color $view_surface;
@define-color view_fg_color $foreground;

@define-color headerbar_bg_color $surface;
@define-color headerbar_fg_color $foreground;
@define-color headerbar_backdrop_color $background;
@define-color headerbar_border_color $border_color;
@define-color headerbar_shade_color $shade_color;

@define-color sidebar_bg_color $surface;
@define-color sidebar_fg_color $foreground;
@define-color sidebar_backdrop_color $background;
@define-color sidebar_border_color $border_color;
@define-color sidebar_shade_color $sidebar_shade_color;

@define-color secondary_sidebar_bg_color $deep_surface;
@define-color secondary_sidebar_fg_color $foreground;
@define-color secondary_sidebar_backdrop_color $background;
@define-color secondary_sidebar_border_color $border_color;
@define-color secondary_sidebar_shade_color $sidebar_shade_color;

@define-color card_bg_color $card_surface;
@define-color card_fg_color $foreground;
@define-color dialog_bg_color $surface;
@define-color dialog_fg_color $foreground;
@define-color popover_bg_color $surface;
@define-color popover_fg_color $foreground;
@define-color thumbnail_bg_color $card_surface;
@define-color thumbnail_fg_color $foreground;
@define-color shade_color $shade_color;
@define-color scrollbar_outline_color $scrollbar_outline_color;

@define-color destructive_color $red;
@define-color destructive_bg_color $red;
@define-color destructive_fg_color $red_foreground;
@define-color error_color $red;
@define-color error_bg_color $red;
@define-color error_fg_color $red_foreground;
@define-color success_color $green;
@define-color success_bg_color $green;
@define-color success_fg_color $green_foreground;
@define-color warning_color $yellow;
@define-color warning_bg_color $yellow;
@define-color warning_fg_color $yellow_foreground;

:root {
  --accent-color: $accent;
  --accent-bg-color: $accent;
  --accent-fg-color: $accent_foreground;
  --window-bg-color: $background;
  --window-fg-color: $foreground;
  --view-bg-color: $view_surface;
  --view-fg-color: $foreground;
  --headerbar-bg-color: $surface;
  --headerbar-fg-color: $foreground;
  --sidebar-bg-color: $surface;
  --sidebar-fg-color: $foreground;
  --card-bg-color: $card_surface;
  --card-fg-color: $foreground;
  --dialog-bg-color: $surface;
  --dialog-fg-color: $foreground;
  --popover-bg-color: $surface;
  --popover-fg-color: $foreground;
  --destructive-color: $red;
  --destructive-bg-color: $red;
  --destructive-fg-color: $red_foreground;
  --error-color: $red;
  --error-bg-color: $red;
  --error-fg-color: $red_foreground;
  --success-color: $green;
  --success-bg-color: $green;
  --success-fg-color: $green_foreground;
  --warning-color: $yellow;
  --warning-bg-color: $yellow;
  --warning-fg-color: $yellow_foreground;
}

/*
 * libadwaita loads part of its application styling after the named-color
 * palette. These user-priority rules make the generated palette visible in
 * Nautilus and other GTK4/libadwaita applications as well.
 */
window.background {
  background-color: $background;
  color: $foreground;
}

headerbar,
.titlebar,
.toolbar {
  background-color: $surface;
  color: $foreground;
  border-color: $border_color;
  box-shadow: $surface_shadow;
  background-image: none;
}

.view,
textview > text,
listview,
gridview,
columnview,
treeview {
  background-color: $view_surface;
  color: $foreground;
}

.navigation-sidebar,
.sidebar,
placessidebar,
placessidebar list {
  background-color: $surface;
  color: $foreground;
  border-color: $border_color;
  box-shadow: $surface_shadow;
  background-image: none;
}

paned > separator {
  background-color: $border_color;
  border-color: $border_color;
  box-shadow: $surface_shadow;
}

popover > contents,
popover.menu > contents {
  background-color: $surface;
  background-clip: padding-box;
  border: $menu_border_width solid $menu_border_color;
  $menu_rounding_rule
  box-shadow: none;
}

selection,
row:selected,
listview > row:selected,
gridview > child:selected {
  background-color: $accent;
  color: $accent_foreground;
}

button.suggested-action,
.suggested-action {
  background-color: $accent;
  color: $accent_foreground;
}
EOF

chmod 644 "$temporary_css"
mv -f "$temporary_css" "$GTK_CSS"
trap - EXIT

# GTK4/libadwaita reads user CSS at process startup.
if pgrep -x nautilus >/dev/null; then
  pkill -x nautilus
fi
