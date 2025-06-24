#!/bin/bash
set -eou

# TODO: fix hardcoded path
vscode_cfg="~/.local/share/chezmoi/home/.chezmoidata/vscode.yml"
extensions=$(yq '.extensions[]' "${vscode_cfg}")
installed=$(code --list-extensions)

for extension in ${extensions}; do
  if ! grep -qx "${extension}" <<<"${installed}"; then
    code --force --install-extension "${extension}"
  fi
done
