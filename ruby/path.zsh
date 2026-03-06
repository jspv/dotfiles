# Add Homebrew Ruby to PATH (prefer over system Ruby)
if [[ -x /opt/homebrew/bin/brew ]]; then
  path=("$(/opt/homebrew/bin/brew --prefix ruby)/bin" $path)
elif [[ -x /usr/local/bin/brew ]]; then
  path=("$(/usr/local/bin/brew --prefix ruby)/bin" $path)
fi
