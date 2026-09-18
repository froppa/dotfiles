#!/bin/sh
# Colourised tmux cheat sheet for the Caps+H popup (piped through less -R).

esc=$(printf '\033')
title="${esc}[1;38;5;255m"
head="${esc}[1;38;5;68m"
key="${esc}[1;38;5;111m"
txt="${esc}[38;5;250m"
dim="${esc}[38;5;243m"
line="${esc}[38;5;238m"
off="${esc}[0m"

section() { printf '\n%s%s%s\n' "$head" "$1" "$off"; }
row() {
  # row <key> <text> [<key> <text>]: two columns, keys left-aligned.
  printf '  %s%-17s%s%s%-30s%s' "$key" "$1" "$off" "$txt" "$2" "$off"
  [ $# -gt 2 ] && printf '%s%-17s%s%s%s%s' "$key" "$3" "$off" "$txt" "$4" "$off"
  printf '\n'
}
note() { printf '  %s%s%s\n' "$dim" "$1" "$off"; }

printf '%stmux%s  %s⇪ Caps = Raycast Hyper chord · Ctrl-a = prefix · every chord is also Ctrl-a + key%s\n' "$title" "$off" "$dim" "$off"
printf '%s%s%s\n' "$line" "$(printf '%84s' '' | tr ' ' '─')" "$off"

section "WINDOWS   tabs: directory or ssh host, ✦ claude, ◆ codex, | - splits, Z zoomed"
note "claude icon: orange working, yellow ✦? waiting for you, grey idle (via hooks)"
row "Caps+C" "new window" "Caps+," "rename window"
row "Caps+0-9" "go to window" "Caps+N / P" "next / previous"
row "Caps+Tab" "last window" "Caps+F" "pick from a list"
row "Ctrl-a < >" "move window left / right" "right-click tab" "swap, rename, kill"

section "PANES     splits inside a window"
row "Caps+I" "split side by side" "Caps+-" "split stacked"
row "Caps+Arrow" "move between panes" "Caps+Shift+Arrow" "resize"
row "Caps+Z" "zoom on / off" "Caps+X / W" "kill (Enter confirms)"
row "Caps+B" "break pane to a new window" "Caps+J" "join a pane from elsewhere"
row "Caps+M" "move this pane to another window"

section "SCROLLBACK AND COPYING   the mouse works everywhere"
row "wheel" "scroll; bottom exits copy mode" "drag" "select + copy, view stays"
row "2x / 3x click" "copy word / line" "Cmd+V" "paste"
row "Esc or q" "leave copy mode" "Ctrl-a [" "copy mode: v select, y copy, / search"
row "Shift+drag" "Ghostty selects, bypassing tmux"

section "LINKS"
row "Cmd+click" "open a URL (Ghostty)" "Caps+U" "pick a URL from history"

section "STATUS BAR"
note "row 1  ⌂ local or ⇅ host badge and window tabs; badge, bar tint and active"
note "       pane border take the colour of the ssh host in focus"
note "row 3  ✦ claude sessions (⟳ working, ? waiting for you) / ◆ codex, hosts, 7d"
note "       limit for Claude and 5h + 7d for Codex, git branch, RAM"
note "files  ~/.config/tmux/hosts.local        <host> <accent> <tint> colour overrides"
note "       ~/.config/tmux/agent-hosts.local  ssh aliases to count agents on"

section "SESSION"
row "Caps+R" "reload tmux config" "Caps+H" "this sheet, q closes"
row "Ctrl-a d" "detach; Ghostty reattaches to main"
note "In an ssht pane the Caps chords drive the remote tmux; Caps+Space or"
note "Ctrl-a, then the key, still reaches this one."
printf '\n'
