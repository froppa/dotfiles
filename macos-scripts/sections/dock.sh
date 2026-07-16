#!/usr/bin/env bash
set -eufo pipefail

AUDIT_MODE="${AUDIT_MODE:-false}"

use_dockutil=false
if [[ "$AUDIT_MODE" != "true" ]] && command -v dockutil >/dev/null 2>&1; then
  use_dockutil=true
fi

# Kill Dock after everything (skip when auditing)
if [[ "$AUDIT_MODE" != "true" ]]; then
  trap 'killall Dock' EXIT
fi

# ------------------------------------------------------------------------
# Remove default apps from Dock
# ------------------------------------------------------------------------
remove_labels=(
  Launchpad Safari Messages Mail Maps Photos FaceTime Calendar
  Contacts Reminders Notes Freeform TV Music Keynote Numbers Pages
  "App Store"
)

if $use_dockutil; then
  for label in "${remove_labels[@]}"; do
    dockutil --no-restart --remove "${label}" || true
  done
fi

# ------------------------------------------------------------------------
# Dock UI / behavior settings
# ------------------------------------------------------------------------
defaults write com.apple.dock mouse-over-hilite-stack -bool true
defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock mineffect -string scale
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock expose-group-by-app -bool false
defaults write com.apple.dashboard mcx-disabled -bool true
defaults write com.apple.dock dashboard-in-overlay -bool true
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock showhidden -bool true
defaults write com.apple.dock show-recents -bool false

# ------------------------------------------------------------------------
# Hot corners
# tl = top-left, tr = top-right, bl = bottom-left, br = bottom-right
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center
# 13: Lock Screen
# ------------------------------------------------------------------------
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tl-modifier -int 0
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-bl-corner -int 11
defaults write com.apple.dock wvous-bl-modifier -int 0

# ------------------------------------------------------------------------
# Add custom apps to Dock
# ------------------------------------------------------------------------
wanted_dock_apps=(
  "/Applications/Google Chrome.app"
  "/System/Applications/Calendar.app"
  "/System/Applications/System Settings.app"
  "/Applications/Spotify.app"
)

if $use_dockutil; then
  for app in "${wanted_dock_apps[@]}"; do
    [[ -d "$app" ]] || continue
    dockutil --no-restart --add "${app}"
  done
fi
