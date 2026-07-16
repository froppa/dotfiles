#!/usr/bin/env bash
set -euo pipefail

[[ "${OSTYPE}" != darwin* ]] && exit 0

# shellcheck disable=SC1091
source "./lib/funcs.sh"

AUDIT_MODE=${AUDIT_MODE:-false}
SKIP_UPDATE=false
SKIP_XCODE=false

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

if [[ "$AUDIT_MODE" != "true" ]]; then
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
fi

# Sections run as child processes; they rely on this being exported.
# (The audit-aware `defaults` shim is exported by lib/funcs.sh.)
export AUDIT_MODE

echo "=> Applying macOS defaults"
for section in ./sections/*.sh; do
  echo "==> ${section}"
  bash "${section}"
done

if [[ "$AUDIT_MODE" != "true" ]]; then
  killall Finder SystemUIServer &>/dev/null || true
fi
