#!/bin/bash
set -euo pipefail
[[ "${OSTYPE}" != darwin* ]] && exit 0

CHEZMOI_SOURCE="$HOME/.local/share/chezmoi/home"

src="${CHEZMOI_SOURCE}/.chezmoitemplates/brewfile.yml"
dest="${CHEZMOI_SOURCE}/.chezmoidata/brewfile.yml"

[[ -f "$src" ]] || {
  echo "Missing: $src" >&2
  exit 1
}

chezmoi execute-template < "$src" > "$dest"

PREFS_CUSTOM_FOLDER="${HOME}/.config/iterm2"

defaults write com.googlecode.iterm2 PrefsCustomFolder -string "${PREFS_CUSTOM_FOLDER}"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

echo "iTerm2 configured to load prefs from ${PREFS_CUSTOM_FOLDER}"
