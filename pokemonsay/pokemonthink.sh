#!/bin/sh

#
# Call pokemonsay with the think option.
#

script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/pokemonsay.sh" --think "$@"
