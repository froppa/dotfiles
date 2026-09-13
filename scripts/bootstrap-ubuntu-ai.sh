#!/usr/bin/env bash
# Native Ubuntu agent tools; authenticate as the normal user after installation.
set -euo pipefail

[[ $EUID -ne 0 ]] || { echo "Run as your normal Ubuntu user, not root." >&2; exit 1; }
[[ -r /etc/os-release ]] || { echo "Ubuntu is required." >&2; exit 1; }
# shellcheck disable=SC1091
source /etc/os-release
[[ "$ID" == ubuntu && "$VERSION_ID" == 26.04 ]] || {
  echo "This bootstrap is validated for Ubuntu 26.04." >&2; exit 1;
}

sudo apt-get update
sudo apt-get install -y --no-install-recommends curl gnupg ca-certificates software-properties-common
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
curl -fsSL https://downloads.claude.ai/keys/claude-code.asc -o "$scratch/claude-code.asc"
fingerprint=$(gpg --show-keys --with-colons "$scratch/claude-code.asc" 2>/dev/null | awk -F: '$1 == "fpr" {print $10; exit}')
[[ "$fingerprint" == 31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE ]] || {
  echo "Unexpected Claude signing key; no repository was trusted." >&2; exit 1;
}
sudo install -d -m 0755 /etc/apt/keyrings
sudo install -m 0644 "$scratch/claude-code.asc" /etc/apt/keyrings/claude-code.asc
printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main' |
  sudo tee /etc/apt/sources.list.d/claude-code.list >/dev/null
sudo add-apt-repository -y --no-update ppa:jdxcode/mise
sudo apt-get update
sudo apt-get install -y --no-install-recommends claude-code mise

# Codex publishes a standalone Linux installer, not an apt package.
export PATH="$HOME/.local/bin:$PATH"
curl -fsSL https://chatgpt.com/codex/install.sh -o "$scratch/install-codex.sh"
CODEX_NON_INTERACTIVE=1 sh "$scratch/install-codex.sh" --release 0.154.0
codex --version
claude --version
mise --version
printf '%s\n' 'Authenticate freshly: codex login; claude auth login; gh auth login --web'
