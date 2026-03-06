# Single source of truth for PATH setup.
# Using path.zsh ensures this runs for both login and non-login shells (e.g. VS Code).

# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

path=(
  $HOME/.local/bin(N)
  $HOME/bin(N)
  /opt/{homebrew,local}/{,s}bin(N)
  /usr/local/{,s}bin(N)
  $path
)

# Add brew-dependent paths if brew is available
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
