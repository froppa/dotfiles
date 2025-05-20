#!/usr/bin/env bash
set -euo pipefail

read -rp "Create SSH key? (y/N) " -n 1
echo ""
[[ ${REPLY} =~ ^[Yy]$ ]] || exit 0

read -rp "Email for SSH key [${USER}@$(hostname)]: " email
email="${email:-${USER}@$(hostname)}"

ssh-keygen -t ed25519 -C "$email" -f "${HOME}/.ssh/id_ed25519" -N ""

if [[ "${OSTYPE}" == "darwin"* ]]; then
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519
else
  eval "$(ssh-agent -s || true)"
  ssh-add ~/.ssh/id_ed25519
fi

echo "✅ SSH key generated and agent configured."
