#!/usr/bin/env bash
set -eufo pipefail

trap 'killall Dock' EXIT

declare -a remove_labels=(
  Launchpad
  Safari
  Messages
  Mail
  Maps
  Photos
  FaceTime
  Calendar
  Contacts
  Reminders
  Notes
  Freeform
  TV
  Music
  Keynote
  Numbers
  Pages
  "App Store"
)

for label in "${remove_labels[@]}"; do
  dockutil --no-restart --remove "${label}" || true
done

declare -a dock_settings=(
  "com.apple.dock mouse-over-hilite-stack -bool true"
  "com.apple.dock tilesize -int 36"
  "com.apple.dock mineffect -string scale"
  "com.apple.dock minimize-to-application -bool true"
  "com.apple.dock enable-spring-load-actions-on-all-items -bool true"
  "com.apple.dock show-process-indicators -bool true"
  "com.apple.dock launchanim -bool false"
  "com.apple.dock expose-animation-duration -float 0.1"
  "com.apple.dock expose-group-by-app -bool false"
  "com.apple.dashboard mcx-disabled -bool true"
  "com.apple.dock dashboard-in-overlay -bool true"
  "com.apple.dock mru-spaces -bool false"
  "com.apple.dock autohide-delay -float 0"
  "com.apple.dock autohide-time-modifier -float 0"
  "com.apple.dock autohide -bool true"
  "com.apple.dock showhidden -bool true"
  "com.apple.dock show-recents -bool false"
)

for setting in "${dock_settings[@]}"; do defaults write "${setting}"; done

# Hot corners
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

declare -a dock_hot_corners=(_
  "com.apple.dock wvous-tl-corner -int 0"
  "com.apple.dock wvous-tl-modifier -int 0"
  "com.apple.dock wvous-tr-corner -int 0"
  "com.apple.dock wvous-tr-modifier -int 0"
  "com.apple.dock wvous-bl-corner -int 11"
  "com.apple.dock wvous-bl-modifier -int 0"
)

for setting in "${dock_hot_corners[@]}"; do defaults write "${setting}"; done

declare -a wanted_dock_apps=(
  "/Applications/Google Chrome.app"
  "/System/Applications/Mail.app"
  "/System/Applications/Calendar.app"
  "/System/Applications/Utilities/Terminal.app"
  "/System/Applications/System Settings.app"
  "/Applications/Spotify.app"
)

for app in "${wanted_dock_apps[@]}"; do
  dockutil --no-restart --add "${app}"
done
