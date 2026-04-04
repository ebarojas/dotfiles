#!/usr/bin/env bash
set -euo pipefail

# 1) Show all files (including hidden files)
defaults write com.apple.finder AppleShowAllFiles -bool true

# 2) Show Mac hard drive on Desktop
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true

# 3) Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# 4a/4b/4c) Menu bar clock: seconds + 24h + flashing separators
# DateFormat: HH = 24h, ss = seconds
# This did not work...
defaults write com.apple.menuextra.clock IsAnalog -bool false
defaults write com.apple.menuextra.clock DateFormat -string "HH:mm:ss"
defaults write com.apple.menuextra.clock FlashDateSeparators -bool true

# 4d) Show Sound in menu bar (Control Center)
# On newer macOS, -int 18 is the common value for "always show"
defaults -currentHost write com.apple.controlcenter Sound -int 18

# 4e) Show Input menu in menu bar (lets you access Emoji & Symbols from menu bar)
# Note: this icon is especially useful/visible when you have multiple input sources enabled
defaults write com.apple.TextInputMenu visible -bool true

# 5) Auto hide dock
# WIP

# 6) Automatically rearrange spaces recent use = False

# 5) Text replacement:
# replace "shrug_emoji;" -> "¯\_(ツ)_/¯"
defaults write -g NSUserDictionaryReplacementItems -array-add '{on=1;replace="shrug_emoji;";with="¯\\_(ツ)_/¯";}'

# Restart affected UI processes
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
killall ControlCenter 2>/dev/null || true

echo "Done. Some changes may require logging out/in (especially menu bar/input items)."

