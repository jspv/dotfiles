#!/usr/bin/env bash
#
# Claude Code
#
# Links the status line script into ~/.claude and merges the statusLine key
# into ~/.claude/settings.json (the rest of that file is machine-specific
# and left alone).
#
# An existing statusLine that differs from ours is kept unless run with --force.

cd "$(dirname "$0")"
CLAUDE_DIR="$(pwd -P)"

. "$CLAUDE_DIR/../script/lib.sh"

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

SETTINGS="$HOME/.claude/settings.json"
# $HOME stays literal here; the shell Claude Code runs the command in expands it.
STATUSLINE_CMD='sh "$HOME/.claude/statusline.sh"'

if ! command -v jq >/dev/null 2>&1; then
  echo "  Skipping Claude Code status line: jq is required (brew install jq / apt install jq)."
  exit 0
fi
command -v git >/dev/null 2>&1 || echo "  Warning: git not found; status line will not show the branch."

mkdir -p "$HOME/.claude"
link_files "$CLAUDE_DIR/statusline.sh" "$HOME/.claude/statusline.sh"

# On stock macOS, `date -d` is missing; the script falls back to gdate, then `date -r`.
if [[ "$(uname -s)" == "Darwin" ]] && ! command -v gdate >/dev/null 2>&1; then
  echo "  Note: gdate not found; status line uses BSD 'date -r' (brew install coreutils for GNU date)."
fi

[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

if ! jq -e . "$SETTINGS" >/dev/null 2>&1; then
  echo "  Warning: $SETTINGS is not valid JSON; not adding statusLine."
  exit 0
fi

if jq -e --arg cmd "$STATUSLINE_CMD" \
     '.statusLine == {type: "command", command: $cmd}' "$SETTINGS" >/dev/null; then
  success "statusLine already set in $SETTINGS"
  exit 0
fi

if [[ $FORCE -eq 0 ]] && jq -e '.statusLine != null' "$SETTINGS" >/dev/null; then
  echo "  Keeping existing statusLine in $SETTINGS:"
  jq -c .statusLine "$SETTINGS" | sed 's/^/    /'
  echo "  To replace it with the dotfiles status line, run: $CLAUDE_DIR/install.sh --force"
  exit 0
fi

tmp="$(mktemp)" || exit 1
# Write back with cat (not mv) so the file's mode and any symlink are preserved.
if jq --arg cmd "$STATUSLINE_CMD" \
     '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp" \
   && cat "$tmp" > "$SETTINGS"; then
  success "statusLine set in $SETTINGS"
else
  echo "  Warning: failed to update $SETTINGS"
fi
rm -f "$tmp"
exit 0
