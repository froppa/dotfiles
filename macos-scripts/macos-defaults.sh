#!/usr/bin/env bash
set -euo pipefail

[[ "${OSTYPE}" != "darwin"* ]] && exit 0

# shellcheck disable=SC1091
source "./lib/funcs.sh"

AUDIT_MODE=${AUDIT_MODE:-false}
SKIP_UPDATE=false
SKIP_XCODE=false

usage() {
  cat <<EOF
Usage: run_macos_defaults.sh [options]

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

osascript -e 'tell application "System Settings" to quit'
keep_sudo_alive

if [[ "${SKIP_UPDATE}" != "true" ]]; then
  echo "=> Updating macOS"
  sudo softwareupdate -i -a
fi

if [[ "${SKIP_XCODE}" != "true" ]]; then
  if ! xcode-select -p &>/dev/null; then
    echo "=> 📦 Installing Xcode command line tools..."
    xcode-select --install
    until xcode-select -p &>/dev/null; do sleep 5; done
  fi
fi

echo "=> Applying macOS defaults"
audit_all true

killall Finder SystemUIServer &>/dev/null || true
