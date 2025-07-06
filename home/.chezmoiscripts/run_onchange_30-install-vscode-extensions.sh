#!/usr/bin/env bash
set -euo pipefail

vscode_cfg="${HOME}/code/dotfiles/home/.chezmoidata/vscode.yml"
installed=$(code --list-extensions)

while IFS= read -r extension; do
  if ! grep -qxF "$extension" <<< "$installed"; then
    echo "Installing $extension"
    code --install-extension "$extension" || echo "Failed to install $extension"
    sleep 1
  fi
done < <(yq -r '.extensions[]' "$vscode_cfg")
