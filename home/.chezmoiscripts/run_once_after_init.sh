#!/bin/bash
set -euo pipefail

src="$HOME/.local/share/chezmoi/home/.chezmoitemplates/brewfile.yml"
dest="$HOME/.local/share/chezmoi/home/.chezmoidata/brewfile.yml"

[[ -f "$src" ]] || {
  echo "Missing: $src" >&2
  exit 1
}

chezmoi execute-template < "$src" > "$dest"
