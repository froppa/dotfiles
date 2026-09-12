#!/bin/sh
# SwiftBar menu bar item: Claude and Codex sessions, how many are working or
# waiting for you, and the remaining limits. Reuses the tmux status scripts
# and their caches; the file name sets the 10 s refresh.
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

scripts="$HOME/.config/tmux/scripts"
agents_dir="${XDG_CACHE_HOME:-$HOME/.cache}/agents"
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

plain() { sed 's/#\[[^]]*\]//g'; }
agents=$("$scripts/status-agents.sh" 2> /dev/null | plain)
limits=$("$scripts/status-usage.sh" 2> /dev/null | plain)

# Menu bar title: local counts and the Claude 7d figure.
claude_part=${agents%%  ◆*}
claude_7d=$(printf '%s' "$limits" | sed -n 's/^✦ 7d \([0-9]*%\).*/\1/p')
printf '%s%s | font=Menlo size=12\n' "$claude_part" "${claude_7d:+ · $claude_7d}"
echo '---'

echo "Sessions | size=11 color=gray"
printf '%s | font=Menlo\n' "$agents"
for f in "$agents_dir"/claude-*; do
  [ -f "$f" ] || continue
  pid=${f##*claude-}
  kill -0 "$pid" 2> /dev/null || continue
  state=$(cat "$f")
  cwd=$(lsof -a -p "$pid" -d cwd -Fn 2> /dev/null | sed -n 's/^n//p')
  case $state in
    working) mark='⟳'; colour='#d7875f' ;;
    input) mark='?'; colour='#d7af5f' ;;
    *) mark='·'; colour='gray' ;;
  esac
  printf '%s %s %s | font=Menlo color=%s\n' "$mark" "${cwd##*/}" "$state" "$colour"
done
echo '---'
echo "Limits left | size=11 color=gray"
printf '%s | font=Menlo\n' "$limits"
echo '---'
echo "Refresh | refresh=true"
