#!/bin/sh

usage() {
	echo
	echo "  Description: Pokemonsay makes a pokémon say something to you."
	echo
	echo "  Usage: $(basename "$0") [-p POKEMON_NAME] [-f COW_FILE] [-w COLUMN] [-l] [-n] [-t] [-h] [MESSAGE]"
	echo
	echo "  Options:"
	echo "    -p, --pokemon POKEMON_NAME"
	echo "      Choose what pokemon will be used by its name."
	echo "    -f, --file COW_FILE"
	echo "      Specify which .cow file should be used."
	echo "    -w, --word-wrap COLUMN"
	echo "      Specify roughly where messages should be wrapped."
	echo "    -l, --list"
	echo "      List all the pokémon available."
	echo "    -n, --no-name"
	echo "      Do not tell the pokémon name."
	echo "    -t, --think"
	echo "      Make the pokémon think the message, instead of saying it."
	echo "    -F, --fortune"
	echo "      Use a random fortune as the message."
	echo "    -h, --help"
	echo "      Display this usage message."
	echo "    MESSAGE"
	echo "      What the pokemon will say. If you don't provide a message, a message will be read form standard input."
	exit 0
}

# Where the pokemon are — resolve through symlinks to the real script location.
script_dir="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || readlink "$0" 2>/dev/null || echo "$0")")" && pwd)"
pokemon_path="$script_dir/cows"

list_pokemon() {
	echo "Pokémon available in '$pokemon_path/':"
	echo
	all_pokemon="$(find "$pokemon_path" -name "*.cow" | sort)"
	echo "$all_pokemon" | while read -r pokemon; do
		pokemon=${pokemon##*/}
		pokemon=${pokemon%.cow}
		echo "$pokemon"
	done
	exit 0
}

# While there are arguments, keep reading them.
while [ $# -gt 0 ]
do
key="$1"
case $key in
	-p|--pokemon)
		POKEMON_NAME="$2"
		shift; shift
		;;
	-p=*|--pokemon=*)
		POKEMON_NAME="${1#*=}"
		shift
		;;
	-f|--file)
		COW_FILE="$2"
		shift; shift
		;;
	-f=*|--file=*)
		COW_FILE="${1#*=}"
		shift
		;;
	-w|--word-wrap)
		WORD_WRAP="$2"
		shift; shift
		;;
	-w=*|--word-wrap=*)
		WORD_WRAP="${1#*=}"
		shift
		;;
	-l|--list)
		list_pokemon
		;;
	-n|--no-name)
		DISPLAY_NAME="NO"
		shift
		;;
	-t|--think)
		THINK="YES"
		shift
		;;
	-F|--fortune)
		FORTUNE="YES"
		shift
		;;
	-h|--help)
		usage
		;;
	-*)
		echo
		echo "  Unknown option '$1'"
		usage
		;;
	*)
		# Append this word to the message.
		if [ -n "$MESSAGE" ]; then
			MESSAGE="$MESSAGE $1"
		else
			MESSAGE="$1"
		fi
		shift
		;;
esac
done

# If --fortune was requested, pick a random fortune as the message.
if [ -n "$FORTUNE" ]; then
	fortune_file="$script_dir/fortunes.txt"
	if [ -f "$fortune_file" ]; then
		# Fortunes are delimited by lines containing only '%'.
		if command -v shuf >/dev/null 2>&1; then
			MESSAGE=$(awk 'BEGIN{RS="\n%\n"} {a[NR]=$0} END{for(i=1;i<=NR;i++) print i"\t"a[i]}' "$fortune_file" | shuf -n1 | cut -f2-)
		else
			MESSAGE=$(awk 'BEGIN{RS="\n%\n"; srand()} {a[NR]=$0} END{print a[int(rand()*NR)+1]}' "$fortune_file")
		fi
	else
		echo "Fortune file not found: $fortune_file" >&2
		exit 1
	fi
fi

# Define where to wrap the message.
if [ -n "$WORD_WRAP" ]; then
	word_wrap="-W $WORD_WRAP"
fi

# Define which pokemon should be displayed.
if [ -n "$POKEMON_NAME" ]; then
	pokemon_cow=$(find "$pokemon_path" -name "$POKEMON_NAME.cow")
elif [ -n "$COW_FILE" ]; then
	pokemon_cow="$COW_FILE"
else
	# Use shuf if available, otherwise awk-based random selection (works on stock macOS).
	if command -v shuf >/dev/null 2>&1; then
		pokemon_cow=$(find "$pokemon_path" -name "*.cow" | shuf -n1)
	else
		pokemon_cow=$(find "$pokemon_path" -name "*.cow" | awk 'BEGIN{srand()}{a[NR]=$0}END{print a[int(rand()*NR)+1]}')
	fi
fi

# Get the pokemon name.
filename=$(basename "$pokemon_cow")
pokemon_name="${filename%.*}"

# Call cowsay or cowthink.
if [ -n "$MESSAGE" ]; then
	if [ -n "$THINK" ]; then
		echo "$MESSAGE" | cowthink -f "$pokemon_cow" $word_wrap
	else
		echo "$MESSAGE" | cowsay -f "$pokemon_cow" $word_wrap
	fi
else
	if [ -n "$THINK" ]; then
		cowthink -f "$pokemon_cow" $word_wrap
	else
		cowsay -f "$pokemon_cow" $word_wrap
	fi
fi

# Write the pokemon name, unless requested otherwise.
if [ -z "$DISPLAY_NAME" ]; then
	echo "$pokemon_name"
fi
