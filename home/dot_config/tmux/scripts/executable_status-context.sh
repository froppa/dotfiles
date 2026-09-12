#!/bin/sh
# Where the pane's foreground process runs: local, an ssh destination, or the
# host tmux itself runs on when it was started over ssh. Every host gets a
# stable colour derived from its name; the unmanaged ~/.config/tmux/hosts.local
# overrides it with lines of "<host> <accent> <bar-tint>" (hex colours).
#
# Usage: status-context.sh <pane_pid> <pane_current_command> <mode> [window_name] [agent_state]
#        status-context.sh host <name> <mode>
#   badge  status-left badge; also publishes @ctx_color/@ctx_tint for styles
#   tab    window label: the window name (with an icon for a claude or codex
#          pane, coloured by the state agent-state.sh recorded: orange working,
#          yellow waiting for input, grey idle), or the coloured host for ssh
#          panes
#   color  the accent colour only

pid=$1
cmd=$2
mode=${3:-badge}
name=$4
state=$5
overrides="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/hosts.local"

local_accent='#5f87d7'
local_tint='#1c1c1c'
accents='#5faf5f #d75fd7 #d7af5f #5fd7d7 #ff8700 #d75f5f'
tints='#1c2a1c #2a1c2a #2a261c #1c2a2a #2a221c #2a1c1c'

# Destination of the ssh process under the pane's shell (one wrapper level deep).
ssh_destination() {
  ssh_pid=$(pgrep -P "$1" -x ssh | head -n 1)
  if [ -z "$ssh_pid" ]; then
    for child in $(pgrep -P "$1"); do
      ssh_pid=$(pgrep -P "$child" -x ssh | head -n 1)
      [ -n "$ssh_pid" ] && break
    done
  fi
  [ -n "$ssh_pid" ] || return 1
  args=$(ps -o args= -p "$ssh_pid" 2>/dev/null)
  # shellcheck disable=SC2086 # word splitting turns the args back into words
  set -- $args
  shift
  while [ $# -gt 0 ]; do
    case $1 in
      -[bcDEeFIiJLlmOopQRSWwB]) shift 2 ;;
      -*) shift ;;
      *)
        dest=${1#ssh://}
        dest=${dest#*@}
        printf '%s\n' "${dest%%:*}"
        return 0
        ;;
    esac
  done
  return 1
}

# Index into the palettes: cksum of the name modulo palette size.
nth() {
  index=$2
  # shellcheck disable=SC2086
  set -- $1
  shift "$index"
  printf '%s\n' "$1"
}

if [ "$pid" = host ]; then
  host=$cmd
  mode=${3:-color}
else
  host=''
  [ "$cmd" = ssh ] && host=$(ssh_destination "$pid")
  [ -z "$host" ] && [ -n "${SSH_CONNECTION:-}${SSH_TTY:-}" ] && host=$(hostname -s)
fi

if [ -z "$host" ]; then
  accent=$local_accent
  tint=$local_tint
else
  override=$([ -r "$overrides" ] && awk -v h="$host" '$1 == h { print $2, $3; exit }' "$overrides")
  if [ -n "$override" ]; then
    accent=${override%% *}
    tint=${override#* }
    [ "$tint" = "$accent" ] && tint=$local_tint
  else
    index=$(( $(printf '%s' "$host" | cksum | cut -d ' ' -f 1) % 6 ))
    accent=$(nth "$accents" "$index")
    tint=$(nth "$tints" "$index")
  fi
fi

case $mode in
  color)
    printf '%s\n' "$accent"
    ;;
  tab)
    if [ -z "$host" ]; then
      # tmux reports Claude's versioned binary ("2.1.270") as the command and
      # the process name varies with how it was started, so match the shell's
      # children by command line.
      agent=''
      case $cmd in
        claude|[0-9]*.[0-9]*.[0-9]*) agent=claude ;;
        codex) agent=codex ;;
        *)
          if pgrep -P "$pid" -f '^([^ ]*/)?claude( |$)|^[^ ]*/claude/versions/[0-9.]+( |$)' > /dev/null 2>&1; then agent=claude
          elif pgrep -P "$pid" -x codex > /dev/null 2>&1; then agent=codex
          fi
          ;;
      esac
      case $agent in
        claude) icon='✦'; colour='#d7875f' ;;
        codex) icon='◆'; colour='#5fd7af' ;;
        *) printf '%s\n' "$name"; exit 0 ;;
      esac
      case $state in
        input) icon="$icon?"; colour='#d7af5f' ;;
        idle) colour='#767676' ;;
      esac
      printf '#[fg=%s]%s %s#[default]\n' "$colour" "$icon" "$name"
    else
      printf '#[fg=%s,bold]⇅ %s#[default]\n' "$accent" "$host"
    fi
    ;;
  *)
    if [ -z "$host" ]; then
      printf '#[bg=#303030,fg=#87afff,bold] ⌂ local #[default]\n'
    else
      printf '#[bg=%s,fg=#000000,bold] ⇅ %s #[default]\n' "$accent" "$host"
    fi
    # Styles cannot run commands, so publish the colours for them.
    if [ "$(tmux show -gqv @ctx_color)" != "$accent" ]; then
      tmux set -g @ctx_color "$accent" \; set -g @ctx_tint "$tint"
    fi
    ;;
esac
