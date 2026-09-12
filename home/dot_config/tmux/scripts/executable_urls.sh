#!/bin/sh
# Pick a URL from the pane's history with fzf; open it locally, otherwise copy
# it to the clipboard (tmux forwards the buffer through OSC 52 over ssh).
# tmux redraws wrapped lines without wrap marks, so the terminal's own link
# detection misses long URLs; -J joins them back before matching.

pane=${1:-$(tmux display-message -p '#{pane_id}')}
urls=$(tmux capture-pane -p -J -S -5000 -t "$pane" \
  | grep -oE '(https?|ssh|git)://[^[:space:]<>"'"'"'`]+' \
  | sed -E 's/[].,;:)\\]+$//' \
  | awk '!seen[$0]++')

[ -n "$urls" ] || { tmux display-message 'No URLs in this pane'; exit 0; }

if command -v fzf > /dev/null 2>&1; then
  url=$(printf '%s\n' "$urls" | fzf --tac --no-sort --prompt='open › ')
else
  url=$(printf '%s\n' "$urls" | tail -n 1)
fi
[ -n "$url" ] || exit 0

if command -v open > /dev/null 2>&1; then
  open "$url"
elif [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && command -v xdg-open > /dev/null 2>&1; then
  xdg-open "$url" > /dev/null 2>&1
else
  tmux set-buffer -w "$url" \; display-message "Copied $url"
fi
