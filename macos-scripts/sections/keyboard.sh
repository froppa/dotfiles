#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# Keyboard repeat rate
# ---------------------------------------------------------------------------
defaults write NSGlobalDomain KeyRepeat        -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# ---------------------------------------------------------------------------
# Keyboard / Input tweaks
# ---------------------------------------------------------------------------
defaults write NSGlobalDomain AppleKeyboardUIMode              -int 3
defaults write NSGlobalDomain ApplePressAndHoldEnabled         -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled     -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled   -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled    -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled   -bool false

# Battery - show percentage (Control Center on modern macOS)
defaults write com.apple.controlcenter BatteryShowPercentage -bool true
