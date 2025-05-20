#!/bin/bash
set -eou

vscode_cfg="${HOME}/code/dotfiles/home//.chezmoidata/vscode.yml"
extensions=$(yq '.extensions[]' "${vscode_cfg}")
installed=$(code --list-extensions)

for extension in ${extensions}; do
  if ! grep -qx "${extension}" <<<"${installed}"; then
    code --force --install-extension "${extension}"
  fi
done
