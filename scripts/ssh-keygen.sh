#!/usr/bin/env bash
set -euo pipefail

key="${HOME}/.ssh/id_ed25519"

read -rp "Create SSH key? (y/N) " -n 1
echo ""
[[ ${REPLY} =~ ^[Yy]$ ]] || exit 0

if [[ -f "${key}" ]]; then
  echo "SSH key already exists: ${key}" >&2
  exit 1
fi

read -rp "Email for SSH key [${USER}@$(hostname)]: " email
email="${email:-${USER}@$(hostname)}"

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

ssh-keygen -t ed25519 -C "$email" -f "${key}" -N ""

if [[ "${OSTYPE}" == "darwin"* ]]; then
  ssh-add --apple-use-keychain "${key}"
  echo "✅ SSH key generated and added to the agent via Keychain."
else
  echo "✅ SSH key generated. Add it to your agent with: ssh-add ${key}"
fi
