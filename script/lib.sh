#!/usr/bin/env bash
#
# Shared helper functions for dotfiles scripts.
# Source this file: . "$(dirname "$0")/../script/lib.sh"
# or from bootstrap:  . "$(dirname "$0")/lib.sh"

info () {
  printf "  [ \033[00;34m..\033[0m ] $1"
}

user () {
  printf "\r  [ \033[0;33m?\033[0m ] $1 "
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit 1
}

check_network () {
  # Quick connectivity test — try to reach GitHub (used by most installers)
  if curl -fsS --connect-timeout 5 https://github.com >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

require_network () {
  if [ "${DOTFILES_NO_NET:-}" = "1" ]; then
    return
  fi
  if ! check_network; then
    fail "No network access (could not reach github.com).

    If you are behind a proxy, export these before running:

      export http_proxy=http://your-proxy:port
      export https_proxy=http://your-proxy:port
      export no_proxy=localhost,127.0.0.1

    Or run with --no-net to skip network-dependent steps:

      $0 --no-net"
  fi
}

persist_proxy () {
  # If proxy env vars are set, offer to save them to ~/.zprofile.local
  local proxy_vars=""
  [ -n "${http_proxy:-}" ]  && proxy_vars+="export http_proxy=\"$http_proxy\"\n"
  [ -n "${https_proxy:-}" ] && proxy_vars+="export https_proxy=\"$https_proxy\"\n"
  [ -n "${no_proxy:-}" ]    && proxy_vars+="export no_proxy=\"$no_proxy\"\n"
  [ -n "${HTTP_PROXY:-}" ]  && proxy_vars+="export HTTP_PROXY=\"$HTTP_PROXY\"\n"
  [ -n "${HTTPS_PROXY:-}" ] && proxy_vars+="export HTTPS_PROXY=\"$HTTPS_PROXY\"\n"
  [ -n "${NO_PROXY:-}" ]    && proxy_vars+="export NO_PROXY=\"$NO_PROXY\"\n"

  [ -z "$proxy_vars" ] && return

  local target="$HOME/.zprofile.local"

  # Skip if proxy vars are already in the file
  if [ -f "$target" ] && grep -q 'http_proxy\|https_proxy\|HTTP_PROXY\|HTTPS_PROXY' "$target" 2>/dev/null; then
    return
  fi

  user "Proxy env vars detected. Save to $target for future sessions? [y/N] "
  read -n 1 reply
  echo
  if [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
    printf "\n# Proxy settings (added by dotfiles bootstrap)\n" >> "$target"
    printf "$proxy_vars" >> "$target"
    success "Proxy settings saved to $target"
  fi
}

pkg_install () {
  # Install one or more packages using the platform's package manager.
  # Usage: pkg_install cowsay fortune uv
  if [[ -x /opt/homebrew/bin/brew ]]; then
    /opt/homebrew/bin/brew install "$@"
  elif [[ -x /usr/local/bin/brew ]]; then
    /usr/local/bin/brew install "$@"
  elif command -v apt-get &>/dev/null; then
    sudo apt-get install -y "$@"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$@"
  elif command -v yum &>/dev/null; then
    sudo yum install -y "$@"
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$@"
  else
    fail "No supported package manager found. Please install manually: $*"
  fi
}

link_files () {
  local src=$1 dst=$2

  local overwrite='' backup='' skip=''
  local action=''

  if [[ -f "$dst" ]] || [[ -d "$dst" ]] || [[ -L "$dst" ]]
  then
    if [ ! "$overwrite_all" ] && [ ! "$backup_all" ] && [ ! "$skip_all" ]
    then

      # shellcheck disable=SC2155
      local currentSrc="$(readlink "$dst")"

      # Resolve physical paths so symlink vs real path comparisons work
      local resolvedCurrent="" resolvedSrc=""
      if [[ -e "$currentSrc" ]]; then
        resolvedCurrent="$(cd "$(dirname "$currentSrc")" && pwd -P)/$(basename "$currentSrc")"
      fi
      if [[ -e "$src" ]]; then
        resolvedSrc="$(cd "$(dirname "$src")" && pwd -P)/$(basename "$src")"
      fi

      if [ "$currentSrc" == "$src" ] || { [ -n "$resolvedCurrent" ] && [ "$resolvedCurrent" == "$resolvedSrc" ]; }
      then

        skip=true;

      else

        user "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        read -n 1 action

        case "$action" in
          o )
            overwrite=true;;
          O )
            overwrite_all=true;;
          b )
            backup=true;;
          B )
            backup_all=true;;
          s )
            skip=true;;
          S )
            skip_all=true;;
          * )
            ;;
        esac

      fi

    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" == "true" ]
    then
      if [[ -f "$dst" ]] && [[ ! -L "$dst" ]] && [[ ! -e "${dst}.local" ]]; then
        mv "$dst" "${dst}.local"
        success "moved $dst to ${dst}.local (preserving as local overrides)"
      else
        rm -rf "$dst"
        success "removed $dst"
      fi
    fi

    if [ "$backup" == "true" ]
    then
      mv "$dst" "${dst}.backup"
      success "moved $dst to ${dst}.backup"
    fi

    if [ "$skip" == "true" ]
    then
      success "skipped $src"
    fi
  fi

  if [ "$skip" != "true" ]  # "false" or empty
  then
    ln -s "$1" "$2"
    success "linked $1 to $2"
  fi
}
