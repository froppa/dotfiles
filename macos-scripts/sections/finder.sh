#!/usr/bin/env bash

# Finder -----------------------------------------------------------------------
set_or_audit com.apple.finder AppleShowAllFiles bool true
set_or_audit com.apple.finder DisableAllAnimations bool true
set_or_audit com.apple.finder FXDefaultSearchScope string "SCcf"
set_or_audit com.apple.finder FXEnableExtensionChangeWarning bool false
defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true Privileges -bool true
set_or_audit com.apple.finder FXPreferredViewStyle string "Nlsv"
set_or_audit com.apple.finder NewWindowTarget string "PfLo"
set_or_audit com.apple.finder NewWindowTargetPath string "file://${HOME}"
set_or_audit com.apple.finder QuitMenuItem bool true
set_or_audit com.apple.finder ShowPathbar bool true
set_or_audit com.apple.finder ShowStatusBar bool true
set_or_audit com.apple.finder WarnOnEmptyTrash bool false
set_or_audit com.apple.finder _FXShowPosixPathInTitle bool true
set_or_audit com.apple.finder _FXSortFoldersFirst bool true
set_or_audit com.apple.finder OpenWindowForNewRemovableDisk bool true
set_or_audit NSGlobalDomain com.apple.springing.delay float 0
set_or_audit NSGlobalDomain com.apple.springing.enabled bool true

# Desktop / IconView -----------------------------------------------------------
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist

# Disk Images ------------------------------------------------------------------
set_or_audit com.apple.frameworks.diskimages auto-open-ro-root bool true
set_or_audit com.apple.frameworks.diskimages auto-open-rw-root bool true
set_or_audit com.apple.frameworks.diskimages skip-verify bool true
set_or_audit com.apple.frameworks.diskimages skip-verify-locked bool true
set_or_audit com.apple.frameworks.diskimages skip-verify-remote bool true
