#!/usr/bin/env bash
set -euo pipefail

key="${1:-${HOME}/.ssh/id_ed25519}"
age_identity="${HOME}/.config/sops/age/keys.txt"

[[ -f "${key}" ]] || {
  echo "SSH private key not found: ${key}" >&2
  exit 1
}

command -v chezmoi >/dev/null 2>&1 || {
  echo "chezmoi is required" >&2
  exit 1
}

[[ -f "${age_identity}" ]] || {
  echo "Restore the age identity first: ${age_identity}" >&2
  echo "It is required for future full chezmoi applies." >&2
  exit 1
}

chmod 600 "${key}"
chezmoi add --encrypt "${key}"

if [[ -f "${key}.pub" ]]; then
  chmod 644 "${key}.pub"
  chezmoi add "${key}.pub"
fi

echo "SSH key imported into Chezmoi's encrypted source state."
echo "Review and commit the source repository before relying on it as backup."
