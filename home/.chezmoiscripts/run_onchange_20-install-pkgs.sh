#!/usr/bin/env bash
set -euo pipefail

echo "=> Disabling analytics..."
brew analytics off

brew update
brew upgrade

brewfile="${HOME}/code/dotfiles/.chezmoidata/brewfile.yml"
[[ -f "${brewfile}" ]] || exit 0

echo "=> Installing packages from .chezmoidata/brewfile.yml..."

# Generate Brewfile format from YAML
generate_brewfile() {
  yq -r '.tap[]   | "tap \"" + . + "\""' "${brewfile}"
  yq -r '.brew[]  | "brew \"" + . + "\""' "${brewfile}"
  yq -r '.cask[]  | "cask \"" + . + "\""' "${brewfile}"
}

temp_brewfile="$(mktemp)"
generate_brewfile >"${temp_brewfile}"
brew bundle --file="${temp_brewfile}"

echo "=> Cleaning up..."
brew cleanup

rm "${temp_brewfile}"
