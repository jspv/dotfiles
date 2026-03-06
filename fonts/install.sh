#!/usr/bin/env bash
#
# Fonts — install Meslo LG S Nerd Font from the official Nerd Fonts project
#
set -e

source "$(cd "$(dirname "$0")/.." && pwd)/script/lib.sh"

if [ "${DOTFILES_NO_NET:-0}" = "1" ]; then
  info 'Skipping font install (--no-net)\n'
  exit 0
fi

FONT_CASK="font-meslo-lg-nerd-font"
FONT_VERSION="v3.4.0"
FONT_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}"

if [ "$(uname)" = "Darwin" ]; then
  if command -v brew >/dev/null 2>&1; then
    if brew list --cask "$FONT_CASK" &>/dev/null; then
      info 'Meslo LG Nerd Font already installed via Homebrew'
    else
      info 'Installing Meslo LG Nerd Font via Homebrew'
      brew install --cask "$FONT_CASK"
    fi
    success 'Meslo LG Nerd Font installed'
  else
    fail 'Homebrew not found — install Homebrew first'
  fi

elif [ "$(uname)" = "Linux" ]; then
  FONT_DIR="${HOME}/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  if ls "$FONT_DIR"/MesloLGSNerdFont*.ttf &>/dev/null; then
    info 'Meslo LG Nerd Font already installed'
  else
    info 'Downloading Meslo LG Nerd Font'
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT
    curl -fsSL "${FONT_BASE_URL}/Meslo.tar.xz" -o "$tmpdir/Meslo.tar.xz"
    tar -xf "$tmpdir/Meslo.tar.xz" -C "$tmpdir"
    # Install only MesloLGS (small line gap) mono variants
    cp "$tmpdir"/MesloLGSNerdFontMono-*.ttf "$FONT_DIR/"
    fc-cache -f "$FONT_DIR"
  fi
  success 'Meslo LG Nerd Font installed'

else
  fail "Unknown OS — don't know how to install fonts"
fi
