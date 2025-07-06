#!/usr/bin/env bash
set -euo pipefail

brewfile="$HOME/.local/share/chezmoi/.chezmoidata/brewfile.yml"
[[ -f "$brewfile" ]] || exit 0

echo "=> Installing packages from $brewfile..."

temp_brewfile=$(mktemp --suffix=.Brewfile)
trap 'rm -f "$temp_brewfile"' EXIT

yq -r '.brew[]  | "brew \\"" + . + "\\"" ' "$brewfile" >> "$temp_brewfile"
yq -r '.cask[]  | "cask \\"" + . + "\\"" ' "$brewfile" >> "$temp_brewfile"

brew bundle --file="$temp_brewfile"
brew cleanup