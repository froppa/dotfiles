#!/usr/bin/env bash

# Hostname ---------------------------------------------------------------------
if [[ "${AUDIT_MODE}" != "true" ]]; then
  sudo scutil --set ComputerName "${COMPUTER_NAME}"
  sudo scutil --set HostName "${COMPUTER_NAME}"
  sudo scutil --set LocalHostName "${COMPUTER_NAME}"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "${COMPUTER_NAME}"

  sudo defaults write /Library/Preferences/com.apple.timezone.auto Active -bool true
  sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo -string "HostName"
  # Disable boot sound
  sudo nvram SystemAudioVolume=" "
fi

# ---------------------------------------------------------------------
defaults write NSGlobalDomain AppleLanguages -array "${LANGUAGES[@]}"
defaults write NSGlobalDomain AppleLocale -string "${LOCALE}"
defaults write NSGlobalDomain AppleMeasurementUnits -string "${MEASUREMENT_UNITS:-"Centimeters"}"
defaults write NSGlobalDomain AppleMetricUnits -bool true

defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain AppleHighlightColor -string "0.847059 0.847059 0.862745 Purple"
defaults write NSGlobalDomain AppleAccentColor -int 6
defaults write NSGlobalDomain AppleShowScrollBars -string "Automatic"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2
defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write NSGlobalDomain AppleEnableMenuBarTransparency -bool false
defaults write NSGlobalDomain AppleReduceMotion -bool true
defaults write NSGlobalDomain AppleFontSmoothing -int 1

defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
defaults write com.apple.universalaccess reduceTransparency -bool true
defaults write com.apple.CrashReporter DialogType -string "none"
defaults write com.apple.helpviewer DevMode -bool true

