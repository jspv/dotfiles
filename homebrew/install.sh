#!/usr/bin/env bash
#
# Homebrew
#
# This installs some of the common dependencies needed (or at least desired)
# using Homebrew.

# Only run on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
  exit 0
fi

# Check for Homebrew
# Check for the actual brew binary, not command -v (which finds the ~/bin wrapper)
if ! [[ -x /opt/homebrew/bin/brew || -x /usr/local/bin/brew ]]
then
  echo "  Installing Homebrew for you."

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

fi

exit 0
