#!/usr/bin/env bash
#
# iTerm2
#
# Symlinks DynamicProfiles, points iTerm2 at this folder for preferences,
# and configures the git clean filter that strips noise keys on commit.

cd "$(dirname "$0")"
ITERM2_DIR="$(pwd -P)"

. ../script/lib.sh

[[ "$(uname -s)" == "Darwin" ]] || exit 0

# Symlink each DynamicProfile file into iTerm2's expected location.
# We link individual files rather than the directory because iTerm2
# recreates the DynamicProfiles directory if it disappears while running.
DEST="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
mkdir -p "$DEST"
for f in "$ITERM2_DIR/DynamicProfiles"/*.json; do
  [ -f "$f" ] || continue
  ln -sfn "$f" "$DEST/$(basename "$f")"
done
success "linked DynamicProfiles"

# Point iTerm2 at this folder for preferences
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$ITERM2_DIR"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -int 1
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile_selection -int 1
success "iTerm2 prefs configured"

# Configure git clean filter so noise keys are stripped on commit
REPO_ROOT="$(cd .. && pwd -P)"
git -C "$REPO_ROOT" config filter.iterm2-clean.clean \
  "python3 $ITERM2_DIR/clean-prefs.py"
git -C "$REPO_ROOT" config filter.iterm2-clean.smudge cat
success "git clean filter configured"

# Create personal profiles placeholder if absent
if [ ! -f "$ITERM2_DIR/DynamicProfiles/personal.local.json" ]; then
  cat > "$ITERM2_DIR/DynamicProfiles/personal.local.json" <<'EOF'
{
  "Profiles": []
}
EOF
  info "created personal.local.json placeholder"
fi
