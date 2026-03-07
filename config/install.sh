#!/usr/bin/env bash
#
# Config
#
# Symlinks individual config subdirs into ~/.config instead of
# symlinking the entire ~/.config directory.

cd "$(dirname "$0")"
CONFIG_DIR="$(pwd -P)"

. "$CONFIG_DIR/../script/lib.sh"

mkdir -p "$HOME/.config"

# If ~/.config is a symlink (old approach), migrate to per-subdir symlinks.
# Move existing app data out of the repo into the real ~/.config first.
if [[ -L "$HOME/.config" ]]; then
  old_target="$(readlink "$HOME/.config")"
  echo "Migrating ~/.config from directory symlink to per-subdir symlinks"
  rm "$HOME/.config"
  mkdir -p "$HOME/.config"
  # Move all contents from old symlink target into real ~/.config
  if [[ -d "$old_target" ]]; then
    for item in "$old_target"/*; do
      [[ -e "$item" ]] || continue
      name="$(basename "$item")"
      # Skip dirs we track in the repo — those will be symlinked below
      [[ -d "$CONFIG_DIR/$name" ]] && continue
      mv "$item" "$HOME/.config/" 2>/dev/null || true
    done
  fi
fi

# Symlink each tracked config subdir into ~/.config
for dir in "$CONFIG_DIR"/*/; do
  [[ -d "$dir" ]] || continue
  name="$(basename "$dir")"
  # Skip legacy config.symlink dir (untracked app data)
  [[ "$name" == "config.symlink" ]] && continue
  link_files "$dir" "$HOME/.config/$name"
done
