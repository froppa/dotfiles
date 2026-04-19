#!/usr/bin/env bash
set -euo pipefail

command -v nvim >/dev/null 2>&1 || exit 0
[[ -d "${HOME}/.config/nvim" ]] || exit 0

nvim --headless "+Lazy! sync" +qa || echo "⚠️ LazyVim plugin sync reported issues"

echo "ℹ️ Open nvim once to finish Mason and tree-sitter installs."
