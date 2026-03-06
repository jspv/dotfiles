# Copy SSH public key to clipboard
if [[ "$OSTYPE" == darwin* ]]; then
  alias pubkey="cat ~/.ssh/id_ed25519.pub | pbcopy && echo '=> Public key copied to pasteboard.'"
elif (( $+commands[xclip] )); then
  alias pubkey="cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard && echo '=> Public key copied to clipboard.'"
fi
