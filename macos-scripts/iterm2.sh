#!/usr/bin/env bash
set -euo pipefail

[[ "${OSTYPE}" != darwin* ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE_PLIST="${SCRIPT_DIR}/com.googlecode.iterm2.plist"
PREFS_CUSTOM_FOLDER="${HOME}/.config/iterm2"

mkdir -p "${PREFS_CUSTOM_FOLDER}"

export_iterm2_prefs() {
  defaults export com.googlecode.iterm2 "${CONFIG_FILE_PLIST}"
}

convert_to_xml() {
  plutil -convert xml1 "${CONFIG_FILE_PLIST}"
}

export_iterm2_prefs
convert_to_xml

cp -p "${CONFIG_FILE_PLIST}" "${PREFS_CUSTOM_FOLDER}/"

defaults write com.googlecode.iterm2 PrefsCustomFolder -string "${PREFS_CUSTOM_FOLDER}"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

echo "✅ iTerm2 configured to load from ${PREFS_CUSTOM_FOLDER}"
