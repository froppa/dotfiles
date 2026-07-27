#!/usr/bin/env bash
set -euo pipefail

vim +PlugInstall +qall || echo "⚠️ Some Vim plugins may have failed to install"

echo "✅ Vim configured."
