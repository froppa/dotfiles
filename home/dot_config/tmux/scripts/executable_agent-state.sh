#!/bin/sh
# Claude Code hook target: records what this session is doing so the tmux tab
# and the status segments can show it. States: working, idle (turn finished),
# input (waiting for a permission or question), off (session ended).
# The state lands in a per-session file under ~/.cache/agents (the hook runs
# as a child of the claude process, so $PPID is the session) and, inside tmux,
# on the pane as @agent_state.
# Usage: agent-state.sh <state>   (stdin, the hook JSON, is ignored)

cat > /dev/null
dir="${XDG_CACHE_HOME:-$HOME/.cache}/agents"
file="$dir/claude-$PPID"
if [ "$1" = off ]; then
  rm -f "$file"
else
  mkdir -p "$dir" && printf '%s\n' "$1" > "$file"
fi

[ -n "${TMUX_PANE:-}" ] || exit 0
# refresh-client -S redraws the status line at once instead of waiting for
# the next status-interval tick.
if [ "$1" = off ]; then
  tmux set -pu -t "$TMUX_PANE" @agent_state \; refresh-client -S 2> /dev/null
else
  tmux set -p -t "$TMUX_PANE" @agent_state "$1" \; refresh-client -S 2> /dev/null
fi
exit 0
