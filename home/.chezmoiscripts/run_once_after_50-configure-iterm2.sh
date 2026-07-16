#!/bin/bash
set -euo pipefail
[[ "${OSTYPE}" != darwin* ]] && exit 0

PREFS_CUSTOM_FOLDER="${HOME}/.config/iterm2"

defaults write com.googlecode.iterm2 PrefsCustomFolder -string "${PREFS_CUSTOM_FOLDER}"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

echo "iTerm2 configured to load prefs from ${PREFS_CUSTOM_FOLDER}"
