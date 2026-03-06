# Add npm global bin to PATH
if [[ -x /opt/homebrew/bin/brew ]]; then
  path=("$(/opt/homebrew/bin/brew --prefix)/share/npm/bin" $path)
elif [[ -x /usr/local/bin/brew ]]; then
  path=("$(/usr/local/bin/brew --prefix)/share/npm/bin" $path)
fi
