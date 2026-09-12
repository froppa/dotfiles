#!/usr/bin/env bash
set -euo pipefail

# Ubuntu uses apt; never install or update Linuxbrew during bootstrap.
[[ "$(uname -s)" == Darwin ]] || exit 0

if ! command -v brew &>/dev/null; then
  echo "=> Homebrew installing..."
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  for brew_bin in \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "${brew_bin}" ]]; then
      eval "$("${brew_bin}" shellenv)"
      break
    fi
  done
fi

command -v brew >/dev/null 2>&1 || {
  echo "Homebrew installed but brew is not available on PATH" >&2
  exit 1
}

echo "=> Disabling analytics..."
brew analytics off

brew update
brew upgrade
