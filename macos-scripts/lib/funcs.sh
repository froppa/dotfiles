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

  # Compound writes (-dict, -data, multi-pair values) can't be compared
  # against `defaults read` output reliably; report them as skipped.
  case "$typeflag" in
    -array)
      local current_arr expected_arr
      current_arr=$(command defaults read "$domain" "$key" 2>/dev/null \
        | tr -d '(),"' | tr -s '[:space:]' '\n' | sed '/^$/d' | sort)
      expected_arr=$(printf '%s\n' "$@" | sort)
      if [[ "$current_arr" == "$expected_arr" ]]; then
        echo "✔ $domain $key = [$*]"
      else
        echo "✘ $domain $key is [$(echo "$current_arr" | xargs)], expected [$*]"
      fi
      return
      ;;
    -bool|-int|-float|-string)
      if [[ $# -gt 1 ]]; then
        echo "– $domain $key skipped (compound value)"
        return
      fi
      ;;
    *)
      echo "– $domain $key skipped (compound type $typeflag)"
      return
      ;;
  esac

  local expected="$1"

  # defaults read prints booleans as 1/0
  if [[ "$typeflag" == "-bool" ]]; then
    case "$expected" in
      true) expected=1 ;;
      false) expected=0 ;;
    esac
  fi

  local current
  current=$(command defaults read "$domain" "$key" 2>/dev/null || echo "<not set>")
  if [[ "$current" == "$expected" ]]; then
    echo "✔ $domain $key = $expected"
  else
    echo "✘ $domain $key is $current, expected $expected"
  fi
}
export -f defaults
