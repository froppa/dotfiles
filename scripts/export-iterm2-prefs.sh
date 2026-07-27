#!/usr/bin/env bash
set -euo pipefail

[[ "${OSTYPE}" != darwin* ]] && exit 0

# Export straight into the chezmoi source so `chezmoi diff` stays clean and
# the change can be committed. Applying deploys it to ~/.config/iterm2.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PLIST="${SCRIPT_DIR}/../home/dot_config/iterm2/com.googlecode.iterm2.plist"

defaults export com.googlecode.iterm2 "${SOURCE_PLIST}"
plutil -convert xml1 "${SOURCE_PLIST}"

echo "Exported iTerm2 preferences to ${SOURCE_PLIST}"
echo "Run 'chezmoi apply' to sync ~/.config/iterm2, then commit the change."
