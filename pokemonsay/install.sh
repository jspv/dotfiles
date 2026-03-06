#!/usr/bin/env bash
#
# Install pokemonsay dependencies: cowsay, uv (Python)
#

. "$(dirname "$0")/../script/lib.sh"

if ! command -v cowsay &>/dev/null; then
  info "Installing cowsay\n"
  pkg_install cowsay
  if command -v cowsay &>/dev/null; then
    success "cowsay installed"
  else
    fail "cowsay installation failed"
  fi
else
  success "cowsay already installed"
fi

if ! command -v uv &>/dev/null; then
  info "Installing uv via pip\n"
  python3 -m pip install --user uv
  if command -v uv &>/dev/null; then
    success "uv installed"
  else
    fail "uv installation failed"
  fi
else
  success "uv already installed"
fi

# Symlink pokemonsay scripts into ~/.local/bin
mkdir -p "$HOME/.local/bin"
script_dir="$(cd "$(dirname "$0")" && pwd)"
link_files "$script_dir/pokemonsay.sh"   "$HOME/.local/bin/pokemonsay"
link_files "$script_dir/pokemonthink.sh" "$HOME/.local/bin/pokemonthink"
