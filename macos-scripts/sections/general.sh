#!/usr/bin/env bash

# Hostname ---------------------------------------------------------------------
sudo scutil --set ComputerName "${COMPUTER_NAME}"
sudo scutil --set HostName "${COMPUTER_NAME}"
sudo scutil --set LocalHostName "${COMPUTER_NAME}"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "${COMPUTER_NAME}"
sudo defaults write /Library/Preferences/com.apple.timezone.auto Active -bool true
sudo nvram SystemAudioVolume=" "

# Locale / Language / Input ----------------------------------------------------
defaults write NSGlobalDomain AppleLanguages -array "${LANGUAGES[@]}"
set_or_audit NSGlobalDomain AppleLocale string "${LOCALE}"
set_or_audit NSGlobalDomain AppleMeasurementUnits string "${MEASUREMENT_UNITS}"
set_or_audit NSGlobalDomain AppleMetricUnits bool true

# UI / General -----------------------------------------------------------------
set_or_audit NSGlobalDomain AppleHighlightColor string "0.764700 0.976500 0.568600"
set_or_audit NSGlobalDomain AppleShowScrollBars string "Always"
set_or_audit NSGlobalDomain AppleShowAllExtensions bool true
set_or_audit NSGlobalDomain NSDocumentSaveNewDocumentsToCloud bool false
set_or_audit NSGlobalDomain NSDisableAutomaticTermination bool true
set_or_audit NSGlobalDomain NSNavPanelExpandedStateForSaveMode bool true
set_or_audit NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 bool true
set_or_audit NSGlobalDomain NSTableViewDefaultSizeMode int 2
set_or_audit NSGlobalDomain NSUseAnimatedFocusRing bool false
set_or_audit NSGlobalDomain NSWindowResizeTime float 0.001
set_or_audit com.apple.print.PrintingPrefs "Quit When Finished" bool true
set_or_audit com.apple.universalaccess reduceTransparency bool true

set_or_audit NSGlobalDomain AppleInterfaceStyle string "Dark"
set_or_audit NSGlobalDomain AppleShowScrollBars string "Automatic"
set_or_audit NSGlobalDomain AppleAccentColor int 6
set_or_audit NSGlobalDomain AppleHighlightColor string '0.847059 0.847059 0.862745 Purple'

set_or_audit NSGlobalDomain NSWindowResizeTime float 0.001
set_or_audit NSGlobalDomain NSDocumentSaveNewDocumentsToCloud bool false
set_or_audit NSGlobalDomain NSNavPanelExpandedStateForSaveMode bool true
set_or_audit NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 bool true
set_or_audit NSGlobalDomain PMPrintingExpandedStateForPrint bool true
set_or_audit NSGlobalDomain PMPrintingExpandedStateForPrint2 bool true

set_or_audit NSGlobalDomain AppleEnableMenuBarTransparency bool false
set_or_audit NSGlobalDomain AppleReduceMotion bool true

set_or_audit NSGlobalDomain AppleFontSmoothing int 1

# Crash / Help / Login ---------------------------------------------------------
set_or_audit com.apple.CrashReporter DialogType string none
set_or_audit com.apple.helpviewer DevMode bool true
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
