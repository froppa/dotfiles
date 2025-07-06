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

defaults_write() {
  local domain=$1
  local key=$2
  local type=$3
  local value=$4

  if [[ "${AUDIT_MODE:-false}" == "true" ]]; then
    local current
    current=$(defaults read "$domain" "$key" 2>/dev/null || echo "<not set>")
    if [[ "$current" == "$value" ]]; then
      echo "✔ $domain $key is set to $value"
    else
      echo "✘ $domain $key is $current, expected $value"
    fi
  else
    case "$type" in
      bool) defaults write "$domain" "$key" -bool "$value" ;;
      int) defaults write "$domain" "$key" -int "$value" ;;
      float) defaults write "$domain" "$key" -float "$value" ;;
      string) defaults write "$domain" "$key" -string "$value" ;;
      *)
        echo "Unknown type '$type' for $domain $key"
        return 1
        ;;
    esac
  fi
}
