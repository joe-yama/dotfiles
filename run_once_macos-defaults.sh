#!/usr/bin/env bash

# Close System Preferences to prevent overriding
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

echo "Applying macOS defaults..."

# Keyboard
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Finder
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-recents -bool false

# Screenshots
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# Trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Mission Control
defaults write com.apple.dock mru-spaces -bool false

# TextEdit
defaults write com.apple.TextEdit RichText -int 0

# Menu bar — auto-hide (System Settings → Control Center → Automatically hide and show)
defaults write NSGlobalDomain _HIHideMenuBar -bool true
defaults write com.apple.controlcenter AutoHideMenuBarOption -int 0

# Login items — apps to auto-launch at login
ensure_login_item() {
  local app_path="$1"
  local app_name
  app_name="$(basename "$app_path" .app)"
  if [ ! -e "$app_path" ]; then
    echo "Skip login item (not installed): $app_name"
    return
  fi
  if osascript -e "tell application \"System Events\" to get the name of every login item" 2>/dev/null | tr ',' '\n' | grep -qx " *$app_name *"; then
    echo "Login item already present: $app_name"
  else
    osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app_path\", hidden:false, name:\"$app_name\"}" >/dev/null
    echo "Added login item: $app_name"
  fi
}

ensure_login_item "/Applications/Ice.app"

echo "Restarting affected apps..."
killall Finder Dock SystemUIServer 2>/dev/null || true

echo "macOS defaults applied. Some changes may require a logout/restart."
