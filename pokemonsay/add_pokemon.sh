#!/bin/sh
#
# Download Pokémon sprites from PokeAPI and convert them to .cow files.
#
# Usage: ./add_pokemon.sh [--force] <name-or-number> [name-or-number ...]
#
# Examples:
#   ./add_pokemon.sh pikachu charizard mew
#   ./add_pokemon.sh 152 153 154
#   ./add_pokemon.sh --force pikachu    # overwrite existing

set -e

script_dir="$(cd "$(dirname "$0")" && pwd)"
cows_dir="$script_dir/cows"
force=0
max_height=13
show_preview=1

usage() {
	echo "Usage: $(basename "$0") [options] <name-or-number> [name-or-number ...]"
	echo
	echo "Download Pokémon sprites from PokeAPI and convert to .cow files."
	echo
	echo "Options:"
	echo "  --force            Overwrite existing .cow files"
	echo "  --height N         Max height in terminal rows (default: 13)"
	echo "  --full-size        Don't scale down (use native sprite resolution)"
	echo "  --quiet            Don't show preview after generating"
	echo "  --help             Show this help"
	echo
	echo "Examples:"
	echo "  $(basename "$0") pikachu charizard mew"
	echo "  $(basename "$0") 152 153 154"
	echo "  $(basename "$0") --force pikachu"
	echo "  $(basename "$0") --height 20 pikachu   # larger"
	echo "  $(basename "$0") --full-size pikachu    # native 96x96 sprite"
	exit 0
}

# Check dependencies
if ! command -v curl >/dev/null 2>&1; then
	echo "Error: curl is required" >&2
	exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
	echo "Error: uv is required (brew install uv)" >&2
	exit 1
fi

# Parse arguments
pokemon_list=""
while [ $# -gt 0 ]; do
	case "$1" in
		--force)
			force=1
			shift
			;;
		--height)
			max_height="$2"
			shift; shift
			;;
		--full-size)
			max_height=""
			shift
			;;
		--quiet|-q)
			show_preview=0
			shift
			;;
		--help|-h)
			usage
			;;
		*)
			pokemon_list="$pokemon_list $1"
			shift
			;;
	esac
done

if [ -z "$pokemon_list" ]; then
	echo "Error: specify at least one Pokémon name or number" >&2
	echo "Run with --help for usage" >&2
	exit 1
fi

# Create temp dir for downloads
tmp_dir=$(mktemp -d)
trap "rm -rf \"$tmp_dir\"" EXIT

mkdir -p "$cows_dir"

for pokemon in $pokemon_list; do
	# Lowercase the input for API lookup
	pokemon_lower=$(echo "$pokemon" | tr '[:upper:]' '[:lower:]')

	echo "Looking up '$pokemon_lower' on PokeAPI..."

	# Fetch Pokémon data from PokeAPI
	api_response="$tmp_dir/api_response.json"
	http_code=$(curl -s -w "%{http_code}" -o "$api_response" "https://pokeapi.co/api/v2/pokemon/$pokemon_lower")

	if [ "$http_code" != "200" ]; then
		echo "  Error: Pokémon '$pokemon' not found (HTTP $http_code), skipping" >&2
		continue
	fi

	# Extract name and sprite URL using python3 (always available on macOS)
	# Write values to a file instead of eval to avoid shell injection
	extracted="$tmp_dir/extracted.txt"
	python3 -c "
import json, sys
with open('$api_response') as f:
    d = json.load(f)
name = d['name']
display_name = name.replace('-', ' ').title().replace(' ', '-')
if '-' not in name:
    display_name = name.capitalize()
sprite_url = d['sprites']['front_default']
if not sprite_url:
    sys.exit(1)
with open('$extracted', 'w') as out:
    out.write(display_name + '\n')
    out.write(sprite_url + '\n')
"

	if [ $? -ne 0 ]; then
		echo "  Error: no sprite available for this Pokémon" >&2
		continue
	fi

	pokemon_name=$(sed -n '1p' "$extracted")
	sprite_url=$(sed -n '2p' "$extracted")

	cow_file="$cows_dir/$pokemon_name.cow"

	# Skip if already exists (unless --force)
	if [ -f "$cow_file" ] && [ "$force" -eq 0 ]; then
		echo "  $pokemon_name.cow already exists, skipping (use --force to overwrite)"
		continue
	fi

	# Download sprite
	sprite_file="$tmp_dir/$pokemon_name.png"
	echo "  Downloading sprite for $pokemon_name..."
	curl -s -o "$sprite_file" "$sprite_url"

	if [ ! -s "$sprite_file" ]; then
		echo "  Error: failed to download sprite for $pokemon_name" >&2
		continue
	fi

	# Convert to cow file using png2cow
	echo "  Converting to $pokemon_name.cow..."
	height_arg=""
	if [ -n "$max_height" ]; then
		height_arg="--max-height $max_height"
	fi
	uv run --project "$script_dir" python3 "$script_dir/png2cow.py" $height_arg "$sprite_file" "$cow_file"

	if [ "$show_preview" -eq 1 ]; then
		echo "$pokemon_name says hello!" | "$script_dir/pokemonsay.sh" -p "$pokemon_name"
	else
		echo "  Done: $cow_file"
	fi
done

echo "Finished."
