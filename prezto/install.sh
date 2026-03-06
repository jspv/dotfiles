#!/usr/bin/env bash
#
# PREZTO
#
# Symlinks ~/.zprezto to the prezto submodule in this repo.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREZTO_SRC="$SCRIPT_DIR/prezto"
LINK="$HOME/.zprezto"

. "$SCRIPT_DIR/../script/lib.sh"

if [ ! -d "$PREZTO_SRC" ]; then
  fail "prezto submodule not initialized — run: git submodule update --init --recursive prezto/prezto"
fi

link_files "$PREZTO_SRC" "$LINK"
