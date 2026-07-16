#!/usr/bin/env bash
set -euo pipefail

keep_sudo_alive() {
  sudo -v
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
}

# Shadows the real `defaults` for this process and all section children
# (exported below). In audit mode, `defaults write` becomes read-and-compare;
# everything else passes through untouched.
defaults() {
  if [[ "${AUDIT_MODE:-false}" != "true" || "$1" != "write" ]]; then
    command defaults "$@"
    return
  fi

  local domain=$2 key=$3 typeflag=$4
  shift 4
  local expected="$*"

  # defaults read prints booleans as 1/0
  if [[ "$typeflag" == "-bool" ]]; then
    case "$expected" in
      true) expected=1 ;;
      false) expected=0 ;;
    esac
  fi

  if [[ "$typeflag" == "-array" ]]; then
    local current_arr
    current_arr=$(command defaults read "$domain" "$key" 2>/dev/null | xargs)
    if [[ "$current_arr" == "$expected" ]]; then
      echo "✔ $domain $key = [$expected]"
    else
      echo "✘ $domain $key is [$current_arr], expected [$expected]"
    fi
  else
    local current
    current=$(command defaults read "$domain" "$key" 2>/dev/null || echo "<not set>")
    if [[ "$current" == "$expected" ]]; then
      echo "✔ $domain $key = $expected"
    else
      echo "✘ $domain $key is $current, expected $expected"
    fi
  fi
}
export -f defaults
