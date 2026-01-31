#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ "${OSTYPE}" != darwin* ]] && exit 0

# shellcheck disable=SC1091
source "${DIR}/lib/funcs.sh"

AUDIT_MODE=${AUDIT_MODE:-false}
SKIP_UPDATE=false
SKIP_XCODE=false

# Default variables for sections
COMPUTER_NAME="${COMPUTER_NAME:-froppa-mac}"
LANGUAGES=("${LANGUAGES[@]:-"en"}")
LOCALE="${LOCALE:-en_US}"
MEASUREMENT_UNITS="${MEASUREMENT_UNITS:-Centimeters}"

usage() {
  cat <<EOF
Usage: $0 [options]
Options:
  --audit              Audit current system state against desired configuration
  --skip-update        Skip macOS software updates
  --skip-xcode         Skip Xcode CLI tools check/install
EOF
  exit 0
}

for arg in "$@"; do
  case "${arg}" in
    --audit) AUDIT_MODE=true ;;
    --skip-update) SKIP_UPDATE=true ;;
    --skip-xcode) SKIP_XCODE=true ;;
    *) usage ;;
  esac
done

osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true
keep_sudo_alive

$SKIP_UPDATE || {
  echo "=> Updating macOS"
  sudo softwareupdate -i -a
}

$SKIP_XCODE || {
  if ! xcode-select -p &>/dev/null; then
    echo "=> Installing Xcode command line tools..."
    xcode-select --install
    until xcode-select -p &>/dev/null; do sleep 5; done
  fi
}

if [[ "$AUDIT_MODE" == "true" ]]; then
  function defaults() {
    if [[ "$1" == "write" ]]; then
      local domain=$2 key=$3 typeflag=$4
      shift 4
      local current
      current=$(command defaults read "$domain" "$key" 2>/dev/null || echo "<not set>")
      local expected="$*"
      if [[ "$typeflag" == "-array" ]]; then
        local current_arr
        current_arr=$(command defaults read "$domain" "$key" 2>/dev/null | xargs)
        if [[ "$current_arr" == "$expected" ]]; then
          echo "✔ $domain $key = [$expected]"
        else
          echo "✘ $domain $key is [$current_arr], expected [$expected]"
        fi
      else
        if [[ "$current" == "$expected" ]]; then
          echo "✔ $domain $key = $expected"
        else
          echo "✘ $domain $key is $current, expected $expected"
        fi
      fi
    fi
  }
fi

echo "=> Applying macOS defaults"
# shellcheck disable=SC1090,SC1091
source "${DIR}/sections/general.sh"
# shellcheck disable=SC1090,SC1091
source "${DIR}/sections/finder.sh"
# source "${DIR}/sections/dock.sh"

killall Finder SystemUIServer &>/dev/null || true
