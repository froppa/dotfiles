#!/usr/bin/env bash
set -euo pipefail

command -v nvim >/dev/null 2>&1 || exit 0
[[ -d "${HOME}/.config/nvim" ]] || exit 0

nvim --headless "+Lazy! sync" +qa || echo "⚠️ Some Neovim plugins may have failed to install"

echo "✅ Neovim configured."
