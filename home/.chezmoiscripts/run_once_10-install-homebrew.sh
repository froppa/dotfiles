#!/usr/bin/env bash

if ! command -v brew &>/dev/null; then
  echo "=> Homebrew installing..."
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 1
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || true)"
fi

echo "=> Disabling analytics..."
brew analytics off

brew update
brew upgrade
