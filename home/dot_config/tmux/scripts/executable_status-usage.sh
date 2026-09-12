#!/bin/sh
# Subscription limits for Claude Code (7-day only; the 5-hour window is on
# Claude Code's own status line) and Codex from their OAuth usage endpoints,
# shown as the percentage still available, cached 5 min. Tokens are read where the CLIs keep them (macOS
# Keychain or ~/.claude/.credentials.json; ~/.codex/auth.json) and never leave
# this machine except for the usage call itself. "--" = no token or no answer.

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux"
cache="$cache_dir/usage"

if [ -f "$cache" ] && find "$cache" -mmin -5 | grep -q .; then
  cat "$cache"
  exit 0
fi

claude_token() {
  if command -v security > /dev/null 2>&1; then
    security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null
  else
    cat "$HOME/.claude/.credentials.json" 2>/dev/null
  fi | jq -r '.claudeAiOauth.accessToken // empty'
}

# "<window seconds> <used percent>" pairs, one per line.
claude_windows() {
  token=$(claude_token)
  [ -n "$token" ] || return 1
  curl -sS -m 8 -H "Authorization: Bearer $token" -H 'anthropic-beta: oauth-2025-04-20' \
    https://api.anthropic.com/api/oauth/usage 2>/dev/null \
    | jq -r '[["604800", .seven_day]][] | select(.[1] != null) | "\(.[0]) \(.[1].utilization | floor)"'
}

codex_windows() {
  auth="$HOME/.codex/auth.json"
  [ -r "$auth" ] || return 1
  token=$(jq -r '.tokens.access_token // empty' "$auth")
  account=$(jq -r '.tokens.account_id // empty' "$auth")
  [ -n "$token" ] || return 1
  curl -sS -m 8 -H "Authorization: Bearer $token" -H "ChatGPT-Account-Id: $account" \
    https://chatgpt.com/backend-api/wham/usage 2>/dev/null \
    | jq -r '.rate_limit | [.primary_window, .secondary_window][] | select(. != null) | "\(.limit_window_seconds) \(.used_percent | floor)"'
}

# Colour by what is left, like the Claude Code status line.
colour() {
  if [ "$1" -ge 50 ]; then printf '#5faf5f'
  elif [ "$1" -ge 20 ]; then printf '#d7af5f'
  else printf '#d75f5f'; fi
}

# segment <icon with colour> <windows>
segment() {
  printf '%s' "$1"
  windows=$2
  [ -n "$windows" ] || { printf ' #[fg=#767676]--'; return; }
  printf '%s\n' "$windows" | while read -r seconds used; do
    case $seconds in
      18000) span=5h ;;
      604800) span=7d ;;
      *) span="$((seconds / 3600))h" ;;
    esac
    left=$((100 - used))
    printf ' #[fg=#767676]%s #[fg=%s]%s%%' "$span" "$(colour "$left")" "$left"
  done
}

mkdir -p "$cache_dir"
{
  segment '#[fg=#d7875f]✦' "$(claude_windows)"
  printf '  '
  segment '#[fg=#5fd7af]◆' "$(codex_windows)"
  printf '\n'
} > "$cache.$$"
mv -f "$cache.$$" "$cache"
cat "$cache"
