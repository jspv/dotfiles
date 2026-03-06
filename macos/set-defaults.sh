#!/usr/bin/env bash
#
# macOS-specific system defaults
#
# Run manually or via `dot` to apply macOS preferences.
# Add new defaults as needed — keep this file to active settings only.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "$SCRIPT_DIR/../script/lib.sh"

# Close any open System Preferences/Settings panes, to prevent them from
# overriding settings we're about to change
osascript -e 'tell application "System Settings" to quit' 2>/dev/null
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null

###############################################################################
# Terminal fonts                                                              #
###############################################################################

info 'Trying to set terminal fonts to MesloLGS Nerd Font\n'
fontskip=false
if ! brew list --cask font-meslo-lg-nerd-font &>/dev/null; then
  if [[ -f "${HOME}/.dotfiles/fonts/install.sh" ]]; then
    info 'Running fonts installer\n'
    "${HOME}/.dotfiles/fonts/install.sh"
  else
    info 'MesloLGS Nerd Font not installed and no installer found, skipping\n'
    fontskip=true
  fi
fi

if [ "$fontskip" = false ]; then
  osascript <<'EOD'
tell application "Terminal"
    set ProfilesNames to name of every settings set
    repeat with ProfileName in ProfilesNames
        set font name of settings set ProfileName to "MesloLGS Nerd Font Mono"
        set font size of settings set ProfileName to 12
    end repeat
end tell
EOD
  success 'Set terminal fonts to MesloLGS Nerd Font'
fi

###############################################################################
# iTerm2 (disabled — prefs managed locally, not in repo)                      #
###############################################################################

# # Point iTerm2 at a shared prefs directory
# defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$HOME/.dotfiles/iterm2"
# defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
# defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -int 1
# defaults write com.googlecode.iterm2 "NoSyncNeverRemindPrefsChangesLostForFile_selection" -int 1
# defaults write com.googlecode.iterm2 PromptOnQuit -bool false
# success 'iTerm2 defaults'

###############################################################################
# Dock                                                                        #
###############################################################################

defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 50
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true
success 'Dock defaults'

###############################################################################
# Finder                                                                      #
###############################################################################

# List view by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Show path bar and status bar
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Disable extension change warning
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Avoid .DS_Store on network and USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
success 'Finder defaults'

###############################################################################
# Keyboard                                                                    #
###############################################################################

# Fast key repeat (lower = faster)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Disable press-and-hold for keys (enable key repeat everywhere)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Disable auto-correct and smart substitutions
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
success 'Keyboard defaults'

###############################################################################
# Trackpad                                                                    #
###############################################################################

# Tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
success 'Trackpad defaults'

###############################################################################
# Screenshots                                                                 #
###############################################################################

# Save to ~/Screenshots instead of Desktop
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"
# Save as PNG
defaults write com.apple.screencapture type -string "png"
# Disable shadow in window captures
defaults write com.apple.screencapture disable-shadow -bool true
success 'Screenshot defaults'

###############################################################################
# Activity Monitor                                                            #
###############################################################################

defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor IconType -int 5
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0
success 'Activity Monitor defaults'

###############################################################################
# Restart affected apps                                                       #
###############################################################################

for app in "Dock" "Finder" "SystemUIServer"; do
  killall "${app}" &>/dev/null || true
done

success "macOS defaults applied. Some changes may require a logout/restart."
echo ''
