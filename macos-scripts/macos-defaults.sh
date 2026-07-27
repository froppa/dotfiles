#!/usr/bin/env bash
set -euo pipefail

[[ "${OSTYPE}" != darwin* ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/funcs.sh"

AUDIT_MODE=${AUDIT_MODE:-false}
RUN_UPDATE=false
SKIP_XCODE=false

usage() {
  cat <<EOF
Usage: $0 [options]
Options:
  --audit              Audit current system state against desired configuration
  --update             Install all macOS software updates first (may restart)
  --skip-xcode         Skip Xcode CLI tools check/install
  -h, --help           Show this help
EOF
}

for arg in "$@"; do
  case "${arg}" in
    --audit) AUDIT_MODE=true ;;
    --update) RUN_UPDATE=true ;;
    --skip-xcode) SKIP_XCODE=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

if [[ "$AUDIT_MODE" != "true" ]]; then
  keep_sudo_alive

  if [[ "$RUN_UPDATE" == "true" ]]; then
    echo "=> Updating macOS"
    sudo softwareupdate -i -a
  fi

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
for section in "${SCRIPT_DIR}"/sections/*.sh; do
  echo "==> ${section}"
  bash "${section}"
done

if [[ "$AUDIT_MODE" != "true" ]]; then
  # Flush the preference cache so direct plist edits (PlistBuddy) survive,
  # then restart the affected apps.
  killall cfprefsd Finder SystemUIServer &>/dev/null || true
fi
