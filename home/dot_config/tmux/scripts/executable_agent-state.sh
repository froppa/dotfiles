#!/bin/sh
# Claude Code hook target: records what this session is doing so the tmux tab,
# the status segments and the terminal tab title can show it. States:
# working, idle (turn finished), input (waiting for a permission or question),
# off (session ended).
#
# The state lands in a per-session file under ~/.cache/agents, named by the
# Claude session id so Verk can join it to the transcript it already lists:
# line 1 the state, line 2 the CLI's pid (the hook runs as a child of the
# claude process, so $PPID is the session), line 3 the working directory. It also goes on the tmux pane as
# @agent_state when inside tmux, and into the terminal tab title through the
# hook's JSON reply: Claude Code emits `terminalSequence` to the terminal on
# the hook's behalf (hooks have no terminal of their own).
# Usage: agent-state.sh <state>   (stdin is the hook JSON)

state=$1
input=$(cat)
event=$(printf '%s' "$input" | jq -r '.hook_event_name // empty' 2> /dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2> /dev/null)
session=$(printf '%s' "$input" | jq -r '.session_id // empty' 2> /dev/null)
dir="${XDG_CACHE_HOME:-$HOME/.cache}/agents"
file="$dir/claude-${session:-$PPID}"

if [ "$state" = off ]; then
  rm -f "$file"
else
  mkdir -p "$dir" && printf '%s\n%s\n%s\n' "$state" "$PPID" "$cwd" > "$file"
fi

if [ -n "${TMUX_PANE:-}" ]; then
  # refresh-client -S redraws the status line at once instead of waiting for
  # the next status-interval tick.
  if [ "$state" = off ]; then
    tmux set -pu -t "$TMUX_PANE" @agent_state \; refresh-client -S 2> /dev/null
  else
    tmux set -p -t "$TMUX_PANE" @agent_state "$state" \; refresh-client -S 2> /dev/null
  fi
fi

# Tab title: a state glyph and the working directory, e.g. "⟳ dotfiles".
# The sequence is OSC 0 (ESC ] 0 ; title BEL), spelled with jq escapes.
case $state in
  working) glyph='⟳' ;;
  input) glyph='?' ;;
  idle) glyph='·' ;;
  *) glyph='' ;;
esac
if [ -n "$event" ] && [ -n "$glyph" ]; then
  name=${cwd##*/}
  jq -cn --arg e "$event" --arg t "$glyph ${name:-claude}" \
    '{hookSpecificOutput: {hookEventName: $e, terminalSequence: ("\u001b]0;" + $t + "\u0007")}}'
fi
exit 0
