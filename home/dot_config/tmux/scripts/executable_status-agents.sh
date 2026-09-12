#!/bin/sh
# Running agent sessions: claude and codex CLI processes on this machine,
# plus the same counts over ssh for every alias listed one per line in the
# unmanaged ~/.config/tmux/agent-hosts.local (cached 60 s; "?" = unreachable).
# ✦ is Claude, ◆ is Codex, as on the window tabs.
# The ChatGPT desktop app's Codex threads are not visible as processes.

hosts_file="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/agent-hosts.local"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux"
# Claude Code re-execs its versioned binary, so the process name is "claude"
# or "2.1.270" depending on the session; match the start of the command line
# instead (anchored, or anything passing a claude path as an argument counts).
claude_pattern='^([^ ]*/)?claude( |$)|^[^ ]*/claude/versions/[0-9.]+( |$)'
# shellcheck disable=SC2016 # runs on the remote shell
remote_cmd="printf '%s %s' \"\$(pgrep -f '$claude_pattern' | wc -l | tr -d ' ')\" \"\$(pgrep -x codex | wc -l | tr -d ' ')\""

# Same icons and colours as the window tabs.
claude_icon='#[fg=#d7875f]✦'
codex_icon='#[fg=#5fd7af]◆'
value='#[fg=#d0d0d0]'

claude=$(pgrep -f "$claude_pattern" | wc -l | tr -d ' ')
codex=$(ps -axo comm=,args= | awk '
  { n = split($1, path, "/") }
  path[n] == "codex" && $0 !~ /app-server|sandbox|code-mode-host|mcp-server/ { count++ }
  END { print count + 0 }')

printf '%s %s%s  %s %s%s' "$claude_icon" "$value" "$claude" "$codex_icon" "$value" "$codex"

[ -r "$hosts_file" ] || { printf '\n'; exit 0; }
mkdir -p "$cache_dir"
while IFS= read -r host; do
  case $host in ''|'#'*) continue ;; esac
  cache="$cache_dir/agents-$host"
  if ! [ -f "$cache" ] || ! find "$cache" -mmin -1 | grep -q .; then
    ssh -o BatchMode=yes -o ConnectTimeout=3 -- "$host" "$remote_cmd" > "$cache.$$" 2>/dev/null \
      || printf '?' > "$cache.$$"
    mv -f "$cache.$$" "$cache"
  fi
  counts=$(cat "$cache")
  accent=$("$(dirname "$0")/status-context.sh" host "$host" color)
  case $counts in
    '?') printf '  #[fg=#767676]%s ?' "$host" ;;
    *) printf '  #[fg=%s]%s %s %s%s %s %s%s' "$accent" "$host" "$claude_icon" "$value" "${counts%% *}" "$codex_icon" "$value" "${counts##* }" ;;
  esac
done < "$hosts_file"
printf '\n'
