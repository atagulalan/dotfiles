#!/usr/bin/env bash

# Report whether any MPRIS player in this desktop session is actively playing.
# Zen/Firefox uses this interface even when its portal idle inhibitor is lost.
while read -r player _; do
  [[ $player == org.mpris.MediaPlayer2.* ]] || continue

  status=$(busctl --user get-property \
    "$player" \
    /org/mpris/MediaPlayer2 \
    org.mpris.MediaPlayer2.Player \
    PlaybackStatus 2>/dev/null) || continue

  if [[ $status == 's "Playing"' ]]; then
    printf 'playing\n'
    exit 0
  fi
done < <(busctl --user --no-pager --no-legend list 2>/dev/null)

printf 'not-playing\n'
