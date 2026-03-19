#!/usr/bin/env bash
#
# Git
#
# - Symlinks ~/.gitconfig.managed → repo's git/gitconfig.managed
# - Replaces the old ~/.gitconfig symlink with a real file that includes it
# - Migrates user identity from ~/.gitconfig.local if present
# - Prompts for identity if not yet configured

cd "$(dirname "$0")/.."
. "script/lib.sh"

DOTFILES="$(pwd)"
MANAGED_SRC="$DOTFILES/git/gitconfig.managed"
MANAGED_LINK="$HOME/.gitconfig.managed"
GITCONFIG="$HOME/.gitconfig"
GITCONFIG_LOCAL="$HOME/.gitconfig.local"

# 1. Symlink ~/.gitconfig.managed → repo file
if [ -L "$MANAGED_LINK" ] && [ "$(readlink "$MANAGED_LINK")" = "$MANAGED_SRC" ]; then
  success "~/.gitconfig.managed already linked"
else
  ln -sf "$MANAGED_SRC" "$MANAGED_LINK"
  success "Linked ~/.gitconfig.managed"
fi

# 2. Replace old ~/.gitconfig symlink with a real file
if [ -L "$GITCONFIG" ]; then
  rm "$GITCONFIG"
  info "Removed old ~/.gitconfig symlink"
fi

if [ ! -f "$GITCONFIG" ]; then
  printf '[include]\n\tpath = ~/.gitconfig.managed\n' > "$GITCONFIG"
  success "Created ~/.gitconfig"
elif ! grep -q 'gitconfig.managed' "$GITCONFIG"; then
  printf '\n[include]\n\tpath = ~/.gitconfig.managed\n' >> "$GITCONFIG"
  success "Added gitconfig.managed include to ~/.gitconfig"
else
  success "~/.gitconfig already configured"
fi

# 3. Migrate identity from ~/.gitconfig.local if present
if [ -f "$GITCONFIG_LOCAL" ]; then
  git_name="$(git config --file "$GITCONFIG_LOCAL" user.name 2>/dev/null)"
  git_email="$(git config --file "$GITCONFIG_LOCAL" user.email 2>/dev/null)"
  if [ -n "$git_name" ] || [ -n "$git_email" ]; then
    [ -n "$git_name" ]  && git config --file "$GITCONFIG" user.name  "$git_name"
    [ -n "$git_email" ] && git config --file "$GITCONFIG" user.email "$git_email"
    success "Migrated git identity from ~/.gitconfig.local to ~/.gitconfig"
  fi
fi

# 4. Prompt for identity if still missing
git_name="$(git config --file "$GITCONFIG" user.name 2>/dev/null)"
git_email="$(git config --file "$GITCONFIG" user.email 2>/dev/null)"

if [ -z "$git_name" ] || [ -z "$git_email" ]; then
  if ! [ -t 0 ]; then
    info "Git identity not set — run 'dot' interactively to configure user.name and user.email\n"
    exit 0
  fi

  if [ -z "$git_name" ]; then
    user "What is your git author name? "
    read -e git_name
    git config --file "$GITCONFIG" user.name "$git_name"
  fi

  if [ -z "$git_email" ]; then
    user "What is your git author email? "
    read -e git_email
    git config --file "$GITCONFIG" user.email "$git_email"
  fi

  success "Git identity configured"
fi

# 5. Initialize git-lfs if installed
if command -v git-lfs &>/dev/null; then
  git lfs install --skip-smudge 2>/dev/null
  success "git-lfs initialized"
fi
