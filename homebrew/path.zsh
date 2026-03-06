# Ensure Homebrew is on PATH in non-login interactive shells.
# Login shells get this from zprofile; this covers the rest.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
