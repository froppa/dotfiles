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

echo "✅ SSH key generated. SSH will add it to the configured agent on first use."
