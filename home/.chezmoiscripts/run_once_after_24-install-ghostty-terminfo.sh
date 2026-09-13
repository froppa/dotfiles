#!/usr/bin/env bash
set -euo pipefail

# Ghostty sends TERM=xterm-ghostty. macOS gets that entry from Ghostty.app, but
# ncurses on Linux ships the same description under the name `ghostty` alone, so
# a plain ssh login lands on an unknown terminal: zle loses cub1/el and can no
# longer echo, erase, or redraw the line. Derive the missing alias from the
# entry that is present. (tmux sessions hide this by rewriting TERM.)

command -v infocmp >/dev/null 2>&1 || exit 0
infocmp xterm-ghostty >/dev/null 2>&1 && exit 0

if ! infocmp ghostty >/dev/null 2>&1; then
  echo "⚠️ No ghostty terminfo to derive from. From a Ghostty host, run:" >&2
  echo "   infocmp -x xterm-ghostty | ssh $(hostname) -- tic -x -" >&2
  exit 0
fi

infocmp -x ghostty | sed '0,/^ghostty|/s//xterm-ghostty|/' | tic -x -o "${HOME}/.terminfo" -

echo "ℹ️ Installed xterm-ghostty terminfo in ~/.terminfo; reconnect to pick it up."
