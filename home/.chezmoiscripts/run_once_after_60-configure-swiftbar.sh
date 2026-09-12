#!/usr/bin/env bash
set -euo pipefail

# Point SwiftBar at the managed plugin directory. Once per machine; SwiftBar
# is a macOS cask, so other platforms skip.
[[ "$(uname -s)" == "Darwin" ]] || exit 0
command -v defaults >/dev/null 2>&1 || exit 0

defaults write com.ameba.SwiftBar PluginDirectory -string "${HOME}/.config/swiftbar"
echo "=> SwiftBar plugin directory set to ~/.config/swiftbar"
