#!/bin/sh
# Claude Code hook target: records what the session in this tmux pane is doing
# so the window tab can show it. States: working, idle (turn finished),
# input (waiting for a permission or question), off (session ended).
# Usage: agent-state.sh <state>   (stdin, the hook JSON, is ignored)

[ -n "${TMUX_PANE:-}" ] || exit 0
cat > /dev/null
if [ "$1" = off ]; then
  tmux set -pu -t "$TMUX_PANE" @agent_state 2> /dev/null
else
  tmux set -p -t "$TMUX_PANE" @agent_state "$1" 2> /dev/null
fi
exit 0
