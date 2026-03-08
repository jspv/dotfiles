#!/usr/bin/env bash
#
# Git
#
# Ensure ~/.gitconfig.local exists with user identity.

cd "$(dirname "$0")/.."
. "script/lib.sh"

GITCONFIG_LOCAL="$HOME/.gitconfig.local"

if [ -f "$GITCONFIG_LOCAL" ]; then
  success "gitconfig.local already exists"
  exit 0
fi

# Non-interactive (e.g. bootstrap --force): warn and move on
if ! [ -t 0 ]; then
  info "~/.gitconfig.local not found — run 'dot' interactively to set up git identity\n"
  exit 0
fi

# Interactive: prompt for name and email
user "What is your git author name? "
read -e git_authorname
user "What is your git author email? "
read -e git_authoremail

git config --file "$GITCONFIG_LOCAL" user.name "$git_authorname"
git config --file "$GITCONFIG_LOCAL" user.email "$git_authoremail"

success "Created $GITCONFIG_LOCAL"
